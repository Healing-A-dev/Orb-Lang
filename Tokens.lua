local Tokens = {}

Tokens = {
--------------------[Keys]-----------------------
    KTOKEN_KEY_EOF = function() return "<EOF>" end,
    KTOKEN_KEY_STATMENT = function() return "<STATMENT>" end,
    KTOKEN_KEY_COMMENT = function() return "<COMMENT>" end,
    KTOKEN_KEY_METHOD = function() return "<METHOD>" end,
    KTOKEN_KEY_ASSIGN = function() return "->" end,
    KTOKEN_KEY_EOL = function() return "<EOL>" end,
    KTOKEN_KEY_MACRO = function() return "@" end,
    KTOKEN_IDENTIFIER = function() return "::<@%w+>" end,
--------------[Keywords (17 for now)]---------------
    KTOKEN_KEYWORD_FUNCTION = function() return "FUNC" end,
    KTOKEN_KEYWORD_IF = function() return "IF" end,
    KTOKEN_KEYWORD_ELIF = function() return "ELIF" end,
    KTOKEN_KEYWORD_UNTIL = function() return "UNTIL" end,
    KTOKEN_KEYWORD_REPEAT = function() return "REPEAT" end,
    KTOKEN_KEYWORD_DERIVE = function() return "DERIVE" end,
    KTOKEN_KEYWORD_FOR = function() return "FOR" end,
    KTOKEN_KEYWORD_SET = function() return "SET" end,
    KTOKEN_KEYWORD_NULL = function() return "NULL" end,
    KTOKEN_KEYWORD_ELSE = function() return "ELSE" end,
    KTOKEN_KEYWORD_TRUE = function() return "TRUE"end,
    KTOKEN_KEYWORD_FALSE = function() return "FALSE" end,
    KTOKEN_KEYWORD_RETURN = function() return "RETURN" end,
    KTOKEN_KEYWORD_CLASS = function() return "CLASS" end,
    KTOKEN_KEYWORD_FORMAT = function() return "FORMAT" end,
    KTOKEN_KEYWORD_PUTLN = function() return "PUTLN" end,
    KTOKEN_KEYWORD_STATIC = function() return "STATIC" end,
------------------------[Others]-------------------------
    KTOKEN_TYPE_STRING = function() return "STRING" end,
    KTOKEN_TYPE_NUMBER = function() return "NUMBER" end,
    KTOKEN_TYPE_OPAREN = function() return "(" end,
    KTOKEN_TYPE_CPAREN = function() return ")" end,
    KOTKEN_TYPE_OBRACE = function () return "{" end,
    KTOKEN_TYPE_CBRACE = function () return "}" end,
    KTOKEN_TYPE_PLUS = function() return "+" end,
    KTOKEN_TYPE_MINUS = function() return "-" end,
    KTOKEN_TYPE_DIVIDE = function() return "/" end,
    KTOKEN_TYPE_MULTIPLY = function() return "*" end,
    KTOKEN_TYPE_MODULO = function() return "%" end,
    KTOKEN_TYPE_SQUOTE = function() return "'" end,
    KTOKEN_TYPE_DQUOTE = function() return '"' end,
    KTOKEN_TYPE_EQUAL = function() return "=" end,
    KTOKEN_TYPE_OBRACKET = function() return "[" end,
    KTOKEN_TYPE_CBRACKET = function() return "]" end,
    KTOKEN_TYPE_PERIOD = function() return "." end,
    KTOKEN_TYPE_COLON = function() return ":" end,
    KTOKEN_TYPE_COMMA = function() return "," end,
    KTOKEN_TYPE_EOL = function() return ";" end
}
    
return Tokens