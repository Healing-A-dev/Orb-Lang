local types = {}

local error = require("errors")

local allowedTypes = {
    Number = {
        required = "%d+"
    },
    Char = {
        required = {"%w",1}
    },
    String = {
        required = "%w+"
    },
    Array = {
        required = "%{"
    },
    Bool = {
        required = {"true","false"}
    },
    Any = {
        required = "."
    }
}

function types.getVarType(variable)
    local varType = nil
    local assignment = nil
    local line = 0
    for _,i in pairs(fullTokens) do
        for s = 1, #i do
            if i[s][2] == variable and i[s][3] == "VARIABLE" then
                if not i[s+1][1]:find("COLON") then
                    local var = i[s][2]
                    error.newError("UNDEFINED_VAR",currentFile,_,{var})
                else
                    varType = i[s+2][2]
                    if i[s+4][1]:find("QUOTE") then assignment = i[s+5][2] else assignment = i[s+4][2] end
                    line = _
                end
            end
        end
    end
    if allowedTypes[varType] == nil then
        error.newError("UNKNOWN_TYPE",currentFile,line,{variable,varType})
    end
    if type(allowedTypes[varType].required) ~= "table" then
        if not assignment:match(allowedTypes[varType].required) then
            error.newError("ASSIGNMENT",currentFile,line,{variable,varType})
        else
            return varType
        end
    elseif type(allowedTypes[varType].required) == "table" then
        for _,i in pairs(allowedTypes[varType]) do
            if type(i[2]) ~= "number" then
                if not assignment:match(i[1]) and not assignment:match(i[2]) then
                    error.newError("ASSIGNMENT",currentFile,line,{variable,varType}) 
                end
            else
                if assignment:match(i[1]) and assignment:len() > i[2] or not assignment:match(i[1]) or assignment:match("%d+") then
                    error.newError("ASSIGNMENT",currentFile,line,{variable,varType})
                end
            end
        end
        return varType
    end
end


return types