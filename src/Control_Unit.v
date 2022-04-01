`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/21/2022 11:18:54 AM
// Design Name: 
// Module Name: Control_Unit
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
`include "ISA.v"
`include "Multiplexers.v"

module Control_Unit(
    input [31:0]        instruction,
    input               rst,
    input               clk,
    input               bru_result,
    input               alu_result,
    input               shift_output_en,
    input               memory_misaligned,
    output reg [31:0]   pc,
    output              immediate, 
    output     [5:0]    bit_position,
    output reg [3:0]    mem_mask,
    output reg [3:0]    op,
    output reg [1:0]    bru_op,
    output     [4:0]    regA,
    output     [4:0]    regB,
    output reg          reg_we,
    output reg          mem_en,
    output reg          alu_rst,
    output reg          bru_rst,
    output reg          reg_rst,
    output reg          mem_rst,
    output reg          pc_addr_en,
    output reg          alu_inA_mux,
    output reg          alu_inB_mux,
    output reg          alu_carry_in,
    output reg          alu_out_mux,
    output reg          alu_out_reg,
    output reg          alu_reg_out_mux,
    output reg          mem_out_mux,
    output reg          reg_in_mux,
    output reg          reg_alu_mux,
    output reg          serial_in_mux,
    output reg          serial_out_mode
    );
    
// Define CU states
parameter START_0       = 4'd0;
parameter START_1       = 4'd1;
parameter ALU_0         = 4'd2;
parameter ALUI_0        = 4'd3;
parameter SHIFT_0       = 4'd4;
parameter SHIFTI_0      = 4'd5;
parameter LOAD_0        = 4'd6;
parameter STORE_0       = 4'd7;
parameter BRANCH_0      = 4'd8;
parameter IMM_0         = 4'd10;
parameter JUMP_0        = 4'd11;
parameter SYSTEM_0      = 4'd13; // TODO
parameter MEM_0         = 4'd14; // TODO
parameter WRITEBACK_0   = 4'd15;

// Registers
reg [31:0]  instruction_reg, immediate_reg;
reg [4:0]   state;
reg [4:0]   next_state;
reg [1:0]   byte_addr;
reg         shift_load;

// Cycle counter to track progress of serial data movements
reg         counter_rst, counter_load, counter_en;
wire [5:0]  count;
reg  [5:0]  counter_val;

Counter #(
    .COUNT_DOWN(0),
    .COUNT_WIDTH(6)
) cycle_counter (
    .clk(clk),
    .rst(counter_rst),
    .load(counter_load),
    .load_in(counter_val),
    .count_en(counter_en),
    .count(count)
    );
    
assign bit_position = count;
    
// Set register selecters from instruction
assign regA = reg_we ? instruction_reg[11:7] : instruction_reg[19:15];
assign regB = instruction_reg[24:20];

// Mux out immediate register
mux32 imm_mux(
    .in(immediate_reg),
    .select(count[4:0]),
    .out(immediate)
);

// Set initial values
initial
begin
    @(posedge clk);
    state           = START_0;
    next_state      = START_0;
    pc              = 32'h00000000;
    instruction_reg = 32'h00000000; 
    reg_we          = 1'b0;
    mem_en          = 1'b0;
    alu_rst         = 1'b0;
    bru_rst         = 1'b0;
    reg_rst         = 1'b0;
    mem_rst         = 1'b0;
    pc_addr_en      = 1'b0;
    alu_inA_mux     = 1'b0;
    alu_inB_mux     = 1'b0;
    alu_carry_in    = 1'b0;
    alu_out_mux     = 1'b0;
    alu_out_reg     = 1'b0;
    alu_reg_out_mux = 1'b0;
    mem_out_mux     = 1'b0;
    reg_in_mux      = 1'b0;
    reg_alu_mux     = 1'b0;
    serial_in_mux   = 1'b0;
    serial_out_mode = 1'b0;
end


// Transition state
always @(posedge clk)
    if (rst) state = START_0;
    else if (memory_misaligned) state = SYSTEM_0;
    else state = next_state;

// State machine case statement    
always @(posedge clk)
    case (state)
    // ------------------------------------------------------------------------
    // Reset units and load instruction
    // 2 Cycles
    START_0:
    begin
        op              = {1'b0, `LW};
        instruction_reg = 32'h00000000;
        byte_addr       = 2'b00;
        bru_op          = 2'b00;
        mem_en          = 1'b0;
        counter_en      = 1'b0;
        // Reset ALU, BRU and counter
        alu_rst         = 1'b1;
        bru_rst         = 1'b1;
        alu_carry_in    = 1'b0;
        alu_inA_mux     = 1'b1; // Register A
        alu_inB_mux     = 1'b1; // Register B
        immediate_reg   = 32'h00000004; // Set immediate to 4
        // Set write mask to 0 to read from memory
        mem_mask        = 4'b0000;
        // Enable memory to load instruction
        if (pc_addr_en) mem_en = 1'b1;
        // Set memory address to read from PC
        pc_addr_en      = 1'b1;
        // Make sure nothing is written to registers
        reg_we          = 1'b0;
        serial_out_mode = 1'b0; // Deserialise to memory data in
        // If memory enable is high the instruction should have been read
        // Therefore transition to decode state
        if (mem_en == 1'b1)
        begin
            alu_rst     = 1'b0;
            bru_rst     = 1'b0;
            counter_rst = 1'b1; // Reset counter to zero
            counter_en  = 1'b1; // Enable cycle counter
            next_state  = START_1;
        end
    end
    // ------------------------------------------------------------------------
    // Decode instruction and increment PC
    // 33 Cycles
    START_1:
    begin
        mem_en          = 1'b0; //
        pc_addr_en      = 1'b0; // Address 
        counter_rst     = 1'b0; // Stop reseting counter
        alu_inA_mux     = 1'b0; // PC register via serialiser
        alu_inB_mux     = 1'b0; // Immediate register
        alu_out_mux     = 1'b0; // ALU sum output
        alu_out_reg     = 1'b0; // ALU output register disabled
        mem_out_mux     = 1'b0; // Bus from CU not memory
        op              = {1'b0, `ADD}; // Set ALU to ADD
        instruction_reg = instruction;
        if (instruction[6:0] == `JALR || instruction[6:0] == `JAL)
        begin   
            reg_we      = 1'b1; // Enable register write for link reg
        end
        else
            pc[count]   = alu_result; // Otherwise update PC
        // Set next state based on instruction
        if (count == 31)
        begin
            alu_inA_mux = 1'b1; // Register file
            alu_inB_mux = 1'b1; // Register file
            reg_we      = 1'b0; // Disable register write
            // Disable counter and reset
            counter_en  = 1'b0;
            counter_rst = 1'b1;
            alu_rst     = 1'b1;
            OP_DECODE (instruction_reg[6:0]);
        end
    end
    // ------------------------------------------------------------------------
    // Execute ALU operation and write into output register for writeback
    // 33 Cycles
    ALU_0:
    begin
        if (count == 31)
        begin
            // Disable counter and reset
            counter_en  = 1'b0;
            counter_rst = 1'b1;
            alu_out_reg = 1'b0; // ALU output register disabled
            // Set next state
            next_state  = WRITEBACK_0;
        end
        else
        begin
            counter_rst      = 1'b0;
            counter_en       = 1'b1; //Enable cycle counter
            alu_rst          = 1'b0;
            alu_out_reg      = 1'b1; // ALU output register enabled
            // Set ALU to function from instruction
            // Set bit [3] to 1 if it is SLT or STLU for SUB operation
            op = {(instruction_reg[14:13] == 2'b01 ? 1'b1 : instruction_reg[30]), instruction_reg[14:12]}; 
            alu_inA_mux      = 1'b1; // Register A
            alu_inB_mux      = 1'b1; // Register B
            if (op[3])
                alu_carry_in = count == 0;
            else 
                alu_carry_in = 1'b0;
            if (op[2:1] == 2'b01 && count == 31)
                alu_out_mux  = 1'b1; // ALU SLT output
            else
                alu_out_mux  = 1'b0; // ALU sum output
        end
    end
    // ------------------------------------------------------------------------
    // Execute ALU immediate operation and write into output register for
    // writeback
    // 33 Cycles
    ALUI_0:
    begin
        if (count == 31)
        begin
            // Disable counter and reset
            counter_en  = 1'b0;
            counter_rst = 1'b1;
            alu_out_reg = 1'b0; // ALU output register disabled
            // Set next state
            next_state  = WRITEBACK_0;
        end
        else
        begin
            counter_rst      = 1'b0;
            counter_en       = 1'b1; //Enable cycle counter
            alu_out_reg      = 1'b1; // ALU output register enabled
            alu_rst          = 1'b0;
            // Set ALU to function from instruction
            // Set bit [3] to 1 if it is SLT or STLU for SUB operation
            op = {(instruction_reg[14:13] == 2'b01 ? 1'b1 : 1'b0), instruction_reg[14:12]}; 
            alu_inA_mux      = 1'b1; // Register A
            alu_inB_mux      = 1'b0; // Immediate output
            mem_out_mux      = 1'b0; // Bus from CU not memory
            if (op[3])
                alu_carry_in = count == 0;
            else 
                alu_carry_in = 1'b0;
            if (op[2:1] == 2'b01 && count == 31)
                alu_out_mux  = 1'b1; // ALU SLT output for final bit
            else
                alu_out_mux  = 1'b0; // ALU sum output
        end
    end
    // ------------------------------------------------------------------------
    // Shift bits by number of bits in register
    // 67 + No. of shifts Cycles (0 for shift left)
    SHIFT_0:
    begin
        // Set ALU to function from instruction
        op              = {instruction_reg[30], instruction_reg[14:12]}; 
        alu_out_reg     = 1'b0; // ALU output register disabled
        alu_rst         = 1'b0;
        if (count == 31 && shift_load)
        begin
            shift_load  = 1'b0;
            counter_rst = 1'b1;
        end
        else if (count == 31)
            next_state  = START_0;
        else 
        begin
            counter_rst = 1'b0;
            counter_en  = shift_load || shift_output_en; // Enable cycle counter
            alu_inA_mux = 1'b1; // Register A
            alu_inB_mux = 1'b1; // Register B
            reg_in_mux  = 1'b0; // From ALU/Shifter
            reg_alu_mux = 1'b1; // From Shifter
            reg_we      = shift_output_en; // Enable reg write
        end
    end
    // ------------------------------------------------------------------------
    // Shift bits by number of bits in immediate register
    // 67 + No. of shifts Cycles (0 for shift left)
    SHIFTI_0:
    begin
        // Set ALU to function from instruction
        op              = {instruction_reg[30], instruction_reg[14:12]};
        alu_out_reg     = 1'b0; // ALU output register disabled
        alu_rst         = 1'b0;
        if (count == 31 && shift_load)
        begin
            shift_load  = 1'b0;
            counter_rst = 1'b1;
        end
        else if (count == 31)
            next_state  = START_0;
        else 
        begin
            counter_rst = 1'b0;
            counter_en  = shift_load || shift_output_en; // Enable cycle counter
            alu_inA_mux = 1'b1; // Register A
            alu_inB_mux = 1'b0; // Immediate output
            mem_out_mux = 1'b0; // Bus from CU not memory
            reg_in_mux  = 1'b0; // From ALU/Shifter
            reg_alu_mux = 1'b1; // From Shifter
            reg_we      = shift_output_en; // Enable reg write
        end
    end
    // ------------------------------------------------------------------------
    // Load from address in source register + immediate offset
    // 44 Cycles due to only needing 11 cycles for the address calculation
    LOAD_0:
    begin
        alu_rst         = 1'b0;
        if (count == 31)
        begin
            mem_en      = 1'b0; // Disable memory
            reg_we      = 1'b0; // Regfile write disabled
            next_state  = START_0; // Set next state
        end
        else if (mem_en)
        begin
            reg_we      = 1'b1; // Enable reg write
            counter_rst = 1'b0;
            counter_en  = 1'b1; // Enable counter
            reg_in_mux  = 1'b1; // Reg in from serialiser
            mem_out_mux = 1'b1; // Serialiser in from memory
            serial_out_mode = 1'b0; // Deserialise to memory data in
        end
        else if (~mem_en && count == 12)
        begin
            mem_en      = 1'b1; // Enable memory
            counter_rst = 1'b1; // Reset counter
        end
        else
        begin
            counter_rst = 1'b0;
            counter_en  = 1'b1;
            op          = {1'b0, `ADD}; // Set ALU to ADD
            alu_inA_mux = 1'b1; // Register A
            alu_inB_mux = 1'b0; // Immediate output
            pc_addr_en  = 1'b0; // Serialiser to memory address
            serial_in_mux = 1'b1; // ALU out to deserialiser
            serial_out_mode = 1'b1; // Deserialise to memory address
        end
    end
    // ------------------------------------------------------------------------
    // Store source register 2 to address in source register 1 + immediate offset
    // 44 Cycles due to only needing 11 cycles for the address calculation
    STORE_0:
    begin
        alu_rst         = 1'b0;
        if (mem_mask == 4'b0000 && count == 12)
        begin
            counter_rst = 1'b1; // Reset counter
            op          = {1'b0, instruction_reg[14:12]};
            // Calculate write enable mask
            mem_mask    = op[1] ? 4'b1111: (op[0] ? 4'b0011 << byte_addr : 4'b0001 << byte_addr);
        end
        else if (count == 31)
        begin
            mem_en      = 1'b1; // Enable memory once deserial register is full
            counter_en  = 1'b0; // Disable counter
            reg_we      = 1'b0; // Regfile write disabled
            next_state  = START_0; // Set next state
        end
        else if (mem_mask != 4'b0000)
        begin
            serial_in_mux = 1'b0;
            counter_rst = 1'b0;
            counter_en  = 1'b1; // Enable counter
            reg_in_mux  = 1'b1; // Reg in from serialiser
            mem_out_mux = 1'b1; // Serialiser in from memory
            serial_out_mode = 1'b0; // Deserialise to memory data in
        end 
        else
        begin
            if (count < 2) byte_addr[count] = alu_result;
            counter_rst = 1'b0;
            counter_en  = 1'b1;
            op          = {1'b0, `ADD}; // Set ALU to ADD
            alu_inA_mux = 1'b1; // Register A
            alu_inB_mux = 1'b0; // Immediate output
            mem_out_mux = 1'b0; // Bus from CU not memory
            pc_addr_en  = 1'b0; // Serialiser to memory address
            serial_in_mux = 1'b1; // ALU out to deserialiser
            serial_out_mode = 1'b1; // Deserialise to memory address
        end
    end
    // ------------------------------------------------------------------------
    // Compare 2 registers and jump if the condition is met
    // 33 cycles for false and 66 cycles for true
    BRANCH_0:
    begin
        if (count == 31 && ~alu_inA_mux)
        begin
            alu_inA_mux     = 1'b1; // Register file
            alu_inB_mux     = 1'b1; // Register file
            // Disable counter and reset
            counter_en      = 1'b0;
            counter_rst     = 1'b1;
            next_state      = START_0;
        end 
        else if (~alu_inA_mux)
        begin
            counter_rst     = 1'b0;
            counter_en      = 1'b1; //Enable cycle counter
            alu_rst         = 1'b0;
            op              = {1'b0, `ADD}; // Set ALU to ADD
            alu_out_mux     = 1'b0; // ALU sum output
            alu_out_reg     = 1'b0; // ALU output register disabled
            mem_out_mux     = 1'b0; // Bus from CU not memory
            pc[count]       = alu_result;
        end  
        else if (count == 31)
        begin
            // Disable and reset counter
            counter_en      = 1'b0;
            counter_rst     = 1'b1;
            // If branch is true change input muxes to offset pc
            if (bru_result)
            begin
                alu_inA_mux = 1'b0; // PC register via serialiser
                alu_inB_mux = 1'b0; // Immediate register      
                immediate_reg = immediate_reg - 4;  
                alu_rst     = 1'b1;
            end
            // Else go back to start
            else
            begin
                next_state  = START_0;
            end
        end
        else
        begin
            counter_rst     = 1'b0;
            counter_en      = 1'b1; //Enable cycle counter
            alu_rst         = 1'b0;
            // Set ALU for the comparison
            op              = {1'b1, instruction_reg[14] ? (instruction_reg[13] ? `SLTU : `SLT) : `SUB};
            bru_op          = {instruction_reg[14], instruction_reg[12]};
            alu_inA_mux     = 1'b1; // Register A
            alu_inB_mux     = 1'b1; // Register B
            alu_carry_in    = count[5];
        end
    end
    // ------------------------------------------------------------------------
    // Update PC for jump operation
    // 33 Cycles
    JUMP_0:
    begin
        counter_rst     = 1'b0;
        counter_en      = 1'b1; //Enable cycle counter
        op              = {1'b0, `ADD}; // Set ALU to ADD
        alu_rst         = 1'b0;
        // PC register via serialiser or register depending on JAL or JALR
        alu_inA_mux     = instruction_reg[7:0] == `JALR;
        alu_inB_mux     = 1'b0; // Immediate register        
        alu_out_mux     = 1'b0; // ALU sum output
        alu_out_reg     = 1'b0; // ALU output register disabled
        mem_out_mux     = 1'b0; // Bus from CU not memory
        pc[count]       = alu_result; // Otherwise update PC
        // Set next state based on instruction
        if (count == 31)
        begin
            // Disable counter
            counter_en  = 1'b0;
            // Check PC is not misaligned
            if (pc[1] || pc[2]) next_state = SYSTEM_0;
            else next_state  = START_0;
        end
    end
    // ------------------------------------------------------------------------
    // Load immediate into register 
    // 33 Cycles
    IMM_0:
    begin
        counter_rst     = 1'b0;
        counter_en      = 1'b1; //Enable cycle counter
        alu_rst         = 1'b0;
        op              = {1'b0, `ADD}; // Set ALU to ADD
        // Add immediate to PC if AUIPC, add 0 if not (ALU passthrough)
        // Regfile outputs 0 on portA if write is enable
        alu_inA_mux     = instruction_reg[6:0] == `LUI;
        alu_inB_mux     = 1'b0; // Immediate register        
        alu_out_mux     = 1'b0; // ALU sum output
        alu_out_reg     = 1'b0; // ALU output register disabled
        reg_alu_mux     = 1'b0; // ALU output to register in
        reg_in_mux      = 1'b0; // Reg in from ALU
        mem_out_mux     = 1'b0; // Bus from CU not memory
        reg_we          = 1'b1;
        // Set next state based on instruction
        if (count == 31)
        begin
            // Stop writing to regfile
            reg_we      = 1'b0;
            // Disable counter
            counter_en  = 1'b0;
            next_state  = START_0;
        end
    end
    // ------------------------------------------------------------------------
    // Write contents of ALU output register into regfile
    // This is because can't read and write to the regfile concurrently
    // 33 Cycles
    WRITEBACK_0:
    begin
        if (count == 31)
        begin
            // Disable counter
            counter_rst     = 1'b1;
            counter_en      = 1'b0;
            alu_out_reg     = 1'b0; // ALU output register disabled
            reg_we          = 1'b0; // Regfile write disabled
            // Set next state
            next_state      = START_0;
        end
        else
        begin
            counter_rst     = 1'b0;
            counter_en      = 1'b1; // Enable cycle counter
            reg_we          = 1'b1; // Regfile write enabled
            reg_in_mux      = 1'b0; // From ALU/Shifter
            reg_alu_mux     = 1'b0; // From ALU
            alu_out_reg     = 1'b1; // ALU output register enabled
            if (op[2:1] == 2'b01 && count == 0)
            begin
                // ALU output register disabled to get SLT result bit
                alu_out_reg     = 1'b0;
                // Last bit of register for SLT result to go first 
                alu_reg_out_mux = 1'b0; 
            end
            else
            begin
                alu_out_reg     = 1'b1; // ALU output register enabled
                alu_reg_out_mux = 1'b1; // Then pad with 0s
            end
        end
    end
    default: $stop;
    endcase

// Task to decode op code of instruction 
// in order to tidy up state machine 
task OP_DECODE;
    input [6:0] opcode;
    case (opcode)
    `LOAD:
        begin
        // I Type
        immediate_reg    = {{22{instruction_reg[31]}}, instruction_reg[30:20]};
        next_state      = LOAD_0;
        reg_we          = 1'b0;
        end
    `STORE:
        begin
        // S Type
        immediate_reg   = {{22{instruction_reg[31]}}, instruction_reg[30:25], instruction_reg[11:7]};
        next_state  = STORE_0;
        end
    `BRANCH:
        begin
        // B Type
        immediate_reg   = {{22{instruction_reg[31]}}, instruction_reg[7], instruction_reg[30:25],
            instruction_reg[11:8], 1'b0};
        next_state      = BRANCH_0;
        end
    `OP_IMM:
        begin
        // I Type
        immediate_reg= {{22{instruction_reg[31]}}, instruction_reg[30:20]};
        next_state  = instruction_reg[13:12] == 2'b01 ? SHIFTI_0 : ALUI_0;
        shift_load  = instruction_reg[13:12] == 2'b01; // State bit for inputing or outputing of shifter
        end
    `OP:
        begin
        next_state  = instruction_reg[13:12] == 2'b01 ? SHIFT_0 : ALU_0;
        shift_load  = instruction_reg[13:12] == 2'b01; // State bit for inputing or outputing of shifter
        end
    `SYSTEM:
        begin
        next_state  = SYSTEM_0;
        end
    `MISC_MEM:
        begin
        next_state  = MEM_0;
        end
    `JALR:
        begin
        // I Type
        immediate_reg   = {{22{instruction_reg[31]}}, instruction_reg[30:20]};
        next_state      = JUMP_0;
        end
    `JAL:
        begin
        // J Type
        immediate_reg   = {{12{instruction_reg[31]}}, instruction_reg[19:12], instruction_reg[20],
            instruction_reg[30:21], 1'b0};
        next_state      = JUMP_0;
        end
    `AUIPC:
        begin
        // U Type
        immediate_reg   = {instruction[31:12], 12'b0};
        next_state      = IMM_0;
        end
    `LUI:
        begin
        // U Type
        immediate_reg   = {instruction[31:12], 12'b0};
        next_state      = IMM_0;
        end
     default:
        next_state      = 4'bXXXX;
    endcase
endtask

endmodule