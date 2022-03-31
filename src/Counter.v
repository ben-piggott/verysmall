`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/29/2022 01:28:13 PM
// Design Name: 
// Module Name: Counter
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

module Counter #(
    parameter COUNT_DOWN  = 0,
    parameter COUNT_WIDTH = 5
)   (
    input                           clk,
    input                           rst,
    input                           load,
    input      [COUNT_WIDTH - 1:0]  load_in,
    input                           count_en,
    output reg [COUNT_WIDTH - 1:0]  count
    );
    
always @(posedge clk)
    if (rst)
        count <= 0;
    else if (load)
        count <= load_in;
    else if (count_en & COUNT_DOWN)
        count <= count - 1;
    else if (count_en)
        count <= count + 1;
    else
        count <= count;
    
endmodule
