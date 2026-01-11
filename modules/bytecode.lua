-- modules/bytecode.lua
-- Bytecode encoder/decoder for VM obfuscation ( this is for Lua 5.1 )

local Bytecode = {}

function Bytecode.obfuscateNumber(n)
    local ops = {
        function(num)
            local a = math.random(10, 200)
            return string.format("(%d+%d)", num - a, a)
        end,
        function(num)
            local a = math.random(10, 200)
            return string.format("(%d-%d)", num + a, a)
        end,
        function(num)
            if num == 0 then return "0" end
            local a = math.random(2, 10)
            if num % a == 0 then
                return string.format("(%d*%d)", num / a, a)
            end
            return tostring(num)
        end
    }
    return ops[math.random(#ops)](n)
end

function Bytecode.bytesToString(bytes)
    local result = {}
    for i, byte in ipairs(bytes) do
        if i == 1 then
            table.insert(result, Bytecode.obfuscateNumber(byte))
        else
            table.insert(result, "," .. Bytecode.obfuscateNumber(byte))
        end
    end
    return result
end

function Bytecode.stringToBytes(str)
    local bytes = {}
    for i = 1, #str do
        table.insert(bytes, string.byte(str, i))
    end
    return bytes
end

function Bytecode.encode(sourceCode)
    local bytes = Bytecode.stringToBytes(sourceCode)
    local encoded = Bytecode.bytesToString(bytes)
    return table.concat(encoded, "")
end

function Bytecode.xorEncode(sourceCode, key)
    key = key or math.random(1, 255)
    local result = {}
    for i = 1, #sourceCode do
        local byte = string.byte(sourceCode, i)
        -- XOR without bitwise operators (Lua 5.1 compatible)
        local encoded = (byte + key) % 256
        table.insert(result, encoded)
    end
    return result, key
end

function Bytecode.base64Encode(data)
    local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    return ((data:gsub('.', function(x) 
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end

function Bytecode.compress(str)
    local dict = {}
    local result = {}
    local w = ""
    local chars = 256
    
    for i = 0, 255 do
        dict[string.char(i)] = i
    end
    
    for i = 1, #str do
        local c = str:sub(i, i)
        local wc = w .. c
        if dict[wc] then
            w = wc
        else
            table.insert(result, dict[w])
            dict[wc] = chars
            chars = chars + 1
            w = c
        end
    end
    
    if w ~= "" then
        table.insert(result, dict[w])
    end
    
    return result
end

return Bytecode
