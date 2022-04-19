`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/17/2022 03:50:08 PM
// Design Name: 
// Module Name: Data_Serialiser
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

module Data_Serialiser(
    input      [31:0] data_in_bus,
    output reg [31:0] data_out_bus,
    output     [9:0]  address_out_bus, // Limited to 10 bits due to size of memory
    input      [4:0]  bitPos,
    input      [2:0]  func,
    input             data_in_bit,
    input             mode,
    input             clk,
    input             rst,
    input             data_in_switch,
    output            data_out_bit,
    output            mem_misaligned
    );

wire [31:0] data_mux_in;
wire        data_mux_out;
reg  [11:0] Address;
reg         extend_bit;

assign address_out_bus = Address[11:2];

// Extend for byte and halfwords
always @(posedge clk)
    if (func[2]) extend_bit = 1'b0;
    else extend_bit = func[0] ? data_mux_in[15] : data_mux_in[7];

// Send signal if memory address is misaligned
// If the byte address is not 0 for full word
// Or the byte address is odd for hald word
assign mem_misaligned = bitPos > 2 && ((func[1] && Address[1:0] > 0) || (func[0] && Address[0]));

// Shift bytes around for byte/halfword addressed loading
// In bus
assign data_mux_in[7:0]   = Address[1] ?
                            (Address[0] ? data_in_bus[31:24] : data_in_bus[23:16]):
                            (Address[0] ? data_in_bus[15:8]  : data_in_bus[7:0]);
assign data_mux_in[15:8]  = func[0] &&  Address[1] ? data_in_bus[31:24] : data_in_bus[15:8];
assign data_mux_in[31:16] = data_in_bus[31:16];
// Out bit
assign data_out_bit       = ~data_in_switch || func[1] ? data_mux_out: (func[0] ?
                            (bitPos[4] ? extend_bit : data_mux_out) :
                            (bitPos[3] || bitPos[4] ? extend_bit : data_mux_out));

mux32 mux (
    .in(data_mux_in),
    .select(bitPos),
    .out(data_mux_out)
);

always @(posedge clk)
    if (rst) Address <= 12'h000;
    else if (mode) Address[bitPos] <= data_in_bit;
    else data_out_bus[{(bitPos[4:3] ^ Address[1:0]), bitPos[2:0]}] <= data_in_bit;
    
endmodule
