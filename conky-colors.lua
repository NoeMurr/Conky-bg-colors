--[[
MIT License

Copyright (c) 2019 Noè Murr

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
--]] 

--[[
    This file contains a usefull function to extract a color palette from an 
    image. It uses the program convert from the suite of tools ImageMagick
    (https://imagemagick.org/) so it is a dependency of this software.

    Another dipendency is the lua file system library 
    (https://keplerproject.github.io/luafilesystem/).
]]


require("lfs")
-- no function checks for errors.
-- you should check for them

function isFile(name)
    if type(name)~="string" then return false end
    if not isDir(name) then
        return os.rename(name,name) and true or false
        -- note that the short evaluation is to
        -- return false instead of a possible nil
    end
    return false
end

function isFileOrDir(name)
    if type(name)~="string" then return false end
    return os.rename(name, name) and true or false
end

function isDir(name)
    if type(name)~="string" then return false end
    local cd = lfs.currentdir()
    local is = lfs.chdir(name) and true or false
    lfs.chdir(cd)
    return is
end

-- This function takes the path of the image to extract, the number 
-- of colors to extract (16 as default) and the cache directory where to save
-- the temporary palette image (.conky-color-cache as default). 
function extract_colors_from_image(path, number_of_colors, cache_dir)

    -- checking for arguments
    assert(isFile(path), "The path is not a valid file")

    -- checking for number type and assigning a default value 
    number_of_colors = number_of_colors or 16
    assert(type(number_of_colors) == 'number',
            'The number of color must be a number')
    
    -- checking for number type and assigning a default value 
    cache_dir = cache_dir or '.conky-color-cache' 
    assert(type(cache_dir) == 'string', 
            'The cache_dir parameter must be a string')
    
    if not isDir(cache_dir) then
        -- trying to create the directory
        if not lfs.mkdir(cache_dir) then 
            error("can't create the cache directory")
        end
    end
    
    -- checking the cache to a palette with the required parameters
    local palette_name = cache_dir .. '/' .. path:gsub('/', '_') .. '_' .. 
                         tostring(number_of_colors) .. '.png'
    
    if not isFile(palette_name) then 
        -- the file file does not exists I have to create the palette
        print('I have to create the palette')
        print('palete name: ' .. palette_name)

        -- creating the color palette
        local cmd = 'convert "' .. path .. '" +dither ' ..
                    '-colors ' .. tostring(number_of_colors) ..
                    ' -unique-colors -filter box "' .. palette_name .. '"'

        print(cmd)
        if not os.execute(cmd) then 
            error("Cannot create the color palette!")
        end
    end

    -- converting the image in txt
    local cmd = 'convert "' .. palette_name .. '" txt:-'
    local out = io.popen(cmd)

    if not out then error("cannot extract the colors") end

    -- extracting the hex values from the txt
    local i = 0
    local colors = {}
    local matching_hex = "%s+#([A-F0-9][A-F0-9][A-F0-9]" ..
                         "[A-F0-9][A-F0-9][A-F0-9]%s+)"
    for l in out:lines() do
        local m = l:match(matching_hex)
        if m then
            colors[i] = m 
            i = i+1
        end
    end
    out:close()

    -- returning the colors.
    return colors
end