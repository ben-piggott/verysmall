`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/15/2022 12:19:12 AM
// Design Name: 
// Module Name: RegFile
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
`include "Multiplexers.v"

module RegFile #(
    parameter D_WIDTH = 32,
	parameter D_NO = 31
)   (
    input       data_in,
    input [4:0] regA_select,
    input [4:0] regB_select,
    input [4:0] bitPos,
    input       writeEn,
    input       rst,
    input       clk,
    output      portA,
    output      portB
    );
    
(* ram_style = "distributed" *) reg [D_WIDTH-1:0] registers [0:D_NO];
wire        regA_mux_out, regB_mux_out;

//Input multiplexer
always @(posedge clk)
begin
    if (writeEn && regA_select > 0)
        registers[regA_select][bitPos] = data_in;
end

// Output multiplexers
mux32 regA_mux (
    .in(registers[regA_select]),
    .select(bitPos),
    .out(regA_mux_out)
);

mux32 regB_mux (
    .in(registers[regB_select]),
    .select(bitPos),
    .out(regB_mux_out)
);

// Port A outputs 0 if write is enable as RegA address is used for writes
assign portA = writeEn ? 1'b0 : regA_mux_out;
assign portB = regB_mux_out;

integer j;
initial 
begin
    for(j = 0; j <= D_NO; j = j+1) 
        registers[j] = 0;
end

endmodule
