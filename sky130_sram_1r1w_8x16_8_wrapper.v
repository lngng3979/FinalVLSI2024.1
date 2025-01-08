`include "sky130_sram_1r1w_8x16_8.v"
module sky130_sram_1r1w_8x16_8_wrapper #(
    parameter DATA_WIDTH   =  8,
    parameter RAM_DEPTH    =  32,
    parameter ADDR_WIDTH   =  $clog2(RAM_DEPTH),			// 0 - 31
    parameter DELAY     = 0 ,
    parameter T_HOLD    = 0  //Delay to hold dout value after posedge. Value is arbitrary
	)(
	input					clk,
	// write
	input					wen,		//write enable active HIGH. 
	input [ADDR_WIDTH-1:0]  wpointer,	//write pointer (5 bit)
	input [DATA_WIDTH-1:0] 	wdata,		//write data
	// read
	input					ren,		//read enable active HIGH
	input  [ADDR_WIDTH-1:0]	rpointer,	//read pointer
	output [DATA_WIDTH-1:0] rdata		//read data
	);
	
	wire  [DATA_WIDTH-1:0] rdata_0;
	wire  [DATA_WIDTH-1:0] rdata_1;
	
	sky130_sram_1r1w_8x16_8 sram_0 (	//active when wpointer[4] = 0;
        .clk0	(clk),
        .csb0	(!wen || wpointer[ADDR_WIDTH-1]),	//csb active low (0+0=0)
        .addr0	(wpointer[ADDR_WIDTH-2:0]),
        .din0	(wdata),
        .clk1	(clk),
        .csb1	(!ren || rpointer[ADDR_WIDTH-1]),
        .addr1	(rpointer[ADDR_WIDTH-2:0]),
        .dout1	(rdata_0)
    );
	
	sky130_sram_1r1w_8x16_8 sram_1 (	//active when wpointer[4] = 1;
        .clk0	(clk),
        .csb0	(!wen || !wpointer[ADDR_WIDTH-1]),	//csb active high (0+1=1)
        .addr0	(wpointer[ADDR_WIDTH-2:0]),
        .din0	(wdata),
        .clk1	(clk),
        .csb1	(!ren || !rpointer[ADDR_WIDTH-1]),
        .addr1	(rpointer[ADDR_WIDTH-2:0]),
        .dout1	(rdata_1)
    );
	
	assign rdata = rpointer[ADDR_WIDTH-1] ? rdata_1:rdata_0;
endmodule
