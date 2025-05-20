--[[Setting Variable and Stack Tables]]--
VARIABLES = {
	GLOBAL = {
		["null"] = {Type = "null", Value = "null"}
	},
	STATIC = {},
	TEMPORARY = {}
}

_STACK = {
	DATA = {},
	RESERVE = {},
	FUNCTIONS = {}
}

--[[Imports]]--
local start_time = os.time()
local Tokens	 = require("src/tokens")
local Lexer	 = require("src/lexer")
local Parser 	 = require("src/parser")
local Ast 	 = require("src/ast")
local Variable 	 = require("src/variables")
local Utils 	 = require("src/utils")

-- Making the Variables table accessable to Orbit
_V = VARIABLES
VARIABLES.GLOBAL["_V"] = {Type = "array", Value = _V}
VARIABLES.GLOBAL["_V.GLOBAL"] = {Type = "array", Value = _V.GLOBAL}
VARIABLES.GLOBAL["_V.STATIC"] = {Type = "array", Value = _V.STATIC}

-- Importing Xohe
XOHE = require("src/Xohe/initVM")

-- Compilation & Warning Collection --
if #arg > 0 then
	A = call(XOHE:GatherCompilerArguemnts())
	X = call(XOHE:Generate())
	L = call(Lexer.lex(arg[1]))
	P = call(Parser.parse(Lexer.tokens))
	C = call(Compile())
end

--[[Fun Data Stuff]]--
if COMPILER.FLAGS.WARN then
	io.write("\nCompilation completed <"..os.time()-start_time.."s> with warning(s):\n\tXohe: "..A.."\n\tXohe: "..X.."\n\tXohe: "..LOAD.."\n\tLexer: "..L.."\n\tParser: "..P.."\n\tCompiler: "..C.."\n")
end


--[[DEBUGGING]]--
--[[for s = 1, #Lexer.tokens do
	for _,token in pairs(Lexer.tokens[s]) do
		print(_.." | "..token.Token.." | "..token.Value)
	end
end]]
--print("a = "..VARIABLES.GLOBAL.a.Value)
