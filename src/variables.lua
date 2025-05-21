local variables = {}

-- Imports --
local Error = require("src/errors")
local Utils = require("src/utils")
local Token = require("src/tokens")

-- nstance Variables --
local parent_value = nil
local Tokens = nil
local VarOps = {}


-- Variable Operations --
function VarOps.ADD(value1,value2,l)
	local value_of_value1, value_of_value2 = value1, value2

	-- Checking if value one is a variable or number
	if not tonumber(value1) then
		if not variables.search(value1) then
			Error.new("UNKNOWN_VAR_CALL",l,{value1.Value})
		else
			value_of_value1 = variables.search(value1).Value or variables.search(value1).Value.Value
			if not tonumber(value_of_value1) then
				Error.new("Cannont perform arithmetic expression on "..value1.Value.." value "..value_of_value1)
			end
		end
	end

	-- Checking if value two is a variable or a number
	if not tonumber(value2) then
		if not variables.search(value2) then
			Error.new("UNKNOWN_VAR_CALL",l,{value2.Value})
		else
			value_of_value2 = variables.search(value2).Value or variables.search(value2).Value.Value
			if not tonumber(value_of_value2) then
				Error.new("Cannot perform arithmetic expression on "..value2.Value.." value "..value_of_value2)
			end
		end
	end
	return value_of_value1 + value_of_value2
end


-- Get Variable Classification Type --
local function getVariableType(variable)
	if VARIABLES.STATIC[variable] then
		return "static"
	elseif VARIABLES.GLOBAL[variable] then
		return "global"
	elseif VARIABLES.TEMPORARY[variable] then
		return "temporary"
	else
		return nil	-- Variable Does Not Exist
	end
end


-- Variable Search --
function variables.search(variable_name)
	if VARIABLES.GLOBAL[variable_name] ~= nil then
		return VARIABLES.GLOBAL[variable_name], "global"
	elseif VARIABLES.STATIC[variable_name] ~= nil then
		return VARIABLES.STATIC[variable_name], "static"
	elseif VARIABLES.TEMPORARY[variable_name] ~= nil then
		return VARIABLES.TEMPORARY[variable_name], "temporary"
	else
		return false	-- Variable Does Not Exist
	end
end


-- Inverse Variable Search (Value -> Variable) --
function variables.inverseSearch(value)
	local types = {"GLOBAL", "STATIC", "TEMPORARY"}
	for _,i in pairs(types) do
		for variable, v_value in pairs(VARIABLES[i]) do
			if v_value.Value == value then
				return variable
			end
		end
	end
	-- No value match was found
	return nil
end


-- Get Variable Data Type --
local function getDataType(value,function_call)
	local variable_type
	parent_value = nil
	local data_types = {
		"string",
		"number",
		"array",
		"bool",
		"function"
	}
	if value:match("^['\"]") then
		variable_type = data_types[1]
	elseif value:match("^%[") then
		variable_type = data_types[3]
	elseif value:match("%d+") and not value:match("^['\"]") and not value:find("%a") then
		variable_type = data_types[2]
	elseif value == "true" or value == "false" then
		variable_type = data_types[4]
	elseif value == "" then
		variable_type = "null"
	else
		if getVariableType(value) == nil and not function_call then
			if value:find("[%^%-%+%^%*]") then
				print("Need to eval value: "..value)
				variables.eval(file.Line)
				Error.new("UNKNOWN_VAR_CALL",file.Line,{value})
			else
				if value:find("%.") then
					local parent_array = value:match("%S+%."):gsub("%.","")
					local child_value = value:match("%.%S+"):gsub("%.","")
					if variables.search(parent_array) == false then
						Error.new("NULL_VALUE_INDEX",file.Line,{parent_array})
					end
					parent_value = variables.search(parent_array).Value
					variable_type = "null"
					value = "null"
					goto skip_error
				end
				Error.new("UNKNOWN_VAR_CALL",file.Line,{value})
				::skip_error::
			end
		end
		if function_call then
			value = value:gsub("%(.+%)","")
		end
		if not function_call then
			--print(getVariableType(value))
			variable_type = VARIABLES[getVariableType(value):upper()][value].Type
			parent_value = VARIABLES[getVariableType(value):upper()][value].Value
			parent_content = VARIABLES[getVariableType(value):upper()][value].Content
		else
			if not variables.search(value) then
				Error.new("UNKNOWN_FUNCTION_CALL",file.Line,{value})
			end
			local data = Utils.getFunctionValue(value,Tokens,variables.search(value).Line_Created).Value
			variable_type = getDataType(data,data:match("%S+%("))
			parent_value = data
			if parent_value == "" then
				parent_value = "null"
			end
		end
	end
	return variable_type
end


-- Variable Eval --
function variables.eval(line,n_rea)
	local n_rea = n_rea or false
	local variable_name = nil
	local after_eq_data = {}
	local OPDATA = nil
	-- Data Collection
	if not n_rea then
		for _,token in pairs(Tokens[line]) do
			if token.Token == "OTOKEN_KEY_EQUAL" then
				variable_name = Tokens[line][_-1].Value
				local counter = 1
				while _+counter <= #Tokens[line] do
					after_eq_data[#after_eq_data+1] = Tokens[line][_+counter]
					counter = counter + 1
				end
			end
		end
	else
		local variable = variables.search(line)
	end
	-- Interpreting Data
	for _,data in ipairs(after_eq_data) do
		if data.Token:match("PLUS") then
-- 			print("ADDING")
			local left, right = after_eq_data[_-1], after_eq_data[_+1]
			if right == nil then Error.new("UNEXPECTED_TOKEN",line,{data.Value,left.Value}) end
			if tonumber(left.Value) then left = left.Value elseif variables.search(left.Value) then left = left.Value end
			if tonumber(right.Value) then right = right.Value elseif variables.search(right.Value) then right = right.Value end
			-- Returned Data
			OPDATA = VarOps.ADD(left, right,line)
			after_eq_data[_+1] = {Value = OPDATA, Token = "OTOKEN_KEY_NAME"}
			-- Clearing used data
			after_eq_data[_-1] = nil
			after_eq_data[_] = nil
		end
	end
	-- No operations found
	local _,variable_class = variables.search(variable_name)
	VARIABLES[variable_class:upper()][variable_name].Value = OPDATA or after_eq_data[#after_eq_data].Value
	VARIABLES[variable_class:upper()][variable_name].Type = getDataType(VARIABLES[variable_class:upper()][variable_name].Value)
end


-- Concat Variable Values --
local function concat(value, next_value, value_fcall, next_value_fcall)
	local var_value, next_var_value, out = nil, nil, ""
	if not value:match("['\"]") then
		local variable = variables.search(value)
		if not variable then
			Error.new("UNKNOWN_VAR_CALL",file.Line,{value})				-- variable does not exist
		end
		if value_fcall ~= nil then
			var_value = variable.Value.Value
		else
			var_value = variable.Value
			if type(var_value) == "table" then
				Error.new("Attempt to concatenate a function value: "..value)
			end
		end
	elseif not next_value:match("['\"]") then
		local variable = variables.search(next_value)
		if not variable then
			Error.new("UNKNOWN_VAR_CALL",file.Line,{next_value})		-- variable does not exist
		end
		if next_value_fcall ~= nil then
			next_var_value = variable.Value.Value
		else
			next_var_value = variable.Value
			if type(next_var_value) == "table" then
				print(value_fcall, next_value_fcall)
				Error.new("Attempt to concatenate a function value: "..next_value)
			end
		end
	end
	-- Error Handling --
	if var_value == "null" then
		Error.new("Attempt to concatinate a null value ")
	elseif next_var_value == "null" then
		Error.new("Attempt to concatinate a null value ")
	end
	
	if var_value == nil and next_var_value == nil then
		out = value:gsub("['\"]$","")..next_value:gsub("^['\"]","")
		return out
	elseif var_value ~= nil and next_var_value == nil then
		out = var_value:gsub("['\"]$","")..next_value:gsub("^['\"]","")
		return out
	elseif var_value ~= nil and next_var_value ~= nil then
		out = var_value:gsub("['\"]$","")..next_var_value:gsub("^['\"]","")
		return out
	elseif var_value == nil and next_var_value ~= nil then
		out = value:gsub("['\"]$","")..next_var_value:gsub("^['\"]","")
		return out
	end
	
	return "" -- Something is wrong
end


-- Create Variable (Global/Static) --
function variables.addVariable(tokens, add, token_table)
	local var_name, var_value, var_data, var_line_created = {}, {}, {}, nil
	local skip_token = false
	if token_table ~= nil then
		Tokens = token_table
	end
	-- Getting variable and value
	for _,token in pairs(tokens) do
		--print(token.Token)
		if not token.Token:find("VAREQL") and not token.Token:find("KEYWORD_GLOBAL") then
			if token.Token:find("VALUE") and not skip_token  then 
				var_value[#var_value+1] = token.Value
			elseif token.Token:find("VALUE") and skip_token then
				skip_token = false
			elseif token.Token:find("CONCAT") then
				var_value[#var_value] = tokens[_+1].Value
				skip_token = true
			end
			if token.Token:find("NAME") then 
				var_name[1] = token.Value
				if token.Token:match("_GLOBAL$") then
					var_name[2] = "global"
				elseif token.Token:match("_TEMPORARY") then
					var_name[2] = "temporary"
				else
					var_name[2] = "static"
				end
			end
		end
	end

	-- Setting Variable Data
	var_data.Name = var_name[1]
	var_data.Classification = var_name[2]
	var_data.Value = table.concat(var_value)
	var_data.DataType = getDataType(var_data.Value,var_data.Value:match("%S+%("))

	-- Adding variable to the variables table
	if add then
		VARIABLES[var_data.Classification:upper()][var_data.Name] = {Value = parent_value or var_data.Value, Type = var_data.DataType, Content = parent_content or nil}
	end
	return var_data
end


-- Create Temporary Variables --
function variables.addTempVariable(variable,parent,line)
	VARIABLES["TEMPORARY"][variable] = {
		Parent = {
			Name = parent,
			Line_Created = line
		}
	}
end

return variables
