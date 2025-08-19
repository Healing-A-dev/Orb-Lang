local lexer  = {}

-- Imports --
local Tokens = require("src/tokens")
local Error  = require("src/errors")
local Utils  = require("src/utils")

-- Instance Variables --
lexer        = {
    tokens = {},
    static_variable_buffer = {}
}

-- Token Checker --
local function isValidToken(token)
    if #token == 1 and token ~= "." then
        for key, value in pairs(Tokens.symbols) do
            if token == value then
                return { Token = key, Value = token, isToken = true }
            end
        end
    elseif #token > 1 or token == "." then
        local token = token:gsub("^%s+", "")
        for key, value in pairs(Tokens.keywords) do
            if token == value then
                if key:find("STMT") then
                    return { Token = key, Value = token, isToken = true, Statement = true }
                end
                return { Token = key, Value = token, isToken = true }
            end
        end
    end
    return { isToken = false }
end

-- Tokenizer --
function lexer.tokenize(string, line, isSafe)
    if not isSafe then
        lexer.tokens[line] = {}
        local hold, iter = {}, 0
        for character in string:gmatch(".") do
            iter = iter + 1
            if not isValidToken(character).isToken then
                hold[#hold + 1] = character
            else
                if #hold > 0 then
                    local token = table.concat(hold)
                    if isValidToken(token).isToken then
                        lexer.tokens[line][#lexer.tokens[line] + 1] = isValidToken(token)
                    else
                        lexer.tokens[line][#lexer.tokens[line] + 1] = { Token = "OTOKEN_KEY_NAME", Value = token, isToken = false }
                    end
                    hold = {}
                end
                lexer.tokens[line][#lexer.tokens[line] + 1] = isValidToken(character)
            end
        end
        if #hold > 0 then
            local token = table.concat(hold)
            if isValidToken(token).isToken then
                lexer.tokens[line][#lexer.tokens[line] + 1] = isValidToken(token)
            else
                lexer.tokens[line][#lexer.tokens[line] + 1] = { Token = "OTOKEN_KEY_NAME", Value = token, isToken = false }
            end
        end
    else
        -- Safe Mode (aka Nested Lexing mode); Does not affect the main token table
        lexer.tokens_safemode[line] = {}
        local hold, iter = {}, 0
        for character in string:gmatch(".") do
            iter = iter + 1
            if not isValidToken(character).isToken then
                hold[#hold + 1] = character
            else
                if #hold > 0 then
                    local token = table.concat(hold)
                    if isValidToken(token).isToken then
                        lexer.tokens_safemode[line][#lexer.tokens_safemode[line] + 1] = isValidToken(token)
                    else
                        lexer.tokens_safemode[line][#lexer.tokens_safemode[line] + 1] = {
                            Token = "OTOKEN_KEY_NAME",
                            Value =
                                token,
                            isToken = false
                        }
                    end
                    hold = {}
                end
                lexer.tokens_safemode[line][#lexer.tokens_safemode[line] + 1] = isValidToken(character)
            end
        end
        if #hold > 0 then
            local token = table.concat(hold)
            if isValidToken(token).isToken then
                lexer.tokens_safemode[line][#lexer.tokens_safemode[line] + 1] = isValidToken(token)
            else
                lexer.tokens_safemode[line][#lexer.tokens_safemode[line] + 1] = {
                    Token = "OTOKEN_KEY_NAME",
                    Value =
                        token,
                    isToken = false
                }
            end
        end
    end
end

-- Token Adjuster --
function lexer.adjust(safemode)
    -- Variables
    local skip
    local is_array_value = false
    local multi_line_comment = false
    local to_remove = { false, nil }
    local lexer_tokens = lexer.tokens

    if safemode then
        lexer_tokens = lexer.tokens_safemode
    else
        --COMPILER.APPEND_HEADER("    .file: \""..arg[1].."\"")
        ASM.HEADER = "    .file \"" .. arg[1] .. "\"\n    .text\n" .. ASM.HEADER
    end

    -- Token Adjuster
    for s = 1, #lexer_tokens do
        local fix = {}
        local is_value = false
        for _, token in pairs(lexer_tokens[s]) do
            -- Setting local instance variables
            local token, token_value = token.Token, token.Value
            local next_token, next_token_value
            local prev_token, prev_token_value
            local combined_token

            -- Previous token
            if lexer_tokens[s][_ - 1] ~= nil then
                prev_token = lexer_tokens[s][_ - 1].Token
                prev_token_value = lexer_tokens[s][_ - 1].Value
            end

            --Next token
            if lexer_tokens[s][_ + 1] ~= nil then
                next_token = lexer_tokens[s][_ + 1].Token
                next_token_value = lexer_tokens[s][_ + 1].Value
            end

            -- Setting combination token values (ie. <=)
            if next_token_value ~= nil then
                combined_token = Tokens.fetchCombinedValue(token_value, next_token_value)
                if combined_token ~= nil then
                    lexer_tokens[s][_] = combined_token
                    lexer_tokens[s][_ + 1] = nil
                end
            end

            -- Setting string literals
            if token:find("QUOTE") and _ ~= skip then
                local string_init_char, hold = token, {}
                hold[1] = token_value
                local skipper = 1
                while lexer_tokens[s][_ + skipper].Token ~= string_init_char do
                    hold[#hold + 1] = lexer_tokens[s][_ + skipper].Value
                    lexer_tokens[s][_ + skipper] = nil
                    skipper = skipper + 1
                    -- Unfinished string
                    if _ + skipper == #lexer_tokens[s] and lexer_tokens[s][_ + skipper].Token ~= string_init_char then
                        Error.new("UNFINISHED_STRING", s, { table.concat(hold) })
                    end
                    -- Ending String
                    if lexer_tokens[s][_ + skipper].Token == string_init_char then
                        hold[#hold + 1] = lexer_tokens[s][_ + skipper].Value
                    end
                end
                -- Adding string to the lexer table
                lexer_tokens[s][_] = { Token = "OTOKEN_KEY_STRING_LIT", Value = table.concat(hold), isToken = true }
                lexer_tokens[s][_ + skipper] = nil
                skip = _ + skipper
            end

            -- Single-line comments
            if prev_token ~= nil and prev_token:find("COMMENT") then
                if not multi_line_comment then
                    lexer_tokens[s][_].Token = prev_token
                elseif multi_line_comment then
                    if not lexer_tokens[s][_].Token:find("E_MULTI") then
                        lexer_tokens[s][_].Token = prev_token
                    end
                end
            end

            -- Multi-line comments
            if multi_line_comment and not lexer_tokens[s][_].Token:find("E_MULTI") then
                lexer_tokens[s][_].Token = "OTOKEN_KEY_COMMENT"
            elseif multi_line_comment and lexer_tokens[s][_].Token:find("E_MULTI") then
                multi_line_comment = false
            end
            if lexer_tokens[s][_].Token:find("S_MULTI") then
                multi_line_comment = true
            end

            -- Adding token to a table to be asjusted order wise (for future lexing reasons)
            if token ~= "OTOKEN_KEY_SPACE" and token ~= "OTOKEN_KEY_TAB" then
                fix[#fix + 1] = lexer_tokens[s][_] -- Removing spaces and tokens marked for removal
            end
        end
        skip = 0
        lexer_tokens[s] = {}
        for _, i in pairs(fix) do
            lexer_tokens[s][#lexer_tokens[s] + 1] = i
        end
    end
end

-- Lexing File --
function lexer.lex(file, safemode)
    -- Clearing safemode tokens and static variable tables
    lexer.tokens_safemode = {}
    if not safemode then
        VARIABLES.STATIC = {}
    else
        lexer.static_variable_buffer = VARIABLES.STATIC
    end

    -- Variables
    local counter = 1
    local is_array_value, array_stack = false, {}
    local lexer_tokens = lexer.tokens
    if safemode then
        lexer_tokens = lexer.tokens_safemode
    end

    -- Actual Lexer
    if type(file) ~= "table" then
        local file_name = file
        local file = io.open(file, "r")
        if file == nil then
            Error.new("IMPORT_NO_FILE", nil, { file_name })
        end
        local lines = file:lines()
        for line in lines do
            lexer.tokenize(line .. " ", counter, safemode)
            counter = counter + 1
        end
        file:close()
    else
        for _, line in pairs(file) do
            lexer.tokenize(line .. " ", counter, safemode)
            counter = counter + 1
        end
    end
    lexer.adjust(safemode)

    -- Creating Function/Variable Tokens --
    for s = 1, #lexer_tokens do
        local is_value = false
        for _, token in pairs(lexer_tokens[s]) do
            -- Setting local instance variables
            local next_token
            local prev_token

            -- Previous token
            if lexer_tokens[s][_ - 1] ~= nil then
                prev_token = lexer_tokens[s][_ - 1]
            end

            -- Next token
            if lexer_tokens[s][_ + 1] ~= nil then
                next_token = lexer_tokens[s][_ + 1]
            end

            -- Creating statement name tokens
            if token.Statement and next_token.Token:find("NAME") then
                local ext, class = token.Token:match("%w+$"), ""
                if ext == "GLOBAL" then
                    class = ext .. "_"
                    ext = token.Token:gsub("_GLOBAL", ""):match("%w+$")
                end
                next_token.Token = "OTOKEN_KEY_" .. class .. ext .. "_NAME"
                next_token.isToken = true
            end

            -- Global values
            if token.Token == "OTOKEN_KEYWORD_GLOBAL" then
                if not next_token.Token:find("NAME") and not next_token.Token:find("FUNC") and not next_token.Token:find("MOD") then
                    Error.new("NAME_EXPECTED", s, { token.Value })
                else
                    next_token.Token = next_token.Token .. "_GLOBAL"
                end
            end

            -- Adding Value Tokens
            if is_value or is_array_value then
                local if_global_value = lexer_tokens[s][_ - 2].Token:match("_GLOBAL$") or ""
                if token.Token:match("OTOKEN_KEY_OBRACKET") then
                    Error.warn("TODO: IMPLEMENT ARRAYS", s)
                    Utils.gatherArrayData(s, lexer_tokens)
                end
                if not token.Token:match("CONCAT") then
                    token.Token = "OTOKEN_TYPE_VALUE"
                end
                if token.Token:find("VAREQL") and not token.Token:find("_CALL") then
                    lexer_tokens[s][_ - 2].Token = "OTOKEN_TYPE_VARIABLE" .. if_global_value
                end
            end
            if lexer_tokens[s][_] ~= nil and lexer_tokens[s][_].Token:find("VAREQL") then
                is_value = true
            end

            -- File Imports --
            if lexer_tokens[s][_] ~= nil and lexer_tokens[s][_].Token == "OTOKEN_KEYWORD_IMPORT" then
                -- Instance Variables
                local possible_ext = false

                -- Getting file name from next expected tokens
                local file = expect({ "NAME", "STRING_LIT" }, lexer_tokens, s, _)

                -- Removing begining and ending quotation marks
                file = file.Value:gsub("^['\"]", ""):gsub("['\"]$", "")

                -- Converting all '.' to '/' for path searching
                if file:find("%.") then
                    file = file:gsub("%.", "/")
                    possible_ext = true
                end

                -- Checking if the file with a .orb extension exist
                if not io.open(file .. ".orb") then
                    if possible_ext then
                        -- Converting the last '/' back to a '.' assuming file extension
                        local ext = file:match("%/[^/]+$"):gsub("/", "")
                        file = file:gsub("%/" .. ext, "." .. ext)
                        if not io.open(file) then
                            Error.new("IMPORT_NO_FILE", s, { file, ".orb <." .. ext .. ">" })
                        end
                    else
                        Error.new("IMPORT_NO_FILE", s, { file })
                    end
                else
                    file = file .. ".orb"
                end

                -- Lexing the new file
                local return_tokens = lexer.lex(file, true)
                lexer_tokens = Utils.merge(return_tokens, lexer_tokens)
                lexer.tokens = Utils.merge(return_tokens, lexer.tokens)

                -- Fixing Error Adjustments
                --Adjustment = (#return_tokens)
            end
        end
    end
    if safemode then
        VARIABLES.STATIC = lexer.static_variable_buffer
    end
    return lexer_tokens
end

return lexer
