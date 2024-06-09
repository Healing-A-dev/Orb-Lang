local variables = {}

local types = require("types")
local error = require("errors")

function variables.isArray(var)
    if var[1]:find("SVARIABLE") then
        if Variables.Static[var[2]].Type == "Array" then 
            return true 
        else 
            return false 
        end
    else
        if Variables.Global[var[2]].Type == "Array" then 
            return true 
        else
            return false 
        end
    end
end

function __ADDVARS(line)
    for _,i in pairs(fullTokens[line]) do
        if i[1]:find("VARIABLE_ANY") then
            local typing = ""
            if Variables.Global[i[2]] ~= nil then
                types.getVarType(i[2], Variables.Global[i[2]])
            elseif Variables.Static[i[2]] ~= nil then
                types.getVarType(i[2], Variables.Static[i[2]])
            else
                error.newError("UNKNOWN_VAR",currentFile,_,{i[2]})
            end
        end
        if i[1]:find("GVARIABLE") and not i[1]:find("ANY") or i[1]:find("FUNC_NAME") and not i[1]:find("SFUNC") and not i[1]:find("EXT") then
            local var = i[2]
            if i[1]:find("FUNC") then
                Variables.Global[var] = {Type = "Function", Value = var}
            elseif not i[1]:find("FUNC") and Variables.Static[var] == nil then
                Variables.Global[var] = {Type = types.getVarType(var).Type, Value = types.getVarType(var).Value}
            end
        elseif i[1]:find("SVARIABLE") and not i[1]:find("ANY") or i[1]:find("SFUNC_NAME") and not i[1]:find("EXT") then
            local var = i[2]
            if i[1]:find("SFUNC") then
                Variables.Static[var] = {Type = "Function", Value = var}
            else
                Variables.Static[var] = {Type = types.getVarType(var).Type, Value = types.getVarType(var).Value}
            end
        end
    end
end

function variables.__ADDTEMPVAR(vname)
    Variables.Temporary[vname] = {Type = "Number", Value = "TBD"}
end

return variables