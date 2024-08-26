local transpiler = {}
local Tokens = require("Tokens")

local function autofill(t,value)
    for _,i in pairs(t) do
        if _:lower():find(value:lower()) then
            return _
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
                        activeImports = true
                        goto passThrough
                    end
                end
            end
            if activeImports and #i:gsub("%s+","") == 1 and i:match("%}") then
                activeImports = false
                goto passThrough
            elseif activeImports then
                goto passThrough
            end
            
            for s,t in pairs(fullTokens[_]) do
                if t[3] == "STATEMENT" then
                    Statements[#Statements+1] = {autofill(Statements,t[2]), true}
                end
                if #Statements > 0 and t[1] == Tokens.OTOKEN_KEY_EOL() then
                    table.remove(Statements,#Statements)
                    t[2] = "end"
                end
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
                elseif t[2] == Tokens.OTOKEN_KEYWORD_FUNCTION():lower() then
                    t[2] = "function "
                elseif t[2] == Tokens.OTOKEN_KEYWORD_SET():lower() then
                    t[2] = nil
                elseif t[2] == Tokens.OTOKEN_KEYWORD_STATIC():lower() then
                    t[2] = "static"
                elseif t[2] == Tokens.OTOKEN_TYPE_COLON() and not t[1]:find("STRING") then
                    if fullTokens[_][s+1][2] == "Number" or fullTokens[_][s+1][2] == "String" or fullTokens[_][s+1][2] == "Array" or fullTokens[_][s+1][2] == "Any" or fullTokens[_][s+1][2] == "Char" or fullTokens[_][s+1][2] == "Bool" then
                        t[2] = nil
                        fullTokens[_][s+1][2] = nil
                    end
                end
                translated[_][#translated[_]+1] = t[2]
            end
            ::passThrough::
        end
    end
    return translated
end

return transpiler
