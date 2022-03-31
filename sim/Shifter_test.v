`timescale 10ns / 10ps

// Import instruction definitions and useful values
`include "defines.v"

module Shifter_test(
    output reg [2:0] Test_report
);
// Clock                             
reg       clk               = 1'b0;  
always #(`CLOCK_PERIOD/2) clk = ~clk;

// Initiliase shifter
wire        shifter_out, shifter_read;
reg         A, B, Shifter_rst;
reg [3:0]   Op;
reg [5:0]   bitPos;

Shifter Shifter(
    .opA(A),
    .opB(B),
    .rst(Shifter_rst),
    .clk(clk),
    .bitPos(bitPos),
    .func(Op),
    .out(shifter_out),
    .out_en(shifter_read)
);

reg [31:0]  RsA, RsB, Dest;
integer     i;

// Tests for each shift operation
// 1, 0000 0001 by 0
// 2. 0000 0001 by 1
// 3. 0000 0001 by 31
// 4. FFFF FFFF by 0
// 5. FFFF FFFF by 1
// 6. FFFF FFFF by 31
// 7. 700F F999 by 16
// 8. F00F F999 by 16

initial
begin
    // Initialise Shifter
    Op = 4'b0000;
    A = 1'b0;
    B = 1'b0;
    Shifter_reset();
    SLL_Test(Test_report[2]);
    SRL_Test(Test_report[1]);
    SRA_Test(Test_report[0]);
    $display("#############################");
    $display("Shifter Test Results : %b", Test_report);
    $display("#############################");
    $stop;
end

task enter_inputs;
    begin
    // Loop through all 32 bits serially
    // to load into shifter
    for (i = 0; i < 32; i = i + 1)
    begin
        A       = RsA[i];
        B       = RsB[i];
        @(posedge clk);
    end
    @(posedge clk) i = 0;
    while (~shifter_read) @(posedge clk);
    while (shifter_read)
    begin   
        Dest[i] = shifter_out;
        i = i + 1;
        @(posedge clk);
    end
    end
endtask

always @(posedge clk) bitPos = i;

task Shifter_reset;
    begin
        @(posedge clk);
        i = 0;
        Shifter_rst = 1'b1;
        @(posedge clk);
        Shifter_rst = 1'b0;
    end
endtask

task SLL_Test;
    output pass;
    begin
        $display("*****************************");
        $display("Test 01 - SLL ");
        pass = 1'b1;
        @(posedge clk);
        Op = `SLL;
        
        // -------------------------------------------------------------------
        // Test 1
        // -------------------------------------------------------------------
        // 0000 0001 << 0
        RsA = `ONE;
        RsB = 0;
        enter_inputs();
        // Check outputs
        if (Dest !== RsA << RsB[4:0]) 
        begin 
            $display("-----------------------------");
            $display("Test 1 - Failed");
            $display("%B << %0D", RsA, RsB[4:0]);
            $display("Expected output: %B", RsA << RsB[4:0]);
            $display("Actual output:   %B", Dest);
            pass = 1'b0;
        end
        Shifter_reset();
        
        // -------------------------------------------------------------------
        // Test 2
        // -------------------------------------------------------------------
        // 0000 0001 << 1
        RsB = 1;
        enter_inputs();
        // Check outputs
        if (Dest !== RsA << RsB[4:0]) 
        begin 
            $display("-----------------------------");
            $display("Test 2 - Failed");
            $display("%B << %0D", RsA, RsB[4:0]);
            $display("Expected output: %B", RsA << RsB[4:0]);
            $display("Actual output:   %B", Dest);
            pass = 1'b0;
        end
        Shifter_reset();
        
        // -------------------------------------------------------------------
        // Test 3
        // -------------------------------------------------------------------
        // 0000 0001 << 31
        RsB = 31;
        enter_inputs();
        // Check outputs
        if (Dest !== RsA << RsB[4:0]) 
        begin 
            $display("-----------------------------");
            $display("Test 3 - Failed");
            $display("%B << %0D", RsA, RsB[4:0]);
            $display("Expected output: %B", RsA << RsB[4:0]);
            $display("Actual output:   %B", Dest);
            pass = 1'b0;
        end
        Shifter_reset();
        
        // -------------------------------------------------------------------
        // Test 4
        // -------------------------------------------------------------------
        // FFFF FFFF << 0
        RsA = `NEG_ONE;
        RsB = 0;
        enter_inputs();
        // Check outputs
        if (Dest !== RsA << RsB[4:0]) 
        begin 
            $display("-----------------------------");
            $display("Test 4 - Failed");
            $display("%B << %0D", RsA, RsB[4:0]);
            $display("Expected output: %B", RsA << RsB[4:0]);
            $display("Actual output:   %B", Dest);
            pass = 1'b0;
        end
        Shifter_reset();
        
        // -------------------------------------------------------------------
        // Test 5
        // -------------------------------------------------------------------
        // FFFF FFFF << 1
        RsB = 1;
        enter_inputs();
        // Check outputs
        if (Dest !== RsA << RsB[4:0]) 
        begin 
            $display("-----------------------------");
            $display("Test 5 - Failed");
            $display("%B << %0D", RsA, RsB[4:0]);
            $display("Expected output: %B", RsA << RsB[4:0]);
            $display("Actual output:   %B", Dest);
            pass = 1'b0;
        end
        Shifter_reset();
        
        // -------------------------------------------------------------------
        // Test 6
        // -------------------------------------------------------------------
        // FFFF FFFF << 31
        RsB = 31;
        enter_inputs();
        // Check outputs
        if (Dest !== RsA << RsB[4:0]) 
        begin 
            $display("-----------------------------");
            $display("Test 6 - Failed");
            $display("%B << %0D", RsA, RsB[4:0]);
            $display("Expected output: %B", RsA << RsB[4:0]);
            $display("Actual output:   %B", Dest);
            pass = 1'b0;
        end
        Shifter_reset();
        
        // -------------------------------------------------------------------
        // Test 7
        // -------------------------------------------------------------------
        // 700F F999 << 16
        RsA = 32'h700FF999;
        RsB = 16;
        enter_inputs();
        // Check outputs
        if (Dest !== RsA << RsB[4:0]) 
        begin 
            $display("-----------------------------");
            $display("Test 7 - Failed");
            $display("%B << %0D", RsA, RsB[4:0]);
            $display("Expected output: %B", RsA << RsB[4:0]);
            $display("Actual output:   %B", Dest);
            pass = 1'b0;
        end
        Shifter_reset();
        
        // -------------------------------------------------------------------
        // Test 8
        // -------------------------------------------------------------------
        // F00F F999 << 16
        RsA = 32'hF00FF999;
        enter_inputs();
        // Check outputs
        if (Dest !== RsA << RsB[4:0]) 
        begin 
            $display("-----------------------------");
            $display("Test 8 - Failed");
            $display("%B << %0D", RsA, RsB[4:0]);
            $display("Expected output: %B", RsA << RsB[4:0]);
            $display("Actual output:   %B", Dest);
            pass = 1'b0;
        end
        Shifter_reset();
        
        $display("*****************************");
        if (~pass) $display("Test 01 - FAILED");
        else $display("Test 01 - PASSED"); 
    end
endtask

task SRL_Test;
    output pass;
    begin
        $display("*****************************");
        $display("Test 02 - SRL ");
        pass = 1'b1;
        @(posedge clk);
        Op = `SRL;
        
        // -------------------------------------------------------------------
        // Test 1
        // -------------------------------------------------------------------
        // 0000 0001 >> 0
        RsA = `ONE;
        RsB = 0;
        enter_inputs();
        // Check outputs
        if (Dest !== RsA >> RsB[4:0]) 
        begin 
            $display("-----------------------------");
            $display("Test 1 - Failed");
            $display("%B >> %0D", RsA, RsB[4:0]);
            $display("Expected output: %B", RsA >> RsB[4:0]);
            $display("Actual output:   %B", Dest);
            pass = 1'b0;
        end
        Shifter_reset();
        
        // -------------------------------------------------------------------
        // Test 2
        // -------------------------------------------------------------------
        // 0000 0001 >> 1
        RsB = 1;
        enter_inputs();
        // Check outputs
        if (Dest !== RsA >> RsB[4:0]) 
        begin 
            $display("-----------------------------");
            $display("Test 2 - Failed");
            $display("%B >> %0D", RsA, RsB[4:0]);
            $display("Expected output: %B", RsA >> RsB[4:0]);
            $display("Actual output:   %B", Dest);
            pass = 1'b0;
        end
        Shifter_reset();
        
        // -------------------------------------------------------------------
        // Test 3
        // -------------------------------------------------------------------
        // 0000 0001 >> 31
        RsB = 31;
        enter_inputs();
        // Check outputs
        if (Dest !== RsA >> RsB[4:0]) 
        begin 
            $display("-----------------------------");
            $display("Test 3 - Failed");
            $display("%B >> %0D", RsA, RsB[4:0]);
            $display("Expected output: %B", RsA >> RsB[4:0]);
            $display("Actual output:   %B", Dest);
            pass = 1'b0;
        end
        Shifter_reset();
        
        // -------------------------------------------------------------------
        // Test 4
        // -------------------------------------------------------------------
        // FFFF FFFF >> 0
        RsA = `NEG_ONE;
        RsB = 0;
        enter_inputs();
        // Check outputs
        if (Dest !== RsA >> RsB[4:0]) 
        begin 
            $display("-----------------------------");
            $display("Test 4 - Failed");
            $display("%B >> %0D", RsA, RsB[4:0]);
            $display("Expected output: %B", RsA >> RsB[4:0]);
            $display("Actual output:   %B", Dest);
            pass = 1'b0;
        end
        Shifter_reset();
        
        // -------------------------------------------------------------------
        // Test 5
        // -------------------------------------------------------------------
        // FFFF FFFF >> 1
        RsB = 1;
        enter_inputs();
        // Check outputs
        if (Dest !== RsA >> RsB[4:0]) 
        begin 
            $display("-----------------------------");
            $display("Test 5 - Failed");
            $display("%B >> %0D", RsA, RsB[4:0]);
            $display("Expected output: %B", RsA >> RsB[4:0]);
            $display("Actual output:   %B", Dest);
            pass = 1'b0;
        end
        Shifter_reset();
        
        // -------------------------------------------------------------------
        // Test 6
        // -------------------------------------------------------------------
        // FFFF FFFF >> 31
        RsB = 31;
        enter_inputs();
        // Check outputs
        if (Dest !== RsA >> RsB[4:0]) 
        begin 
            $display("-----------------------------");
            $display("Test 6 - Failed");
            $display("%B >> %0D", RsA, RsB[4:0]);
            $display("Expected output: %B", RsA >> RsB[4:0]);
            $display("Actual output:   %B", Dest);
            pass = 1'b0;
        end
        Shifter_reset();
        
        // -------------------------------------------------------------------
        // Test 7
        // -------------------------------------------------------------------
        // 700F F999 >> 16
        RsA = 32'h700FF999;
        RsB = 16;
        enter_inputs();
        // Check outputs
        if (Dest !== RsA >> RsB[4:0]) 
        begin 
            $display("-----------------------------");
            $display("Test 7 - Failed");
            $display("%B >> %0D", RsA, RsB[4:0]);
            $display("Expected output: %B", RsA >> RsB[4:0]);
            $display("Actual output:   %B", Dest);
            pass = 1'b0;
        end
        Shifter_reset();
        
        // -------------------------------------------------------------------
        // Test 8
        // -------------------------------------------------------------------
        // F00F F999 >> 16
        RsA = 32'hF00FF999;
        enter_inputs();
        // Check outputs
        if (Dest !== RsA >> RsB[4:0]) 
        begin 
            $display("-----------------------------");
            $display("Test 8 - Failed");
            $display("%B >> %0D", RsA, RsB[4:0]);
            $display("Expected output: %B", RsA >> RsB[4:0]);
            $display("Actual output:   %B", Dest);
            pass = 1'b0;
        end
        Shifter_reset();
        
        $display("*****************************");
        if (~pass) $display("Test 02 - FAILED");
        else $display("Test 02 - PASSED"); 
    end
endtask

task SRA_Test;
    output pass;
    begin
        $display("*****************************");
        $display("Test 03 - SRA ");
        pass = 1'b1;
        @(posedge clk);
        Op = `SRA;
        
        // -------------------------------------------------------------------
        // Test 1
        // -------------------------------------------------------------------
        // 0000 0001 >>> 0
        RsA = `ONE;
        RsB = 0;
        enter_inputs();
        // Check outputs
        if (Dest !== RsA >>> RsB[4:0]) 
        begin 
            $display("-----------------------------");
            $display("Test 1 - Failed");
            $display("%B >>> %0D", RsA, RsB[4:0]);
            $display("Expected output: %B", RsA >>> RsB[4:0]);
            $display("Actual output:   %B", Dest);
            pass = 1'b0;
        end
        Shifter_reset();
        
        // -------------------------------------------------------------------
        // Test 2
        // -------------------------------------------------------------------
        // 0000 0001 >>> 1
        RsB = 1;
        enter_inputs();
        // Check outputs
        if (Dest !== RsA >>> RsB[4:0]) 
        begin 
            $display("-----------------------------");
            $display("Test 2 - Failed");
            $display("%B >>> %0D", RsA, RsB[4:0]);
            $display("Expected output: %B", RsA >>> RsB[4:0]);
            $display("Actual output:   %B", Dest);
            pass = 1'b0;
        end
        Shifter_reset();
        
        // -------------------------------------------------------------------
        // Test 3
        // -------------------------------------------------------------------
        // 0000 0001 >>> 31
        RsB = 31;
        enter_inputs();
        // Check outputs
        if (Dest !== RsA >>> RsB[4:0]) 
        begin 
            $display("-----------------------------");
            $display("Test 3 - Failed");
            $display("%B >>> %0D", RsA, RsB[4:0]);
            $display("Expected output: %B", RsA >>> RsB[4:0]);
            $display("Actual output:   %B", Dest);
            pass = 1'b0;
        end
        Shifter_reset();
        
        // -------------------------------------------------------------------
        // Test 4
        // -------------------------------------------------------------------
        // FFFF FFFF >>> 0
        RsA = `NEG_ONE;
        RsB = 0;
        enter_inputs();
        // Check outputs
        if (Dest !== RsA >>> RsB[4:0]) 
        begin 
            $display("-----------------------------");
            $display("Test 4 - Failed");
            $display("%B >>> %0D", RsA, RsB[4:0]);
            $display("Expected output: %B", RsA >>> RsB[4:0]);
            $display("Actual output:   %B", Dest);
            pass = 1'b0;
        end
        Shifter_reset();
        
        // -------------------------------------------------------------------
        // Test 5
        // -------------------------------------------------------------------
        // FFFF FFFF >>> 1
        RsB = 1;
        enter_inputs();
        // Check outputs
        if (Dest !== `NEG_ONE) 
        begin 
            $display("-----------------------------");
            $display("Test 5 - Failed");
            $display("%B >>> %0D", RsA, RsB[4:0]);
            $display("Expected output: %B", RsA >>> RsB[4:0]);
            $display("Actual output:   %B", Dest);
            pass = 1'b0;
        end
        Shifter_reset();
        
        // -------------------------------------------------------------------
        // Test 6
        // -------------------------------------------------------------------
        // FFFF FFFF >>> 31
        RsB = 31;
        enter_inputs();
        // Check outputs
        if (Dest !== `NEG_ONE) 
        begin 
            $display("-----------------------------");
            $display("Test 6 - Failed");
            $display("%B >>> %0D", RsA, RsB[4:0]);
            $display("Expected output: %B", RsA >>> RsB[4:0]);
            $display("Actual output:   %B", Dest);
            pass = 1'b0;
        end
        Shifter_reset();
        
        // -------------------------------------------------------------------
        // Test 7
        // -------------------------------------------------------------------
        // 700F F999 >>> 16
        RsA = 32'h700FF999;
        RsB = 16;
        enter_inputs();
        // Check outputs
        if (Dest !== RsA >>> RsB[4:0]) 
        begin 
            $display("-----------------------------");
            $display("Test 7 - Failed");
            $display("%B >>> %0D", RsA, RsB[4:0]);
            $display("Expected output: %B", RsA >>> RsB[4:0]);
            $display("Actual output:   %B", Dest);
            pass = 1'b0;
        end
        Shifter_reset();
        
        // -------------------------------------------------------------------
        // Test 8
        // -------------------------------------------------------------------
        // F00F F999 >>> 16
        RsA = 32'hF00FF999;
        enter_inputs();
        // Check outputs
        if (Dest !== 32'b11111111111111111111000000001111) 
        begin 
            $display("-----------------------------");
            $display("Test 8 - Failed");
            $display("%B >>> %0D", RsA, RsB[4:0]);
            $display("Expected output: %B", RsA >>> RsB[4:0]);
            $display("Actual output:   %B", Dest);
            pass = 1'b0;
        end
        Shifter_reset();
        
        $display("*****************************");
        if (~pass) $display("Test 03 - FAILED");
        else $display("Test 03 - PASSED");
    end
endtask



endmodule