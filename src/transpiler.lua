local transpiler = {}
local Tokens = require("src/Tokens")

local function autofill(t,value)
    for _,i in pairs(t) do
        if not tonumber(_) then
            if _:lower():find(value:lower()) then
                return _
            end
        end
    end
end

function transpiler.translate() -- No input need because im super smart >:)
    local translated = {}
    local activeImports = false
    local Statements = {
        Function = false,
        While = false,
        If = false,
        For = false
    }
    for _,i in ipairs(syntax) do
        translated[_] = {}
        if _ > 1 or currentFile == "Interactive Interpreter" then
            if fullTokens[_] ~= nil then
                for s,t in pairs(fullTokens[_]) do
                    if t[1]:find("INCLUDING") then
                        goto passThrough
                    end
                    if t[1]:find("ASSIGN") then
                        local arguments = syntax[_]:match("%(%)%s?->%s?%(.+%)"):gsub("%(%)%s?->%s?","")
                        local functionName = syntax[_]:match("=.+%(%)") or syntax[_]:match("%W?%w+%(%)")
                        functionName = functionName:gsub("[%(%)=%s]","")
                        Buffer[_] = {}
                        Buffer[_][#Buffer[_]+1] = functionName
                        Buffer[_][#Buffer[_]+1] = arguments
                    end
                end
            end
            for s,t in pairs(fullTokens[_]) do
                if t[3] == "STATEMENT" then
                    Statements[#Statements+1] = {autofill(Statements,t[2]), true}
                end
                if #Statements > 0 and t[1] == Tokens.OTOKEN_KEY_EOL() then
                    table.remove(Statements,#Statements)
                    t[2] = "end"
                end
                if t[3] ~= nil and t[3]:find("COMMENT") then goto isComment end
                if t[1]:find("OBRACE") and fullTokens[_][s-1][1]:find("COLON") and #Statements > 0 then
                    if Statements[#Statements][1]:lower():find("func") then
                        t[2] = nil
                    elseif Statements[#Statements][1]:lower():find("if") then
                        t[2] = " then"
                    elseif Statements[#Statements][1]:lower():find("while") or Statements[#Statements][1]:lower():find("for") then
                        t[2] = " do"
                    end
                    translated[_][#translated[_]] = nil
                end
                if t[2] == Tokens.OTOKEN_KEYWORD_PUTLN():lower() then
                    t[2] = "print("
                    fullTokens[_][#fullTokens[_]][2] = ");"
                elseif t[2] == Tokens.OTOKEN_KEYWORD_PUT():lower() then
                    t[2] = "io.write("
                    fullTokens[_][#fullTokens[_]][2] = ");"
                elseif t[2] == Tokens.OTOKEN_KEYWORD_FUNCTION():lower() then
                    t[2] = "function "
                elseif t[2] == Tokens.OTOKEN_KEYWORD_SET():lower() then
                    t[2] = nil
                elseif t[2] == Tokens.OTOKEN_KEYWORD_STATIC():lower() then
                    t[2] = "local"
                elseif t[2] == Tokens.OTOKEN_TYPE_COLON() and not t[1]:find("STRING") then
                    if fullTokens[_][s+1][2] == "Number" or fullTokens[_][s+1][2] == "String" or fullTokens[_][s+1][2] == "Array" or fullTokens[_][s+1][2] == "Any" or fullTokens[_][s+1][2] == "Char" or fullTokens[_][s+1][2] == "Bool" then
                        t[2] = nil
                        fullTokens[_][s+1][1] = "OTOKEN_SPECIAL_TYPE"
                        fullTokens[_][s+1][2] = nil
                    end
                elseif t[1]:find("CONCAT") then
                    t[2] = ".."
                elseif t[1]:find("NOT_EQUALTO") then
                    t[2] = "~="
                elseif t[1]:find("KEY_OR") then
                    t[2] = "or"
                elseif t[1]:find("KEY_AND") then
                    t[2] = "and"
                elseif t[1]:find("MLINE_COMMENT_START") then
                    t[2] = "--[["
                elseif t[1]:find("MLINE_COMMENT_END") then
                    t[2] = "]]--"
                end
                translated[_][#translated[_]+1] = t[2]
                ::isComment::
            end
            ::passThrough::
        end
    end
    return translated
end

return transpiler
