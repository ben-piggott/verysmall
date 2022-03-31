`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/28/2022 07:30:00 PM
// Design Name: 
// Module Name: ALU
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

module ALU(
    input [3:0] func,
    input       opA,
    input       opB,
    input       carry_in,
    input       rst,
    input       clk,
    output      result,
    output      slt
    );
    
reg Carry;
wire adder_sum;
wire adder_carry_out;

// Full adder operands 
wire adder_opA = opA;
wire adder_opB = func[3] ? ~opB : opB; //Invert for SUB

// Full adder carry
wire adder_carry_in = Carry | carry_in;

// Full adder
assign {adder_carry_out, adder_sum} = adder_opA + adder_opB + adder_carry_in;
always @(posedge clk)
    if (rst) Carry <= 1'b0;
    else case (func[2:0])
        3'b000: Carry <= adder_carry_out; // ADD or SUB  
        3'b100: Carry <= 1'b0; // XOR         
        3'b110: Carry <= 1'b1; // OR          
        3'b111: Carry <= 1'b0; // AND   
        3'b010: Carry <= adder_carry_out; // SLT
        3'b011: Carry <= adder_carry_out; // SLTU      
        default: Carry <= 1'b0;
    endcase                
    
// Less than comparisons
reg slt_reg_unsigned, slt_reg_signed;
always @(posedge clk)
begin
    // Do unsigned comparison serially using the adder
    slt_reg_unsigned <= ~adder_carry_out;
    
    // For signed treat the current input as the sign bits to modify the previous unsigned results
    slt_reg_signed <= opA + ~opB + ~slt_reg_unsigned;
end

// SLT output multiplexer
assign slt = (func[0] ? slt_reg_unsigned : slt_reg_signed);

// ALU output multiplexer
assign result = func[1] ? (func[2] ?  adder_carry_out : 1'b0) : adder_sum;

endmodule
