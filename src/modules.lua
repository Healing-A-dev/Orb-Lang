local modules = {}

-- Imports --
local Error     = require("src/errors")
local Variables = require("src/variables")
local Lexer     = require("src/lexer")

-- Instance Variables --
MODULES = {}

-- Module Content Collection --
function modules.getContent(module_name, tokens, line)
	local stack_mini, out, set_out, contents = {}, "", false, {}
	for s = line, #tokens do
		contents[s] = {}
		contents[s][#contents[s]+1] = ""
		for _,i in pairs(tokens[s]) do
			contents[s][#contents[s]] = contents[s][#contents[s]]..i.Value.." "
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
				if set_out then
					out = out..i.Value
				end
				if i.Token:find("_RET") then
					set_out = true
				end
			end
		end
	end
	::nil_return::
	return {Value = "null", Returned = false, Contents = contents	}
end


-- New Modules --
function modules.new(tokens, add, token_table)
	local module_name = nil
    for _,token in pairs(tokens) do
    	if token.Token:find("MOD_NAME") then
    		module_name = token.Value
    		MODULES[module_name] = {
    			Classification = "static",
    			Functions = {},
    			Content = {}
    		}
    	elseif token.Token:find("GLOBAL$") then
    		MODULES[module_name].Classification = "global"
    	end
	end

	local content = modules.getContent(module_name, token_table, file.Line).Contents
	for s = 1, #content do
		if content[s] ~= nil then
			if s > 2 and s < #content then
				MODULES[module_name].Content[#MODULES[module_name].Content+1] = content[s][1]
			end
		end
	end

	if add then
		VARIABLES[MODULES[module_name].Classification:upper()][module_name] = {
			Value = modules.getContent(module_name, token_table, file.Line).Value,
			Type = "module",
			Line_Created = file.Line,
			Content = content
		}
	end
	return {Name = module_name, Classification = module_classification, Arguments = module_variables}
	--os.exit()
end


return modules
