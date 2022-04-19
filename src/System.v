`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/28/2022 10:54:04 AM
// Design Name: 
// Module Name: System
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
`include "ALU.v"
`include "BlockRAMwithMask.v"
`include "BRU.v"
`include "Control_Unit.v"
`include "Data_Serialiser.v"
`include "RegFile.v"
`include "Shifter.v"

`define   DEBUG

module System(
    input clk,
    input cu_rst,
    // Debug outputs
    `ifdef DEBUG
    output mem_addr_bus_port,
    output mem_out_bus_port,
    output mem_in_bus_port,
    output bit_position_port
    `endif
);
wire [31:0] pc;
wire [31:0] mem_in_bus, mem_out_bus, serial_in_bus;
wire [9:0]  mem_addr_bus, serial_addr_bus;
wire [5:0]  bit_position;
wire [3:0]  func, mem_we_mask;
wire [1:0]  bru_func;
wire [4:0]  regA_select, regB_select;
wire        imm;

`ifdef DEBUG
assign mem_addr_bus_port = mem_addr_bus;
assign mem_out_bus_port = mem_out_bus;
assign mem_in_bus_port = mem_in_bus;
assign bit_position_port = bit_position;
`endif

// Initiliase Control Block
Control_Unit CU(
    .instruction(mem_out_bus),
    .rst(cu_rst),
    .clk(clk),
    .bru_result(bru_out),
    .alu_result(alu_out),
    .shift_output_en(shift_output_en),
    .memory_misaligned(memory_misaligned),
    .pc(pc),
    .immediate(imm), 
    .bit_position(bit_position),
    .mem_mask(mem_we_mask),
    .op(func),
    .bru_op(bru_func),
    .regA(regA_select),
    .regB(regB_select),
    .reg_we(reg_we),
    .mem_en(mem_en),
    .alu_rst(alu_rst),
    .bru_rst(bru_rst),
    .reg_rst(reg_rst),
    .mem_rst(mem_rst),
    .serial_rst(serialiser_rst),
    .pc_addr_en(pc_addr_en),
    .alu_inA_mux(alu_inA_mux),
    .alu_inB_mux(alu_inB_mux),
    .alu_out_mux(alu_out_mux),
    .alu_carry_in(alu_carry),
    .alu_out_reg(alu_out_reg_en),
    .alu_reg_out_mux(alu_reg_out_mux),
    .mem_out_mux(mem_out_mux),
    .reg_in_mux(reg_in_mux),
    .reg_alu_mux(reg_alu_mux),
    .serial_in_mux(serial_in_mux),
    .serial_out_mode(serial_out_mode)
    );

// Initialise shift register to store ALU output
SRLC32E #(
    .INIT(32'h00000000) // Initial Value of Shift Register
) SRLC32E_inst (
    .Q(alu_reg_q0), // SRL data output
    .Q31(alu_reg_q31), // SRL cascade output pin
    .A(5'b00000), // 5-bit shift depth select input
    .CE(alu_out_reg_en), // Clock enable input
    .CLK(clk), // Clock input
    .D(alu_out) // SRL data input
);

// Initialise ALU    
ALU ALU (
    .bitPos(bit_position),
    .func(func),
    .opA(alu_inA),
    .opB(alu_inB),
    .carry_in(alu_carry),
    .rst(alu_rst),
    .clk(clk),
    .result(alu_out_sum),
    .slt(alu_out_slt)
);

// Initiliase BRU
BRU BRU (
    .func(bru_func),
    .ALU_output(alu_out_sum),
    .ALU_slt(alu_out_slt),
    .rst(bru_rst),
    .clk(clk),
    .branch(bru_out)
);

// Initiliase register file
RegFile #(
    .D_WIDTH(32),
	.D_NO(31)
) RegFile (
    .data_in(reg_in),
    .regA_select(regA_select),
    .regB_select(regB_select),
    .bitPos(bit_position),
    .writeEn(reg_we),
    .rst(reg_rst),
    .clk(clk),
    .portA(regA_out),
    .portB(regB_out)
);

// Initiliase memory block
BlockRAMwithMask #(
	.D_WIDTH(32),
	.D_DEPTH_WIDTH(10),
	.INIT_FILE("./system.mem")
) Memory (
	.clk(clk),
	.dataIn(mem_in_bus),
	.en(mem_en),
	.wr_mask(mem_we_mask),
	.addr(mem_addr_bus),
	.dataOut(mem_out_bus)
	);

// Initiliase data serialiser/deserialiser
Data_Serialiser Serialiser (
    .data_in_bus(serial_in_bus),
    .data_out_bus(mem_in_bus),
    .address_out_bus(serial_addr_bus),
    .data_in_bit(serial_in_bit),
    .data_out_bit(serial_out_bit),
    .bitPos(bit_position),
    .mode(serial_out_mode),
    .clk(clk),
    .rst(serialiser_rst),
    .func(func[2:0]),
    .data_in_switch(mem_out_mux),
    .mem_misaligned(memory_misaligned)
);

//Initiliase shifter
Shifter Shifter(
    .opA(alu_inA),
    .opB(alu_inB),
    .rst(alu_rst),
    .clk(clk),
    .bitPos(bit_position),
    .func(func),
    .out(shifter_out),
    .out_en(shift_output_en)
);

// Multiplexers

// ALU
assign alu_inA = alu_inA_mux ? regA_out : serial_out_bit;
assign alu_inB = alu_inB_mux ? regB_out : imm;
assign alu_out = alu_out_mux ? alu_out_slt : alu_out_sum;
assign alu_reg_out = alu_reg_out_mux ? alu_reg_q31 : alu_reg_q0;
// Memory
assign mem_addr_bus = pc_addr_en ? pc[11:2] : serial_addr_bus; 
// RegFile
assign reg_in = reg_in_mux ? serial_out_bit : (reg_alu_mux ? shifter_out : (alu_out_reg_en || ~alu_reg_out_mux ? alu_reg_out : alu_out));
// Serialiser
assign serial_in_bit = serial_in_mux ? alu_out : regB_out;
assign serial_in_bus = mem_out_mux ? mem_out_bus : pc;


endmodule
