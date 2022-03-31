`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/14/2022 16:23:07 PM
// Design Name: 
// Module Name: Memory
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

module Memory (
    inout [31:0] data,
    input [31:0] address,
    input [4:0]  write_mask,      
    input        enable,
    input        rst,
    input        clk
);

// Initiliase block RAM
BRAM_SINGLE_MACRO #(
    .BRAM_SIZE("36Kb"), // Target BRAM, "18Kb" or "36Kb"
    .DEVICE("7SERIES"), // Target Device: "7SERIES"
    .DO_REG(0), // Optional output register (0 or 1)
    .INIT(36'h000000000), // Initial values on output port
    .INIT_FILE ("NONE"),
    .WRITE_WIDTH(32), // Valid values are 1-72 (37-72 only valid when BRAM_SIZE="36Kb")
    .READ_WIDTH(32), // Valid values are 1-72 (37-72 only valid when BRAM_SIZE="36Kb")
    .SRVAL(36'h000000000), // Set/Reset value for port output
    .WRITE_MODE("WRITE_FIRST") // "WRITE_FIRST", "READ_FIRST", or "NO_CHANGE"
) BRAM_SINGLE_MACRO_inst (
    .DO(data), // Output data, width defined by READ_WIDTH parameter
    .ADDR(Address_reg), // Input address, width defined by read/write port depth
    .CLK(clk), // 1-bit input clock
    .DI(data), // Input data port, width defined by WRITE_WIDTH parameter
    .EN(enable), // 1-bit input RAM enable
    .RST(rst), // 1-bit input reset
    .WE(write_mask) // Input write enable, width defined by write port depth
);

endmodule