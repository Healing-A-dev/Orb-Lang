local parser = {}

-- Imports --
local Variables  = require("src/variables")
local Function   = require("src/functions")
local Error 	 = require("src/errors")
local Ast        = require("src/ast")
local Tokens	 = require("src/tokens")
local Module     = require("src/modules")

-- Instance Variables -
file = {
	Name = arg[1],
	Line = 0
}
parser = {}


-- Seek Function --
local function seek(t,line,to_seek)
	local to_seek = to_seek or 0
	return t[line+to_seek]
end

-- Parser --
function parser.parse(token_table)
	local in_mod = false
	for line = 1, #token_table do
		file.Line = line
		for _,token in pairs(token_table[line]) do
			-- Setting local instance variables
			local next_token
			local prev_token

			-- Previous token
			if token_table[line][_-1] ~= nil then
				prev_token = token_table[line][_-1]
			end
			-- Next token
			if token_table[line][_+1] ~= nil then
				next_token = token_table[line][_+1]
			end
			if not in_mod_func then
				if token.Token:find("VAREQL") then
					-- ERROR IN HERE SOMWHERE
					--print(in_mod)
					local variable_data = Variables.addVariable(token_table[line], true, token_table)
				elseif token.Token:find("KEY_EQUAL") then
					local variable_data, classification = Variables.search(token_table[line][_-1].Value)
					if not variable_data then
						Error.new("ASSIGN_TO_UNDECLARED",line,{token_table[line][_-1].Value})
					end
					Variables.eval(line)
				end

				-- Module calls
				if token.Token == "OTOKEN_KEY_MODULE_CALL" then
					local module_name = token_table[line][_+1].Value
					local m_function_name = ""
					if token_table[line][_+2].Value == "::" then
						m_function_name = token_table[line][_+3].Value
					end
					print("Module: "..module_name)
					print("Subfunction: "..m_function_name)
					print("TODO: IMPLEMENT MODULES")
					os.exit()
				end

				-- Function calls
				if token.Token == "OTOKEN_TYPE_VALUE" and token.Value == Tokens.symbols.OTOKEN_KEY_OPAREN --[[and not token_table[line][_-1].Token:find("VAREQL")]] or token.Token == "OTOKEN_KEY_OPAREN" and token_table[line][_-1].Token == "OTOKEN_KEY_NAME" then
					local to_call
					local call_data = Variables.search(token_table[line][_-1].Value)
					if type(call_data) == "table" then
						to_call = call_data.Type
					end
					if to_call == "function" then
						XOHE:UpdateOrbValues({_Data = call_data.Content, Line_Data = token_table[line]})
					elseif to_call ~= "function" and to_call ~= "module" then
						Error.new("UNKNOWN_FUNCTION_CALL",line,{token_table[line][_-1].Value})
					end
				end

			--[[Adding Data To The Stack]]--
			-- Functions and Modules
			if token.Token:find("FUNC_NAME") then
				Function.new(token_table[line], true, token_table, line)
				_STACK.DATA[#_STACK.DATA+1] = {Type = "FUNC", Name = token.Value, Line_Created = line}
			elseif token.Token:find("MOD_NAME") then
				Module.new(token_table[line], true, token_table, line)
				_STACK.DATA[#_STACK.DATA+1] = {Type = "MOD", Name = token.Value, Line_Created = line}
			end
			-- Everything else
			if token.Token:find("STMT") and not token.Token:find("FUNC") and not token.Token:find("MOD") then
				_STACK.DATA[#_STACK.DATA+1] = {Type = token.Token:match("%w+$"), Name = "", Line_Created = line}
			end
			if token.Token == "OTOKEN_KEY_OBRACE" and #_STACK.DATA > 0 then
				_STACK[#_STACK+1] = _STACK.DATA[#_STACK.DATA]
				table.remove(_STACK.DATA,#_STACK.DATA)
			end

			-- Removing data from the stack
			if token.Token == "OTOKEN_KEY_CBRACE" and #_STACK > 0 then
				if _STACK[#_STACK].Type == "FUNC" or _STACK[#_STACK].Type == "MOD" then
					_STACK.RESERVE[#_STACK.RESERVE+1] = _STACK[#_STACK]
					if _STACK.RESERVE[#_STACK.RESERVE].Type == "MOD" then
						in_mod = false
					end
				end
				table.remove(_STACK,#_STACK)
			end
		end
	end

	-- Data Remaining Stack After Execution (Throws Error)
	if #_STACK.DATA > 0 then
		local end_value = token_table[_STACK.DATA[#_STACK.DATA].Line_Created][#token_table[_STACK.DATA[#_STACK.DATA].Line_Created]].Value
		local end_token = _STACK.DATA[#_STACK.DATA].Type:lower()
		Error.new("STATEMENT_INIT",_STACK.DATA[#_STACK.DATA].Line_Created,{end_value,end_token,_STACK.DATA[#_STACK.DATA].Name})
	elseif #_STACK > 0 then
		Error.new("STATEMENT_END",file.Line,{_STACK[#_STACK].Type:lower(), _STACK[#_STACK].Line_Created,_STACK[#_STACK].Name})
	end
	return true
end
end

return parser
