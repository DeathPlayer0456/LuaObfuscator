-- modules/minifier.lua
-- Code minification utilities

local Minifier = {}

function Minifier.removeComments(code)
    local result = {}
    local i = 1
    local inString = false
    local stringChar = nil
    
    while i <= #code do
        local char = code:sub(i, i)
        local next = code:sub(i + 1, i + 1)
        
        -- TODO Handle strings
        if (char == '"' or char == "'") and (i == 1 or code:sub(i - 1, i - 1) ~= "\\") then
            if not inString then
                inString = true
                stringChar = char
            elseif char == stringChar then
                inString = false
                stringChar = nil
            end
            table.insert(result, char)
            i = i + 1
        
        -- TODO Handle comments when not in string
        elseif not inString and char == "-" and next == "-" then
            -- Check for multiline comment
            if code:sub(i + 2, i + 3) == "[[" then
                local endPos = code:find("]]", i + 4, true)
                if endPos then
                    i = endPos + 2
                else
                    i = #code + 1
                end
            else
                -- Single line comment
                while i <= #code and code:sub(i, i) ~= "\n" do
                    i = i + 1
                end
            end
        else
            table.insert(result, char)
            i = i + 1
        end
    end
    
    return table.concat(result)
end

function Minifier.removeWhitespace(code)
    local result = {}
    local prev = ""
    local inString = false
    local stringChar = nil
    
    for i = 1, #code do
        local char = code:sub(i, i)
        
        -- Track strings
        if (char == '"' or char == "'") and (i == 1 or code:sub(i - 1, i - 1) ~= "\\") then
            if not inString then
                inString = true
                stringChar = char
            elseif char == stringChar then
                inString = false
                stringChar = nil
            end
        end
        
        -- Keep whitespace in strings
        if inString then
            table.insert(result, char)
        -- Remove unnecessary whitespace
        elseif char:match("%s") then
            local next = code:sub(i + 1, i + 1)
            -- Keep space between alphanumeric characters
            if prev:match("[%w_]") and next:match("[%w_]") then
                table.insert(result, " ")
            end
        else
            table.insert(result, char)
            prev = char
        end
    end
    
    return table.concat(result)
end

function Minifier.minify(code)
    code = Minifier.removeComments(code)
    code = Minifier.removeWhitespace(code)
    return code
end

function Minifier.obfuscateStrings(code)
    local result = {}
    local i = 1
    
    while i <= #code do
        local char = code:sub(i, i)
        
        if char == '"' or char == "'" then
            local quote = char
            local str = ""
            i = i + 1
            
            while i <= #code and code:sub(i, i) ~= quote do
                if code:sub(i, i) == "\\" then
                    str = str .. code:sub(i, i + 1)
                    i = i + 2
                else
                    str = str .. code:sub(i, i)
                    i = i + 1
                end
            end
            
            -- Convert to byte array
            local bytes = {}
            for j = 1, #str do
                table.insert(bytes, string.byte(str, j))
            end
            
            table.insert(result, "string.char(" .. table.concat(bytes, ",") .. ")")
            i = i + 1
        else
            table.insert(result, char)
            i = i + 1
        end
    end
    
    return table.concat(result)
end

return Minifier
