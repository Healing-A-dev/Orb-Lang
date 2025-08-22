local cli_file_builder = {}

local line_storage = {}
local file_name = "src/Xohe/"

-- Add Data To Stored Lines --
function cli_file_builder.APPEND_TEMP(data)
    line_storage[#line_storage + 1] = data
end

-- Reset Stored Lines --
function cli_file_builder.CLEAR()
    line_storage = {}
end

-- Compile Stored Data --
function cli_file_builder.PushToXohe(new_file_name)
    -- Loading required imports
    local Lexer  = require("src/lexer")
    local Parser = require("src/parser")

    -- Compiling data
    if new_file_name ~= nil then
        -- Compiling a file
        arg[1] = new_file_name
        A = call(XOHE:GatherCompilerArguemnts())
        X = call(XOHE:Generate())
        L = call(Lexer.lex(arg[1]))
        P = call(Parser.parse(Lexer.tokens))
        C = call(Compile())
    else
        -- Gathering data
        local lines  = table.concat(line_storage, "\n")
        local file   = assert(io.open(file_name, "a+"), "")
        file:write(lines)
        file:close()
        arg[1] = file_name

        A = call(XOHE:GatherCompilerArguemnts())
        X = call(XOHE:Generate())
        L = call(Lexer.lex(arg[1]))
        P = call(Parser.parse(Lexer.tokens))
        C = call(Compile())

        -- Clearing the storage table
        if line_storage[#line_storage]:gsub("^%s+",""):find("^puts%(.?%)") then
            table.remove(line_storage, #line_storage)
        end

        -- Clearing file
        file = io.open(file_name, "w+")
        file:close()
    end
end

function cli_file_builder.New(new_file_name)
    -- Creating File Name
    if new_file_name == nil then
        file_name = file_name .. "out.intr"
    else
        file_name = file_name .. new_file_name
    end

    local file = io.open(file_name, "w+")
    file:close()
    return file_name
end

return cli_file_builder
