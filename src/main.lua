-- Setting Global Variables --
VARIABLES = {
    GLOBAL = {
        ["null"] = { Type = "null", Value = "null" }
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
local Tokens                  = require("src/tokens")
local Lexer                   = require("src/lexer")
local Parser                  = require("src/ir/parser")
local Ast                     = require("src/ast")
local Variable                = require("src/variables")
local Utils                   = require("src/utils")

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
end

-- Displaying Warnings --
if COMPILER.FLAGS.WARN then
    io.write("\nCompilation completed <\027[95m" ..
    os.time() - start_time ..
    "s\027[0m> with warning(s):\n\tXohe: " ..
    A .. "\n\tXohe: " .. X .. "\n\tXohe: " .. LOAD .. "\n\tLexer: " .. L .. "\n\tParser: " ..
    P .. "\n\tCompiler: " .. C .. "\n")
elseif not COMPILER.FLAGS.WARN and not COMPILER.FLAGS.EXECUTE then
    io.write("Compilation completed <\027[95m" .. os.time() - start_time .. "s\027[0m>\n")
end


--[[DEBUGGING]] --
local o = ""
for s = 1, #Lexer.tokens do
	o = o..s..":\n"
	for _,token in pairs(Lexer.tokens[s]) do
		o = o.."    ".._.." | "..token.Token.." | "..token.Value.."\n"
	end
end
local f = io.open("out.token","w+")
f:write(o)
f:close()
-- Exit the program with the corresponding exit code
if COMPILER.FLAGS.EXECUTE then
    os.exit(_EXITCODE)
end
