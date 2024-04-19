-- An expression and expression error handler 
local expressions = {}

--[[Imports]]
local utils = require("utils")
local error = require("errors")
local types = require("types")
local Tokens = require("Tokens")
local lexer = require("lexer")

--[[Expression Types]]
function expressions.IF(string,line)
    local args = {}
    local argCount = {}
    local compareType = nil
    local matchedArgs = string:match("%(.+%):{"):gsub(":{",""):chop({1,#string:match("%(.+%):{"):gsub(":{","")-1})
    for arg in matchedArgs:gmatch("[%S+]+") do
        argCount[#argCount+1] = #argCount+1
        args[#args+1] = arg
    end
    if #argCount > 1 then
        for _,i in pairs(args) do
            if tonumber(i) then
                for s,t in pairs(args) do
                    if not tonumber(t) and t:match("%w+") then
                        local variable = utils.varCheck(t)
                        if not variable.Real then
                            error.newError("COMPARISON",currentFile,line)
                        elseif variable.Real and variable.Type ~= "Number" then
                            error.newError("COMPARISON",currentFile,line)
                        end 
                    end
                end
            elseif i == (true or false) then
                compareType = "bools"
            else
                compareType = "strings"
            end 
        end
        
    end
end

function expressions.parseExpression(line)
    local syntax = syntax[line]
    local expressionType = syntax:match("%w+.?%("):chop():gsub("%s+",""):upper()
    expressions[expressionType](syntax,line)
end

return expressions