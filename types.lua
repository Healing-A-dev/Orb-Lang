local types = {}

local allowedTypes = {
    Int = {
        required = "%d+"
    },
    Char = {
        required = "%w"
    },
    String = {
        required = {"'%w+'",'"%w+"'}
    },
    Array = {
        required = "%{"
    },
    Bool = {
        required = {"true","false"}
    },
    Any = {
        required = "none"
    }
}

function types.getVarType(variable)

end


return types