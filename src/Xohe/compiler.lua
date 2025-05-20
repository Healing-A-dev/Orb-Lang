local compiler = {}

--[[Imports]]--
local Error = require("src/errors")


--[[Compiler Table]]--
COMPILER = {
    CREATED_FILES = {
        'src/Xohe/out.asm',
        'src/Xohe/out.o',
    },
    FLAGS = {
        OUTFILE = nil,
        EXECUTE = true,
        ASM = false,
        WARN = false,
    }
}

--[[Compiler]]--
NASM = {}
NASM.MACROS = [[
%macro WRITE 2
    mov rax, 1	                ; Write
    mov rdi, 1                  ; STDOUT
    mov rsi, %1
    mov rdx, %2
    syscall
%endmacro

%macro EXIT 1
    mov rax, 60
    mov rdi, %1
    syscall
%endmacro

%macro READ 1
    mov rax, 0                  ; READ
    mov rdi, 0                  ; SDTIN
    mov rsi, read_buffer
    mov rdx, %1                 ; 128
    syscall
%endmacro
]]

NASM.BSS = [[

section .bss
    read_buffer resb 128
    write_buffer resb 128
]]

NASM.DATA = [[

section .data
]]

NASM.TEXT = [[
section .text
    global _start
    _start:
    	WRITE a, L_a
]]

-- Variable Data Collection
-- Collects all global variables and static variables that are only included in the input file
function gatherVariableData()
    local V = VARIABLES
    for _,variable in pairs(V.GLOBAL) do
        if variable.Type ==  "string" or variable.Type == "number" then
            local variable_value = variable.Value
            if not tonumber(variable_value) then
                variable_value = variable_value:gsub("%\\%n", "\", 0x0A, \""):gsub("%\\%t","\", 0x09, \""):gsub("^['\"]",""):gsub("['\"]$","")
            end
            NASM.DATA = NASM.DATA.."\t"..tostring(_)..": db \""..variable_value.."\", 0\n"
            NASM.DATA = NASM.DATA.."\t".."L_"..tostring(_)..": equ $-"..tostring(_).."\n\n"
        end
    end
end

function Compile()
    gatherVariableData()
    local file = io.open("src/Xohe/out.asm","w+")
    -- Macros and variable data
    file:write(NASM.MACROS)
    file:write(NASM.BSS)
    file:write(NASM.DATA)
    -- Porgram --
    file:write(NASM.TEXT)
    file:write("\t\tEXIT 0")
    file:close()

    -- Executing file
    if not COMPILER.FLAGS.EXECUTE then
        if COMPILER.FLAGS.OUTFILE == nil then
            Error.new("NO_OUTPUT")
        end
        if not COMPILER.FLAGS.ASM then
            os.execute('nasm -felf64 '..COMPILER.CREATED_FILES[1]..' && ld -o '..COMPILER.FLAGS.OUTFILE..' '..COMPILER.CREATED_FILES[2])
        else
            local file = io.open(COMPILER.FLAGS.OUTFILE, "w+")
            file:write(NASM.MACROS)
            file:write(NASM.BSS)
            file:write(NASM.DATA)
            -- Program --
            file:write(NASM.TEXT)
            file:write("\t\tEXIT 0")
            file:close()
        end
    else
        COMPILER.FLAGS.OUTFILE = "orb.out"
        table.insert(COMPILER.CREATED_FILES, COMPILER.FLAGS.OUTFILE)
        os.execute('nasm -felf64 '..COMPILER.CREATED_FILES[1]..' && ld -o '..COMPILER.FLAGS.OUTFILE..' '..COMPILER.CREATED_FILES[2].." && ./"..COMPILER.FLAGS.OUTFILE)
    end

    -- Cleaning
    for _,c_file in pairs(COMPILER.CREATED_FILES) do
        os.remove(c_file)
    end
    return true
end

return compiler
