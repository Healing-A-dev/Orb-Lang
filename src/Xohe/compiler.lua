local compiler = {}

-- Imports --
local Error = require("src/errors")
local Lexer = require("src/lexer")

-- Compiler Table --
COMPILER = {
    CREATED_FILES = {
        'src/Xohe/out.s',
        'src/Xohe/out.o',
    },
    LINKER_FILES = {},
    FLAGS = {
        OUTFILE = nil,
        EXECUTE = true,
        ASM = false,
        OBJ = false,
        VMTF = false,
        WARN = false,
        WARNALL = false,
        VERBOSE = false,
        DEBUG = false,
        PROG_EXIT = false,
        SILENT = false,
        USE_EXTERN = false
    },
    VARIABLES = 0
}


-- ASM Headers --
ASM = {
    HEADER = [[
    .section .bss
read_buffer:
    .skip 128

    ]],
    DATA = [[
.section .data
int_buffer:
    .fill 32, 1, 0

]],
    TEXT = [[
    .section .text
_start:
]]
}

local ASM2 = ASM
-- Variable Data Collection --
function gatherVariableData()
    local V = VARIABLES

    -- Global variables
    for _, variable in pairs(V.GLOBAL) do
        if variable.Type == "string" or variable.Type == "null" then
            local variable_value = variable.Value

            -- Constructing and adding the variable to the program
            ASM.DATA = ASM.DATA .. tostring(_) .. ":\n"
            ASM.DATA = ASM.DATA .. "    .ascii " .. variable_value .. "\n"
            ASM.DATA = ASM.DATA .. "    .byte 0\n"
            ASM.DATA = ASM.DATA .. "L_" .. tostring(_) .. " = . - " .. tostring(_) .. "\n\n"
        elseif variable.Type == "number" then
            local variable_value = variable.Value

            -- Constructing and adding the variable to the program
            ASM.DATA = ASM.DATA .. tostring(_) .. ":\n"
            ASM.DATA = ASM.DATA .. "    .quad " .. variable_value .. "\n\n"
        end
    end

    -- Static variables
    for _, variable in pairs(V.STATIC) do
        if variable.Type == "string" then
            local variable_value = variable.Value

            -- Constructing and adding the variable to the program
            ASM.DATA = ASM.DATA .. tostring(_) .. ":\n"
            ASM.DATA = ASM.DATA .. "    .ascii " .. variable_value .. "\n"
            ASM.DATA = ASM.DATA .. "    .byte 0\n"
            ASM.DATA = ASM.DATA .. "L_" .. tostring(_) .. " = . - " .. tostring(_) .. "\n\n"
        elseif variable.Type == "number" then
            local variable_value = variable.Value

            -- Constructing and adding the variable to the program
            ASM.DATA = ASM.DATA .. tostring(_) .. ":\n"
            ASM.DATA = ASM.DATA .. "    .quad " .. variable_value .. "\n\n"
        end
    end
end

-- Utility Function(s) --
function COMPILER.APPEND_TEXT(data)
    data = data or ""
    ASM.TEXT = ASM.TEXT .. data .. "\n"
end

function COMPILER.APPEND_DATA(data)
    data = data or ""
    ASM.DATA = ASM.DATA .. data .. "\n"
end

function COMPILER.APPEND_BSS(data)
    data = data or ""
    ASM.BSS = ASM.BSS .. data .. "\n"
end

function COMPILER.APPEND_HEADER(data)
    data = data or ""
    ASM.HEADER = ASM.HEADER .. data .. "\n"
end

-- Program Compilation --
function Compile()
    gatherVariableData()
    local file = io.open(COMPILER.CREATED_FILES[1], "w+")

    -- Macros and variable data
    file:write(ASM.HEADER)
    file:write(ASM.DATA)

    -- Porgram --
    file:write(ASM.TEXT)
    file:write("    mov $" .. _EXITCODE .. ", %rdi\n")
    file:write("    mov $60, %rax\n")
	file:write("    syscall\n")
    file:close()

    -- Executing file
    if not COMPILER.FLAGS.EXECUTE then
        if COMPILER.FLAGS.OUTFILE == nil then
            local filename = arg[1]
            if filename:find("%/") then
                filename = arg[1]:match("%/%S+$")
            end
            COMPILER.FLAGS.OUTFILE = filename:match("%S+%."):gsub("[%/%.]", "")
        end

        -- Assembly --
        if COMPILER.FLAGS.ASM then
            if not COMPILER.FLAGS.OUTFILE:find("%.%S+$") then
                COMPILER.FLAGS.OUTFILE = COMPILER.FLAGS.OUTFILE .. ".s"
            end
            local file = io.open(COMPILER.FLAGS.OUTFILE, "w+")
            file:write(ASM.HEADER)
            file:write(ASM.DATA)
            -- Program --
            file:write(ASM.TEXT)
            if not COMPILER.FLAGS.PROG_EXIT then
                file:write("    mov $0, %rdi\n")
                file:write("    mov $60, %rax\n")
                file:write("    syscall\n")
            end
            file:close()

        -- Object File --
        elseif COMPILER.FLAGS.OBJ then
            if not COMPILER.FLAGS.OUTFILE:find("%.%S+$") then
                COMPILER.FLAGS.OUTFILE = COMPILER.FLAGS.OUTFILE .. ".o"
            end
            if not COMPILER.FLAGS.SILENT then
            	print("<\027[95mCmd\027[0m> as -g -o " .. COMPILER.FLAGS.OUTFILE .. " " .. COMPILER.CREATED_FILES[1])
			end
            os.execute('as -g -o ' .. COMPILER.FLAGS.OUTFILE .. " " .. COMPILER.CREATED_FILES[1])

        elseif COMPILER.FLAGS.VMTF then
            if not COMPILER.FLAGS.OUTFILE:find("%.%S+$") then
                COMPILER.FLAGS.OUTFILE = COMPILER.FLAGS.OUTFILE .. ".vmtf"
            end
            local out = ""
            local tfile = io.open(COMPILER.FLAGS.OUTFILE, "w+")
            for s = 1, #Lexer.tokens do
                out = out..tostring(s).."\n"
                for _,i in pairs(Lexer.tokens[s]) do
                    out = out..("    {Token: "..i.Token..", Value: "..i.Value.."}\n")
                end
            end
            tfile:write(out)
            tfile:close()

            print("Generated XoheVM token file")

        else
            -- Creating static library --
            if #COMPILER.LINKER_FILES > 0 then
                COMPILER.CREATED_FILES[#COMPILER.CREATED_FILES+1] = "src/Xohe/olib.a"
                if not COMPILER.FLAGS.SILENT then
					print("<\027[95mCmd\027[0m> ar rcs "..COMPILER.CREATED_FILES[3].." "..table.unpack(COMPILER.LINKER_FILES))
                end
        	    os.execute("ar rcs "..COMPILER.CREATED_FILES[3].." "..table.unpack(COMPILER.LINKER_FILES))
            end
            
            -- Compiling
        	if not COMPILER.FLAGS.SILENT then
            	print("<\027[95mCmd\027[0m> as -g -o " .. COMPILER.CREATED_FILES[2] .. " " .. COMPILER.CREATED_FILES[1])
            	os.execute('as -g -o ' .. COMPILER.CREATED_FILES[2] .. " " .. COMPILER.CREATED_FILES[1])
            	print("<\027[95mCmd\027[0m> ld -o " .. COMPILER.FLAGS.OUTFILE .. ' ' .. COMPILER.CREATED_FILES[2].." "..(COMPILER.CREATED_FILES[3] or ""))
            	os.execute('ld -o ' .. COMPILER.FLAGS.OUTFILE .. ' ' .. COMPILER.CREATED_FILES[2].." "..(COMPILER.CREATED_FILES[3] or ""))
            else
            	os.execute('as -g -o ' .. COMPILER.CREATED_FILES[2] .. " " .. COMPILER.CREATED_FILES[1])
            	os.execute('ld -o ' .. COMPILER.FLAGS.OUTFILE .. ' ' .. COMPILER.CREATED_FILES[2].." "..(COMPILER.CREATED_FILES[3] or ""))
            end
        end
    else
        -- Creating Static Library --
        if #COMPILER.LINKER_FILES > 0 then
            COMPILER.CREATED_FILES[#COMPILER.CREATED_FILES+1] = "src/Xohe/olib.a"
            if COMPILER.FLAGS.VERBOSE then
				print("<\027[95mCmd\027[0m> ar rcs "..COMPILER.CREATED_FILES[3].." "..table.unpack(COMPILER.LINKER_FILES))
			end
        	os.execute("ar rcs "..COMPILER.CREATED_FILES[3].." "..table.unpack(COMPILER.LINKER_FILES))
        end
        
        -- Generating output file location
        COMPILER.FLAGS.OUTFILE = "orb.out"
        COMPILER.CREATED_FILES[10] = COMPILER.FLAGS.OUTFILE
        
        -- Compiling
        if COMPILER.FLAGS.VERBOSE then
            print("<\027[95mCmd\027[0m> as -g -o " .. COMPILER.CREATED_FILES[2] .. " " .. COMPILER.CREATED_FILES[1])
            os.execute('as -g -o ' .. COMPILER.CREATED_FILES[2] .. " " .. COMPILER.CREATED_FILES[1])
            print("<\027[95mCmd\027[0m> ld -o " .. COMPILER.FLAGS.OUTFILE .. ' ' .. COMPILER.CREATED_FILES[2].." "..(COMPILER.CREATED_FILES[3] or ""))
            os.execute('ld -o ' .. COMPILER.FLAGS.OUTFILE .. ' ' .. COMPILER.CREATED_FILES[2].." "..(COMPILER.CREATED_FILES[3] or ""))
            print("<\027[95mCmd\027[0m> ./" .. COMPILER.FLAGS.OUTFILE)
            os.execute("./" .. COMPILER.FLAGS.OUTFILE)
        else
            os.execute('as -g -o ' .. COMPILER.CREATED_FILES[2] .. " " .. COMPILER.CREATED_FILES[1])
            os.execute('ld -o ' .. COMPILER.FLAGS.OUTFILE .. ' ' .. COMPILER.CREATED_FILES[2].." "..(COMPILER.CREATED_FILES[3] or ""))
            os.execute("./" .. COMPILER.FLAGS.OUTFILE)
        end
    end

    -- Cleaning
    for _, c_file in pairs(COMPILER.CREATED_FILES) do
        os.remove(c_file)
    end
    return true
end

return compiler
