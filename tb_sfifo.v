`timescale 1ns/1ps
`define PERIOD 10
module tb_sfifo();
	reg	 			clk , resetn ;
	reg 	[ WIDTH -1 : 0] 	wdata ;
	reg	 			i_wreq;
    	wire 	                 	o_wready;
    	//read
    	reg [  WIDTH-1:0  ] 		rdata;
    	reg	                   	i_rreq;
    	wire                 		o_rready;
    	//fifo status
    	wire 				fifo_isfull;
    	wire    			fifo_isempty;
        
	wire [ADDR_WIDTH -1: 0] 	wr_pointer;
	wire [ADDR_WIDTH -1:0 ]   	rd_pointer;
	wire [ADDR_WIDTH -1 :0] 	fifo_dcount;
	




;
