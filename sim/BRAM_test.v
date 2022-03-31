`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/28/2022 05:57:12 PM
// Design Name: 
// Module Name: BRAM_test
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


module BRAM_test(
    );
reg [31:0] mem_in_bus;
wire [31:0] mem_out_bus;
reg [9:0]  mem_addr_bus;
reg [3:0]  mem_we_mask;
reg        mem_en;

reg  clk = 1'b0;
always #(2) clk = ~clk;
initial #120 $stop;


// Initiliase memory block
BlockRAMwithMask #(
    .INIT_FILE("./test.mem")
) RAM (
    .clk(clk),
    .dataIn(mem_in_bus),
    .en(mem_en),
    .wr_mask(mem_we_mask),
    .addr(mem_addr_bus),
    .dataOut(mem_out_bus)
);

initial
begin
    mem_we_mask = 4'b0000;
    @(posedge clk);
    mem_en = 1'b1;
    mem_addr_bus = 10'b00000000;
    @(posedge clk);
    $display("%H", mem_out_bus);
    @(posedge clk);
    mem_addr_bus = 10'b00000001;
    mem_in_bus = 32'h018;
    mem_we_mask = 4'b1111;
    @(posedge clk);
    mem_we_mask = 4'b0000;
    @(posedge clk);
    $display("%H", mem_out_bus);
    @(posedge clk) #3 $stop;
end

endmodule