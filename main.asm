;;;;;;NASM MACROS;;;;;;
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

;;;;;;VARIABLE DATA;;;;;;
section .bss
    read_buffer resb 128

section .data
	int_buffer times 33 db 0
	newline db 0x0A
    Orb_CVARIABLE_0x00: db "Orb: <panic> error", 0x0A, "traceback:", 0x0A, "    [orb]: panic function test", 0x0A, "    [file]: main.orb", 0x0A, "    [line]: 5", 0x0A, "", 0
    L_Orb_CVARIABLE_0x00: equ $-Orb_CVARIABLE_0x00

    Orb_CVARIABLE_0x01: db "", 0x0A, "[91mexit status <37>[0m", 0x0A, "", 0
    L_Orb_CVARIABLE_0x01: equ $-Orb_CVARIABLE_0x01

    null: db "null", 0
    L_null: equ $-null

    a: dq (13+15)*3
    b: db "paul", 0
    L_b: equ $-b


;;;;;;PROGRAM;;;;;;
section .text
    global _start
    _start:
        WRITE Orb_CVARIABLE_0x00, L_Orb_CVARIABLE_0x00
        WRITE Orb_CVARIABLE_0x01, L_Orb_CVARIABLE_0x01
        EXIT 37
