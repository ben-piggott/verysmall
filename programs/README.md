# Testing programs
## test.mem
A simple program to test all implemented major states
`
LW	 x4, 24(x0)
ADDI x2, x0,  1
ADD  x3, x2, x3
BLT  x3, x4, -2 // Signed offset in multiples of 2 bytes
SW	 x2, 28(x0)
JAL  x5, 12
10              // Value used for loop comparison
0               // "Output" address for storing values
SLL  x6, x2, x3
SRAI x6, x6,  8
LUI  x6,  1     // 12 bit left shifted immediate
SB	 x6, 24(x0)
`
## loop.c
A simple C loop for use in the RISC-V toolchain found [here](https://github.com/riscv-collab/riscv-gnu-toolchain).
Compile from C source code to ELF and then to object code for the processor.

## memmap
A memory map definition for the RISC-V toolchain.
