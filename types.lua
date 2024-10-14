local types = {}

local error = require("errors")
local utils = require("utils")

local allowedTypes = {
    Number = {
        required = "%d+" -- Doesn't get used btw, I'm using the tonumber function instead, because it does what I need it to do
    },
    Char = {
        required = {"'.'", '"."', 1}
    },
    String = {
        required = {"'.+'", '".+"'}
    },
    Array = {
        required = "^%{"
    },
    Bool = {
        required = {"true", "false"}
    },
    Any = {
        required = "."
    },
    Function = {
        required = "func"
    },
}

function getAllowedTypes()
    return allowedTypes
end

local function getValue(line,option)
    local toSearch = syntax[line]
    local hold = {}
    --if option ~= "Array" then
        return toSearch:match("%=.+"):chop({#toSearch:match("%=.+")}):gsub("=","")
    --else

    --end
end

function types.getVarType(variable,Type)
    local varType = nil
    local assignment = nil
    local line = 0
    for _,i in pairs(fullTokens) do
        for s = 1, #i do
            if not i[s][1]:match("SPACE") then
                if i[s][2] == variable and i[s][3] == "VARIABLE" then
                    if i[s][1]:find("ANY") and Type ~= nil then
                        varType = Type
                        if i[s-2][1]:find("QUOTE") and varType == "String" or i[s-2][1]:find("QUOTE") and varType == "Char" then
                            assignment = getValue(_)
                        else
                            if i[s-3] == nil then
                                assignment = getValue(_,varType)
                            else
                                assignment = getValue(_,varType)
                            end
                        end
                        line = _
                    elseif not i[s][1]:find("ANY") and i[s+1][1]:find("COLON") then
                        varType = i[s+2][2]
                        if i[s+4][1]:find("QUOTE") and varType == "String" or i[s+4][1]:find("QUOTE") and varType == "Char" or i[s+4][1]:find("QUOTE") and varType == "Any" then
                            assignment = getValue(_)
                        else
                            assignment = getValue(_,varType)
                        end
                        line = _
                    elseif not i[s][1]:find("ANY") and i[s+2][1]:find("COLON") then
                        varType = i[s+3][2]
                        if i[s+5][1]:find("QUOTE") and varType == "String" or i[s+5][1]:find("QUOTE") and varType == "Char" or i[s+5][1]:find("QUOTE") and varType == "Any" then
                            assignment = getValue(_)
                        else
                            assignment = getValue(_,varType)
                        end
                        line = _
                    elseif not i[s][1]:find("ANY") and not i[s+1][1]:find("COLON") then
                        varType = "Any"
                        if not i[s][1]:find("SVARIABLE") then
                            if i[s+3][1]:find("QUOTE") then 
                                assignment = getValue(_) 
                            else 
                                assignment = getValue(_,varType)
                            end
                        else
                            if i[s+4][1]:find("QUOTE") then 
                                assignment = getValue(_) 
                            else 
                                assignment = getValue(_,varType)
                            end
                        end
                        line = _
                    end
                end
            end
        end
    end
    assignmentSUB = assignment:gsub("%s+","")
    if allowedTypes[varType] == nil then
        error.newError("UNKNOWN_TYPE",currentFile,line,{variable,varType})
    elseif type(allowedTypes[varType].required) ~= "table" and assignment ~= nil then
        local varChecks = utils.varCheck(assignmentSUB)
        if varType ~= "Number" then
            assignment = assignment:gsub("^%s+","")
            if not assignment:match(allowedTypes[varType].required) and not varChecks.Real then
                error.newError("ASSIGNMENT",currentFile,line,{variable,varType})
            elseif not assignment:match(allowedTypes[varType].required) and varChecks.Real then
                if varChecks.Type ~= varType then
                    error.newError("ASSIGNMENT",currentFile,line,{variable,varType,"'"..assignment.."'"," |varType: "..varChecks.Type.."| "})
                end
                return {Type = varType, Value = varChecks.Value:gsub("%s+","")}
            else
                return {Type = varType, Value = assignment}
            end
        else
            if not tonumber(assignmentSUB) and not varChecks.Real and assignmentSUB:find("[%+%-%/%*%^]") then
                for _,i in pairs(assignmentSUB:index()) do
                    if not tonumber(i) then
                        i = i:gsub("[%(%)]","")
                        if not tonumber(i) then
                            if not utils.varCheck(i).Real then
                                error.newError("UNKNOWN_VAR_CALL",currentFile,line,{i})
                            end
                            if utils.varCheck(i).Type ~= "Number" then
                                error.newError("ARITHMETIC_NON_NUMBER",currentFile,line,{utils.varCheck(i).Type,i})
                            end
                            assignmentSUB = assignmentSUB:replace(i,utils.varCheck(i).Value)
                        end
                    end
                end
                return {Type = varType, Value = load("return "..assignmentSUB)()}
            elseif not tonumber(assignmentSUB) and varChecks.Real then
                if varChecks.Type ~= varType then
                    error.newError("ASSIGNMENT",currentFile,line,{variable,varType,"'"..assignment.."'"," |varType: "..varChecks.Type.."| "})
                end
                return {Type = varType, Value = varChecks.Value}
            elseif not tonumber(assignmentSUB) and not varChecks.Real then
                error.newError("ASSIGNMENT",currentFile,line,{variable,varType})
            else
                return {Type = varType, Value = assignment}
            end
        end
    elseif type(allowedTypes[varType].required) == "table" and assignment ~= nil then
        local varChecks = utils.varCheck(assignmentSUB)
        for _,i in pairs(allowedTypes[varType]) do
            if type(i[2]) ~= "Number" then
                if not assignment:match(i[1]) and not assignment:match(i[2]) and not varChecks.Real then
                    error.newError("ASSIGNMENT",currentFile,line,{variable,varType})
                elseif not assignment:match(i[1]) and not assignment:match(i[2]) and varChecks.Real then
                    if varChecks.Type ~= varType then
                        error.newError("ASSIGNMENT",currentFile,line,{variable,varType,"'"..assignment.."'"," |varType: "..varChecks.Type.."| "})
                    end
                end
            else
                if assignment:match(i[1]) and assignmentSUB:len() > i[3] or not assignment:match(i[1]) or assignment:match("%d+") then
                    error.newError("ASSIGNMENT",currentFile,line,{variable,varType})
                end
            end
        end
        return {Type = varType, Value = assignment}
    end
end

function types.checkType(variable,line)
    local varType = variable:match(":%w+"):gsub("%:","")
    local varName = variable:match(".+:"):gsub("%:","")
    for _,i in pairs(allowedTypes) do
        if varType == _ then
            return {Type = varType, Name = varName}
        end
    end
    error.newError("UNKNOWN_TYPE",currentFile,line,{varName,varType})
end 


return types
