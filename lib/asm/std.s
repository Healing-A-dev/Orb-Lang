.section .data
	int_buffer:
		.skip 128
	
.section .text
	.global Orb_CFUNCTION_puts
	.global Orb_CFUNCTION_exit
	.global Orb_CFUNCTION_puts_INT

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
	
