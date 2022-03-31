`timescale 10ns / 10ps

// Import instruction definitions and useful values
`include "defines.v"

module Data_Serialiser_test(
    output reg [7:0] Test_report
);
// Clock                             
reg       clk               = 1'b0;  
always #(`CLOCK_PERIOD/2) clk = ~clk;

// Serialiser wires
wire [31:0] data_in_bus, data_out_bus;
wire [9:0]  address_out_bus;
wire [4:0]  bitPos;
wire        data_out_bit, mem_misaligned;

// Registers
reg  [31:0] Memory_in, Memory_out, Register_in, Register_out;
reg  [11:0] Register_address;
reg  [9:0]  Memory_address;
integer     Count, i;
reg  [2:0]  Op;
reg         Data_in_bit, Mode, Memory_error;

assign                bitPos                    = Count[4:0];          
assign                data_in_bus               = Memory_out;

always @(posedge clk) Register_in[Count[4:0]]   = data_out_bit;

always @(posedge clk) Memory_error = Memory_error | mem_misaligned;
  
// Initiliase serialiser/deserialiser
Data_Serialiser Data_Serialiser(
    .data_in_bus(data_in_bus),
    .data_out_bus(data_out_bus),
    .address_out_bus(address_out_bus), // Limited to 10 bits due to size of memory
    .bitPos(bitPos),
    .func(Op),
    .data_in_bit(Data_in_bit),
    .mode(Mode),
    .clk(clk),
    .data_out_bit(data_out_bit),
    .mem_misaligned(mem_misaligned)
    );
    
//always @(posedge start)
initial
begin
    // Initialise Serialiser/Deserialiser
    Op               = 3'b000;
    Memory_in        = 32'h00000000;
    Memory_out       = 32'h00000000;
    Register_in      = 32'h00000000;
    Register_out     = 32'h00000000;
    Memory_address   = 10'h000;
    Register_address = 12'h000;
    Data_in_bit      = 1'b0;
    Mode             = 1'b0;
    Memory_error     = 1'b0;
    LB_Test (Test_report[7]);
    LH_Test (Test_report[6]);
    LW_Test (Test_report[5]);
    LBU_Test(Test_report[4]);
    LHU_Test(Test_report[3]);
    SB_Test (Test_report[2]);
    SH_Test (Test_report[1]);
    SW_Test (Test_report[0]);
    $display("#############################");
    $display("Serialiser Test Results : %b", Test_report);
    $display("#############################");
    $stop;
end

task input_address;
    begin
    Memory_error = 1'b0;
    Mode = 1'b1;
    @(posedge clk);
    for (Count = 0; Count < 12; Count = Count + 1)
        @(posedge clk) Data_in_bit = Register_address[Count];
    @(posedge clk) Mode = 1'b0;
    Memory_address = address_out_bus;
    end
endtask

task load;
    begin
    input_address();
    if (~Memory_error)
    for (Count = 0; Count < 32; Count = Count + 1)
        @(posedge clk) Register_in[Count] = data_out_bit;
    end
endtask

task store;
    begin
    input_address();
    if (~Memory_error)
    for (Count = 0; Count < 32; Count = Count + 1)
        @(posedge clk) Data_in_bit = Register_out[Count];
    @(posedge clk) Memory_in = data_out_bus;
    end
endtask

// ***************************************************************************
// Testing LB function
// Tests:
// 1. 8'hFF at 0
// 2. 8'hFF at 1
// 3. 8'hFF at 2
// 4. 8'hFF at 3
// 5. 8'h76 at 4
// 6. 8'h76 at 5
// 7. 8'h76 at 6
// 8. 8'h76 at 7
task LB_Test;
    output pass;
    begin
        $display("*****************************");
        $display("Test 01 - LB ");
        pass = 1'b1;
        @(posedge clk);
        Op = `LB;
        for (i = 0; i < 8; i = i + 1)
        begin
            if (i < 4) Memory_out = 32'h000000FF << i*8;
            else       Memory_out = 32'h00000076 << (i%4)*8;
            
            Register_address = i;
            
            load();
            
            if(Memory_error || (Memory_address !== Register_address[11:2]))
            begin
                $display("-----------------------------");
                $display("Test %0D - Failed", i + 1);
                $display("Memory error ");
                $display("Expected: %B", Register_address[11:2]);
                $display("Actual:   %B", Memory_address);
                pass = 1'b0;
            end
            else if (Register_in !== (i < 4 ? 32'hFFFFFFFF : 32'h00000076)) 
            begin 
                $display("-----------------------------");
                $display("Test %0D - Failed", i + 1);
                $display("Expected output: %H", (i < 4 ? 32'hFFFFFFFF : 32'h00000076));
                $display("Actual output:   %H", Register_in);
                pass = 1'b0;
            end
        end
    end
endtask

// ***************************************************************************
// Testing LH function
// Tests:
// 1. 16'hFFFF at 0
// 2. 16'hFFFF at 2
// 3. 16'h7006 at 4
// 4. 16'h7006 at 6
task LH_Test;
    output pass;
    begin
        $display("*****************************");
        $display("Test 02 - LH ");
        pass = 1'b1;
        @(posedge clk);
        Op = `LH;
        for (i = 0; i < 8; i = i + 2)
        begin
            if (i < 4) Memory_out = 32'h0000FFFF << i*8;
            else       Memory_out = 32'h00007006 << (i%4)*8;
            
            Register_address = i;
            
            load();
            
            if(Memory_error || (Memory_address !== Register_address[11:2]))
            begin
                $display("-----------------------------");
                $display("Test %0D - Failed", i/2 + 1);
                $display("Memory error ");
                $display("Expected: %B", Register_address[11:2]);
                $display("Actual:   %B", Memory_address);
                pass = 1'b0;
            end
            else if (Register_in !== (i < 4 ? 32'hFFFFFFFF : 32'h00007006)) 
            begin 
                $display("-----------------------------");
                $display("Test %0D - Failed", i/2 + 1);
                $display("Expected output: %H", (i < 4 ? 32'hFFFFFFFF : 32'h00007006));
                $display("Actual output:   %H", Register_in);
                pass = 1'b0;
            end
        end
    end
endtask

// ***************************************************************************
// Testing LW function
// Tests:
// 1. 16'hFFFF at 0
// 2. 16'hFFFF at 2
// 3. 16'h7006 at 4
// 4. 16'h7006 at 6
task LW_Test;
    output pass;
    begin
        $display("*****************************");
        $display("Test 03 - LW ");
        pass = 1'b1;
        @(posedge clk);
        Op = `LW;
        for (i = 0; i < 8; i = i + 4)
        begin
            if (i < 4) Memory_out = 32'hF000000F;
            else       Memory_out = 32'h00008006;
            
            Register_address = i;
            
            load();
            
            if(Memory_error || (Memory_address !== Register_address[11:2]))
            begin
                $display("-----------------------------");
                $display("Test %0D - Failed", i/4 + 1);
                $display("Memory error ");
                $display("Expected: %B", Register_address[11:2]);
                $display("Actual:   %B", Memory_address);
                pass = 1'b0;
            end
            else if (Register_in !== (i < 4 ? 32'hF000000F : 32'h00008006)) 
            begin 
                $display("-----------------------------");
                $display("Test %0D - Failed", i/4 + 1);
                $display("Expected output: %H", (i < 4 ? 32'hF000000F : 32'h00008006));
                $display("Actual output:   %H", Register_in);
                pass = 1'b0;
            end
        end
    end
endtask

// ***************************************************************************
// Testing LBU function
// Tests:
// 1. 8'hFF at 0
// 2. 8'hFF at 1
// 3. 8'hFF at 2
// 4. 8'hFF at 3
// 5. 8'h76 at 4
// 6. 8'h76 at 5
// 7. 8'h76 at 6
// 8. 8'h76 at 7
task LBU_Test;
    output pass;
    begin
        $display("*****************************");
        $display("Test 04 - LBU ");
        pass = 1'b1;
        @(posedge clk);
        Op = `LBU;
        for (i = 0; i < 8; i = i + 1)
        begin
            if (i < 4) Memory_out = 32'h000000FF << i*8;
            else       Memory_out = 32'h00000076 << (i%4)*8;
            
            Register_address = i;
            
            load();
            
            if(Memory_error || (Memory_address !== Register_address[11:2]))
            begin
                $display("-----------------------------");
                $display("Test %0D - Failed", i + 1);
                $display("Memory error ");
                $display("Expected: %B", Register_address[11:2]);
                $display("Actual:   %B", Memory_address);
                pass = 1'b0;
            end
            else if (Register_in !== (i < 4 ? 32'h000000FF : 32'h00000076)) 
            begin 
                $display("-----------------------------");
                $display("Test %0D - Failed", i + 1);
                $display("Expected output: %H", (i < 4 ? 32'h000000FF : 32'h00000076));
                $display("Actual output:   %H", Register_in);
                pass = 1'b0;
            end
        end
    end
endtask

// ***************************************************************************
// Testing LHU function
// Tests:
// 1. 16'hFFFF at 0
// 2. 16'hFFFF at 2
// 3. 16'h7006 at 4
// 4. 16'h7006 at 6
task LHU_Test;
    output pass;
    begin
        $display("*****************************");
        $display("Test 05 - LHU ");
        pass = 1'b1;
        @(posedge clk);
        Op = `LHU;
        for (i = 0; i < 8; i = i + 2)
        begin
            if (i < 4) Memory_out = 32'h0000FFFF << i*8;
            else       Memory_out = 32'h00007006 << (i%4)*8;
            
            Register_address = i;
            
            load();
            
            if(Memory_error || (Memory_address !== Register_address[11:2]))
            begin
                $display("-----------------------------");
                $display("Test %0D - Failed", i/2 + 1);
                $display("Memory error ");
                $display("Expected: %B", Register_address[11:2]);
                $display("Actual:   %B", Memory_address);
                pass = 1'b0;
            end
            else if (Register_in !== (i < 4 ? 32'h0000FFFF : 32'h00007006)) 
            begin 
                $display("-----------------------------");
                $display("Test %0D - Failed", i/2 + 1);
                $display("Expected output: %H", (i < 4 ? 32'h0000FFFF : 32'h00007006));
                $display("Actual output:   %H", Register_in);
                pass = 1'b0;
            end
        end
    end
endtask

// ***************************************************************************
// Testing SB function
// Tests:
// 1. 8'hFF at 0
// 2. 8'hFF at 1
// 3. 8'hFF at 2
// 4. 8'hFF at 3
// 5. 8'h76 at 4
// 6. 8'h76 at 5
// 7. 8'h76 at 6
// 8. 8'h76 at 7
task SB_Test;
    output pass;
    begin
        $display("*****************************");
        $display("Test 06 - SB ");
        pass = 1'b1;
        @(posedge clk);
        Op = `SB;
        for (i = 0; i < 8; i = i + 1)
        begin
            if (i < 4) Register_out = 32'h000000FF;
            else       Register_out = 32'h00000076;
            
            Register_address = i;
            
            store();
            
            if(Memory_error || (Memory_address !== Register_address[11:2]))
            begin
                $display("-----------------------------");
                $display("Test %0D - Failed", i + 1);
                $display("Memory error ");
                $display("Expected: %B", Register_address[11:2]);
                $display("Actual:   %B", Memory_address);
                pass = 1'b0;
            end
            else if (Memory_in !== (i < 4 ? 32'h000000FF << i*8 : 32'h00000076 << (i%4)*8)) 
            begin 
                $display("-----------------------------");
                $display("Test %0D - Failed", i + 1);
                $display("Expected output: %H", (i < 4 ? 32'h000000FF << i*8 : 32'h00000076 << (i%4)*8));
                $display("Actual output:   %H", Memory_in);
                pass = 1'b0;
            end
        end
    end
endtask

// ***************************************************************************
// Testing SH function
// Tests:
// 1. 16'hFFFF at 0
// 2. 16'hFFFF at 2
// 3. 16'h7006 at 4
// 4. 16'h7006 at 6
task SH_Test;
    output pass;
    begin
        $display("*****************************");
        $display("Test 07 - SH ");
        pass = 1'b1;
        @(posedge clk);
        Op = `SH;
        for (i = 0; i < 8; i = i + 2)
        begin
            if (i < 4) Register_out = 32'h0000FFFF;
            else       Register_out = 32'h00007006;
            
            Register_address = i;
            
            store();
            
            if(Memory_error || (Memory_address !== Register_address[11:2]))
            begin
                $display("-----------------------------");
                $display("Test %0D - Failed", i/2 + 1);
                $display("Memory error ");
                $display("Expected: %B", Register_address[11:2]);
                $display("Actual:   %B", Memory_address);
                pass = 1'b0;
            end
            else if (Memory_in !== (i < 4 ? 32'h0000FFFF << i*8 : 32'h00007006 << (i%4)*8)) 
            begin 
                $display("-----------------------------");
                $display("Test %0D - Failed", i/2 + 1);
                $display("Expected output: %H", (i < 4 ? 32'h0000FFFF << i*8 : 32'h00007006 << (i%4)*8));
                $display("Actual output:   %H", Memory_in);
                pass = 1'b0;
            end
        end
    end
endtask

// ***************************************************************************
// Testing SW function
// Tests:
// 1. 16'hFFFF at 0
// 2. 16'hFFFF at 2
// 3. 16'h7006 at 4
// 4. 16'h7006 at 6
task SW_Test;
    output pass;
    begin
        $display("*****************************");
        $display("Test 08 - SW ");
        pass = 1'b1;
        @(posedge clk);
        Op = `SW;
        for (i = 0; i < 8; i = i + 4)
        begin
            if (i < 4) Register_out = 32'hF000000F;
            else       Register_out = 32'h00008006;
            
            Register_address = i;
            
            store();
            
            if(Memory_error || (Memory_address !== Register_address[11:2]))
            begin
                $display("-----------------------------");
                $display("Test %0D - Failed", i/4 + 1);
                $display("Memory error ");
                $display("Expected: %B", Register_address[11:2]);
                $display("Actual:   %B", Memory_address);
                pass = 1'b0;
            end
            else if (Memory_in !== (i < 4 ? 32'hF000000F : 32'h00008006)) 
            begin 
                $display("-----------------------------");
                $display("Test %0D - Failed", i/4 + 1);
                $display("Expected output: %H", (i < 4 ? 32'hF000000F : 32'h00008006));
                $display("Actual output:   %H", Memory_in);
                pass = 1'b0;
            end
        end
    end
endtask

endmodule
