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
        if not tonumber(args[1]) and args[1]:match("%w+") then
            local variable = utils.varCheck(args[1])
            if not variable.Real then
                error.newError("UNKNOWN_VAR_CALL",currentFile,line,{args[1]})
            end
        end
    end
end

function expressions.FOR(string,line)
    local args, argCount = expressions.getArgs(string)
    if #argCount >= 2 then
        for increment,i in pairs(args) do
            i = i:gsub(":%w+","")
            local variable = utils.varCheck(i)
            if not tonumber(i) and not variable.Real then
                if not string:find("in") then
                    if not string:find("for%s?%(.+%?%=") then
                        print("NO EQUAL NEAR "..args[1])
                    end
                else
                    if syntax[line]:match("<.+>") then
                        local lineHold = syntax[line]:match("<.+>"):gsub("[<>]",""):gsub(","," , ")
                        for var in lineHold:gmatch("[%S+]+") do
                            if not var:match("[%==%>%<%<=%>=%!=%,]") then
                                variables.__ADDTEMPVAR(var,line)
                            end   
                        end
                        if args[2] == "in" then
                            local var = utils.varCheck(args[3])
                            if not var.Real then
                                error.newError("UNKNOWN_VAR_CALL",currentFile,line,{args[3]})
                            elseif var.Real then
                                if var.Type ~= "Any" and var.Type ~= "Array" then
                                    error.newError("FOR_KNOWN_TABLE",currentFile,line,{args[3],var.Class,var.Type})
                                elseif var.Type == "Any" and var.Value  ~= "{" then
                                    error.newError("FOR_KNOWN_TABLE",currentFile,line,{args[3],var.Class,var.Type})
                                end
                            end
                        elseif args[3] == "in" then
                            local var = utils.varCheck(args[4])
                            if not var.Real then
                                error.newError("UNKNOWN_VAR_CALL",currentFile,line,{args[4]})
                            elseif var.Real then
                                if var.Type ~= "Any" and var.Type ~= "Array" then
                                    error.newError("FOR_KNOWN_TABLE",currentFile,line,{args[3],var.Class,var.Type})
                                elseif var.Type == "Any" and var.Value  ~= "{" then
                                    error.newError("FOR_KNOWN_TABLE",currentFile,line,{args[3],var.Class,var.Type})
                                end
                            end
                        end
                    else
                        print("NO ARGS FOUND")
                        os.exit()
                    end
                end
            end 
        end
    else
        print("NOT ENOUGH ARGS")
        os.exit()
    end
end

function expressions.FUNCTION(string,line)
    local args, argCount = expressions.getArgs(string)
    for _,i in pairs(args) do
        if not i:match("%:%w+") then
            i = i..":Any"
        end
        variables.__ADDTEMPVAR(i,line)
    end
end

function expressions.parseExpression(line)
    local syntax = syntax[line]
    local expressionType = ""
    if syntax:match("%w+%s?%(") then
        expressionType = syntax:match("%w+%s?%("):chop():gsub("%s+","")
        if expressionType:lower() == "elif" then expressionType = "if" end
    end
    if expressions[expressionType:upper()] == nil and not utils.varCheck(expressionType).Real then
        return
    end
    if utils.varCheck(expressionType).Real then
        expressions[utils.varCheck(expressionType).Type:upper()](syntax,line)
    else
        expressions[expressionType:upper()](syntax,line)
    end
end

return expressions