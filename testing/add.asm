%macro addInt 2
	mov rax, %1
	mov rbx, %2
	add rax, rbx
	mov [rdx + 4], rax
%endmacro

%macro disp 2
	mov rax, 1
	mov rdi, 1
	mov rsi, %1
	mov rdx, %2
	syscall
%endmacro

%macro dispInt 1
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

%macro exit 1
    mov rax, 60
    mov rdi, %1
    syscall
%endmacro

section .data
	int_buffer times 33 db 0
	newline db 0x0A

section .text
	global _start
	_start:
		; Test 0
		mov rax, 3
		mov rbx, 7
		add rax, rbx
		dispInt rax
		disp newline, 1
		
		; Test 1
		dispInt 12345
		disp newline, 1

		; Test 2
		dispInt 13
		disp newline, 1

		; Exit
		exit 0
