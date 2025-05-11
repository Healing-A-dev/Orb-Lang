local compiler = {}

--[[Imports]]--
local Error = require("src/errors")

local COMPILER = {
    CREATED_FILES = {
        'src/Xohe/out.asm',
        'src/Xohe/out.o',
        'src/Xohe/out.lua'
    },
    FLAG = {
        OUTFILE = ""
    }
}

local NASM = {}
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

function gatherVariableData()
    local V = VARIABLES
    for _,variable in pairs(V.GLOBAL) do
        if variable.Type ==  "string" or variable.Type == "number" then
            local variable_value = variable.Value
            if not tonumber(variable_value) then
                variable_value = variable_value:gsub("^['\"]",""):gsub("['\"]$","")
            end
            NASM.DATA = NASM.DATA.."\t"..tostring(_)..": db \""..variable_value.."\", 10\n"
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
    if not SELF_EXECUTE then
        if C_OUT == nil then
            Error.new("NO_OUTPUT")
        end
        os.execute('nasm -felf64 '..COMPILER.CREATED_FILES[1]..' && ld -o '..C_OUT..' '..COMPILER.CREATED_FILES[2])
    else
        local C_OUT = "orb.out"
        table.insert(COMPILER.CREATED_FILES, C_OUT)
        os.execute('nasm -felf64 '..COMPILER.CREATED_FILES[1]..' && ld -o '..C_OUT..' '..COMPILER.CREATED_FILES[2].." && ./"..C_OUT)
    end

    -- Cleaning
    for _,c_file in pairs(COMPILER.CREATED_FILES) do
        os.remove(c_file)
    end
    return true
end

-- gatherVariableData()
-- Compile()

return compiler
