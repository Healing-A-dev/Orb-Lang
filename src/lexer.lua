local lexer = {}

--[[Imports]]--
local Tokens = require("src/tokens")
local Errors = require("src/errors")
local Utils  = require("src/utils")

--[[Instance Variables]]--
lexer = {
	tokens = {}
}


--[[Token Checker]]--
local function isValidToken(token)
	if #token == 1 then
		for key,value in pairs(Tokens.symbols) do
			if token == value then
				return {Token = key, Value = token, isToken = true}
			end			
		end
	elseif #token > 1 then
		local token = token:gsub("^%s+","")
		for key,value in pairs(Tokens.keywords) do
			if token == value then
				if key:find("STMT") then
					return {Token = key, Value = token, isToken = true, Statement = true}
				end
				return {Token = key, Value = token, isToken = true}
			end
		end
	end
	return {isToken = false}
end

--[[Tokenizer]]--
function lexer.tokenize(string, line)
	lexer.tokens[line] = {}
	local hold, iter = {},0
	for character in string:gmatch(".") do
		iter = iter + 1
		if not isValidToken(character).isToken then
			hold[#hold+1] = character
		else
			if #hold > 0 then
				local token  = table.concat(hold)
				if isValidToken(token).isToken then
					lexer.tokens[line][#lexer.tokens[line]+1] = isValidToken(token)
				else
					lexer.tokens[line][#lexer.tokens[line]+1] = {Token = "OTOKEN_KEY_NAME", Value = token, isToken = false}
				end
				hold = {}
			end
			lexer.tokens[line][#lexer.tokens[line]+1] = isValidToken(character)
		end
	end
	if #hold > 0 then
		local token  = table.concat(hold)
		if isValidToken(token).isToken then
			lexer.tokens[line][#lexer.tokens[line]+1] = isValidToken(token)
		else
			lexer.tokens[line][#lexer.tokens[line]+1] = {Token = "OTOKEN_KEY_NAME", Value = token, isToken = false}
		end
	end
end

--[[Token Adjuster]]--
function lexer.adjust()
	local skip
	local is_array_value = false
	local multi_line_comment = false
	local to_remove = {false, nil}
	for s = 1, #lexer.tokens do
		local fix = {}
		local is_value = false
		for _,token in pairs(lexer.tokens[s]) do
			-- Setting local instance variables
			local token, token_value = token.Token, token.Value
			local next_token, next_token_value
			local prev_token, prev_token_value
			local combined_token

			-- Previous token
			if lexer.tokens[s][_-1] ~= nil then
				prev_token = lexer.tokens[s][_-1].Token
				prev_token_value = lexer.tokens[s][_-1].Value
			end

			--Next token
			if lexer.tokens[s][_+1] ~= nil then
				next_token = lexer.tokens[s][_+1].Token
				next_token_value = lexer.tokens[s][_+1].Value
			end
			
			-- Setting combination token values (ie. <=)
			if next_token_value ~= nil then
				combined_token = Tokens.fetchCombinedValue(token_value, next_token_value)
				if combined_token ~= nil then
					lexer.tokens[s][_] = combined_token
					lexer.tokens[s][_+1] = nil
				end
			end
			
			-- Setting string literals
			if token:find("QUOTE") and _ ~= skip then
				local string_init_char, hold = token, {}
				hold[1] = token_value
				local skipper = 1
				while lexer.tokens[s][_+skipper].Token ~= string_init_char do
					hold[#hold+1] = lexer.tokens[s][_+skipper].Value
					lexer.tokens[s][_+skipper] = nil
					skipper = skipper + 1
					-- Unfinished string
					if _+skipper == #lexer.tokens[s] and lexer.tokens[s][_+skipper].Token ~= string_init_char then
						Errors.new("UNFINISHED_STRING",s,{table.concat(hold)})
					end
					-- Ending String
					if lexer.tokens[s][_+skipper].Token == string_init_char then
						hold[#hold+1] = lexer.tokens[s][_+skipper].Value
					end
				end
				-- Adding string to the lexer table
				lexer.tokens[s][_] = {Token = "OTOKEN_KEY_STRING_LIT", Value = table.concat(hold), isToken = true}
				lexer.tokens[s][_+skipper] = nil
				skip = _+skipper
			end

			-- Single-line comments
			if prev_token ~= nil and prev_token:find("COMMENT") then
				if not multi_line_comment then
					lexer.tokens[s][_].Token = prev_token
				elseif multi_line_comment then
					if not lexer.tokens[s][_].Token:find("E_MULTI") then
						lexer.tokens[s][_].Token = prev_token
					end
				end
			end
			
			-- Multi-line comments
			if multi_line_comment and not lexer.tokens[s][_].Token:find("E_MULTI") then
				lexer.tokens[s][_].Token = "OTOKEN_KEY_COMMENT"
			elseif multi_line_comment and lexer.tokens[s][_].Token:find("E_MULTI") then
				multi_line_comment = false
			end
			if lexer.tokens[s][_].Token:find("S_MULTI") then
				multi_line_comment = true
			end
			
			-- Adding token to a table to be asjusted order wise (for future lexing reasons)
			if token ~= "OTOKEN_KEY_SPACE" and token ~= "OTOKEN_KEY_TAB" then
				fix[#fix+1] = lexer.tokens[s][_] -- Removing spaces and tokens marked for removal
			end
		end
		skip = 0
		lexer.tokens[s] = {}
		for _,i in pairs(fix) do
			lexer.tokens[s][#lexer.tokens[s]+1] = i
		end
	end
end

function lexer.lex(file)
	--[[Lexing File]]--
	local file = io.open(file,"r")
	local lines = file:lines()
	local counter = 1
	local is_array_value, array_stack = false, {}
	for line in lines do
		lexer.tokenize(line.." ",counter)
		counter = counter + 1
	end
	file:close()
	lexer.adjust()
	
	--[[Creating Function/Variable Tokens]]--
	for s = 1, #lexer.tokens do
		local is_value = false
		for _,token in pairs(lexer.tokens[s]) do
			-- Setting local instance variables
			local next_token
			local prev_token
			-- Previous token
			if lexer.tokens[s][_-1] ~= nil then
				prev_token = lexer.tokens[s][_-1]
			end
			-- Next token
			if lexer.tokens[s][_+1] ~= nil then
				next_token = lexer.tokens[s][_+1]
			end
			
			-- Creating statement name tokens
			if token.Statement and next_token.Token:find("NAME") then
				local ext,class = token.Token:match("%w+$"), ""
				if ext == "GLOBAL" then
					class = ext.."_"
					ext = token.Token:gsub("_GLOBAL",""):match("%w+$")
				end
				next_token.Token = "OTOKEN_KEY_"..class..ext.."_NAME"
				next_token.isToken = true
			end
			
			-- Global values
			if token.Token == "OTOKEN_KEYWORD_GLOBAL" then
				next_token.Token = next_token.Token.."_GLOBAL"
			end
			
			-- Adding Value Tokens
			if is_value or is_array_value then
				local if_global_value = lexer.tokens[s][_-2].Token:match("_GLOBAL$") or ""
				if token.Token:match("OTOKEN_KEY_OBRACKET") then
					print(s)
					Utils.gatherArrayData(s,lexer.tokens)
				end
				if not token.Token:match("CONCAT") then
					token.Token = "OTOKEN_TYPE_VALUE"
				end
				if token.Token:find("VAREQL") and not token.Token:find("_CALL") then
					lexer.tokens[s][_-2].Token = "OTOKEN_TYPE_VARIABLE"..if_global_value
				end
			end
			if lexer.tokens[s][_].Token:find("VAREQL") then
				is_value = true
			end
			
		end
	end
end

return lexer
