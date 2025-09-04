local arrays = {}

-- Imports --
local Utils = require("src/utils")
local Error = require("src/errors")

-- Instance Variables --
arrays = {
    STACK = {}
}

-- Code --
local function search_next_line(tokens, line)
    local line = line + 1
    if tokens[line] == nil then
        return
    end
    for _,token in pairs(tokens[line]) do
        if token.Token:match("CBRACKET") then
            return true
        end
    end
end


function arrays.verifyArraySyntax(tokens, line, token_pos)
    arrays.STACK[#arrays.STACK+1] = {Line_Created = line, Token = tokens[line][token_pos].Token}
    while #arrays.STACK > 0 do
        -- Increment token position
        if (token_pos + 1) > #tokens[line] then
            line = line + 1
            token_pos = 1
        else
            token_pos = token_pos + 1
        end

        -- Setting token variable
        local token = tokens[line][token_pos].Token

        -- Checking if a "dictionary" value is present (ie. key := value)
        if token:match("VAREQL") then
            expect({"NAME", "STRING_LIT"}, tokens, line, token_pos - 2)
            expect({"NAME", "STRING_LIT", "MOD", "FUNC", "OBRACKET"}, tokens, line, token_pos)
        end

        -- Checking if all arrays have been closed
        if token:match("CBRACKET") then
            table.remove(arrays.STACK, #arrays.STACK)
            if #arrays.STACK == 0 then
                break
            end
        end

        -- Checking if still in array at EOL (comma required)
        if token_pos == #tokens[line] then
            if not search_next_line(tokens, line) then
                if token_pos == 1 then
                    expect({"COMMA","OBRACKET"}, tokens, line, token_pos, "ARRAY_EOL")
                    else
                    expect({"COMMA","OBRACKET"}, tokens, line, token_pos - 1, "ARRAY_EOL")
                end
            end
        end
    end
end

return arrays
