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

function gatherFunctionName(str)
    return str:match("%S+%("):gsub("%(","")
end

-- pcall Function Wrapper --
function call(function_name)
	local status, error = pcall(function_name)
	if not status then
		return("[orb]: '"..error.."' |> \027[93mSafe to ignore\027[0m")
	end
end

return utils
