`timescale 10ns / 10ps

// Import instruction definitions and useful values
`include "defines.v"

module ALU_test(
    output reg [7:0] Test_report
);
// Clock                             
reg       clk               = 1'b0;  
always #(`CLOCK_PERIOD/2) clk = ~clk;

wire        sum, slt;
reg         A, B;
reg         ALU_rst, Carry;
reg [3:0]   Op;

ALU ALU (
    .func(Op),
    .opA(A),
    .opB(B),
    .carry_in(Carry),
    .rst(ALU_rst),
    .clk(clk),
    .result(sum),
    .slt(slt)
);

reg [31:0]  RsA, RsB, Dest;
integer     i;

initial
begin
    // Initialise ALU
    Op = 4'b0000;
    Carry = 1'b0;
    A = 1'b0;
    B = 1'b0;
    ALU_reset();
    BASIC_Test(Test_report[7]);
    Op = 4'b0000;
    Carry = 1'b0;
    A = 1'b0;
    B = 1'b0;
    ALU_reset();
    //ADD_Test  (Test_report[6]);
    //SUB_Test  (Test_report[5]);
    SLT_Test  (Test_report[4]);
    //SLTU_Test (Test_report[3]);
    //XOR_Test  (Test_report[2]);
    //OR_Test   (Test_report[1]);
    //AND_Test  (Test_report[0]);
    $display("#############################");
    $display("ALU Test Results : %b", Test_report);
    $display("#############################");
    $stop;
end

task enter_inputs;
    begin
    // Loop through all 32 bits serially
    for (i = 0; i < 32; i = i + 1)
    begin
        if ((Op == `SUB || Op[3:1] == 3'b101) && i == 0) Carry = 1'b1;
        A       = RsA[i];
        B       = RsB[i];
        @(posedge clk);
        Dest[i] = sum;
        Carry = 1'b0;
    end
    if(Op == `SLT || Op == `SLTU) @(posedge clk) Dest[0] = slt;
    end
endtask

task ALU_reset;
    begin
        @(posedge clk);
        ALU_rst = 1'b1;
        @(posedge clk);
        ALU_rst = 1'b0;
    end
endtask

// ***************************************************************************
// Basic 1 bit test of all functions
// Tests for each function of ALU
// ADD
//    A B C_in
// 1. 0 0  0
// 2. 0 0  1
// 3. 0 1  0
// 4. 0 1  1
// 5  1 0  0
// 6. 1 0  1
// 7. 1 1  0
// 8. 1 1  1
// REST
//    A B
// 1. 0 0
// 2. 1 0
// 3. 0 1
// 4. 1 1
reg [3:0] functions [0:4];
reg [3:0] inputs;
reg loop_pass;
task BASIC_Test;
    output pass;
    begin
        $display("*****************************");
        $display("Test 01 - Basic Functions ");
        pass         = 1'b1;
        functions[0] = `ADD;
        functions[1] = `SUB;
        functions[2] = `XOR; 
        functions[3] = `OR; 
        functions[4] = `AND; 
        for (inputs = 0; inputs < 8; inputs = inputs + 1)
            begin
                Op = functions[0];
                loop_pass = 1'b1;
                @(posedge clk);
                A     = inputs[0];
                B     = inputs[1];
                Carry = inputs[2];
                @(posedge clk);
                if (sum != A + B + Carry)
                begin
                    $display("-----------------------------");
                    $display("Test %0d - Failed ", inputs + 1);
                    $display("Function %b", Op);
                    $display("Input:  %b %b %b ", A, B, Carry);
                    $display("Output: %b ", sum);
                    pass      = 1'b0;
                    loop_pass = 1'b0;
                end
            end
        for (i = 1; i < 8; i = i + 1)
        begin
            Op = functions[i];
            for (inputs = 0; inputs < 4; inputs = inputs + 1)
            begin
                loop_pass = 1'b1;
                @(posedge clk);
                A     = inputs[0];
                B     = inputs[1];
                Carry = Op[3];
                @(posedge clk);
                case (Op)
                `SUB:  if(sum != A - B)   loop_pass = 1'b0;
                `XOR:  if(sum != (A ^ B)) loop_pass = 1'b0;
                `OR:   if(sum != (A | B)) loop_pass = 1'b0;
                `AND:  if(sum != (A & B)) loop_pass = 1'b0;
                endcase
                if (~loop_pass)
                begin
                    $display("-----------------------------");
                    $display("Test %0d - Failed ", inputs + 1);
                    $display("Function %b", Op);
                    $display("Input:  %b %b ", A, B);
                    $display("Output: %b ", sum);
                    pass = 1'b0;
                end
            end
        end
        $display("*****************************");
        if (~pass) $display("Test 01 - FAILED");
        else $display("Test 01 - PASSED"); 
    end
endtask

// ***************************************************************************
// Testing ADD function
// Tests:
// 1. 0 + 0
// 2. 0 + 2,147,483,647 (7FFF FFFF)
// 3. 2,147,483,647 (7FFF FFFF) + 2,147,483,647 (7FFF FFFF)
// 4. -1 (FFFF FFFF) + 1
// 5. -2,147,483,648 (8000 000) + -2,147,483,648 (8000 000)
task ADD_Test;
    output pass;
    begin
        $display("*****************************");
        $display("Test 02 - ADD ");
        pass = 1'b1;
        // Set parameters
        @(posedge clk);
        Op = `ADD;
        Carry = 1'b0;
  
        // -------------------------------------------------------------------
        // Test 1
        // -------------------------------------------------------------------
        // 0 + 0
        RsA = `ZERO;
        RsB = `ZERO;
        enter_inputs();
        // Check outputs
        if (Dest !== $signed(RsA) + $signed(RsB)) 
        begin 
            $display("-----------------------------");
            $display("Test 1 - Failed");
            $display("%0D + %0D", $signed(RsA), $signed(RsB));
            $display("Expected output: %0D", $signed(RsA) + $signed(RsB));
            $display("Actual output:   %0D", Dest);
            pass = 1'b0;
        end
        ALU_reset();
        
        // -------------------------------------------------------------------
        // Test 2
        // -------------------------------------------------------------------
        // 0 + 2,147,483,647
        @(posedge clk);
        RsB = `HIGHEST;
        enter_inputs();
        // Check outputs
        if (Dest !== $signed(RsA) + $signed(RsB)) 
        begin 
            $display("-----------------------------");
            $display("Test 2 - Failed");
            $display("%0D + %0D", $signed(RsA), $signed(RsB));
            $display("Expected output: %0D", $signed(RsA) + $signed(RsB));
            $display("Actual output:   %0D", Dest);
            pass = 1'b0;
        end
        ALU_reset();

        // -------------------------------------------------------------------
        // Test 3
        // -------------------------------------------------------------------
        // 2,147,483,647 + 2,147,483,647
        @(posedge clk);
        RsA = `HIGHEST;
        enter_inputs();
        // Check outputs
        if (Dest !== $signed(RsA) + $signed(RsB)) 
        begin 
            $display("-----------------------------");
            $display("Test 3 - Failed");
            $display("%0D + %0D", $signed(RsA), $signed(RsB));
            $display("Expected output: %0D", $signed(RsA) + $signed(RsB));
            $display("Actual output:   %0D", Dest);
            pass = 1'b0;
        end
        ALU_reset();
        
        // -------------------------------------------------------------------
        // Test 4
        // -------------------------------------------------------------------
        // -1 + 1
        @(posedge clk);
        RsA = `NEG_ONE;
        RsB = `ONE;
        enter_inputs();
        // Check outputs
        if (Dest !== $signed(RsA) + $signed(RsB)) 
        begin 
            $display("-----------------------------");
            $display("Test 4 - Failed");
            $display("%0D + %0D", $signed(RsA), $signed(RsB));
            $display("Expected output: %0D", $signed(RsA) + $signed(RsB));
            $display("Actual output:   %0D", Dest);
            pass = 1'b0;
        end
        ALU_reset();
        
        // -------------------------------------------------------------------
        // Test 5
        // -------------------------------------------------------------------
        // -2,147,483,648 + -2,147,483,648
        RsA = `LOWEST;
        RsB = `LOWEST;
        enter_inputs();
        // Check outputs
        if (Dest !== $signed(RsA) + $signed(RsB)) 
        begin 
            $display("-----------------------------");
            $display("Test 5 - Failed");
            $display("%0D + %0D", $signed(RsA), $signed(RsB));
            $display("Expected output: %0D", $signed(RsA) + $signed(RsB));
            $display("Actual output:   %0D", Dest);
            pass = 1'b0;
        end
        ALU_reset();
        
        
        $display("*****************************");
        if (~pass) $display("Test 02 - FAILED");
        else $display("Test 02 - PASSED"); 
        
    end
endtask

// ***************************************************************************
// Testing SUB function
// Tests:
// 1. 0 - 0
// 2. 0 - 2,147,483,647 (7FFF FFFF)
// 3. 2,147,483,647 (7FFF FFFF) - 2,147,483,647 (7FFF FFFF)
// 4. -1 (FFFF FFFF) - 1
// 5. -2,147,483,648 (8000 000) - -2,147,483,648 (8000 000)
task SUB_Test;
    output pass;
    begin
        $display("*****************************");
        $display("Test 03 - SUB ");
        pass = 1'b1;
        // Set parameters
        @(posedge clk);
        Op = `SUB;
        Carry = 1'b0;
  
        // -------------------------------------------------------------------
        // Test 1
        // -------------------------------------------------------------------
        // 0 - 0
        RsA = `ZERO;
        RsB = `ZERO;
        enter_inputs();
        // Check outputs
        if (Dest !== $signed(RsA) - $signed(RsB))  
        begin 
            $display("-----------------------------");
            $display("Test 1 - Failed");
            $display("%0D - %0D", $signed(RsA), $signed(RsB));
            $display("Expected output: %0D", $signed(RsA) - $signed(RsB));
            $display("Actual output:   %0D", Dest);
            pass = 1'b0;
        end
        ALU_reset();
        
        // -------------------------------------------------------------------
        // Test 2
        // -------------------------------------------------------------------
        // 0 - 2,147,483,647
        @(posedge clk);
        RsB = `HIGHEST;
        enter_inputs();
        // Check outputs
        if (Dest !== $signed(RsA) - $signed(RsB))  
        begin 
            $display("-----------------------------");
            $display("Test 2 - Failed");
            $display("%0D - %0D", $signed(RsA), $signed(RsB));
            $display("Expected output: %0D", $signed(RsA) - $signed(RsB));
            $display("Actual output:   %0D", Dest);
            pass = 1'b0;
        end
        ALU_reset();

        // -------------------------------------------------------------------
        // Test 3
        // -------------------------------------------------------------------
        // 2,147,483,647 - 2,147,483,647
        @(posedge clk);
        RsA = `HIGHEST;
        enter_inputs();
        // Check outputs
        if (Dest !== $signed(RsA) - $signed(RsB))  
        begin 
            $display("-----------------------------");
            $display("Test 3 - Failed");
            $display("%0D - %0D", $signed(RsA), $signed(RsB));
            $display("Expected output: %0D", $signed(RsA) - $signed(RsB));
            $display("Actual output:   %0D", Dest);
            pass = 1'b0;
        end
        ALU_reset();
        
        // -------------------------------------------------------------------
        // Test 4
        // -------------------------------------------------------------------
        // -1 - 1
        @(posedge clk);
        RsA = `NEG_ONE;
        RsB = `ONE;
        enter_inputs();
        // Check outputs
        if (Dest !== $signed(RsA) - $signed(RsB))  
        begin 
            $display("-----------------------------");
            $display("Test 4 - Failed");
            $display("%0D - %0D", $signed(RsA), $signed(RsB));
            $display("Expected output: %0D", $signed(RsA) - $signed(RsB));
            $display("Actual output:   %0D", Dest);
            pass = 1'b0;
        end
        ALU_reset();
        
        // -------------------------------------------------------------------
        // Test 5
        // -------------------------------------------------------------------
        // -2,147,483,648 - -2,147,483,648
        RsA = `LOWEST;
        RsB = `LOWEST;
        enter_inputs();
        // Check outputs
        if (Dest !== $signed(RsA) - $signed(RsB)) 
        begin 
            $display("-----------------------------");
            $display("Test 5 - Failed");
            $display("%0D - %0D", $signed(RsA), $signed(RsB));
            $display("Expected output: %0D", $signed(RsA) - $signed(RsB));
            $display("Actual output:   %0D", Dest);
            pass = 1'b0;
        end
        ALU_reset();
        
        
        $display("*****************************");
        if (~pass) $display("Test 03 - FAILED");
        else $display("Test 03 - PASSED");  
    end
endtask

// ***************************************************************************
// Testing SLT function
// Tests:
// 1. 0 < 0
// 2. 0 < 2,147,483,647 (7FFF FFFF)
// 3. 2,147,483,647 (7FFF FFFF) < 2,147,483,647 (7FFF FFFF)
// 4. -1 (FFFF FFFF) < 1
// 5. 0 < 1
// 6. 1 < 1
// 7. 0 < -1 (FFFF FFFF)
task SLT_Test;
    output pass;
    begin
        $display("*****************************");
        $display("Test 04 - SLT ");
        pass = 1'b1;
        // Set parameters
        @(posedge clk);
        Op = `SLT;
        Carry = 1'b0;
  
        // -------------------------------------------------------------------
        // Test 1
        // -------------------------------------------------------------------
        // 0 < 0
        RsA = `ZERO;
        RsB = `ZERO;
        enter_inputs();
        // Check outputs
        if (Dest !== `ZERO) 
        begin 
            $display("-----------------------------");
            $display("Test 1 - Failed");
            $display("%0D < %0D", $signed(RsA), $signed(RsB));
            $display("Expected output: %0D", `ZERO);
            $display("Actual output:   %0D", Dest);
            pass = 1'b0;
        end
        ALU_reset();
        
        // -------------------------------------------------------------------
        // Test 2
        // -------------------------------------------------------------------
        // 0 < 2,147,483,647
        @(posedge clk);
        RsB = `HIGHEST;
        enter_inputs();
        // Check outputs
        if (Dest !== `ONE) 
        begin 
            $display("-----------------------------");
            $display("Test 2 - Failed");
            $display("%0D < %0D", $signed(RsA), $signed(RsB));
            $display("Expected output: %0D", `ONE);
            $display("Actual output:   %0D", Dest);
            pass = 1'b0;
        end
        ALU_reset();

        // -------------------------------------------------------------------
        // Test 3
        // -------------------------------------------------------------------
        // 2,147,483,647 < 2,147,483,647
        @(posedge clk);
        RsA = `HIGHEST;
        enter_inputs();
        // Check outputs
        if (Dest !== `ZERO) 
        begin 
            $display("-----------------------------");
            $display("Test 3 - Failed");
            $display("%0D < %0D", $signed(RsA), $signed(RsB));
            $display("Expected output: %0D", `ZERO);
            $display("Actual output:   %0D", Dest);
            pass = 1'b0;
        end
        ALU_reset();
        
        // -------------------------------------------------------------------
        // Test 4
        // -------------------------------------------------------------------
        // -1 < 1
        @(posedge clk);
        RsA = `NEG_ONE;
        RsB = `ONE;
        enter_inputs();
        // Check outputs
        if (Dest !== `ONE) 
        begin 
            $display("-----------------------------");
            $display("Test 4 - Failed");
            $display("%0D < %0D", $signed(RsA), $signed(RsB));
            $display("Expected output: %0D", `ONE);
            $display("Actual output:   %0D", Dest);
            pass = 1'b0;
        end
        ALU_reset();
        
        // -------------------------------------------------------------------
        // Test 5
        // -------------------------------------------------------------------
        // 0 < 1
        RsA = `ZERO;
        RsB = `ONE;
        enter_inputs();
        // Check outputs
        if (Dest !== `ONE) 
        begin 
            $display("-----------------------------");
            $display("Test 5 - Failed");
            $display("%0D < %0D", $signed(RsA), $signed(RsB));
            $display("Expected output: %0D", `ONE);
            $display("Actual output:   %0D", Dest);
            pass = 1'b0;
        end
        ALU_reset();
        
        // -------------------------------------------------------------------
        // Test 6
        // -------------------------------------------------------------------
        // 1 < 1
        RsA = `ONE;
        enter_inputs();
        // Check outputs
        if (Dest !== `ZERO) 
        begin 
            $display("-----------------------------");
            $display("Test 6 - Failed");
            $display("%0D < %0D", $signed(RsA), $signed(RsB));
            $display("Expected output: %0D", `ZERO);
            $display("Actual output:   %0D", Dest);
            pass = 1'b0;
        end
        ALU_reset();
        
        // -------------------------------------------------------------------
        // Test 7
        // -------------------------------------------------------------------
        // 0 < -1
        @(posedge clk);
        RsA = `ZERO;
        RsB = `NEG_ONE;
        enter_inputs();
        // Check outputs
        if (Dest !== `ZERO) 
        begin 
            $display("-----------------------------");
            $display("Test 7 - Failed");
            $display("%0D < %0D", $signed(RsA), $signed(RsB));
            $display("Expected output: %0D", `ZERO);
            $display("Actual output:   %0D", Dest);
            pass = 1'b0;
        end
        ALU_reset();
        
        // -------------------------------------------------------------------
        // Test 8
        // -------------------------------------------------------------------
        // 10 < 10
        @(posedge clk);
        RsA = 10;
        RsB = 10;
        enter_inputs();
        // Check outputs
        if (Dest !== `ZERO) 
        begin 
            $display("-----------------------------");
            $display("Test 8 - Failed");
            $display("%0D < %0D", $signed(RsA), $signed(RsB));
            $display("Expected output: %0D", `ZERO);
            $display("Actual output:   %0D", Dest);
            pass = 1'b0;
        end
        ALU_reset();
                
        $display("*****************************");
        if (~pass) $display("Test 04 - FAILED");
        else $display("Test 04 - PASSED"); 
    end
endtask

// ***************************************************************************
// Testing SLTU function
// Tests:
// 1. 0 < 0
// 2. 0 < 4,294,967,295 (FFFF FFFF)
// 3. 2,147,483,647 (7FFF FFFF) < 4,294,967,295 (FFFF FFFF)
// 4. 4,294,967,295 (FFFF FFFF) < 1
// 5. 4,294,967,295 (FFFF FFFF) < 0
task SLTU_Test;
    output pass;
    begin
        $display("*****************************");
        $display("Test 05 - SLTU ");
        pass = 1'b1;
        // Set parameters
        @(posedge clk);
        Op = `SLTU;
        Carry = 1'b0;
  
        // -------------------------------------------------------------------
        // Test 1
        // -------------------------------------------------------------------
        // 0 < 0
        RsA = `ZERO;
        RsB = `ZERO;
        enter_inputs();
        // Check outputs
        if (Dest !== `ZERO) 
        begin 
            $display("-----------------------------");
            $display("Test 1 - Failed");
            $display("%0D < %0D", RsA, RsB);
            $display("Expected output: %0D", `ZERO);
            $display("Actual output:   %0D", Dest);
            pass = 1'b0;
        end
        ALU_reset();
        
        // -------------------------------------------------------------------
        // Test 2
        // -------------------------------------------------------------------
        // 0 < 2,147,483,647
        @(posedge clk);
        RsB = `NEG_ONE;
        enter_inputs();
        // Check outputs
        if (Dest !== `ONE) 
        begin 
            $display("-----------------------------");
            $display("Test 2 - Failed");
            $display("%0D < %0D", RsA, RsB);
            $display("Expected output: %0D", `ONE);
            $display("Actual output:   %0D", Dest);
            pass = 1'b0;
        end
        ALU_reset();

        // -------------------------------------------------------------------
        // Test 3
        // -------------------------------------------------------------------
        // 2,147,483,647 < 4,294,967,295
        @(posedge clk);
        RsA = `HIGHEST;
        enter_inputs();
        // Check outputs
        if (Dest !== `ONE) 
        begin 
            $display("-----------------------------");
            $display("Test 3 - Failed");
            $display("%0D < %0D", RsA, RsB);
            $display("Expected output: %0D", `ONE);
            $display("Actual output:   %0D", Dest);
            pass = 1'b0;
        end
        ALU_reset();
        
        // -------------------------------------------------------------------
        // Test 4
        // -------------------------------------------------------------------
        // 4,294,967,295 < 1
        @(posedge clk);
        RsA = `NEG_ONE;
        RsB = `ONE;
        enter_inputs();
        // Check outputs
        if (Dest !== `ZERO) 
        begin 
            $display("-----------------------------");
            $display("Test 4 - Failed");
            $display("%0D < %0D", RsA, RsB);
            $display("Expected output: %0D", `ZERO);
            $display("Actual output:   %0D", Dest);
            pass = 1'b0;
        end
        ALU_reset();
        
        // -------------------------------------------------------------------
        // Test 5
        // -------------------------------------------------------------------
        // 0 < 1
        RsB = `ZERO;
        enter_inputs();
        // Check outputs
        if (Dest !== `ZERO) 
        begin 
            $display("-----------------------------");
            $display("Test 5 - Failed");
            $display("%0D < %0D", RsA, RsB);
            $display("Expected output: %0D", `ZERO);
            $display("Actual output:   %0D", Dest);
            pass = 1'b0;
        end
        ALU_reset();
        
        $display("*****************************");
        if (~pass) $display("Test 05 - FAILED");
        else $display("Test 05 - PASSED"); 
    end
endtask

// ***************************************************************************
// Testing XOR function
// Tests:
// 1. 0 ^ 0
// 2. 0 ^ 4,294,967,295 (FFFF FFFF)
// 3. 4,294,967,295 (FFFF FFFF) ^ 4,294,967,295 (FFFF FFFF)
// 4. 2,147,483,647 (7FFF FFFF) ^ 4,294,967,295 (FFFF FFFF)
// 5. 4,294,967,295 (FFFF FFFF) ^ 1
task XOR_Test;
    output pass;
    begin
        $display("*****************************");
        $display("Test 06 - XOR ");
        pass = 1'b1;
        // Set parameters
        @(posedge clk);
        Op = `XOR;
        Carry = 1'b0;
  
        // -------------------------------------------------------------------
        // Test 1
        // -------------------------------------------------------------------
        // 0 ^ 0
        RsA = `ZERO;
        RsB = `ZERO;
        enter_inputs();
        // Check outputs
        if (Dest !== (RsA ^ RsB)) 
        begin 
            $display("-----------------------------");
            $display("Test 1 - Failed");
            $display("%H ^ %H", RsA, RsB);
            $display("Expected output: %H", RsA ^ RsB);
            $display("Actual output:   %H", Dest);
            pass = 1'b0;
        end
        ALU_reset();
        
        // -------------------------------------------------------------------
        // Test 2
        // -------------------------------------------------------------------
        // 0 ^ 4,294,967,295
        @(posedge clk);
        RsB = `NEG_ONE;
        enter_inputs();
        // Check outputs
        if (Dest !== (RsA ^ RsB)) 
        begin 
            $display("-----------------------------");
            $display("Test 2 - Failed");
            $display("%H ^ %H", RsA, RsB);
            $display("Expected output: %H", RsA ^ RsB);
            $display("Actual output:   %H", Dest);
            pass = 1'b0;
        end
        ALU_reset();

        // -------------------------------------------------------------------
        // Test 3
        // -------------------------------------------------------------------
        // 4,294,967,295 ^ 4,294,967,295
        @(posedge clk);
        RsA = `NEG_ONE;
        enter_inputs();
        // Check outputs
        if (Dest !== (RsA ^ RsB)) 
        begin 
            $display("-----------------------------");
            $display("Test 3 - Failed");
            $display("%H ^ %H", RsA, RsB);
            $display("Expected output: %H", RsA ^ RsB);
            $display("Actual output:   %H", Dest);
            pass = 1'b0;
        end
        ALU_reset();
        
        // -------------------------------------------------------------------
        // Test 4
        // -------------------------------------------------------------------
        // 2,147,483,647 ^ 4,294,967,295
        @(posedge clk);
        RsA = `HIGHEST;
        enter_inputs();
        // Check outputs
        if (Dest !== (RsA ^ RsB)) 
        begin 
            $display("-----------------------------");
            $display("Test 4 - Failed");
            $display("%H ^ %H", RsA, RsB);
            $display("Expected output: %H", RsA ^ RsB);
            $display("Actual output:   %H", Dest);
            pass = 1'b0;
        end
        ALU_reset();
        
        // -------------------------------------------------------------------
        // Test 5
        // -------------------------------------------------------------------
        // 0 ^ 1
        RsB = `ONE;
        enter_inputs();
        // Check outputs
        if (Dest !== (RsA ^ RsB)) 
        begin 
            $display("-----------------------------");
            $display("Test 5 - Failed");
            $display("%H ^ %H", RsA, RsB);
            $display("Expected output: %H", RsA ^ RsB);
            $display("Actual output:   %H", Dest);
            pass = 1'b0;
        end
        ALU_reset();
        
        $display("*****************************");
        if (~pass) $display("Test 06 - FAILED");
        else $display("Test 06 - PASSED");  
    end
endtask

// ***************************************************************************
// Testing OR function
// Tests:
// 1. 0 | 0
// 2. 0 | 4,294,967,295 (FFFF FFFF)
// 3. 4,294,967,295 (FFFF FFFF) | 4,294,967,295 (FFFF FFFF)
// 4. 2,147,483,647 (7FFF FFFF) | 4,294,967,295 (FFFF FFFF)
// 5. 4,294,967,295 (FFFF FFFF) | 1
task OR_Test;
    output pass;
    begin
        $display("*****************************");
        $display("Test 07 - OR ");
        pass = 1'b1;
        // Set parameters
        @(posedge clk);
        Op = `OR;
        Carry = 1'b0;
  
        // -------------------------------------------------------------------
        // Test 1
        // -------------------------------------------------------------------
        // 0 | 0
        RsA = `ZERO;
        RsB = `ZERO;
        enter_inputs();
        // Check outputs
        if (Dest !== (RsA | RsB)) 
        begin 
            $display("-----------------------------");
            $display("Test 1 - Failed");
            $display("%H | %H", RsA, RsB);
            $display("Expected output: %H", RsA | RsB);
            $display("Actual output:   %H", Dest);
            pass = 1'b0;
        end
        ALU_reset();
        
        // -------------------------------------------------------------------
        // Test 2
        // -------------------------------------------------------------------
        // 0 | 4,294,967,295
        @(posedge clk);
        RsB = `NEG_ONE;
        enter_inputs();
        // Check outputs
        if (Dest !== (RsA | RsB)) 
        begin 
            $display("-----------------------------");
            $display("Test 2 - Failed");
            $display("%H | %H", RsA, RsB);
            $display("Expected output: %H", RsA | RsB);
            $display("Actual output:   %H", Dest);
            pass = 1'b0;
        end
        ALU_reset();

        // -------------------------------------------------------------------
        // Test 3
        // -------------------------------------------------------------------
        // 4,294,967,295 | 4,294,967,295
        @(posedge clk);
        RsA = `NEG_ONE;
        enter_inputs();
        // Check outputs
        if (Dest !== (RsA | RsB)) 
        begin 
            $display("-----------------------------");
            $display("Test 3 - Failed");
            $display("%H | %H", RsA, RsB);
            $display("Expected output: %H", RsA | RsB);
            $display("Actual output:   %H", Dest);
            pass = 1'b0;
        end
        ALU_reset();
        
        // -------------------------------------------------------------------
        // Test 4
        // -------------------------------------------------------------------
        // 2,147,483,647 | 4,294,967,295
        @(posedge clk);
        RsA = `HIGHEST;
        enter_inputs();
        // Check outputs
        if (Dest !== (RsA | RsB)) 
        begin
            $display("-----------------------------");
            $display("Test 4 - Failed");
            $display("%H | %H", RsA, RsB);
            $display("Expected output: %H", RsA | RsB);
            $display("Actual output:   %H", Dest);
            pass = 1'b0;
        end
        ALU_reset();
        
        // -------------------------------------------------------------------
        // Test 5
        // -------------------------------------------------------------------
        // 0 | 1
        RsB = `ONE;
        enter_inputs();
        // Check outputs
        if (Dest !== (RsA | RsB)) 
        begin 
            $display("-----------------------------");
            $display("Test 5 - Failed");
            $display("%H | %H", RsA, RsB);
            $display("Expected output: %H", RsA | RsB);
            $display("Actual output:   %H", Dest);
            pass = 1'b0;
        end
        ALU_reset();
        
        $display("*****************************");
        if (~pass) $display("Test 07 - FAILED");
        else $display("Test 07 - PASSED"); 
    end
endtask

// ***************************************************************************
// Testing AND function
// Tests:
// 1. 0 & 0
// 2. 0 & 4,294,967,295 (FFFF FFFF)
// 3. 4,294,967,295 (FFFF FFFF) & 4,294,967,295 (FFFF FFFF)
// 4. 2,147,483,647 (7FFF FFFF) & 4,294,967,295 (FFFF FFFF)
// 5. 4,294,967,295 (FFFF FFFF) & 1
task AND_Test;
    output pass;
    begin
        $display("*****************************");
        $display("Test 08 - AND ");
        pass = 1'b1;
        // Set parameters
        @(posedge clk);
        Op = `AND;
        Carry = 1'b0;
  
        // -------------------------------------------------------------------
        // Test 1
        // -------------------------------------------------------------------
        // 0 & 0
        RsA = `ZERO;
        RsB = `ZERO;
        enter_inputs();
        // Check outputs
        if (Dest !== (RsA & RsB)) 
        begin 
            $display("-----------------------------");
            $display("Test 1 - Failed");
            $display("%H & %H", RsA, RsB);
            $display("Expected output: %H", RsA & RsB);
            $display("Actual output:   %H", Dest);
            pass = 1'b0;
        end
        ALU_reset();
        
        // -------------------------------------------------------------------
        // Test 2
        // -------------------------------------------------------------------
        // 0 & 4,294,967,295
        @(posedge clk);
        RsB = `NEG_ONE;
        enter_inputs();
        // Check outputs
        if (Dest !== (RsA & RsB)) 
        begin 
            $display("-----------------------------");
            $display("Test 2 - Failed");
            $display("%H & %H", RsA, RsB);
            $display("Expected output: %H", RsA & RsB);
            $display("Actual output:   %H", Dest);
            pass = 1'b0;
        end
        ALU_reset();

        // -------------------------------------------------------------------
        // Test 3
        // -------------------------------------------------------------------
        // 4,294,967,295 & 4,294,967,295
        @(posedge clk);
        RsA = `NEG_ONE;
        enter_inputs();
        // Check outputs
        if (Dest !== (RsA & RsB)) 
        begin 
            $display("-----------------------------");
            $display("Test 3 - Failed");
            $display("%H & %H", RsA, RsB);
            $display("Expected output: %H", RsA & RsB);
            $display("Actual output:   %H", Dest);
            pass = 1'b0;
        end
        ALU_reset();
        
        // -------------------------------------------------------------------
        // Test 4
        // -------------------------------------------------------------------
        // 2,147,483,647 & 4,294,967,295
        @(posedge clk);
        RsA = `HIGHEST;
        enter_inputs();
        // Check outputs
        if (Dest !== (RsA & RsB)) 
        begin 
            $display("-----------------------------");
            $display("Test 4 - Failed");
            $display("%H & %H", RsA, RsB);
            $display("Expected output: %H", RsA & RsB);
            $display("Actual output:   %H", Dest);
            pass = 1'b0;
        end
        ALU_reset();
        
        // -------------------------------------------------------------------
        // Test 5
        // -------------------------------------------------------------------
        // 0 & 1
        RsB = `ONE;
        enter_inputs();
        // Check outputs
        if (Dest !== (RsA & RsB)) 
        begin
            $display("-----------------------------");
            $display("Test 5 - Failed");
            $display("%H & %H", RsA, RsB);
            $display("Expected output: %H", RsA & RsB);
            $display("Actual output:   %H", Dest);
            pass = 1'b0;
        end
        ALU_reset();
        
        $display("*****************************");
        if (~pass) $display("Test 08 - FAILED");
        else $display("Test 08 - PASSED"); 
    end
endtask

endmodule