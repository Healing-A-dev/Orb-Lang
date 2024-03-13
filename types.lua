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
        required = {"'.+'", '".+"'}
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

local function getString(line,search,typing)
    local toSearch = syntax[line]
    if search and typing == "String" then
        return toSearch:match(allowedTypes[typing].required[1]) or toSearch:match(allowedTypes[typing].required[2])
    end
end

function types.getVarType(variable)
    local varType = nil
    local assignment = nil
    local line = 0
    for _,i in pairs(fullTokens) do
        for s = 1, #i do
            if i[s][2] == variable and i[s][3] == "VARIABLE" then
                if i[s][1]:find("VARIABLE_ANY") and not i[s+1][1]:find("COLON") then
                    varType = "Any"
                    assignment = i[s-2][2]
                    line = _
                elseif i[s][1]:find("VARIABLE_ANY") and i[s+1][1]:find("COLON") then
                    varType = i[s+2][2]
                    if not i[s][1]:find("SVARIABLE") then
                        if i[s-2][1]:find("QUOTE") then assignment = getString(_,true,varType) else assignment = i[s-2][2] end
                    else
                        if i[s-3][1]:find("QUOTE") then assignment = getString(_,true,varType) else assignment = i[s-3][2] end
                    end
                    line = _
                elseif i[s+1][1]:find("COLON") and not i[s][1]:find("VARIABLE_ANY") then
                    varType = i[s+2][2]
                    if i[s+4][1]:find("QUOTE") then assignment = getString(_,true,varType) else assignment = i[s+4][2] end
                    line = _
                elseif not i[s+1][1]:find("COLON") then
                    varType = "Any"
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