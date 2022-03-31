`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/31/2022 01:15:14 PM
// Design Name: 
// Module Name: RegFile_test
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


module RegFile_test(
    );
integer     i, j;
wire        reg_outA, reg_outB;
reg [31:0]  In, RegA, RegB;
reg [4:0]   regA_select, regB_select;
reg         reg_we, reg_rst, reg_in, pass;
    
// Clock
reg     clk = 1'b0;
always #(`CLOCK_PERIOD/2) clk = ~clk;

initial #100000 $stop;

// Initialise registers
RegFile RegFile (
    .data_in(reg_in),
    .regA_select(regA_select),
    .regB_select(regB_select),
    .bitPos(i[4:0]),
    .writeEn(reg_we),
    .rst(reg_rst),
    .clk(clk),
    .portA(reg_outA),
    .portB(reg_outB)
);


// Tests
initial
begin
    reg_rst     = 1'b0;
    reg_we      = 1'b0;
    regB_select = 5'b00000;
    test();
    @(posedge clk) #3 $stop;
end

task store;
begin
    reg_we = 1'b1;
    for (i = 0; i < 32; i = i + 1)
    begin
        reg_in = In[i];
        @(posedge clk);
    end
    reg_we = 1'b0;
end
endtask

task load;
begin
    for(i = 0; i < 32; i = i + 1)
    begin
        @(posedge clk);
        RegA[i] = reg_outA;
        RegB[i] = reg_outB;
    end
end
endtask

task test;
begin
pass        = 1'b1;
for (j = 1; j < 32; j = j + 1)
    begin
        @(posedge clk);
        if (j % 2) In   = j;
        else In         = {1'b1, j[30:0]};
        regA_select     = j;
        store();
    end
for (j = 1; j < 32; j = j + 1)
    begin
        @(posedge clk);
        if (j % 2) In   = j;
        else In         = {1'b1, j[30:0]};
        regA_select     = j;
        i               = 1'b0;
        load();
        if (RegA !== In)
        begin
            $display("Test %0d FAILED", j);
            $display("Expected: %H", In);
            $display("Actual:   %H", RegA);
            pass = 1'b0;
        end
        if (RegB !== 32'h00000000)
        begin
            $display("Test %0d FAILED", j);
            $display("Expected: %H", In);
            $display("Actual:   %H", RegB);
            pass = 1'b0;
        end
    end
    $display("Testing Complete");
end
endtask

endmodule
