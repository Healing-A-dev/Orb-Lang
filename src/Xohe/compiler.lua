local compiler = {}

-- Imports --
local Error = require("src/errors")

-- Compiler Table --
COMPILER = {
    CREATED_FILES = {
        'src/Xohe/out.s',
        'src/Xohe/out.o',
    },
    FLAGS = {
        OUTFILE = nil,
        EXECUTE = true,
        ASM = false,
        WARN = false,
        WARNALL = false,
        VERBOSE = false,
        DEBUG = false,
        PROG_EXIT = false,
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
    .global _start
_start:
]],
    FUNC = [[
Orb_CFUNCTION_puts:
    mov $1, %rax
    mov $1, %rdi
    syscall
    ret

Orb_CFUNCTION_exit:
    mov $60, %rax
    syscall
    ret

Orb_CFUNCTION_puts_INT:
    mov %rax, %rdi
    mov $int_buffer + 32, %rsi
    mov $10, %rcx

.displayInt:
    xor %rdx, %rdx
    div %rcx
    add $'0', %dl
    dec %rsi
    mov %dl, (%rsi)
    test %rax, %rax
    jnz .displayInt

    mov $int_buffer + 32, %rdx
    sub %rsi, %rdx
    mov %rsi, %rsi
    callq "Orb_CFUNCTION_puts"
    ret

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
    file:write("    call Orb_CFUNCTION_exit\n\n")
    file:write(ASM.FUNC)
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
        if not COMPILER.FLAGS.ASM then
            print("<\027[95mCmd\027[0m> as -g -o " .. COMPILER.CREATED_FILES[2] .. " " .. COMPILER.CREATED_FILES[1])
            os.execute('as -g -o ' .. COMPILER.CREATED_FILES[2] .. " " .. COMPILER.CREATED_FILES[1])
            print("<\027[95mCmd\027[0m> ld -o " .. COMPILER.FLAGS.OUTFILE .. ' ' .. COMPILER.CREATED_FILES[2])
            os.execute('ld -o ' .. COMPILER.FLAGS.OUTFILE .. ' ' .. COMPILER.CREATED_FILES[2])
        else
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
                file:write("    callq \"Orb_CFUNCTION_exit\"\n\n")
            end
            file:write(ASM.FUNC)
            file:close()
        end
    else
        COMPILER.FLAGS.OUTFILE = "orb.out"
        table.insert(COMPILER.CREATED_FILES, COMPILER.FLAGS.OUTFILE)
        if COMPILER.FLAGS.VERBOSE then
            print("<\027[95mCmd\027[0m> as -g -o " .. COMPILER.CREATED_FILES[2] .. " " .. COMPILER.CREATED_FILES[1])
            os.execute('as -g -o ' .. COMPILER.CREATED_FILES[2] .. " " .. COMPILER.CREATED_FILES[1])
            print("<\027[95mCmd\027[0m> ld -o " .. COMPILER.FLAGS.OUTFILE .. ' ' .. COMPILER.CREATED_FILES[2])
            os.execute('ld -o ' .. COMPILER.FLAGS.OUTFILE .. ' ' .. COMPILER.CREATED_FILES[2])
            print("<\027[95mCmd\027[0m> ./" .. COMPILER.FLAGS.OUTFILE)
            os.execute("./" .. COMPILER.FLAGS.OUTFILE)
        else
            os.execute('as -g -o ' .. COMPILER.CREATED_FILES[2] .. " " .. COMPILER.CREATED_FILES[1])
            os.execute('ld -o ' .. COMPILER.FLAGS.OUTFILE .. ' ' .. COMPILER.CREATED_FILES[2])
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
