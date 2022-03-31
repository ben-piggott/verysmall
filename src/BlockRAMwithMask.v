
//Custom BRAM inst, write to kristi.manev@gmail.com for questions
module BlockRAMwithMask #(
	parameter D_WIDTH = 32,
	parameter D_DEPTH_WIDTH = 10,
	parameter D_WIDTH_BYTES = D_WIDTH/8,
	parameter INIT_FILE = ""
) (
	input clk,
	input [D_WIDTH-1:0] dataIn,
	input en,
	input [D_WIDTH_BYTES-1:0] wr_mask,
	input [D_DEPTH_WIDTH-1:0] addr,
	output reg [D_WIDTH-1:0] dataOut
	);
	(* ram_style = "block" *) reg [D_WIDTH-1:0] ram [0:2**D_DEPTH_WIDTH-1];
	
    generate
    genvar i;
        for (i = 0; i < D_WIDTH_BYTES; i = i+1) 
            begin: byte_write
            always @(posedge clk)
            if (en)
                if (wr_mask[i])
                begin
                    ram[addr][(i+1)*8-1:i*8] <= dataIn[(i+1)*8-1:i*8];
                    dataOut[(i+1)*8-1:i*8] <= dataIn[(i+1)*8-1:i*8];
                end
                else
                    dataOut[(i+1)*8-1:i*8] <= ram[addr][(i+1)*8-1:i*8];

            end
    endgenerate
	integer j;
	initial 
	begin
        if (INIT_FILE == "")
        begin
            for(j = 0; j < (2**D_DEPTH_WIDTH); j = j+1) 
                ram[j] = 0;
        end
        else
        begin
            $readmemh(INIT_FILE, ram);
        end
    end
endmodule
