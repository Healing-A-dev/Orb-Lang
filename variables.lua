local variables = {}

local types = require("types")
local error = require("errors")

function variables.checkVar(var)
    if var[1]:find("SVARIABLE") then
        if Variables.Static[var[2]] == "Array" then return true else return false end
    else
        if Variables.Global[var[2]] == "Array" then return true else return false end
    end
end

function __ADDVARS()
    for _,i in pairs(fullTokens) do
        for s = 1, #i do
            if i[s][1]:find("VARIABLE_ANY") then
                local typing = ""
                if Variables.Global[i[s][2]] ~= nil then
                    Variables.Global[i[s][2]] = types.getVarType(i[s][2], Variables.Global[i[s][2]])
                elseif Variables.Static[i[s][2]] ~= nil then
                    Variables.Static[i[s][2]] = types.getVarType(i[s][2], Variables.Static[i[s][2]])
                else
                    error.newError("UNKNOWN_VAR",currentFile,_,{i[s][2]})
                end
            end
            if i[s][1]:find("GVARIABLE") and not i[s][1]:find("ANY") or i[s][1]:find("FUNC_NAME") and not i[s][1]:find("SFUNC") and not i[s][1]:find("EXT") then
                local var = i[s][2]
                if i[s][1]:find("FUNC") then
                    Variables.Global[var] = "Function"
                elseif not i[s][1]:find("FUNC") and Variables.Static[var] == nil then
                    Variables.Global[var] = types.getVarType(var)
                end
            elseif i[s][1]:find("SVARIABLE") and not i[s][1]:find("ANY") or i[s][1]:find("SFUNC_NAME") and not i[s][1]:find("EXT") then
                local var = i[s][2]
                if i[s][1]:find("SFUNC") then
                    Variables.Static[var] = "Function"
                else
                    Variables.Static[var] = types.getVarType(var)
                end
            end
        end
    end
end

return variables