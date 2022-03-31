`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/26/2022 07:54:32 PM
// Design Name: 
// Module Name: Subsystem_tests
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
`define  test
`include "ALU_test.v"
`include "Data_Serialiser_test.v"
`include "Shifter_test.v"

module Subsystem_tests(
    );
// Test select
reg [7:0]  ALU_tests;
reg [7:0]  Serialiser_tests;
reg [2:0]  Shifter_tests;
// Test results
wire [7:0] ALU_results;
wire [7:0] Serialiser_results;
wire [2:0] Shifter_results;
// Test control

// Clock
reg       clk               = 1'b0;
always #(`CLOCK_PERIOD/2) clk = ~clk;

initial #100000000 $stop;

// Iterate through tests
always @(posedge clk)
    if (ALU_tests !== 8'b11111111)
        ALU_tests        = 8'b11111111;
    else if (ALU_results >= 0 && Serialiser_tests !== 8'b11111111)
        Serialiser_tests = 8'b11111111; 
    else if (Serialiser_results >= 0 && Shifter_tests !== 3'b111)
        Shifter_tests    = 3'b111; 
    else if (Shifter_results >= 0)
    begin
        $display("#############################");
        $display(" FINAL TEST REPORT ");
        $display(" ALU    %B ", ALU_results);
        $display(" Serial %B ", Serialiser_results);
        $display(" Shift  %B ", Shifter_results);
        $display("#############################");
        $stop;
    end;

// Initialise test modules
ALU_test ALU_test(
    .tests(ALU_tests),
    .clk(clk),
    .Test_report(ALU_results)
    );
    
Data_Serialiser_test Data_Serialiser_test(
    .tests(Serialiser_tests),
    .clk(clk),
    .Test_report(Serialiser_results)
    );

Shifter_test Shifter_test(
    .tests(Shifter_tests),
    .clk(clk),
    .Test_report(Shifter_results)
    );

endmodule
