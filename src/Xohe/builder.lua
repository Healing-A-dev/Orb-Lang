local builder = {}

-- Imports --
local Lexer = require("src/lexer")
local Parser = require("src/parser")
local Functions = require("src/functions")

-- Builtin Function Data --
local function_data = {
    ['puts'] = {
        "global func puts(words, Orb_ArgContinuation0x00) {",
        "args := Orb_ArgContinuation_T0x00",
        "if (words == null) {",
        "    words = 'null'",
        "}",
        "XOHE::PUSH_OP::WRITE('\"' << words << '\"', args)",
        ".1",
        "}"
    },
    ['panic'] = {
        "global func panic(msg, err) {",
        "if (msg == null) {",
        "    msg = 'Orb_PanicMSG_DEFAULT0x00'",
        "}",
        "XOHE::PUSH_OP::PANIC('\"' << msg << '\"', err)",
        ".1",
        "}"
    },
    ['typeof'] = {
        "global func typeof(var_name) {",
        "require('src/utils')",
        "if (var_name == null) {",
        "    var_name = 'null'",
        "}",
        ".variable_search(var_name)",
        "}",
    }
}

-- Creating Builtin Functions --
builder.builtins = {}

for _, i in pairs(function_data) do
    local lexical_data = Lexer.lex(function_data[_], true)
    builder.builtins[_] = {
        Type = "function",
        Value = Functions.getValue(_, lexical_data, 1).Value,
        Content = Functions.getValue(_, lexical_data, 1).Contents,
        Tokens = lexical_data
    }
end

return builder
