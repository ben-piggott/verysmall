.section .init, "ax"
.global _start
_start:
    .cfi_startproc
    .cfi_undefined ra
    la gp, __global_pointer$
    la sp, __stack_top
    add s0, sp, zero
    jal zero, main
    .cfi_endproc
    .end
	
