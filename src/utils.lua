local utils = {}

-- Get Function Return Value --
function utils.getFunctionValue(function_name,tokens,line)
	local stack_mini, out, set_out = {}, "", false
	for s = line, #tokens do
		for _,i in pairs(tokens[s]) do
			if i.Token:find("OBRACE") then
				stack_mini[#stack_mini+1] = 1
			elseif i.Token:find("CBRACE") then
				table.remove(stack_mini,#stack_mini)
				if #stack_mini == 0 and not set_out then
					goto nil_return
				elseif #stack_mini == 0 and set_out then
					set_out = nil
					return {Value = out, Returned = true}
				end
			end
			if set_out then
				out = out..i.Value
			end
			if i.Token:find("_RET") then
				set_out = true
			end
		end
	end
	::nil_return::
	return {Value = "null", Returned = false}
end


-- String.Chop function --
function string.chop(string,locations)
	local split_string = {}
	for letter in string:gmatch(".") do
		split_string[#split_string+1] = letter
	end
	if locations ~= nil then
		for _,i in pairs(locations) do
			table.remove(splitString,i)
		end
	else
    	table.remove(splitString,#splitString)
  	end
	return table.concat(splitString)
end


-- Collecting Array Data [WIP] --
function utils.gatherArrayData(start_line, syntax_table)
	local array_stack_data, array_stack = {}, {}
	local start = syntax_table[start_line]


	local function getArrayParent()
		for _,i in pairs(array_stack_data) do
			if i.Position == #array_stack - 1 then
				return _
			end
		end
	end

	local function gatherData(init,array)
		local skipper = init+1
		while #array_data > 0 do
			if skipper ~= #array then

			else

			end
		end
	end


	for s = 1, #start do
		local token = start[s]
		if token.Token:match("_OBRACKET") then
			local var_name = start[s-2].Value
			local skipper = s+1
			array_stack[#array_stack+1] = true
			array_stack_data[var_name] = {Parent = nil, Data = {}, Position = #array_stack}
		end
	end
end


-- Orb Help Message --
function displayHelpMessage(err)
	local err = err or 0
	if COMPILER.FLAGS.EXECUTE then
		io.write([[Usage: orb <filename> <arguments>
Commands:
    -h  [--help]       |> Displays this message and exits
    -v  [--version]    |> Displays the current version and exits
    -ve [--verbose]    |> Displays all commands used during compilation
    -w  [--warnings]   |> Displays warngins that occured during compilation
]])
		os.exit(err)
	else
		io.write([[Usage: orbc <filename> <arguments>
Commands:
    -h  [--help]       |> Displays this message and exits
    -v  [--version]    |> Displays the current version and exits
    -ve [--verbose]    |> Displays all commands used during compilation
    -w  [--warnings]   |> Displays warngins that occured during compilation
    -a                 |> Compiler flag to generate only an assembly file of the specified program
    -o                 |> Specify an output file
]])
		os.exit(err)
	end
end

function gatherFunctionName(str, Tokens)
    return str:match("%S+%("):gsub("%(","")
end

-- pcall Function Wrapper --
function call(function_name)
	local status, error = pcall(function_name)
	if not status then
		return("[orb]: '"..error.."' |> \027[93mSafe to ignore\027[0m")
	end
end

local function varSearch(var_name)
    if VARIABLES.GLOBAL[var_name] ~= nil then
		return VARIABLES.GLOBAL[var_name], "global"
	elseif VARIABLES.STATIC[var_name] ~= nil then
		return VARIABLES.STATIC[var_name], "static"
	elseif VARIABLES.TEMPORARY[var_name] ~= nil then
		return VARIABLES.TEMPORARY[var_name], "temporary"
	else
		return false	-- Variable Does Not Exist
	end
end

-- Secondary OLua converter
utils.stack = {}
utils.tokenStorage = {}
local is_in_string
local is_function
local string_init_character
function utils.subLex(str)
    -- Mini Lua Transpiler
    for token in str:gmatch("%S+") do
        utils.tokenStorage[#utils.tokenStorage+1] = {token, isString = false}
    end

    -- Converting Orbit tokens to Lua tokens
    for _,token in ipairs(utils.tokenStorage) do

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
                utils.tokenStorage[_][1] = "function"
                utils.tokenStorage[_][2] = "statement"
                is_function = true
            elseif token[1] == "if" or token[1] == "elseif" then
                token[1] = "\n"..token[1]
                utils.tokenStorage[_][2] = "statement"
            elseif token[1] == "for" then
                token[1] = "\n"..token[1]
                utils.tokenStorage[_][2] = "statement"
            elseif token[1] == "global" then
                utils.tokenStorage[_][1] = "\n"
            elseif token[1] == "while" then
                token[1] = "\n"..token[1]
                utils.tokenStorage[_][2] = "statement"
            elseif token[1] == "ret" then
                utils.tokenStorage[_][1] = "\nreturn"
            elseif token[1] == ":=" then
                utils.tokenStorage[_][1] = "="
            elseif token[1] == "null" then
                utils.tokenStorage[_][1] = "nil"
            elseif token[1] == "&&" then
                utils.tokenStorage[_][1] = "and"
            elseif token[1] == "||" then
                utils.tokenStorage[_][1] = "or"
            elseif token[1] == "<<" then
                utils.tokenStorage[_][1] = ".."
            elseif token[1] == "/=" then
                utils.tokenStorage[_][1] = "--[["
            elseif token[1] == "=/" then
                utils.tokenStorage[_][1] = "]]"
            elseif token[1] == "#" then
                utils.tokenStorage[_][1] = "\n--"
            elseif token[1] == "[" then
                utils.tokenStorage[_][1] = "{*"
            elseif token[1] == "]" then
                utils.tokenStorage[_][1] = "}*"
            elseif token[1] == "!" then
            	utils.tokenStorage[_][1] = "not"
            end
        end

        -- Variable Handling
        if not token.isString then
           local variable_data, variable_type = varSearch(token[1])
           if variable_data then
               if is_function == false and variable_data.Type ~= "function" then
                   if utils.tokenStorage[_-1][1] ~= "function" and utils.tokenStorage[_-1][1] ~= "\nfor" and utils.tokenStorage[_-1][1] ~= "\nwhile" then
                       utils.tokenStorage[_][1] = "VARIABLES."..variable_type:upper().."."..token[1]..".Value"
                   end
               end
           end
        end

        -- Resetting is_function to false
        if token[1] == ")" and not token.isString then
            is_function = false
        end

        -- Statement Handling
        if utils.tokenStorage[_][2] == "statement" or utils.tokenStorage[_][1] == "{*" then
            utils.stack[#utils.stack+1] = utils.tokenStorage[_][1]
        end

        -- Internal function calling
        if token[1] == "(" and not token.isString then
            local var_data = varSearch(utils.tokenStorage[_-1][1])
            if var_data ~= false and var_data.Type == "function" then
                local c0 = coroutine.create(function ()
                    local tokens_of_puts_function = VARIABLES.GLOBAL[utils.tokenStorage[_-1][1]].Content
                        for _,i in pairs(tokens_of_puts_function) do
                            for k,v in pairs(i) do
                                utils.lex(v,true)
                            end
                        end
                    end
                )
                coroutine.resume(c0)
            end
        end

        -- Changing '{' to the proper Lua equivalent
        if token[1] == "{" and not token.isString then
           if utils.stack[#utils.stack] == "function" then
               if utils.tokenStorage[_-1][1] == ")" then
                    utils.tokenStorage[_][1] = "\n"
                else
                    utils.tokenStorage[_][1] = "()\n"
                end
            elseif utils.stack[#utils.stack] == "\nif" or utils.stack[#utils.stack] == "\nelseif" then
                utils.tokenStorage[_][1] = "then\n"
            elseif utils.stack[#utils.stack] == "\nfor" or utils.stack[#utils.stack] == "\nwhile" then
                utils.tokenStorage[_][1] = "do\n"
            elseif utils.stack[#utils.stack] == "{*" then
                utils.tokenStorage[_][1] = "{"
            end
        end

        -- Adding 'end' when needed
        if token[1] == "}" and not token.isString and #utils.stack > 0 then
            if utils.stack[#utils.stack] ~= "{*" then
                utils.tokenStorage[_][1] = "\nend\n"
            else
                utils.tokenStorage[_][1] = "}"
            end
            table.remove(utils.stack,#utils.stack)
        end
    end
end


-- Table merger function
function utils.merge(t1, t2)
    local tmp = {}
    for _,i in ipairs(t1) do
        tmp[#tmp+1] = i
    end
    for _,i in ipairs(t2) do
        tmp[#tmp+1] = i
    end
    return tmp
end

return utils
