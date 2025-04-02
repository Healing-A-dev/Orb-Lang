
-- Orbit to Lua transpiler
-- Used to return function and module values and update variable data accordingly
-- Does NOT work with the current orbit tokens stored in the lexer.tokens table [WILL FIX IN THE FUTURE FOR IMPROVED PERFORMANCE]
-- Does nNOT include any form of error checking since it should've already been handled by the compiler


--[[LUA Transpiler]]--
local initVM = {}

--[[Imports]]--
local Variables     = require("src/variables")
local Tokens        = require("src/tokens")

--[[Instance Variables]]--
local string_init_character = nil
local is_in_string = false
initVM = {
    Tokens = {},
    Stack  = {
        Init = {},
        End = {}
    },
    Out = {}
}

--[[Orbit -> Lua Lexer]]--
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
            elseif token[1] == "if" or token[1] == "elseif" then
                self.Tokens[_][2] = "statement"
            elseif token[1] == "for" then
                self.Tokens[_][2] = "statement"
            elseif token[1] == "while" then
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
                self.Tokens[_][1] = "--"
            end
        end

        -- Statement Handling
        if self.Tokens[_][2] == "statement" then
            self.Stack.Init[#self.Stack.Init+1] = self.Tokens[_][1]
        end

        -- Changing '{' to the proper Lua equivalent
        if token[1] == "{" then
           if self.Stack.Init[#self.Stack.Init] == "function" then
                self.Tokens[_][1] = "\n"
            elseif self.Stack.Init[#self.Stack.Init] == "if" or self.Stack.Init[#self.Stack.Init] == "elseif" then
                self.Tokens[_][1] = "then\n"
            elseif self.Stack.Init[#self.Stack.Init] == "for" or self.Stack.Init[#self.Stack.Init] == "while" then
                self.Tokens[_][1] = "do\n"
            end
        end

        -- Adding 'end' when needed
        if token[1] == "}" and #self.Stack.Init > 0 then
            self.Tokens[_][1] = "\nend"
            table.remove(self.Stack.Init,#self.Stack.Init)
        end
        self.Out[#self.Out+1] = self.Tokens[_][1]
    end
end

--[[OLua -> Lua Parser]]--
function initVM.execute(self,Line_Data)
    local out = ""
    local function_data = ""

    -- Combining Lua Code
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

    -- Loading Data To Execute
    load(out)()
end


function initVM.UpdateOrbitValues(self,program)
    for _,tokens in pairs(program.Function_Data) do
        for _,data in pairs(tokens) do
            self:lex(data)
        end
    end
    self:execute(program.Line_Data)
    --[[for _,i in pairs(self.Tokens) do
        print(i[1])
    end]]
    --print(program.Function_Data[1][1])
end

return initVM
