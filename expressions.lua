-- An expression and expression error handler 
local expressions = {}

--[[Imports]]
local utils = require("utils")
local error = require("errors")
local types = require("types")
local Tokens = require("Tokens")
local lexer = require("lexer")


function expressions.getArgs(string)
    local args = {}
    local argCount = {}
    local compareType = nil
    local matchedArgs = string:match("%(.+%):{"):gsub(":{",""):chop({1,#string:match("%(.+%):{"):gsub(":{","")-1})
    for arg in matchedArgs:gmatch("[%S+]+") do
        if not arg:match("[%==%>%<%<=%>=%!=%,]") then
            argCount[#argCount+1] = #argCount+1
            args[#args+1] = arg
        end
    end
    return args,argCount
end

--[[Expression Types]]
function expressions.IF(string,line)
    local compareType = nil
    local args,argCount = expressions.getArgs(string)
    if #argCount > 1 then
        for _,i in pairs(args) do
            if tonumber(i) or tonumber(utils.varCheck(i).Value)then
                compareType = "number"
                local init = i
                for s,t in pairs(args) do
                    if not tonumber(t) and t:match("%w+") then
                        local variable = utils.varCheck(t)
                        if not variable.Real and not t:find('[%"%\']') then
                            error.newError("COMPARISON",currentFile,line,{compareType,"unknown variable '"..t.."'",args[1],args[2],"'"..tostring(init).."'"})
                        elseif not variable.Real and t:find('[%"%\']') then
                            error.newError("COMPARISON",currentFile,line,{compareType,type(t):lower().." "..t,args[1],args[2],"'"..tostring(init).."'"})
                        elseif variable.Real and variable.Type ~= "Number" then
                            if variable.Type == "Any" and not tonumber(variable.Value) or variable.Type ~= "Any" then
                                error.newError("COMPARISON",currentFile,line,{compareType,variable.Class.." variable '"..t.."' |varType: "..variable.Type.."|",args[1],args[2],"'"..tostring(init).."'"})
                            end
                        end 
                    end
                end
            elseif i == ("true" or "false") then
                compareType = "boolean"
                local init = i
                for s,t in pairs(args) do
                    if t ~= "true" and t ~= "false" then
                        local variable = utils.varCheck(t)
                        if not variable.Real and t ~= "true" and t ~= "false" then
                            error.newError("COMPARISON",currentFile,line,{compareType,"unknown variable '"..t.."'",args[1],args[2],"'"..tostring(init).."'"})
                        elseif variable.Real and variable.Type ~= "Bool" then
                            if variable.Type == "Any" and variable.Value ~= ("true" or "false") or variable.Type ~= "Any" then
                                error.newError("COMPARISON",currentFile,line,{compareType,variable.Class.." variable '"..t.."' |varType: "..variable.Type.."|",args[1],args[2],"'"..tostring(init).."'"})
                            end
                        end
                    end
                end
            elseif i:match("[%\"%.+%\"]") or i:match("[%'%.+%']") then
                compareType = "string"
                local init = i
                for s,t in pairs(args) do
                    local variable = utils.varCheck(t)
                    if not variable.Real and not t:match("[%'%.+%']") and not t:match("[%\"%.+%\"]") then
                        if t:match("%{") then
                            error.newError("COMPARISON",currentFile,line,{compareType,"array",args[1],args[2],"'"..tostring(init):gsub("[%\"%']","").."'"})
                        elseif tonumber(t) then
                            error.newError("COMPARISON",currentFile,line,{compareType,"number",args[1],args[2],"'"..tostring(init):gsub("[%\"%']","").."'"})
                        end
                        error.newError("COMPARISON",currentFile,line,{compareType,"unknown variable '"..t.."'",args[1],args[2],"'"..tostring(init):gsub("[%\"%']","").."'"})
                    elseif variable.Real and variable.Type ~= "String" then
                        if variable.Type == "Any" and not variable.Value:match("[%\"%.+%\']") and not variable.Value:match("[%'%.+%']") or variable.Type ~= "Any" then
                            error.newError("COMPARISON",currentFile,line,{compareType,variable.Class.." variable '"..t.."' |varType: "..variable.Type.."|",args[1],args[2],"'"..tostring(init):gsub("[%\"%']","").."'"})
                        end
                    end
                end
            end 
        end
        
    end
end

function expressions.FOR(string,line)

end

function expressions.parseExpression(line)
    local syntax = syntax[line]
    local expressionType = syntax:match("%w+%s?%("):chop():gsub("%s+",""):upper()
    if expressionType == "IF" then
        expressions[expressionType](syntax,line)
    end
end

return expressions