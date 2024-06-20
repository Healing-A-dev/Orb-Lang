-- An expression and expression error handler 
local expressions = {}

--[[Imports]]
local utils = require("utils")
local error = require("errors")
local types = require("types")
local Tokens = require("Tokens")
local lexer = require("src/lexer")
local variables = require("variables")


function expressions.getArgs(string)
    local args = {}
    local argCount = {}
    local compareType = nil
    local matchedArgs = string:match("%(.+%):{"):gsub(":{",""):chop({1,#string:match("%(.+%):{"):gsub(":{","")-1}):gsub(","," , ")
    for arg in matchedArgs:gsub("[<>]",""):gmatch("[%S+]+") do
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
                            --error.newError("COMPARISON",currentFile,line,{compareType,"unknown variable '"..t.."'",args[1],args[2],"'"..tostring(init).."'"})
                            error.newError("UNKNOWN_VAR_CALL",currentFile,line,{t})
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
                            --error.newError("COMPARISON",currentFile,line,{compareType,"unknown variable '"..t.."'",args[1],args[2],"'"..tostring(init).."'"})
                            error.newError("UNKNOWN_VAR_CALL",currentFile,line,{t})
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
                        --error.newError("COMPARISON",currentFile,line,{compareType,"unknown variable '"..t.."'",args[1],args[2],"'"..tostring(init):gsub("[%\"%']","").."'"})
                        error.newError("UNKNOWN_VAR_CALL",currentFile,line,{t})
                    elseif variable.Real and variable.Type ~= "String" then
                        if variable.Type == "Any" and not variable.Value:match("[%\"%.+%\']") and not variable.Value:match("[%'%.+%']") or variable.Type ~= "Any" then
                            error.newError("COMPARISON",currentFile,line,{compareType,variable.Class.." variable '"..t.."' |varType: "..variable.Type.."|",args[1],args[2],"'"..tostring(init):gsub("[%\"%']","").."'"})
                        end
                    end
                end
            end 
        end
    else
        print("OOGIE BOOGIE")
        os.exit() 
    end
end

function expressions.FOR(string,line)
    local args, argCount = expressions.getArgs(string)
    if #argCount > 1 then
        for increment,i in pairs(args) do
            i = i:gsub(":%w+","")
            local variable = utils.varCheck(i)
           --[[if not tonumber(i) and not variable.Real and string:find("%=") then
                if increment == 1 then
                    variables.__ADDTEMPVAR(i)
                elseif increment > 1 then
                    error.newError("ARGUMENT",currentFile,line,{i})
                end
            elseif not tonumber(i) and variable.Real and variable.Type ~= "Number" and string:find("%=") then
                error.newError("FOR_KNOWN",currentFile,line,{i,variable.Class,variable.Type})
            end]]
            if not tonumber(i) and not variable.Real then
                if string:find("%=") then

                else
                    if syntax[line]:match("<.+>") then
                        local lineHold = syntax[line]:match("<.+>"):gsub("[<>]",""):gsub(","," , ")
                        for var in lineHold:gmatch("[%S+]+") do
                            if not var:match("[%==%>%<%<=%>=%!=%,]") then
                                variables.__ADDTEMPVAR(var,line)
                            end   
                        end
                        if args[3] == "in" then
                            local var = utils.varCheck(args[4])
                            if not var.Real then
                                error.newError("UNKNOWN_VAR_CALL",currentFile,line,{args[4]})
                            elseif var.Real and var.Type ~= "Array" then
                                error.newError("FOR_KNOWN_TABLE",currentFile,line,{args[4],var.Class,var.Type})
                            end
                        end
                    end
                end
            end 
        end
    end
end

function expressions.parseExpression(line)
    local syntax = syntax[line]
    local expressionType = ""
    if syntax:match("%w+%s?%(") then
        expressionType = syntax:match("%w+%s?%("):chop():gsub("%s+",""):upper()
    end
    if not expressionType:find("IF") and not expressionType:find("FOR") then
        return
    end
    expressions[expressionType](syntax,line)
end

return expressions