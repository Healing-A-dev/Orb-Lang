local parser    = {}

-- Imports --
local Variables = require("src/variables")
local Function  = require("src/functions")
local Error     = require("src/errors")
local Ast       = require("src/ast")
local Tokens    = require("src/tokens")
local Module    = require("src/modules")

-- Instance Variables --
file = {
    Name = arg[1],
    Line = 0,
}


-- Seek Function --
local function seek()
    -- May fill out if needed
end

-- Parser --
function parser.parse(token_table)
    local sandboxed = false
    for line = 1, #token_table do
        file.Line = line
        for _, token in pairs(token_table[line]) do
            if not sandboxed then
                -- Variable detection
                if token.Token:find("VAREQL") then
                    local variable_data = Variables.addVariable(token_table[line], true, token_table)
                elseif token.Token:find("KEY_EQUAL") then
                    local variable_data, classification = Variables.search(token_table[line][_-1].Value)
                    if not variable_data then
                        Error.new("ASSIGN_TO_UNDECLARED", line, {token_table[line][_-1].Value})
                    end
                end

                -- Module calls
                if token.Token:find("MODULE_CALL") then
                    local module_name = token_table[line][_+1].Value
                    local module_function_name = ""
                    if token_table[line][_+2].Value == "::" then
                        module_function_name = token_table[line][_+3].Value
                    end
                    print("Module: "..module_name)
                    print("Subfunction: "..module_function_name)
                    print("Line: "..line)
                    print("TODO: Implement Modules")
                    os.exit()
                end

                -- Function calls
                if token.Value == Tokens.symbols.OTOKEN_KEY_OPAREN then
                    if token_table[line][_-1].Token == "OTOKEN_KEY_NAME" then
                        local to_call, call_data
                        call_data = Variables.search(token_table[line][_-1].Value)
                        if type(call_data) == "table" then
                            to_call = call_data.Type
                            if to_call == "function" then
                                XOHE:UpdateOrbValues({_Data = call_data.Content, Line_Data = token_table[line]})

                                -- Small optimization to prevent double exit & extra data from being compiled after program exits from panic()
                                if _EXITCODE ~= 0 then
                                    COMPILER.FLAGS.PROG_EXIT = true
                                    goto program_exit
                                end
                            elseif to_call ~= "function" and to_call ~= "module" then
                                Error.new("UNKNOWN_FUNCTION_CALL",line,{token_table[line][_-1].Value})
                            end
                        end
                    end
                end

                -- Adding Functions & Modules to the stack buffer
                if token.Token:find("FUNC_NAME") then
                    Function.new(token_table[line], true, token_table, line)
                    _STACK.BUFFER[#_STACK.BUFFER+1] = {Type = "FUNC", Name = token.Value, Line_Created = line}
                elseif token.Token:find("MOD_NAME") then
                    Module.new(token_table[line], true, token_table)
                    _STACK.BUFFER[#_STACK.BUFFER+1] = {Type = "MOD", Name = token.Value, Line_Created = line}
                end

                -- Adding regular statments to the stack buffer
                if token.Token:find("STMT") then
                    if not token.Token:find("FUNC") and not token.Token:find("MOD") then
                        _STACK.BUFFER[#_STACK.BUFFER+1] = {Type = token.Token:match("%w+"):upper(), Name = "", Line_Created = line}
                        Function.newStatement()
                    end
                end

                -- Moving data from the stack buffer to the stack
                if token.Value == Tokens.symbols.OTOKEN_KEY_OBRACE then
                    if #_STACK.BUFFER > 0 then
                        _STACK[#_STACK+1] = _STACK.BUFFER[#_STACK.BUFFER]
                        table.remove(_STACK.BUFFER, #_STACK.BUFFER)
                        if _STACK[#_STACK].Type == "FUNC" or _STACK[#_STACK].Type == "MOD" then
                            sandboxed = true
                        end
                    else
                        local prev_token = (token_table[line][_-1] or token_table[line-1][#token_table[line-1]] or token_table[line+1][1]).Value
                        if token.Token:match("OBRACE") then
                            Error.new("UNEXPECTED_TOKEN", line, {token.Value, prev_token})
                        end
                    end
                end

                -- Removing data from the stack
                if token.Value == Tokens.symbols.OTOKEN_KEY_CBRACE then
                    table.remove(_STACK, #_STACK)
                end
            else
                if token.Value == Tokens.symbols.OTOKEN_KEY_CBRACE then
                    if _STACK[#_STACK].Type == "FUNC" or _STACK[#_STACK].Type == "MOD" then
                        sandboxed = false
                    end
                    table.remove(_STACK, #_STACK)
                end
            end
        end
    end

    -- Checking if the stack is empty after execution
    if #_STACK.BUFFER > 0 then
        local end_value = token_table[_STACK.BUFFER[#_STACK.BUFFER].Line_Created][#token_table[_STACK.BUFFER[#_STACK.BUFFER].Line_Created]].Value
        local end_token = _STACK.BUFFER[#_STACK.BUFFER].Type:lower()
        Error.new("STATEMENT_INIT", _STACK.BUFFER[#_STACK.BUFFER].Line_Created, { end_value, end_token, _STACK.BUFFER[#_STACK.BUFFER].Name })
    elseif #_STACK > 0 then
        Error.new("STATEMENT_END", file.Line, { _STACK[#_STACK].Type:lower(), _STACK[#_STACK].Line_Created, _STACK[#_STACK].Name })
    end

    ::program_exit::
    return true
end

return parser
