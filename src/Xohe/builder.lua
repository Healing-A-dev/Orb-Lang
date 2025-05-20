local builder = {}

--[[Imports]]--
local Lexer = require("src/lexer")
local Parser = require("src/parser")
local Functions = require("src/functions")

local function_data = {
    put = {
        "global func put(words) {",
        "XOHE.PUSH_OP.WRITE(words)",
        "ret words",
        "}"
    },

}

builder.builtins = {}
builder.builtins.put = {
    Type = "function",
    Value = Functions.getValue("put",Lexer.lex(function_data.put,true),1).Value,
    Content = Functions.getValue("put",Lexer.lex(function_data.put,true),1).Contents
}


return builder
