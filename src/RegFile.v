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

module RegFile(
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
    
wire [30:0] reg_in;
wire [31:0] regA_out, regB_out;
wire        regA_mux_out;

// Assign register 0 to be hardwired to 0
assign regA_out[0] = 32'h00000000;
assign regB_out[0] = 32'h00000000;

// Generate array of 31 registers
generate
    genvar i;
    for (i = 1; i < 32; i = i + 1)
    begin
        RAM32X1D #(
            .INIT(32'h00000000) // Initial contents of RAM
        ) RAM32X1D_inst (
            .DPO(regB_out[i]), // Read-only 1-bit data output
            .SPO(regA_out[i]), // Rw/ 1-bit data output
            .A0(bitPos[0]), // R/W address[0] input bit
            .A1(bitPos[1]), // R/W address[1] input bit
            .A2(bitPos[2]), // R/W address[2] input bit
            .A3(bitPos[3]), // R/W address[3] input bit
            .A4(bitPos[4]), // R/W address[4] input bit
            .D(reg_in[i - 1]), // Write 1-bit data input
            .DPRA0(bitPos[0]), // Read-only address[0] input bit
            .DPRA1(bitPos[1]), // Read-only address[0] input bit
            .DPRA2(bitPos[2]), // Read-only address[0] input bit
            .DPRA3(bitPos[3]), // Read-only address[0] input bit
            .DPRA4(bitPos[4]), // Read-only address[0] input bit
            .WCLK(clk), // Write clock input
            .WE(writeEn) // Write enable input
        );
    end
endgenerate

//Input multiplexer
assign reg_in = input_imux(data_in, regA_select);

// Output multiplexers
mux32 regA_mux (
    .in(regA_out),
    .select(regA_select),
    .out(regA_mux_out)
);

mux32 regB_mux (
    .in(regB_out),
    .select(regB_select),
    .out(regB_mux_out)
);

// Port A outputs 0 if write is enable as RegA address is used for writes
assign portA = writeEn ? 1'b0 : regA_mux_out;
assign portB = regB_mux_out;

// Function for input line selector
function [30:0] input_imux(
    input       in,
    input [4:0] select
);
case (select)
    default : input_imux   = 32'h00000000;
    5'd1  : input_imux[0]  = in;
    5'd2  : input_imux[1]  = in;
    5'd3  : input_imux[2]  = in;
    5'd4  : input_imux[3]  = in;
    5'd5  : input_imux[4]  = in;
    5'd6  : input_imux[5]  = in;
    5'd7  : input_imux[6]  = in;
    5'd8  : input_imux[7]  = in;
    5'd9  : input_imux[8]  = in;
    5'd10 : input_imux[9]  = in;
    5'd11 : input_imux[10] = in;
    5'd12 : input_imux[11] = in;
    5'd13 : input_imux[12] = in;
    5'd14 : input_imux[13] = in;
    5'd15 : input_imux[14] = in;
    5'd16 : input_imux[15] = in;
    5'd17 : input_imux[16] = in;
    5'd18 : input_imux[17] = in;
    5'd19 : input_imux[18] = in;
    5'd20 : input_imux[19] = in;
    5'd21 : input_imux[20] = in;
    5'd22 : input_imux[21] = in;
    5'd23 : input_imux[22] = in;
    5'd24 : input_imux[23] = in;
    5'd25 : input_imux[24] = in;
    5'd26 : input_imux[25] = in;
    5'd27 : input_imux[26] = in;
    5'd28 : input_imux[27] = in;
    5'd29 : input_imux[28] = in;
    5'd30 : input_imux[29] = in;
    5'd31 : input_imux[30] = in;
endcase
endfunction

endmodule
