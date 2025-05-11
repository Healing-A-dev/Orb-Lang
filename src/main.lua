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
local Utils 	 = require("src/utils")

-- Making the Variables table accessable to Orbit
_V = VARIABLES
VARIABLES.GLOBAL["_V"] = {Type = "array", Value = _V}
VARIABLES.GLOBAL["_V.GLOBALS"] = {Type = "array", Value = _V.GLOBALS}
VARIABLES.GLOBAL["_V.STATIC"] = {Type = "array", Value = _V.STATIC}

-- Main variables
XOHE = require("src/Xohe/initVM")
SELF_EXECUTE = true
WARN = false

-- Compiler Arguments
if arg[1] == "-c" and arg[#arg] == ("orbc") then
	SELF_EXECUTE = false
	table.remove(arg,1)
elseif arg[1] == "-c" and arg[#arg] ~= ("orbc") then
	print("[orb]: invalid option '"..arg[1].."'")
	displayHelpMessage()
	os.exit(0)
end
for _,i in pairs(arg) do
	if i:find("%-") then
		local arg_type = i:gsub("%-","")
		if arg_type == "o" then
			C_OUT = arg[_+1]
		elseif arg_type == "v" then
			print("WIP")
			table.remove(arg,_)
		elseif arg_type == "h" then
			displayHelpMessage()
		elseif arg_type == "ve" then
			WARN = true
			table.remove(arg,_)
		end
	end
end

-- Warning Collection --
X = call(XOHE:Generate())
L = call(Lexer.lex(arg[1]))
P = call(Parser.parse(Lexer.tokens))
C = call(Compile())

--[[Fun Data Stuff]]--
if WARN then
	print("Compilation Completed: "..os.time()-start_time.."s")
	io.write("\nWith warning(s):\n\tXohe: "..X.."\n\tLexer: "..L.."\n\tParser: "..P.."\n\tCompiler: "..C.."\n")
end



--[[DEBUGGING]]--
--[[for s = 1, #Lexer.tokens do
for _,token in pairs(Lexer.tokens[s]) do
	print(_.." | "..token.Token.." | "..token.Value)
	end
]]
