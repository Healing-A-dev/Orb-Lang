local def = {}

function def.storeDef(def,...)
    local args = ...
    return {def,args[1]}
end


return def