local tokens = {}

tokens = {
	symbols = {
		OTOKEN_KEY_MODULE_CALL 			= "@",
		OTOKEN_KEY_OPAREN 				= "(",
		OTOKEN_KEY_CPAREN 				= ")",
		OTOKEN_KEY_OBRACE 				= "{",
		OTOKEN_KEY_CBRACE 				= "}",
		OTOKEN_KEY_OBRACKET 			= "[",
		OTOKEN_KEY_CBRACKET 			= "]",
		OTOKEN_KEY_PLUS 				= "+",
		OTOKEN_KEY_MINUS 				= "-" ,
		OTOKEN_KEY_DIVIDE 				= "/",
		OTOKEN_KEY_MULTIPLY				= "*",
		OTOKEN_KEY_SQUOTE 				= "'",
		OTOKEN_KEY_DQUOTE 				= '"',
		OTOKEN_KEY_EQUAL 				= "=",
		OTOKEN_KEY_PERIOD 				= ".",
		OTOKEN_KEY_COLON 				= ":",
		OTOKEN_KEY_COMMA 				= ",",
		OTOKEN_KEY_GTHAN 				= ">",
		OTOKEN_KEY_LTHAN 				= "<",
		OTOKEN_KEY_BANG 				= "!",
		OTOKEN_KEY_SPACE				= " ",
		OTOKEN_KEY_COMMENT				= "#",
		OTOKEN_KEY_POINTER				= "&",
		OTOKEN_KEY_TAB					= "\t",
		OTOKEN_KEY_NEWLINE				= "\n"
	},
	keywords = {
		OTOKEN_KEYWORD_STMT_IF			= "if",
		OTOKEN_KEYOWRD_STMT_ELSE		= "else",
		OTOKEN_KEYWORD_STMT_ELSEIF		= "elseif",
		OTOKEN_KEYWORD_STMT_FUNC		= "func",
		OTOKEN_KEYWORD_STMT_MOD			= "mod",
		OTOKEN_KEYWORD_STMT_FOR			= "for",
		OTOKEN_KEYWORD_STMT_WHILE		= "while",
		OTOKEN_KEYWORD_RET				= "ret",
		OTOKEN_KEYWORD_GLOBAL			= "global",
		OTOKEN_KEYWORD_FALSE			= "false",
		OTOKEN_KEYWORD_NULL				= "null",
		OTOKEN_KEYWORD_TRUE				= "true",
	},
	combined = {
		OTOKEN_KEYWORD_AND				= "&&",
		OTOKEN_KEYWORD_OR				= "||",
		OTOKEN_COMBINED_VAREQL			= ":=",
		OTOKEN_COMBINED_GEQLTO			= ">=",
		OTOKEN_COMBINED_LEQLTO			= "<=",
		OTOKEN_COMBINED_EQL				= "==",
		OTOKEN_COMBINED_NOT_EQL			= "!=",
		OTOKEN_COMBINED_MVARCALL		= "::",
		OTOKEN_COMBINED_S_MULTI			= "/=",
		OTOKEN_COMBINED_E_MULTI			= "=/",		
		OTOKEN_COMBINED_CONCAT			= "<<",
		OTOKEN_COMBINED_PIPE			= "=>"
	}
}

-- Utility Functions --
function tokens.fetchCombinedValue(token1, token2)
	for token,value in pairs(tokens.combined) do
		if token1..token2 == value then
			return {Token = token, Value = value, isToken = true}
		end
	end
end

return tokens
