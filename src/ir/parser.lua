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
    --	local in_mod = false
    for line = 1, #token_table do
        file.Line = line
        for _, token in pairs(token_table[line]) do

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
            if token.Token == Tokens.symbols.OTOKEN_KEY_MODULE_CALL then
                local module_name = token_table[line][_-1].Value
                local module_function_name = ""
                if token_table[line][_+2].Value == "::" then
                    module_function_name = token_table[line][_+3].Value
                end
                print("Module: "..module_name)
                print("Subfunction: "..module_function_name)
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

                            -- Small optimization to prevent double exit extra data from being compiled after program exits from panic()
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
        end
    end

    -- Checking if the data stack is empty after execution
    if #_STACK.DATA > 0 then
        local end_value = token_table[_STACK.DATA[#_STACK.DATA].Line_Created]
            [#token_table[_STACK.DATA[#_STACK.DATA].Line_Created]].Value
        local end_token = _STACK.DATA[#_STACK.DATA].Type:lower()
        Error.new("STATEMENT_INIT", _STACK.DATA[#_STACK.DATA].Line_Created,
            { end_value, end_token, _STACK.DATA[#_STACK.DATA].Name })
    elseif #_STACK > 0 then
        Error.new("STATEMENT_END", file.Line,
            { _STACK[#_STACK].Type:lower(), _STACK[#_STACK].Line_Created, _STACK[#_STACK].Name })
    end

    ::program_exit::
    return true
end

return parser
