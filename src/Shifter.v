`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/22/2022 11:00:59 AM
// Design Name: 
// Module Name: Shifter
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
`include "Counter.v"

module Shifter(
    input       opA,
    input       opB,
    input       rst,
    input       clk,
    input [5:0] bitPos,
    input [3:0] func,
    output      out,
    output      out_en
    );    
// Shifter wires and reg
wire shift_out, shift_in, shift_enable, sign_bit;
reg load;
// Counter wires and reg
wire        count_enable;
wire        counter_load;
wire [4:0]  count;
reg  [4:0]  counter_val;

// Enable signals
assign shift_enable = ~bitPos[5] && (load || (func[2] ? 1'b1 : count == 0));
assign count_enable = ~load && count > 0 && ~bitPos[5];
assign out_en       = ~load && ~bitPos[5] && (func[2] ? count == 0 : 1'b1);

// Load in bits into shifter
assign shift_in = load ? opA : func[3] ? sign_bit : 1'b0;

// Load for 31 bits after a reset
always @(posedge clk)
    if (rst) load = 1'b1;
    else if(bitPos[5]) load = 1'b0;

// Load how much to shift by into counter
always @(posedge clk)
    if (load && bitPos[2:0] < 5) counter_val[bitPos[2:0]] = opB;
assign counter_load = load && bitPos == 5;

// Choose output source
assign out = out_en ? (~func[2] && count > 0 ? 1'b0 : shift_out ) : 1'bZ;

// Initialise shift register
SRLC32E #(
    .INIT(32'h00000000) // Initial Value of Shift Register
) SRLC32E_inst (
    .Q(sign_bit), // SRL data output
    .Q31(shift_out), // SRL cascade output pin
    .A(5'b00000), // 5-bit shift depth select input
    .CE(shift_enable), // Clock enable input
    .CLK(clk), // Clock input
    .D(shift_in) // SRL data input
);

// Initialise cycle counter
Counter #(
    .COUNT_DOWN(1),
    .COUNT_WIDTH(5)
) shifter_counter (
    .clk(clk),
    .rst(rst),
    .load(counter_load),
    .load_in(counter_val),
    .count_en(count_enable),
    .count(count)
    );

endmodule