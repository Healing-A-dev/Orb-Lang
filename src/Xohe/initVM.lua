-- Orb to OLua transpiler
-- Used to return function and module values and update variable data accordingly
-- Does NOT work with the current orbit tokens stored in the lexer.tokens table [WILL FIX IN THE FUTURE FOR IMPROVED PERFORMANCE]

-- OLua
-- Description: OLua is Lua that is compatable with Orbit variables
-- eg.
--[[
    Orb:
        x := "13"
        y := "12"

        func combine(x1,x2) {
            z := x1 << x2
            .z
        }

        a := combine(x,y)


    OLua:
        function combine(x1,x2)
            VARIABLES.STATIC.z.Value = VARIABLES.TEMPORARY.x1.Value..VARIABLES.TEMPORARY.x2.Value
            return VARIABLES.STATIC.z.Value
        end

        VARIABLES.STATIC.a.Value = combine(VARIABLES.STATIC.x.Value, VARIABLES.STATIC.y.Value)
]] --

-- OLua Transpiler --
local initVM                = {}

-- Imports --
local Variables             = require("src/variables")
local Tokens                = require("src/tokens")
local Compiler              = require("src/Xohe/compiler")
local Utils                 = require("src/utils")
local Error                 = require("src/errors")
local CLI                   = require("src/Cli/cli")

-- Global Import Values --
X_Lib                       = require("src/Xohe/loadlib")
X_Error                     = require("src/Xohe/errors")

-- Instance Variables --
local string_init_character = nil
local is_in_string          = false
local is_function           = false
local counter               = 1
warnings                    = ""
initVM                      = {
    Tokens  = {},
    Stack   = {
        Init = {},
    },
    PUSH_OP = {}, -- Compiler Operations (ie. Write, Read, etc)
    VERSION = "0.0.3+15"
}


-- Orbit -> OLua Lexer --
initVM.Tokens[counter] = {}
function initVM.lex(self, program)
    -- Mini Tokenizer
    for token in program:gmatch("%S+") do
        self.Tokens[counter][#self.Tokens[counter] + 1] = { token, isString = false }
    end

    -- Converting Orbit tokens to Lua tokens
    for _, token in ipairs(self.Tokens[counter]) do
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
                self.Tokens[counter][_][1] = "function"
                self.Tokens[counter][_][2] = "statement"
                is_function = true
            elseif token[1] == "if" or token[1] == "elseif" then
                token[1] = "\n" .. token[1]
                self.Tokens[counter][_][2] = "statement"
            elseif token[1] == "for" then
                token[1] = "\n" .. token[1]
                self.Tokens[counter][_][2] = "statement"
            elseif token[1] == "global" then
                self.Tokens[counter][_][1] = "\n"
            elseif token[1] == "while" then
                token[1] = "\n" .. token[1]
                self.Tokens[counter][_][2] = "statement"
            elseif token[1] == "." and self.Tokens[counter][_][2] ~= "skip_me" then
                self.Tokens[counter][_][1] = "\nreturn"
            elseif token[1] == "::" then
                self.Tokens[counter][_][1] = "."
                self.Tokens[counter][_][2] = "skip_me"
            elseif token[1] == ":=" then
                self.Tokens[counter][_][1] = "="
            elseif token[1] == "null" then
                self.Tokens[counter][_][1] = "nil"
            elseif token[1] == "&&" then
                self.Tokens[counter][_][1] = "and"
            elseif token[1] == "||" then
                self.Tokens[counter][_][1] = "or"
            elseif token[1] == "<<" then
                self.Tokens[counter][_][1] = ".."
            elseif token[1] == "/=" then
                self.Tokens[counter][_][1] = "--[["
            elseif token[1] == "=/" then
                self.Tokens[counter][_][1] = "]]"
            elseif token[1] == "#" then
                self.Tokens[counter][_][1] = "\n--"
            elseif token[1] == "[" then
                self.Tokens[counter][_][1] = "{*"
            elseif token[1] == "]" then
                self.Tokens[counter][_][1] = "}*"
            elseif token[1] == "!" then
                self.Tokens[counter][_][1] = "not"
            end
        end

        -- Variable Handling
        if not token.isString then
            local variable_data, variable_type = Variables.search(token[1])
            if variable_data then
                if is_function == false and variable_data.Type ~= "function" then
                    if self.Tokens[counter][_ - 1][1] ~= "function" and self.Tokens[counter][_ - 1][1] ~= "\nfor" and self.Tokens[counter][_ - 1][1] ~= "\nwhile" then
                        self.Tokens[counter][_][1] = "VARIABLES." .. variable_type:upper() .. "." .. token[1] .. ".Value"
                    end
                end
            end
        end

        -- Resetting is_function to false
        if token[1] == ")" and not token.isString then
            is_function = false
        end

        -- Statement Handling
        if self.Tokens[counter][_][2] == "statement" or self.Tokens[counter][_][1] == "{*" then
            self.Stack.Init[#self.Stack.Init + 1] = self.Tokens[counter][_][1]
        end

        -- Internal function calling
        if token[1] == Tokens.symbols.OTOKEN_KEY_OPAREN and not token.isString then
            local v_search = Variables.search(self.Tokens[counter][_ - 1][1])
            if v_search ~= false and v_search.Type == "function" and self.Tokens[counter][_ - 2][1] ~= "function" then
                local c0 = coroutine.create(function()
                    counter = counter + 1
                    self.Tokens[counter] = {}
                    for _, i in pairs(v_search.Content) do
                        for k, func_data in pairs(i) do
                            self:lex(func_data)
                        end
                    end
                    counter = 1
                end)
                coroutine.resume(c0)
                -- Adding unknown function call error
            elseif v_search == false and self.Tokens[counter][_ - 1][2] ~= "statement" then
                if self.PUSH_OP[self.Tokens[counter][_ - 1][1]] == "nil" then -- Checking if the function exist in the PUSH_OP's table to avoid throwing an error
                    Error.new("UNKNOWN_FUNCTION_CALL", file.Line, { self.Tokens[counter][_ - 1][1] })
                end
            end
        end

        -- Changing '{' to the proper Lua equivalent
        if token[1] == "{" and not token.isString then
            if self.Stack.Init[#self.Stack.Init] == "function" then
                if self.Tokens[counter][_ - 1][1] == ")" then
                    self.Tokens[counter][_][1] = "\n"
                else
                    self.Tokens[counter][_][1] = "()\n"
                end
            elseif self.Stack.Init[#self.Stack.Init] == "\nif" or self.Stack.Init[#self.Stack.Init] == "\nelseif" then
                self.Tokens[counter][_][1] = "then\n"
            elseif self.Stack.Init[#self.Stack.Init] == "\nfor" or self.Stack.Init[#self.Stack.Init] == "\nwhile" then
                self.Tokens[counter][_][1] = "do\n"
            elseif self.Stack.Init[#self.Stack.Init] == "{*" then
                self.Tokens[counter][_][1] = "{"
            end
        end

        -- Adding 'end' when needed
        if token[1] == "}" and not token.isString and #self.Stack.Init > 0 then
            if self.Stack.Init[#self.Stack.Init] ~= "{*" then
                self.Tokens[counter][_][1] = "\nend\n"
            else
                self.Tokens[counter][_][1] = "}"
            end
            table.remove(self.Stack.Init, #self.Stack.Init)
        end

        if token[1] == "Orb_ArgContinuation0x00" then
            self.Tokens[counter][_][1] = "..."
        elseif token[1] == "Orb_ArgContinuation_T0x00" then
            self.Tokens[counter][_][1] = "{...}"
        elseif token[1] == "Orb_ForceReturn0x00" then
            self.Tokens[counter][_][1] = "return"
        end

        if token[1]:find("^%%") and #token[1] > 1 then
            self.VM.TYPEOF(token[1]:gsub("^%%", ""))
            print(token[1])
        end
    end
end

-- Lua Code Finalizer & Executor --
function initVM.execute(self, Line_Data)
    local out, buff = "", ""
    local no_variable_function_call = nil
    local function_data = ""
    local function_stack = {}
    local internal_functions = {
        Name = "",
        Functions = {}
    }

    -- Combining OLua Code
    local s = #self.Tokens
    while s >= 1 do
		for _, i in pairs(self.Tokens[s]) do
			out = out .. i[1] .. " "
		end
		out = out .. "\n"
		s = s -1
    end

    -- Adding Data To Update
    for _, i in pairs(Line_Data) do
        if i.Value == Tokens.combined.OTOKEN_COMBINED_VAREQL or i.Value == Tokens.symbols.OTOKEN_KEY_EQUAL then
            no_variable_function_call = false
            local skipper = 1
            while _ + skipper <= #Line_Data do
                function_data = function_data .. Line_Data[_ + skipper].Value
                if Line_Data[_ + skipper].Value == Tokens.symbols.OTOKEN_KEY_OPAREN then
                    if #function_stack > 1 then
                        for s = #function_data, 1, -1 do
                            local character = function_data:sub(s, s)
                            if not character:match("[%,%(]") then
                                internal_functions.Name = internal_functions.Name .. character
                            elseif character:match("[%,%(]") and #internal_functions.Name > 0 then
                                table.insert(internal_functions.Functions, internal_functions.Name:reverse())
                                internal_functions.Name = ""
                                break
                            end
                        end
                    end
                    function_stack[#function_stack + 1] = 1
                elseif Line_Data[_ + skipper].Value == Tokens.symbols.OTOKEN_KEY_CPAREN then
                    table.remove(function_stack, #function_stack)
                end
                skipper = skipper + 1
            end

            -- MUST FIX LATER FOR RECURSION PURPOSES
            for _, Name in pairs(internal_functions.Functions) do
                local Data = Variables.search(Name)
                if Data then
                    local Name = Name .. "%(%)"
                    function_data = function_data:gsub(Name, Data.Value)
                else
                    print("UNKNOWN FUNCTION CALL <" .. Name .. ">")
                end
            end
            -- END FIX AREA

            local variable_name = Line_Data[_ - 1].Value
            local variable_data, variable_type = Variables.search(variable_name)
            function_data = (function_data:match("%)%S+%(.?%)$") or function_data):gsub("^%)", ""):gsub("<<", "..")

            -- Concverting function data to OLua
            if function_data:match("%((%S+)%)") then
                local f_head = function_data:match("%S+%("):gsub("%(", "")
                local f_data = function_data:match("%((%S+)%)")
                local v_data, v_class = Variables.search(f_data)
                if v_data ~= false then
                    f_data = "VARIABLES." .. v_class:upper() .. "." .. f_data .. ".Value"
                end
                function_data = f_head .. "(" .. f_data .. ")"
            end

            -- Creating variable expression (eg. VARIABLES.Static.x.Value = foo(VARIABLES.Global.bar.Value))
            out = out .. "\n\nVARIABLES." .. variable_type:upper() .. "." .. variable_name .. ".Value = " ..
                function_data
        elseif _ == #Line_Data and no_variable_function_call == nil then
            no_variable_function_call = true
            local skipper = 1
            while _ + skipper <= #Line_Data do
                function_data = function_data .. Line_Data[_ + skipper].Value
                if Line_Data[_ + skipper].Value == Tokens.symbols.OTOKEN_KEY_OPAREN then
                    function_stack[#function_stack + 1] = 1
                    if #function_stack > 1 then
                        for s = #function_data, 1, -1 do
                            local character = function_data:sub(s, s)
                            if not character:match("[%,%(]") then
                                internal_functions.Name = internal_functions.Name .. character
                            elseif character:match("[%,%(]") and #internal_functions.Name > 0 then
                                table.insert(internal_functions.Functions, internal_functions.Name:reverse())
                                internal_functions.Name = ""
                                break
                            end
                        end
                    end
                elseif Line_Data[_ + skipper].Value == Tokens.symbols.OTOKEN_KEY_CPAREN then
                    table.remove(function_stack, #function_stack)
                end
                skipper = skipper + 1
            end
        end
        -- FIX LATER
        for _, Name in pairs(internal_functions.Functions) do
            local Data = Variables.search(Name)
            if Data then
                local Name = Name .. "%(%)"
                function_data = function_data:gsub(Name, Data.Value)
            else
                print("UNKOWN FUNCTION CALL <" .. Name .. ">")
            end
        end
    end

    -- CASE: STATIC FUNCION CALLING (eg. puts(...))
    if no_variable_function_call then
        for _, i in pairs(Line_Data) do
            local variable, classification = Variables.search(i.Value)
            if variable ~= false and variable.Type ~= "function" and variable.Type ~= "mod" then
                if variable.Type == "Number" then
                    local variable_value = VARIABLES[classification:upper()][i.Value].NewValue or
                        VARIABLES[classification:upper()][i.Value].NewValue
                    buff = buff .. "\"" .. variable_value .. "\""
                else
                    buff = buff .. "VARIABLES." .. classification:upper() .. "." .. i.Value .. ".Value"
                end
            elseif tonumber(i.Value) then
                buff = buff .. "\"" .. i.Value .. "\""
            elseif i.Value == Tokens.combined.OTOKEN_COMBINED_CONCAT then
                buff = buff .. ", "
            else
                buff = buff .. i.Value
            end
        end
    end

    -- Loading, Executing, & Collecting Warnings
    LOAD = call(load(out .. "\n" .. buff)())
    warnings = warnings .. LOAD .. "\n"

    -- Restting Token Table
    counter = 1
    self.Tokens = {}
    self.Tokens[counter] = {}
end

-- Xohe Function Handler --
function initVM.UpdateOrbValues(self, program)
    self.Tokens[counter] = {}
    for _, tokens in pairs(program._Data) do
        for _, data in pairs(tokens) do
            self:lex(data)
        end
    end
    self:execute(program.Line_Data)
end


-- Compiler Arguemnt Handler --
function initVM.GatherCompilerArguemnts()
    if arg[1] == "-c" and arg[#arg] == ("--compiler=orbc") then
        COMPILER.FLAGS.EXECUTE = false
        table.remove(arg, 1)
        table.remove(arg, #arg)
    elseif arg[1] == "-c" and arg[#arg] ~= ("--compiler=orbc") then
        print("[orb]: invalid option '" .. arg[1] .. "'")
        displayHelpMessage(1)
    end
    for _, i in pairs(arg) do
        if #arg == 0 then
            os.exit()
        end
        if i:find("%-") then
            local arg_type = i:gsub("%-", "")
            if arg_type == "o" or arg_type == "outfile" then
                if not COMPILER.FLAGS.EXECUTE then
                    COMPILER.FLAGS.OUTFILE = arg[_ + 1]
                    table.remove(arg, _ + 1)
                    table.remove(arg, _)
                else
                    print("[orb]: invalid option '" .. arg[_] .. "'")
                    displayHelpMessage(1)
                end
            elseif arg_type == "v" then
                print("[version]: " .. initVM.VERSION)
                os.exit()
            elseif arg_type == "h" or arg_type == "help" then
                displayHelpMessage()
            elseif arg_type == "w" or arg_type == "warn" then
                COMPILER.FLAGS.WARN = true
            elseif arg_type == "W" or arg_type == "WARN" then
                COMPILER.FLAGS.WARN = true
                COMPILER.FLAGS.WARNALL = true
            elseif arg_type == "ve" or arg_type == "verbose" then
                COMPILER.FLAGS.VERBOSE = true
            elseif arg_type == "i" or arg_type == "interactive" then
                CLI.interactive(initVM, arg[_ + 1])
                os.exit()
            elseif arg_type == "uex" or arg_type == "useextern" then
                COMPILER.FLAGS.USE_EXTERN = true
            elseif arg_type == "silent" and COMPILER.FLAGS.EXECUTE == false then
            	COMPILER.FLAGS.SILENT = true
            elseif arg_type:match("t%=") or arg_type:match("target%=") then
                if not COMPILER.FLAGS.EXECUTE then
                    local options = {
                        ["asm"] = 1,
                        ["obj"] = 1,
                        ["vmtf"] = 1
                    }
                    local emit = arg_type:match("%=.+$"):gsub("%=","")
                    if options[emit] == nil then
                        print("[orb]: invalid target option '" .. arg[_] .. "'")
                        displayHelpMessage(1)
                    else
                        COMPILER.FLAGS[emit:upper()] = true
                    end
                else
                    print("[orb]: invalid option '" .. arg[_] .. "'")
                    displayHelpMessage(1)
                end
            else
                print("[orb]: invalid option '" .. arg[_] .. "'")
                displayHelpMessage(1)
            end

            -- Clearing argument
            if _ ~= #arg then
                --table.remove(arg, _)
            end
        end
    end
end

-- [[BELOW ARE THE OPERATIONS FOR THE COMPILER THAT ARE CALLED THROUGH FUNCTIONS BUILT IN THE XOHE/builder File]] --


-- Compiler ADD VARIABLE operation --
function initVM.PUSH_OP.ADDVAR(type, value)
    local var, type, value, quote_char = "Orb_CVARIABLE_0x0" .. COMPILER.VARIABLES, type,
        tostring(value):gsub("\n", "\\n"), '"'
    if value:find("\"") then
        quote_char = "'"
    end

    -- Incrementing compiler made variable count and adding compiler variable to .data
    COMPILER.VARIABLES = COMPILER.VARIABLES + 1

    -- Adding data to .data depending on the type of variable
    if type == "STR" then
        value = value
        COMPILER.APPEND_DATA(var .. ":")
        COMPILER.APPEND_DATA("    .ascii " .. quote_char .. value .. quote_char)
        COMPILER.APPEND_DATA("    .byte 0")
        COMPILER.APPEND_DATA("L_" .. var .. " = . -" .. var .. "\n")
    elseif type == "NUM" then
        COMPILER.APPEND_DATA(var .. ":")
        COMPILER.APPEND_DATA()
    end
    return var
end

-- Compiler WRITE/PRINT operation --
function initVM.PUSH_OP.WRITE(value, ...)
    if _EXITCODE ~= 0 then return end
    value = value:gsub("^[\"']", ""):gsub("[\"']$", "")
    value = Variables.inverseSearch(value) or value
    local var = Variables.search(value)
    if not var or var.Type == "function" or var.Type == "module" then
        if not tonumber(value) then
            value = value:gsub("^\"", ""):gsub("\"$", "")
        end
        value = value .. (table.concat(...) or "")
        local value = initVM.PUSH_OP.ADDVAR("STR", value)
        COMPILER.APPEND_TEXT("    mov $" .. value .. ", %rsi")
        COMPILER.APPEND_TEXT("    mov $L_" .. value .. ", %rdx")
        COMPILER.APPEND_TEXT("    callq \"Orb_CFUNCTION_puts\"")
    else
        local _, var_type = Variables.search(value)
        local var_type = VARIABLES[var_type:upper()][value].Type
        if var_type == "number" then
            COMPILER.APPEND_TEXT("    mov " .. value .. "(%rip), %rax")
            COMPILER.APPEND_TEXT("    callq \"Orb_CFUNCTION_puts_INT\"")

            -- Adding concatenated data
            local etc_data = initVM.PUSH_OP.ADDVAR("STR", table.concat(...) or "")
            COMPILER.APPEND_TEXT("    mov $" .. etc_data .. ", %rsi")
            COMPILER.APPEND_TEXT("    mov $L_" .. etc_data .. ", %rdx")
            COMPILER.APPEND_TEXT("    callq \"Orb_CFUNCTION_puts\"")
        elseif var_type == "string" or var_type == "null" then
            value = value:gsub("^\"", ""):gsub("\"$", "")
            COMPILER.APPEND_TEXT("    mov $" .. value .. ", %rsi")
            COMPILER.APPEND_TEXT("    mov $L_" .. (var.NewCallSign or value) .. ", %rdx")
            COMPILER.APPEND_TEXT("    callq \"Orb_CFUNCTION_puts\"")
            if ... ~= nil then
                local etc = ""
                for _, i in pairs(...) do
                    etc = etc .. i:gsub("^['\"]", ""):gsub("['\"]", "")
                end
                local etc = initVM.PUSH_OP.ADDVAR("STR", etc)
                COMPILER.APPEND_TEXT("    mov $" .. etc .. ", %rsi")
                COMPILER.APPEND_TEXT("    mov $L_" .. etc .. ", %rdx")
                COMPILER.APPEND_TEXT("    callq \"Orb_CFUNCTION_puts\"")
            end
        end
    end
end

-- Compiler PANIC operation --
function initVM.PUSH_OP.PANIC(msg, errcode)
    if _EXITCODE ~= 0 then return end
    local stack_msg = ""
    local Stack = _STACK

    -- Reading the current stack
    for s = #Stack, 1, -1 do
        local Type = Stack[s].Type:lower()
        if Type == "func" then
            Type = "function <" .. Stack[s].Name .. ">"
        elseif Type == "mod" then
            Type = "module <" .. Stack[s].Name .. ">"
        elseif Type == "if" or Type == "elseif" or Type == "for" or Type == "while" then
            Type = Type .. " statment"
        end
        if s > 1 then
            stack_msg = stack_msg .. "            ^" .. " in " .. Type .. " | " .. Stack[s].Line_Created .. "\n"
        else
            stack_msg = stack_msg .. "            ^" .. " in " .. Type .. " | " .. Stack[s].Line_Created .. "\n"
        end
    end

    -- No error message provided
    if msg == "\"Orb_PanicMSG_DEFAULT0x00\"" then
        Error.new("BAD_ARGUMENT", file.Line, { 1, "func", "panic", "value", "null" })
    end

    -- Creating error code
    errcode = tonumber(errcode) or 3

    -- Constructing error message
    msg = msg:gsub("^[\"']", ""):gsub("[\"']$", "")
    local msg_construct0 = initVM.PUSH_OP.ADDVAR("STR",
        "Orb: <panic> error\ntraceback:\n    [orb]: " .. msg .. "\n    [file]: " .. arg[1] .. "\n    [line]: " .. file.Line .. "\n")
    local msg_construct1 = initVM.PUSH_OP.ADDVAR("STR", "\n\027[91mexit status <" .. errcode .. ">\027[0m\n")
    local msg_construct2 = initVM.PUSH_OP.ADDVAR("STR", stack_msg)

    -- Writing error message
    COMPILER.APPEND_TEXT("    mov $" .. msg_construct0 .. ", %rsi")
    COMPILER.APPEND_TEXT("    mov $L_" .. msg_construct0 .. ", %rdx")
    COMPILER.APPEND_TEXT("    callq \"Orb_CFUNCTION_puts\"")
    COMPILER.APPEND_TEXT("    mov $" .. msg_construct2 .. ", %rsi")
    COMPILER.APPEND_TEXT("    mov $L_" .. msg_construct2 .. ", %rdx")
    COMPILER.APPEND_TEXT("    callq \"Orb_CFUNCTION_puts\"")
    if not COMPILER.FLAGS.EXECUTE then
        COMPILER.APPEND_TEXT("    mov $" .. msg_construct1 .. ", %rsi")
        COMPILER.APPEND_TEXT("    mov $L_" .. msg_construct1 .. ", %rdx")
        COMPILER.APPEND_TEXT("    callq \"Orb_CFUNCTION_puts\"")
    end
    COMPILER.APPEND_TEXT("    mov $" .. errcode .. ", %rdi")
    COMPILER.APPEND_TEXT("    callq \"Orb_CFUNCTION_exit\"\n")
    _EXITCODE = errcode
end

function initVM.PUSH_OP.EXIT(errcode)
	COMPILER.APPEND_TEXT("    mov $" .. errcode .. ", %rdi")
	COMPILER.APPEND_TEXT("    callq \"Orb_CFUNCTION_exit\"\n")
	_EXITCODE = errcode
end

function initVM.PUSH_OP.UPDATE(var, value, type)
    if type == "STR" then
        COMPILER.APPEND_TEXT("    mov $" .. value .. ", %rsi")
        COMPILER.APPEND_TEXT("    mov $" .. var .. " + 0" .. ", %rdi")
        COMPILER.APPEND_TEXT("    mov $L_" .. value .. ", %rcx")
        COMPILER.APPEND_TEXT("    cld")
        COMPILER.APPEND_TEXT("    rep movsb")
    else
        print("IMPLEMENT: " .. type .. " variable updates")
        os.exit()
    end
end

return initVM
