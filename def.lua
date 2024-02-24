local def = {}

function def.storeDef(def,...)
    local args = ...
    return {def,args[1]}
end


return def


--[[
    for s = 1, #i do
      if i[s][1]:find("GVARIABLE") then
        local var = i[s][2]
        if not i[s][1]:find("ANY") then
          Variables.Global[var] = types.getVarType(var)
        else
          Variables.Global[var] = "Any"
        end
      elseif i[s][1]:find("SVARIABLE") then
        local var = i[s][2]
        Variables.Static[#Variables.Static+1] = {var, types.getVarType(var)}
      end
    end
]]