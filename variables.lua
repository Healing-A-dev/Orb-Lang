local variables = {}

local types = require("types")
function __ADDVARS()
    for _,i in pairs(fullTokens) do
        for s = 1, #i do
            if i[s][1]:find("GVARIABLE") or i[s][1]:find("FUNC_NAME") and not i[s][1]:find("SFUNC") and not i[s][1]:find("EXT") then
                local var = i[s][2]
                if i[s][1]:find("FUNC") then
                    Variables.Global[var] = "Function"
                elseif not i[s][1]:find("ANY") then
                    Variables.Global[var] = types.getVarType(var)
                else
                    Variables.Global[var] = "Any"
                end
            elseif i[s][1]:find("SVARIABLE") or i[s][1]:find("SFUNC_NAME") and not i[s][1]:find("EXT") then
                local var = i[s][2]
                if i[s][1]:find("SFUNC") then
                    Variables.Static[#Variables.Static+1] = {var, "Function"}
                else
                    Variables.Static[#Variables.Static+1] = {var, types.getVarType(var)}
                end
            end
        end
    end
end

return variables


--[[
]]