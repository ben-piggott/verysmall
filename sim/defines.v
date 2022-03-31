`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/10/2022 11:50:53 AM
// Design Name: 
// Module Name: defines
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

// Clock period
`define CLOCK_PERIOD 4
// ALU Functions
`define ADD     4'b0000 // Addition
`define SUB     4'b1000 // Subtraction
`define SLT     4'b1010 // Less Than Comparison
`define SLTU    4'b1011 // Less Than Unsigned Comparison
`define XOR     4'b0100 // Bitwise Exlusive OR
`define OR      4'b0110 // Bitwise OR
`define AND     4'b0111 // Bitwise AND
// Shifter Functions
`define SLL     4'b0001 // Logical shift left
`define SRL     4'b0101 // Logical shift right
`define SRA     4'b1101 // Arithmetic shift right
// Deserialiser Functions
`define LB      3'b000 // Load byte
`define LH      3'b001 // Load halfword
`define LW      3'b010 // Load word
`define LBU     3'b100 // Load byte unsigned
`define LHU     3'b101 // Load halfword unsigned
`define SB      3'b000 // Store byte
`define SH      3'b001 // Store halfword
`define SW      3'b010 // Store word
// 32 bit Values
`define ZERO        32'h00000000
`define ONE         32'h00000001
`define NEG_ONE     32'hFFFFFFFF
`define LOWEST      32'h80000000
`define HIGHEST     32'h7FFFFFFF