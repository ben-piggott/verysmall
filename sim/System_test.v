`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/28/2022 11:59:09 AM
// Design Name: 
// Module Name: System_test
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
module System_test(
);
wire [31:0] pc;
wire [31:0] mem_in_bus, mem_out_bus, serial_in_bus;
(* keep = "true" *) wire [9:0]  mem_addr_bus, serial_addr_bus;
wire [5:0]  bit_position;
wire [3:0]  func, mem_we_mask;
wire [4:0]  regA_select, regB_select;
wire        imm;

reg  clk = 1'b0;
always #(2) clk = ~clk;
initial #12000 $stop;

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
    .regA(regA_select),
    .regB(regB_select),
    .reg_we(reg_we),
    .mem_en(mem_en),
    .alu_rst(alu_rst),
    .bru_rst(bru_rst),
    .reg_rst(reg_rst),
    .mem_rst(mem_rst),
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
    .func(func[2:0]),
    .ALU_output(alu_out_sum),
    .ALU_slt(alu_out_slt),
    .rst(bru_rst),
    .clk(clk),
    .branch(bru_out)
);

// Initiliase register file
RegFile RegFile (
    .data_in(reg_in),
    .regA_select(regA_select),
    .regB_select(regB_select),
    .bitPos(bit_position),
    .writeEn(reg_we),
    .rst(reg_rst),
    .clk(clk),
    .portA(reg_outA),
    .portB(reg_outB)
);

// Initiliase memory block
// Initiliase memory block
BlockRAMwithMask #(
	.D_WIDTH(32),
	.D_DEPTH_WIDTH(10),
	.INIT_FILE("./test.mem")
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
    .func(func[2:0]),
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
(* keep = "true" *) assign alu_inA = alu_inA_mux ? reg_outA : serial_out_bit;
(* keep = "true" *) assign alu_inB = alu_inB_mux ? reg_outB : imm;
(* keep = "true" *) assign alu_out = alu_out_mux ? alu_out_slt : alu_out_sum;
(* keep = "true" *) assign alu_reg_out = alu_reg_out_mux ? alu_reg_q31 : alu_reg_q0;
// Memory
(* keep = "true" *) assign mem_addr_bus = pc_addr_en ? pc[11:2] : serial_addr_bus; 
// RegFile
(* keep = "true" *) assign reg_in = reg_in_mux ? serial_out_bit : (reg_alu_mux ? shifter_out : (alu_out_reg_en ? alu_reg_out : alu_out));
// Serialiser
(* keep = "true" *) assign serial_in_bit = serial_in_mux ? alu_out : reg_outB;
(* keep = "true" *) assign serial_in_bus = mem_out_mux ? mem_out_bus : pc;


endmodule

