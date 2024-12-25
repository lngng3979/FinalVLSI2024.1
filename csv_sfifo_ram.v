`include "sky130_sram_1r1w_8x16_8_wrapper.v"
module csv_sfifo_ram #(
    parameter WIDTH = 8,
    parameter DEPTH = 32,
    parameter ADDR_WIDTH= $clog2(DEPTH)
)(
    input                   clk,
    input                   resetn,
    //write
    input   [WIDTH-1 : 0]       wdata,
    input                   i_wreq,
    output                  o_wready,
    //read
    output  [WIDTH-1 : 0]      rdata,
    input                   i_rreq,
    output                  o_rready,
    //fifo status
    output fifo_isfull,
    output fifo_isempty
); 
    reg [ADDR_WIDTH-1:0]         write_pointer;    // write and read pointer are used to access the address inside RAM
    reg [ADDR_WIDTH-1:0]         read_pointer; 
    reg [ADDR_WIDTH  :0]         fifo_dcount;      // fifo_dcount is to count the data in fifo so that state of empty and full can be controlled

    wire wen;
    wire ren;

    assign wen = i_wreq     & o_wready;
    assign ren = o_rready   & i_rreq;

    // fill in the parenthesis () to instantiate RAM wrapper
    sky130_sram_1r1w_8x16_8_wrapper #(
        .DATA_WIDTH(WIDTH),
        .RAM_DEPTH(DEPTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DELAY(0),
        .T_HOLD(0)
    )
    u_ram_wrapper (
        .clk(clk),
        .wen(wen),
        .wpointer(write_pointer),
        .wdata(wdata),
        .ren(ren),
        .rpointer(read_pointer),
        .rdata(rdata)
    );
// Circuit for write_pointer
    // When write pointer reachs the depth of the fifo, it moves back to 0 
    always @(posedge clk or negedge resetn)
    begin
        if (~resetn)          write_pointer <= 0; 
        else if (wen) begin
            if  (write_pointer < DEPTH)         write_pointer <= write_pointer + 1;
            else                                write_pointer <= 0;
        end  
    end

    //--------------------------------
    // Circuit for read_pointer
    // When read pointer reachs the depth of the fifo, it moves back to 0 
    always @(posedge clk or negedge resetn)
    begin
        if(~resetn)         read_pointer <= 0;
        else if (ren) begin
            if  (read_pointer < DEPTH)    read_pointer <= read_pointer + 1;
            else                          read_pointer <= 0;
        end  
    end
// circuit for fifo_dcount
    always @(posedge clk or negedge resetn)
    begin
        if (~resetn)                    fifo_dcount <= 0;
        else
            case ( {wen,ren} )
                2'b10 :                 fifo_dcount <= fifo_dcount + 1   ; 
                2'b01 :                 fifo_dcount <= fifo_dcount - 1   ; 
                default:                fifo_dcount <= fifo_dcount       ;
            endcase
    end
// fifo state logic
    assign fifo_isfull      = (fifo_dcount == (DEPTH)) ;
    assign fifo_isempty     = (fifo_dcount == 0);

    //-------------------------------------
    // o_wready & o_rready
    assign o_wready = ~fifo_isfull;
    assign o_rready = ~fifo_isempty;

endmodule