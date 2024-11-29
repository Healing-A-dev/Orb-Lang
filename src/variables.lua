local variables = {}

local types = require("src/types")
local error = require("src/errors")
local utils = require("src/utils")

--Checks whether a varaible is an array
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

--Adds varaibles
function __ADDVARS(line)
    for _,i in pairs(fullTokens[line]) do
        if #i > 0 then
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
                if i[1]:find("FUNC") and not utils.varCheck(i[2]).Real then
                    Variables.Global[var] = {Type = "Function", Value = var, Args = {}, Return_Type = types.getFunctionType(var,line)}
                elseif not i[1]:find("FUNC") and Variables.Static[var] == nil then
                    Variables.Global[var] = {Type = types.getVarType(var).Type, Value = types.getVarType(var).Value}
                end
            elseif i[1]:find("SVARIABLE") and not i[1]:find("ANY") or i[1]:find("SFUNC_NAME") and not i[1]:find("EXT") then
                local var = i[2]
                if i[1]:find("SFUNC") and not utils.varCheck(i[2]).Real then
                    Variables.Static[var] = {Type = "Function", Value = var, Args = {}, Return_Type = types.getFunctionType(var,line)}
                else
                    Variables.Static[var] = {Type = types.getVarType(var).Type, Value = types.getVarType(var).Value}
                end
            end
        end
    end
end

--Adds temporary variables
function variables.__ADDTEMPVAR(vname,line)
    local variable = types.checkType(vname,line)
    Variables.Temporary[variable.Name] = {Type = variable.Type, Value = "TBD", Creation = line}
end

--Updates the value of the specififed temporary variable
function variables.__UPDATETEMPVAR(variableName,value,line)
    if Variables.Temporary[variableName] ~= nil then
        Variables.Temporary[variableName].Value = value
        types.checkValue(variableName,value,line)
    end
end

--Utility functions for orb variables
function asString(value)
    return tostring(value)
end

function asNumber(value)
    if not value:find("%w") then
        return tonumber(value)
    else
        print("NOT A NUMBER DUMMY")
        os.exit()
    end
end

function asArray(value)
    return string.split(value)
end

return variables
