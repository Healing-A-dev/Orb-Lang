local def = {}

--Defs are quite literally just classes... but with a lua implementation

function def.storeDef(def,...)
    local args = ...
    return {def,args[1]}
end


return def


--[[
]]