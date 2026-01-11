-- modules/parser.lua
-- AST Parser for Lua bytecode obfuscation

local Parser = {}
Parser.__index = Parser

function Parser.new()
    local self = setmetatable({}, Parser)
    self.pos = 1
    self.source = ""
    self.tokens = {}
    return self
end

function Parser:init(source)
    self.source = source
    self.pos = 1
    self.tokens = {}
    return self
end

function Parser:peek(offset)
    offset = offset or 0
    return self.source:sub(self.pos + offset, self.pos + offset)
end

function Parser:advance()
    local char = self.source:sub(self.pos, self.pos)
    self.pos = self.pos + 1
    return char
end

function Parser:skipWhitespace()
    while self:peek():match("%s") do
        self:advance()
    end
end

function Parser:skipComment()
    if self:peek() == "-" and self:peek(1) == "-" then
        if self:peek(2) == "[" and self:peek(3) == "[" then
            self:advance()
            self:advance()
            self:advance()
            self:advance()
            while not (self:peek() == "]" and self:peek(1) == "]") and self.pos <= #self.source do
                self:advance()
            end
            if self:peek() == "]" then
                self:advance()
                self:advance()
            end
        else
            while self:peek() ~= "\n" and self.pos <= #self.source do
                self:advance()
            end
        end
        return true
    end
    return false
end

function Parser:readString()
    local quote = self:advance()
    local str = ""
    while self:peek() ~= quote and self.pos <= #self.source do
        if self:peek() == "\\" then
            self:advance()
            local next = self:advance()
            if next == "n" then str = str .. "\n"
            elseif next == "t" then str = str .. "\t"
            elseif next == "r" then str = str .. "\r"
            elseif next == "\\" then str = str .. "\\"
            elseif next == quote then str = str .. quote
            else str = str .. next
            end
        else
            str = str .. self:advance()
        end
    end
    if self:peek() == quote then
        self:advance()
    end
    return str
end

function Parser:readNumber()
    local num = ""
    if self:peek() == "0" and (self:peek(1) == "x" or self:peek(1) == "X") then
        num = num .. self:advance() .. self:advance()
        while self:peek():match("[0-9a-fA-F]") do
            num = num .. self:advance()
        end
    else
        while self:peek():match("[0-9]") or self:peek() == "." do
            num = num .. self:advance()
        end
        if self:peek() == "e" or self:peek() == "E" then
            num = num .. self:advance()
            if self:peek() == "+" or self:peek() == "-" then
                num = num .. self:advance()
            end
            while self:peek():match("[0-9]") do
                num = num .. self:advance()
            end
        end
    end
    return tonumber(num)
end

function Parser:readIdentifier()
    local ident = ""
    while self:peek():match("[%w_]") do
        ident = ident .. self:advance()
    end
    return ident
end

function Parser:tokenize()
    self.tokens = {}
    
    while self.pos <= #self.source do
        self:skipWhitespace()
        
        if self.pos > #self.source then break end
        
        if not self:skipComment() then
            local char = self:peek()
            
            if char == '"' or char == "'" then
                table.insert(self.tokens, {type = "string", value = self:readString()})
            elseif char:match("[0-9]") then
                table.insert(self.tokens, {type = "number", value = self:readNumber()})
            elseif char:match("[%a_]") then
                local ident = self:readIdentifier()
                local keywords = {
                    ["and"] = true, ["break"] = true, ["do"] = true, ["else"] = true,
                    ["elseif"] = true, ["end"] = true, ["false"] = true, ["for"] = true,
                    ["function"] = true, ["if"] = true, ["in"] = true, ["local"] = true,
                    ["nil"] = true, ["not"] = true, ["or"] = true, ["repeat"] = true,
                    ["return"] = true, ["then"] = true, ["true"] = true, ["until"] = true,
                    ["while"] = true
                }
                
                if keywords[ident] then
                    table.insert(self.tokens, {type = "keyword", value = ident})
                else
                    table.insert(self.tokens, {type = "identifier", value = ident})
                end
            elseif char == "." and self:peek(1) == "." then
                if self:peek(2) == "." then
                    self:advance()
                    self:advance()
                    self:advance()
                    table.insert(self.tokens, {type = "operator", value = "..."})
                else
                    self:advance()
                    self:advance()
                    table.insert(self.tokens, {type = "operator", value = ".."})
                end
            elseif char == "=" and self:peek(1) == "=" then
                self:advance()
                self:advance()
                table.insert(self.tokens, {type = "operator", value = "=="})
            elseif char == "~" and self:peek(1) == "=" then
                self:advance()
                self:advance()
                table.insert(self.tokens, {type = "operator", value = "~="})
            elseif char == "<" and self:peek(1) == "=" then
                self:advance()
                self:advance()
                table.insert(self.tokens, {type = "operator", value = "<="})
            elseif char == ">" and self:peek(1) == "=" then
                self:advance()
                self:advance()
                table.insert(self.tokens, {type = "operator", value = ">="})
            else
                local singles = "+-*/%^#<>=(){}[];:,."
                if singles:find(char, 1, true) then
                    table.insert(self.tokens, {type = "operator", value = char})
                    self:advance()
                else
                    self:advance()
                end
            end
        end
    end
    
    return self.tokens
end

function Parser:parse()
    self:tokenize()
    return self:parseBlock()
end

function Parser:parseBlock()
    local statements = {}
    return {
        type = "Block",
        statements = statements
    }
end

return Parser
