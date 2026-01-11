#!/usr/bin/env lua
-- init.lua
-- Main entry point for the obfuscator

local version = "v1.0.1"

if game ~= nil and typeof ~= nil then
    print("This Obfuscator cannot be ran in Roblox or luau.")
    return
end

local climode = arg ~= nil and true or false

if table.find == nil then
    table.find = function(tbl, value, pos)
        for i = pos or 1, #tbl do
            if tbl[i] == value then
                return i
            end
        end
    end
end

local function loadModule(name)
    local success, module = pcall(require, "modules." .. name)
    if not success then
        
        success, module = pcall(require, name)
    end
    if not success then
        error("Failed to load module: " .. name)
    end
    return module
end

local Parser = loadModule("parser")
local Bytecode = loadModule("bytecode")
local VM = loadModule("vm")
local Minifier = loadModule("minifier")

local function parseArgs()
    if #arg <= 1 and (arg[1] == "--help" or arg[1] == "-h" or arg[1] == nil) then
        print("VM-Based Obfuscator " .. version)
        print("\nUsage:\n" .. arg[0] .. " --source <FILE> --output <FILE> [OPTIONS]\n")
        print("Arguments:")
        print("  --help -h          Shows help")
        print("  -S --silent        Silent mode")
        print("  -s --source <file> Source file")
        print("  -o --output <file> Output file")
        print("  -f --force         Ignore warnings")
        print("  -m --minify        Minify before obfuscation")
        print("  --no-vm            Skip VM wrapping")
        return nil
    end
    
    local realargs = {}
    local nextvargs = {"source", "output"}
    local longargs = {s="source", o="output", f="force", S="silent", m="minify"}
    local skipdexes = {}
    
    for i, v in pairs(arg) do
        if (not table.find(skipdexes, i)) or (i > 0) then
            if v:sub(1, 2) == "--" then
                local key = v:sub(3)
                if table.find(nextvargs, key) then
                    realargs[key] = arg[i + 1]
                    table.insert(skipdexes, #skipdexes + 1, i + 1)
                else
                    realargs[key] = true
                end
            elseif v:sub(1, 1) == "-" then
                local key = longargs[v:sub(2)]
                if key and table.find(nextvargs, key) then
                    realargs[key] = arg[i + 1]
                    table.insert(skipdexes, #skipdexes + 1, i + 1)
                elseif key then
                    realargs[key] = true
                end
            end
        end
    end
    
    return realargs
end

local function obfuscate(sourceCode, options)
    options = options or {}
    
    local loadFunc = loadstring or load
    local func, err = loadFunc(sourceCode)
    if not func then
        error("Syntax error in source: " .. tostring(err))
    end
    
    if options.minify then
        if not options.silent then
            print("Minifying code...")
        end
        sourceCode = Minifier.minify(sourceCode)
    end
    
    if not options.silent then
        print("Encoding to bytecode...")
    end
    local encoded = Bytecode.encode(sourceCode)
    
    if not options.novm then
        if not options.silent then
            print("Wrapping in VM...")
        end
        return VM.wrapCode(encoded)
    else
        return encoded
    end
end

if climode then
    math.randomseed(os.time())
    
    local args = parseArgs()
    if not args then
        return
    end
    
    if not args.source then
        print("ERROR: Source file required")
        print("Usage: " .. arg[0] .. " --source <file> --output <file>")
        return
    end
    
    local silent = args.silent or false
    
    if not silent and not args.force then
        local exist = io.open(args.output or "output.lua", "r")
        if exist then
            io.close(exist)
            io.write("Overwrite " .. (args.output or "output.lua") .. "? (y/N) ")
            if io.read():lower():sub(1, 1) ~= "y" then
                print("Cancelled")
                return
            end
        end
    end
    
    local srcFile = io.open(args.source, "rb")
    if not srcFile then
        print("ERROR: Cannot open: " .. args.source)
        return
    end
    local source = srcFile:read("*a")
    srcFile:close()
    
    if not silent then
        print("VM-Based Obfuscator " .. version)
        print("Source: " .. args.source)
        print("Output: " .. (args.output or "output.lua"))
    end
    
    local startTime = os.clock()
    local success, result = pcall(obfuscate, source, {
        silent = silent,
        minify = args.minify,
        novm = args["no-vm"]
    })
    
    if not success then
        print("ERROR: " .. tostring(result))
        return
    end
    
    if not silent then
        print(string.format("Done in %.3fs", os.clock() - startTime))
    end
    
    local outFile = io.open(args.output or "output.lua", "w")
    if not outFile then
        print("ERROR: Cannot write output")
        return
    end
    outFile:write(result)
    outFile:close()
    
    if not silent then
        print("Written to: " .. (args.output or "output.lua"))
    end
else
    return {
        version = version,
        obfuscate = obfuscate,
        Parser = Parser,
        Bytecode = Bytecode,
        VM = VM,
        Minifier = Minifier
    }
end
