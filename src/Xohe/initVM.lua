-- Orb to OLua transpiler
-- Used to return function and module values and update variable data accordingly
-- Does NOT work with the current orbit tokens stored in the lexer.tokens table [WILL FIX IN THE FUTURE FOR IMPROVED PERFORMANCE]
-- Does NOT include any form of error checking since it should've already been handled by the compiler

-- OLua
-- Description: OLua is Lua that is compatable with Orbit variables
-- eg.
--[[
    Orbit:
        x := "13"
        y := "12"

        func combine(x1,x2) {
            z := x1 << x2
            ret z
        }

        a := combine(x,y)


    OLua:
        function combine(x1,x2)
            VARIABLES.STATIC.z.Value = VARIABLES.TEMPORARY.x1.Value .. VARIABLES.TEMPORARY.x2.Value
            return VARIABLES.STATIC.z.Value
        end

        VARIABLES.STATIC.a.Value = combine(VARIABLES.STATIC.x.Value, VARIABLES.STATICy.Value)
]]

--[[OLua Transpiler]]--
local initVM = {}

--[[Imports]]--
local Variables = require("src/variables")
local Tokens    = require("src/tokens")
local Builder   = require("src/Xohe/builder")
local Compiler  = require("src/Xohe/compiler")

--[[Instance Variables]]--
local string_init_character = nil
local is_in_string = false
local is_function = false
initVM = {
    Tokens = {},
    Stack  = {
        Init = {},
    },
}

--[[Orbit -> OLua Lexer]]--
function initVM.lex(self,program)
    -- Mini Tokenizer
    for token in program:gmatch("%S+") do
       self.Tokens[#self.Tokens+1] = {token, isString = false}
    end

    -- Converting Orbit tokens to Lua tokens
    for _,token in pairs(self.Tokens) do

        -- String Literals
        if token[1]:match('^"') then
            string_init_character = '"'
            token.isString = true
            is_in_string = true
        elseif token[1]:match("^'") then
            string_init_character = "'"
            token.isString = true
            is_in_string = true
        end
        if token[1]:match("['\"]$") and token[1]:match("['\"]$") == string_init_character then
            token.isString = true
            is_in_string = false
        end

        -- Simple Keyword & Statement Conversions
        if not is_in_string then
            if token[1] == "func" then
                self.Tokens[_][1] = "function"
                self.Tokens[_][2] = "statement"
                is_function = true
            elseif token[1] == "if" or token[1] == "elseif" then
                token[1] = "\n"..token[1]
                self.Tokens[_][2] = "statement"
            elseif token[1] == "for" then
                token[1] = "\n"..token[1]
                self.Tokens[_][2] = "statement"
            elseif token[1] == "global" then
                self.Tokens[_][1] = "\n"
            elseif token[1] == "while" then
                token[1] = "\n"..token[1]
                self.Tokens[_][2] = "statement"
            elseif token[1] == "ret" then
                self.Tokens[_][1] = "\nreturn"
            elseif token[1] == ":=" then
                self.Tokens[_][1] = "="
            elseif token[1] == "null" then
                self.Tokens[_][1] = "nil"
            elseif token[1] == "&&" then
                self.Tokens[_][1] = "and"
            elseif token[1] == "||" then
                self.Tokens[_][1] = "or"
            elseif token[1] == "<<" then
                self.Tokens[_][1] = ".."
            elseif token[1] == "/=" then
                self.Tokens[_][1] = "--[["
            elseif token[1] == "=/" then
                self.Tokens[_][1] = "]]"
            elseif token[1] == "#" then
                self.Tokens[_][1] = "\n--"
            elseif token[1] == "[" then
                self.Tokens[_][1] = "{*"
            elseif token[1] == "]" then
                self.Tokens[_][1] = "}*"
            end
        end

        -- Variable Handling
        if not token.isString then
           local variable_data, variable_type = Variables.search(token[1])
           if variable_data then
               if is_function == false then
                   if self.Tokens[_-1][1] ~= "function" and self.Tokens[_-1][1] ~= "\nfor" and self.Tokens[_-1][1] ~= "\nwhile" then
                       self.Tokens[_][1] = "VARIABLES."..variable_type:upper().."."..token[1]..".Value"
                    end
               end
           end
        end

        -- Resetting is_function to false
        if token[1] == ")" and not token.isString then
            is_function = false
        end

        -- Statement Handling
        if self.Tokens[_][2] == "statement" or self.Tokens[_][1] == "{*" then
            self.Stack.Init[#self.Stack.Init+1] = self.Tokens[_][1]
            --print(self.Stack.Init[#self.Stack.Init])
        end

        -- Changing '{' to the proper Lua equivalent
        if token[1] == "{" and not token.isString then
           if self.Stack.Init[#self.Stack.Init] == "function" then
               if self.Tokens[_-1][1] == ")" then
                    self.Tokens[_][1] = "\n"
                else
                    self.Tokens[_][1] = "()\n"
                end
            elseif self.Stack.Init[#self.Stack.Init] == "\nif" or self.Stack.Init[#self.Stack.Init] == "\nelseif" then
                self.Tokens[_][1] = "then\n"
            elseif self.Stack.Init[#self.Stack.Init] == "\nfor" or self.Stack.Init[#self.Stack.Init] == "\nwhile" then
                self.Tokens[_][1] = "do\n"
            elseif self.Stack.Init[#self.Stack.Init] == "{*" then
                self.Tokens[_][1] = "{"
            end
        end

        -- Adding 'end' when needed
        if token[1] == "}" and not token.isString and #self.Stack.Init > 0 then
            if self.Stack.Init[#self.Stack.Init] ~= "{*" then
                self.Tokens[_][1] = "\nend\n"
            else
                self.Tokens[_][1] = "}"
            end
            table.remove(self.Stack.Init,#self.Stack.Init)
        end
    end
end

--[[Lua Code Finalizer & Executor]]--
function initVM.execute(self,Line_Data)
    local out = ""
    local function_data = ""

    -- Combining OLua Code
    for _,i in pairs(self.Tokens) do
        out = out..i[1].." "
    end

    -- Adding Data To Update
    for _,i in pairs(Line_Data) do
       if i.Value == Tokens.combined.OTOKEN_COMBINED_VAREQL or i.Value == Tokens.symbols.OTOKEN_KEY_EQUAL then
            local skipper = 1
            while _+skipper <= #Line_Data do
               function_data = function_data..Line_Data[_+skipper].Value
               skipper = skipper+1
            end
            local variable_name = Line_Data[_-1].Value
            local variable_data, variable_type = Variables.search(variable_name)
            out = out.."\n\nVARIABLES."..variable_type:upper().."."..variable_name..".Value = "..function_data
        end
    end

    -- Loading & Executing
    os.execute("echo '"..out.."' > src/Xohe/out.lua")
    load(out)()
end


function initVM.UpdateOrbitValues(self,program)
    for _,tokens in pairs(program.Function_Data) do
        for _,data in pairs(tokens) do
            self:lex(data)
        end
    end
    self:execute(program.Line_Data)
end



--[[XoheVM builtin functions]]--
function initVM.Generate(self,...)
    local exclusions = {...}
    for Function,_ in pairs(Builder.builtins) do
        VARIABLES.GLOBAL[Function] = {Value = Builder.builtins[Function].Value, Type = Builder.builtins[Function].Type, Content = Builder.builtins[Function].Content, Line_Created = "-1"}
    end
    return true
end


return initVM
