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
        required = "%{"
    },
    Bool = {
        required = {"true", "false"}
    },
    Any = {
        required = "."
    }
}

local function getValue(line)
    local toSearch = syntax[line]
    return toSearch:match(allowedTypes["String"].required[1]) or toSearch:match(allowedTypes["String"].required[2])
end

function types.getVarType(variable,Type)
    local varType = nil
    local assignment = nil
    local line = 0
    for _,i in pairs(fullTokens) do
        for s = 1, #i do
            if i[s][2] == variable and i[s][3] == "VARIABLE" then
                if i[s][1]:find("ANY") and Type ~= nil then
                    varType = Type
                    if i[s-2][1]:find("QUOTE") and varType == "String" or i[s-2][1]:find("QUOTE") and varType == "Char" then
                        assignment = getValue(_)
                    else
                        if i[s-3] == nil then
                            assignment = i[s-2][2]
                        else
                            assignment = i[s-3][2]
                        end
                    end
                    line = _
                elseif not i[s][1]:find("ANY") and i[s+1][1]:find("COLON") then
                    varType = i[s+2][2]
                    if i[s+4][1]:find("QUOTE") and varType == "String" or i[s+4][1]:find("QUOTE") and varType == "Char" then
                        assignment = getValue(_)
                    else
                        assignment = i[s+4][2]
                    end
                    line = _
                elseif not i[s][1]:find("ANY") and not i[s+1][1]:find("COLON") then
                    varType = "Any"
                    if i[s+4][1]:find("QUOTE") and varType == "String" or i[s+4][1]:find("QUOTE") and varType == "Char" then 
                        assignment = getValue(_) 
                    else 
                        assignment = i[s+4][2]
                    end
                    line = _
                end
            end
        end
    end
    if allowedTypes[varType] == nil then
        error.newError("UNKNOWN_TYPE",currentFile,line,{variable,varType})
    elseif type(allowedTypes[varType].required) ~= "table" and assignment ~= nil then
        local varChecks = utils.varCheck(assignment)
        if varType ~= "Number" then
            if not assignment:match(allowedTypes[varType].required) and not varChecks.Real then
                error.newError("ASSIGNMENT",currentFile,line,{variable,varType})
            elseif not assignment:match(allowedTypes[varType].required) and varChecks.Real then
                if varChecks.Type ~= varType then
                    error.newError("ASSIGNMENT",currentFile,line,{variable,varType,"'"..assignment.."'"," |varType: "..varChecks.Type.."| "})
                end
            else
                return varType
            end
        else
            if not tonumber(assignment) and not varChecks.Real then
                error.newError("ASSIGNMENT",currentFile,line,{variable,varType})
            elseif not tonumber(assignment) and varChecks.Real then
                if varChecks.Type ~= varType then
                    error.newError("ASSIGNMENT",currentFile,line,{variable,varType,"'"..assignment.."'"," |varType: "..varChecks.Type.."| "})
                end
            else
                return varType
            end
        end
    elseif type(allowedTypes[varType].required) == "table" and assignment ~= nil then
        local varChecks = utils.varCheck(assignment)
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
                if assignment:match(i[1]) and assignment:len() > i[3] or not assignment:match(i[1]) or assignment:match("%d+") then
                    error.newError("ASSIGNMENT",currentFile,line,{variable,varType})
                end
            end
        end
        return varType
    end
end


return types