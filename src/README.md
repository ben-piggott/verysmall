# Processor source code
## ALU
1 bit full adder. Can also do bitwise operations and set less than comparisons.
Takes bit 6 of func7 and the func3 of an instruction as the operation.
## BlockRAMwithMask
Module to implement 1024 32 bit word main memory as a Block RAM on the FPGA. Uses write a mask to enable to byte and halfword writes in addition to full word operations.
## BRU
Branch resolving unit. Uses ALU sum output to determine equality and ALU set less than output to then return if a branch should be taken. Works in parallel to ALU doing a SUB, SLT or SLTU operation.
## Control\_Unit
Contains program counter and immediate register. Reads instruction from memory using PC and decodes it. Relatively simple state machine (diagram TBD) with a maximum depth of 4 states (e.g. START\_0 -> START\_1 -> ALU\_0 -> WRITEBACK\_0). More details on each state is commented in the source code.
## Data\_Serialiser
Serialises and deserialises data between the memory and system data-path. Also converts address in system from byte addressing to word addressing for memory.
## ISA
Contains definitions of operation codes and functions. Makes Control\_Unit more readable.
## Multiplexers
Contains definition of 16:1 and 32:1 continuous multiplexer used in the system.
## RegFile
Module to implement registers for processor. This is done using distributed RAM on the FPGA. Point to note register 0 in RISC-V is hardwired to 0.
## Shifter
Wrapper around a Xilinix 32 bit SRL shifter to be able to do  SLL and SRA operations too.
## System
Essentially a data-path with multiplexers that ties all sub-systems together and acts as top level module.
