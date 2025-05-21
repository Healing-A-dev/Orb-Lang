local modules = {}

-- Imports --
local Error     = require("src/errors")
local Variable = require("src/variables")

-- Instance Variables --
modules = {}


-- New Modules --
function modules.new(tokens, add, token_table)
    VARIABLES.STATIC["test"] = {Type = "module", Value = "module", Contents = tokens}
end


return modules
