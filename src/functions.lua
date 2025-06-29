local functions = {}

-- Imports --
local Error    = require("src/errors")
local Variable = require("src/variables")

-- Instance Variables --
functions = {}

-- Function Return Value --
function functions.getValue(function_name, tokens, line)
	local stack_mini, out, set_out, contents = {}, "", false, {}
	for s = line, #tokens do
		for _,i in pairs(tokens[s]) do
			contents[#contents+1] = {}
			contents[#contents][#contents[#contents]+1] = i.Value.." "
			if i.Token:find("OBRACE") then
				stack_mini[#stack_mini+1] = 1
			elseif i.Token:find("CBRACE") then
				table.remove(stack_mini,#stack_mini)
				if #stack_mini == 0 and not set_out then
					goto nil_return
				elseif set_out then
					set_out = false
					return {Value = out, Returned = true, Contents = contents}
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
	return {Value = "null", Returned = false, Contents = contents}
end

-- New Functions --
function functions.new(tokens, add, token_table)
	local function_name = nil
	local function_variables = {}
	local function_classification = "static"
	for _,token in pairs(tokens) do
		if token.Token:find("FUNC_NAME") then
			function_name = token.Value
		elseif token.Token:find("GLOBAL$") then
			function_classification = "global"
		elseif token.Token == "OTOKEN_KEY_NAME" then
			function_variables[#function_variables+1] = token.Value
			Variable.addTempVariable(token.Value, function_name, file.Line, functions_variables)
		end
	end

	if add then
		VARIABLES[function_classification:upper()][function_name] = {Value = functions.getValue(function_name,token_table,file.Line).Value, Type = "function", Line_Created = file.Line, Content = functions.getValue(function_name,token_table,file.Line).Contents}
	end

	return {Name = function_name, Classification = function_classification, Arguments = function_Arguments}
end

-- New Statement Functions --
-- statments in Orb will be handled as a form of functions (for my convinence and sandboxing)
function functions.newStatement(tokens, type, add, token_table)
    Error.new("TODO: Implement statment functions!")
end
return functions
