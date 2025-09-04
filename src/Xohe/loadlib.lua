local loadlib = {}

loadlib = {}

-- Imports --
local Error = require("src/errors")
local Lexer = require("src/lexer")
local Functions = require("src/functions")

-- Instance Variables --
local lib_locations = {["lib"] = true, ["usr"] = true}
local lib_functions = {}

-- Building Library Functions --
function loadlib.buildfunction(func_name, func_contents)
    local lexical_data = Lexer.lex(func_contents, true)
    VARIABLES.GLOBAL[func_name] = {
        Value = Functions.getValue(func_name, lexical_data, 1).Value,
        Type = "function",
        Content = Functions.getValue(func_name, lexical_data, 1).Contents,
        Tokens = lexical_data,
        Line_Created = nil
    }
end


-- Loading Liraries --
function loadlib.loadlib(lib_location, lib_name)
    -- Instance Variables --
    local filename = lib_location.."/headers/"..lib_name..".olib"
    local defs = {}
    local file_data = {}
    local defname = ""
    local linkerfile = ""
    local asmfile = ""
    local outfile = ""
    local line_count = 0
    local to_append = false
    
    -- Checking if library location is valid
    if not lib_locations[lib_location] then
        Error.new("LIB_LOCATION", file.Line, {lib_location})
    end
    
    -- Opening library file
    local headerfile = io.open(filename,"r")
    if headerfile == nil then
         Error.new("LIB_NAME", file.Line, {lib_name})
    end
    
    local lines = headerfile:lines()
    for line in lines do
        line_count = line_count + 1
        -- Skipping commented lines
        if not line:gsub("^%s+",""):match("^#") then
        
            -- Appending function data (if to_append is true)
            if to_append then
                lib_functions[defname][#lib_functions[defname]+1] = line
            end
            
            -- Checking for '@' symbol
            if line:match("^@") then
                
                -- @linkerfile := <filename>
                if line:match("linkerfile%s+%:%=") then
                    linkerfile = line:gsub("@linkerfile%s+%:%=%s+",""):gsub("['\"]","")
                end
                
                -- @asmfile := <filename>
                if line:match("asm%.file%s+%:%=") then
                    asmfile = line:gsub("@asm%.file%s+%:%=%s+",""):gsub("['\"]","")
                end
                
                -- @outfile := <filename>
                if line:match("asm%.output%s+%:%=") then
                    outfile = line:gsub("@asm%.output%s+%:%=%s+",""):gsub("['\"]","")
                end
                
                -- @extern <name>
                if line:match("extern") then
                    external_variable = line:gsub("@extern%s+",""):gsub("['\"]","")
                    if COMPILER.FLAGS.USE_EXTERN then
                        COMPILER.APPEND_TEXT("    .extern "..external_variable)
                    end
                end
                
                -- @DEF <name>
                if line:match("@DEF%s+") then
                    to_append = true
                    defname = line:gsub("@DEF%s+","")
                    defs[#defs+1] = {Name = defname, Line = line_count}
                    if defname == "" then
                        X_Error.new("DEFINITION_NAME", line_count, {filename})
                    end
                    lib_functions[defname] = {}
                end
                
                -- @END_DEF
                if line:match("@END_DEF") then
                    -- Removing "@END_DEF" from the function table (will cause issues with lexing)
                    table.remove(lib_functions[defname], #lib_functions[defname])
                    
                    -- Resetting values
                    table.remove(defs, #defs)
                    to_append = false
                    defname = ""
                end
            end
        end
    end
    
    -- Error Checking
    if #defs > 0 then
		X_Error.new("END_DEF_NOT_FOUND", defs[#defs].Line, {filename, defs[#defs].Name})
    end
    if linkerfile == "" or not io.open(linkerfile,"r") then
        -- No precompiled file, but asm file exist
        if not io.open("lib/compiled/"..lib_name..".o") then
            if asmfile ~= "" then
                if outfile == "" then
                    X_Error.new("NO_ASM_OUTFILE", nil, {filename})
                end
                X_Error.warn("NO_LINKERFILE_LOCATION_WITH_ASM", nil, {filename, asmfile, outfile})
                os.execute("as -o "..outfile.." "..asmfile)
                linkerfile = outfile
            else
                X_Error.new("NO_LINKERFILE_LOCATION", nil, {filename})
            end
        else
            linkerfile = "lib/compiled/"..lib_name..".o"
        end
    end
    
    -- Adding linker file path to compiler
    COMPILER.LINKER_FILES[#COMPILER.LINKER_FILES+1] = linkerfile
    
    -- Processing library function data
    for name,contents in pairs(lib_functions) do
        loadlib.buildfunction(name, contents)
    end
end




return loadlib
