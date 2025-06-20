local compiler = {}

-- Imports --
local Error = require("src/errors")

-- Compiler Table --
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
        VERBOSE = false,
        DEBUG = false,
        PROG_EXIT = false,
    },
    VARIABLES = 0
}


-- Compiler --
NASM = {}
NASM.MACROS = [[;;;;;;NASM MACROS;;;;;;
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

%macro WRITEINT 1
	mov rax, %1
	push rax
	pop rdi
	mov rsi, int_buffer + 32
	mov rcx, 10

%%displayInt:
	xor rdx, rdx
	div rcx
	add dl, '0'
	dec rsi
	mov [rsi], dl
	test rax, rax
	jnz %%displayInt

	; display int
	mov rax, 1
	mov rdi, 1
	mov rdx, int_buffer + 32
	sub rdx, rsi
	syscall
%endmacro
]]

NASM.BSS = [[

;;;;;;VARIABLE DATA;;;;;;
section .bss
    read_buffer resb 128
]]

NASM.DATA = [[

section .data
	int_buffer times 33 db 0
	newline db 0x0A
]]

NASM.TEXT = [[

;;;;;;PROGRAM;;;;;;
section .text
    global _start
    _start:
]]

-- Variable Data Collection --
function gatherVariableData()
    local V = VARIABLES
    for _,variable in pairs(V.GLOBAL) do
        if variable.Type ==  "string" or variable.Type == "null" then
            local variable_value = variable.Value
            if not tonumber(variable_value) then
                variable_value = variable_value:gsub("%\\%n", "\", 0x0A, \""):gsub("%\\%t","\", 0x09, \""):gsub("^['\"]",""):gsub("['\"]$","")
            end
            if variable_value:find("^['\"]") or variable_value:find("['\"]$") then
            	local quote_char = "'"
            	if variable_value:match("^[']") then quote_char = '"' end
            	NASM.DATA = NASM.DATA.."    "..tostring(_)..": db "..quote_char..variable_value..quote_char..", 0\n"
            else
            	NASM.DATA = NASM.DATA.."    "..tostring(_)..": db \""..variable_value.."\", 0\n"
            end
            NASM.DATA = NASM.DATA.."    ".."L_"..tostring(_)..": equ $-"..tostring(_).."\n\n"
        elseif variable.Type == "number" then
			local variable_value = variable.Value
			NASM.DATA = NASM.DATA.."    "..tostring(_)..": dq "..variable_value.."\n"
		end
    end
    for _,variable in pairs(V.STATIC) do
		if variable.Type ==  "string" then
			local variable_value = variable.Value
			if not tonumber(variable_value) then
				variable_value = variable_value:gsub("%\\%n", "\", 0x0A, \""):gsub("%\\%t","\", 0x09, \""):gsub("^['\"]",""):gsub("['\"]$","")
			end
			NASM.DATA = NASM.DATA.."    "..tostring(_)..": db \""..variable_value.."\", 0\n"
			NASM.DATA = NASM.DATA.."    ".."L_"..tostring(_)..": equ $-"..tostring(_).."\n\n"
		elseif variable.Type == "number" then
			local variable_value = variable.Value
			NASM.DATA = NASM.DATA.."    "..tostring(_)..": dq "..variable_value.."\n"
		end
	end
end

-- Utility Function(s) --
function COMPILER.APPEND_DATA(data)
    data = data or ""
    NASM.TEXT = NASM.TEXT..data.."\n"
end

-- Program Compilation --
function Compile()
    gatherVariableData()
    local file = io.open("src/Xohe/out.asm","w+")

    -- Macros and variable data
    file:write(NASM.MACROS)
    file:write(NASM.BSS)
    file:write(NASM.DATA)

    -- Porgram --
    file:write(NASM.TEXT)
    file:write("        EXIT 0")
    file:close()

    -- Executing file
    if not COMPILER.FLAGS.EXECUTE then
        if COMPILER.FLAGS.OUTFILE == nil then
        	local filename = arg[1]
        	if filename:find("%/") then
				filename = arg[1]:match("%/%S+$")
        	end
        	COMPILER.FLAGS.OUTFILE = filename:match("%S+%."):gsub("[%/%.]","")
        end
        if not COMPILER.FLAGS.ASM then
        	print("<\027[95mCmd\027[0m> nasm -felf64 ".. COMPILER.CREATED_FILES[1])
            os.execute('nasm -felf64 '..COMPILER.CREATED_FILES[1])
            print("<\027[95mCmd\027[0m> ld -o ".. COMPILER.FLAGS.OUTFILE..' '..COMPILER.CREATED_FILES[2])
            os.execute('ld -o '..COMPILER.FLAGS.OUTFILE..' '..COMPILER.CREATED_FILES[2])
        else
            local file = io.open(COMPILER.FLAGS.OUTFILE, "w+")
            file:write(NASM.MACROS)
            file:write(NASM.BSS)
            file:write(NASM.DATA)
            -- Program --
            file:write(NASM.TEXT)
            if not COMPILER.FLAGS.PROG_EXIT then
                file:write("        EXIT 0")
            end
            file:close()
        end
    else
        COMPILER.FLAGS.OUTFILE = "orb.out"
        table.insert(COMPILER.CREATED_FILES, COMPILER.FLAGS.OUTFILE)
        if COMPILER.FLAGS.VERBOSE then
 	 		print("<\027[95mCmd\027[0m> nasm -felf64 ".. COMPILER.CREATED_FILES[1])
			os.execute('nasm -felf64 '..COMPILER.CREATED_FILES[1])
			print("<\027[95mCmd\027[0m> ld -o ".. COMPILER.FLAGS.OUTFILE..' '..COMPILER.CREATED_FILES[2])
			os.execute('ld -o '..COMPILER.FLAGS.OUTFILE..' '..COMPILER.CREATED_FILES[2])
			print("<\027[95mCmd\027[0m> ./"..COMPILER.FLAGS.OUTFILE)
			os.execute("./"..COMPILER.FLAGS.OUTFILE)
		else
			os.execute('nasm -felf64 '..COMPILER.CREATED_FILES[1])
			os.execute('ld -o '..COMPILER.FLAGS.OUTFILE..' '..COMPILER.CREATED_FILES[2])
			os.execute("./"..COMPILER.FLAGS.OUTFILE)
		end
    end

    -- Cleaning
    for _,c_file in pairs(COMPILER.CREATED_FILES) do
        os.remove(c_file)
    end
    return true
end

return compiler
