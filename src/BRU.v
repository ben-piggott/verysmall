`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/18/2022 02:32:03 PM
// Design Name: 
// Module Name: BRU
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
// Use ALU SLT function for BLT and BGE (inverse of SLTU)
// Use ALU SLTU function for BLTU and BGEU (inverse of SLTU)
// Use ALU SUB function for BEQ and BNE (SUB results in NOT 0)

module BRU(
    input [1:0] func, // Made of bits 2 to 0 of func3 of Branch instruction
    input       ALU_slt,
    input       ALU_output,
    input       rst,
    input       clk,
    output      branch
    );

// Register to store if values are not equal
reg neq;

// BEQ output inverse of not equal register
// BNE just output not equal register
// BLT[U] just pass through the ALU slt/sltu output
// BGE[U] pass inverse of ALU slt/sltu output
assign branch = func[1] ? (func[0] ? ~ALU_slt : ALU_slt) : (func[0] ? neq : ~neq);

// At each clock edge take OR of not equal register and ALU sum output (output
// will be from a subtraction operation)
// If there a single 1 in the output bitstream of the SUB op then the values are
// not equal
// and the register will capture this
always @(posedge clk)
begin
    if (rst) neq <= 1'b0;
    else neq <= neq | ALU_output;
end
    
endmodule
