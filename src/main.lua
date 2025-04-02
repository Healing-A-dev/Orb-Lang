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
local Lexer		 = require("src/lexer")
local Parser 	 = require("src/parser")
local Ast 		 = require("src/ast")
local Variable 	 = require("src/variables")

--[[Orbit]]--
Lexer.lex(arg[1]) -- Lexing file
pathToFile = {arg[1]}
Parser.parse(Lexer.tokens) -- Parsing tokens
--[[for s = 1, #Lexer.tokens do
	for _,token in pairs(Lexer.tokens[s]) do
		print(_.." | "..token.Token.." | "..token.Value)
	end
end]]
-- print(VARIABLES.static.Kai.Type, VARIABLES.static.Kai.Value)
-- print(VARIABLES.static.Moose.Type, VARIABLES.static.Moose.Value)
-- print("x: "..VARIABLES.static.x.Value)
-- print("y: "..VARIABLES.static.y.Value)
-- print("test: "..VARIABLES.STATIC.test.Type.." | "..tostring(VARIABLES.STATIC.test.Value))
print("z: "..VARIABLES.STATIC.z.Type.." | "..tostring(VARIABLES.STATIC.z.Value))
print("Compilation Completed: "..os.time()-start_time.."s")
