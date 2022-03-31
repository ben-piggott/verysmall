module mux32(
    input [31:0] in,
    input [4:0]  select,
    output       out
    );

wire MUXA_out, MUXB_out;

// Initiliase 2 16:1 muxes
mux16 MUXA (
    .in(in[15:0]),
    .select(select[3:0]),
    .out(MUXA_out)
);

mux16 MUXB (
    .in(in[31:16]),
    .select(select[3:0]),
    .out(MUXB_out)
);

// Select mux out using MSB
assign out = select[4] ? MUXB_out : MUXA_out;

endmodule

module mux16(
    input [15:0] in,
    input [3:0]  select,
    output       out
    );

wire    F7A_out, F7B_out;
wire    LUTA_out, LUTB_out, LUTC_out, LUTD_out;

// Initiliase MUXs in slice
MUXF8 F8MUX (
    .O(out), // Output of MUX to general routing
    .I0(F7A_out), // Input (tie to MUXF7 L/LO out)
    .I1(F7B_out), // Input (tie to MUXF7 L/LO out)
    .S(select[3]) // Input select to MUX
);

MUXF7 F7AMUX (
    .O(F7A_out), // Output of MUX to general routing
    .I0(LUTA_out), // Input (tie to LUT6 O6 pin)
    .I1(LUTB_out), // Input (tie to LUT6 O6 pin)
    .S(select[2]) // Input select to MUX
);

MUXF7 F7BMUX (
    .O(F7B_out), // Output of MUX to general routing
    .I0(LUTC_out), // Input (tie to LUT6 O6 pin)
    .I1(LUTD_out), // Input (tie to LUT6 O6 pin)
    .S(select[2]) // Input select to MUX
);

// 4:1 Muxs which can be modelled by a LUT each
assign LUTA_out = select[1] ? ( select[0] ? in[3] : in[2]) : ( select[0] ? in[1] : in[0]);
assign LUTB_out = select[1] ? ( select[0] ? in[7] : in[6]) : ( select[0] ? in[5] : in[4]);
assign LUTC_out = select[1] ? ( select[0] ? in[11] : in[10]) : ( select[0] ? in[9] : in[8]);
assign LUTD_out = select[1] ? ( select[0] ? in[15] : in[14]) : ( select[0] ? in[13] : in[12]);
    
endmodule