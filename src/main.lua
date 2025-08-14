-- Setting Global Variables --
VARIABLES = {
    GLOBAL = {
        ["null"] = { Type = "null", Value = "\"null\"" }
    },
    STATIC = {},
    TEMPORARY = {}
}

_STACK = {
   BUFFER = {}
}

_EXITCODE = 0

-- Imports --
local start_time              = os.time()
local Lexer                   = require("src/lexer")
local Parser                  = require("src/parser")

-- Making the Variables table accessable to Orbit
_V = VARIABLES
VARIABLES.GLOBAL["_V"]        = { Type = "array", Value = _V }
VARIABLES.GLOBAL["_V.GLOBAL"] = { Type = "array", Value = _V.GLOBAL }
VARIABLES.GLOBAL["_V.STATIC"] = { Type = "array", Value = _V.STATIC }

-- Importing Xohe
XOHE = require("src/Xohe/initVM")

-- Compilation & Warning Collection --
if #arg > 0 then
    A = call(XOHE:GatherCompilerArguemnts())
    X = call(XOHE:Generate())
    L = call(Lexer.lex(arg[1]))
    P = call(Parser.parse(Lexer.tokens))
    C = call(Compile())
    if _EXITCODE ~= 0 and COMPILER.FLAGS.EXECUTE then
        print("\n\027[91mexit status <".._EXITCODE..">\027[0m")
    end

    -- Displaying Warnings --
    if COMPILER.FLAGS.WARNALL then
        io.write("\nCompilation completed <\027[95m"..os.time() - start_time ..
        "s\027[0m> with warning(s):\n  |> \027[2mXohe: " ..
        A .. "\n  |> \027[2mXohe: " .. X .. "\n  |> \027[2mXohe: " .. LOAD .. "\n  |> \027[2mLexer: " .. L .. "\n  |> \027[2mParser: " ..
        P .. "\n  |> \027[2mCompiler: " .. C .. "\n\027[0m")
    elseif not COMPILER.FLAGS.WARN and not COMPILER.FLAGS.EXECUTE then
        io.write("Compilation completed <\027[95m" .. os.time() - start_time .. "s\027[0m>\n")
    end

    -- Exit the program with the corresponding exit code
    if COMPILER.FLAGS.EXECUTE then
        os.exit(_EXITCODE)
    end
end



-- DEBUGGING
--[[local out = ""
for s = 1, #Lexer.tokens do
    out = out..tostring(s).."\n"
    for _,i in pairs(Lexer.tokens[s]) do
        out = out..("    {Token: "..i.Token..", Value: "..i.Value.."}\n")
    end
end
local g = io.open("out.tokens","w+")
g:write(out)
g:close()
]]
