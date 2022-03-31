// Definitions for ISA
// ---------------------------------------------------------------------------
// OP Codes - [6:0] of Instruction
// ---------------------------------------------------------------------------
`define LOAD        7'b0000011
`define STORE       7'b0100011
`define BRANCH      7'b1100011
`define OP_IMM      7'b0010011
`define OP          7'b0110011
`define SYSTEM      7'b1110011
`define MISC_MEM    7'b0001111
`define JALR        7'b1100111
`define JAL         7'b1101111
`define AUIPC       7'b0010111
`define LUI         7'b0110111
// ---------------------------------------------------------------------------
// Function - [14:12] of Instruction (Called funct3)
// ---------------------------------------------------------------------------
// BRANCH
`define BEQ         3'b000
`define BNE         3'b001
`define BLT         3'b100
`define BGE         3'b101
`define BLTU        3'b110
`define BGEU        3'b111
// LOAD
`define LB          3'b000
`define LH          3'b001
`define LW          3'b010
`define LBU         3'b100
`define LHU         3'b101
// STORE
`define SB          3'b000
`define SH          3'b001
`define SW          3'b010
// OP-IMM
`define ADDI        3'b000
`define SLTI        3'b010 
`define SLTIU       3'b011
`define XORI        3'b100
`define ORI         3'b110
`define ANDI        3'b111
`define SLLI        3'b001
`define STLI        3'b101
`define SRAI        3'b101 // Bit 30 is 1 i.e. funct7 is 0100000
// OP
`define ADD         3'b000
`define SUB         3'b000 // Bit 30 is 1 i.e. funct7 is 0100000
`define SLL         3'b001
`define SLT         3'b010
`define SLTU        3'b011
`define XOR         3'b100
`define STL         3'b101
`define SRA         3'b101 // Bit 30 is 1 i.e. funct7 is 0100000
`define OR          3'b110
`define AND         3'b111
// MISC-MEM
`define FENCE       3'b000
// SYSTEM
`define ECALL       3'b000
`define EBREAK      3'b000 // Bit 20 is 1 i.e. immediate is 000000000001

