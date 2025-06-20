local builder = {}

-- Imports --
local Lexer = require("src/lexer")
local Parser = require("src/parser")
local Functions = require("src/functions")

-- Builtin Function Data --
local function_data = {
	['puts'] = {
		"global func puts(words) {",
		"if (words == null) {",
		"    words = 'null'",
		"}",
		"XOHE.PUSH_OP.WRITE('\"' << words << '\"')",
		"ret words",
		"}"
	},
	['panic'] = {
	    "global func panic(msg, err) {",
		"if (msg == null) {",
		"    msg = 'Orb_PanicMSG_DEFAULT0x00'",
		"}",
		"XOHE.PUSH_OP.PANIC('\"' << msg << '\"', err)",
		"}"
	},
	['typeof'] = {
		"global func typeof(value) {",
		"",
		"}",
	}
}

-- Creating Builtin Functions --
builder.builtins = {}

for _,i in pairs(function_data) do
	builder.builtins[_] = {
		Type = "function",
		Value = Functions.getValue(_,Lexer.lex(function_data[_],true),1).Value,
		Content = Functions.getValue(_,Lexer.lex(function_data[_],true),1).Contents
	}
end

return builder
