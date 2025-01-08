`timescale 1ns/1ps
module tb_sfifo();

// Parameters for FIFO
parameter WIDTH = 8;
parameter DEPTH = 32;
parameter ADDR_WIDTH = $clog2(DEPTH);

// FIFO signals
wire [WIDTH-1:0] Data_out;
wire fifo_isfull, fifo_isempty;
wire o_wready, o_rready;

reg [WIDTH-1:0] Data_in;
reg i_rreq, i_wreq, clk, resetn;

// Test-specific variables
reg [WIDTH-1:0] sing_wdata;
reg [WIDTH*3-1:0] burst_wdata;

// Instantiate the DUT
csv_sfifo_ram dut (
    .wdata          (Data_in),
    .fifo_isempty   (fifo_isempty),
    .fifo_isfull    (fifo_isfull),
    .rdata          (Data_out),
    .i_rreq         (i_rreq),
    .i_wreq         (i_wreq),
    .clk            (clk),
    .resetn         (resetn),
    .o_rready       (o_rready),
    .o_wready       (o_wready)
);

// Clock generation
initial begin
    clk = 0;
    forever #5 clk = ~clk; // 10ns clock period
end

// Task: Write data to FIFO
task fifo_write(input [WIDTH-1:0] data);
begin
    @(posedge clk);
    Data_in <= data;
    i_wreq  <= 1;
    @(posedge clk);
    i_wreq <= 0;
end
endtask

// Task: Read data from FIFO
task fifo_read();
begin
    @(posedge clk);
    i_rreq <= 1;
    @(posedge clk);
    i_rreq <= 0;
end
endtask

// Task: Write burst data
task fifo_burst_write(input [WIDTH*3-1:0] burst_data);
begin
    for (int i = 0; i < 3; i++) begin
        fifo_write(burst_data[(i+1)*WIDTH-1 -: WIDTH]);
    end
end
endtask

// Task: Read burst data
task fifo_burst_read(input int num);
begin
    for (int i = 0; i < num; i++) begin
        fifo_read();
    end
end
endtask

// Task: Attempt to write when FIFO is full
task fifo_write_full(input [WIDTH-1:0] data);
begin
    if (fifo_isfull) begin
        $display("\nAttempting to write when FIFO is full...");
        fifo_write(data);
        @(posedge clk);
        assert (!o_wready) $display("\nPASSED: Write attempt blocked when FIFO is full");
        else $error("\nFAILED: Write succeeded despite FIFO being full");
    end else begin
        $error("\nFAILED: FIFO is not full before write attempt.");
    end
end
endtask

// Task: Attempt to read when FIFO is empty
task fifo_read_empty();
begin
    if (fifo_isempty) begin
        $display("\nAttempting to read when FIFO is empty...");
        fifo_read();
        @(posedge clk);
        assert (!o_rready) $display("\nPASSED: Read attempt blocked when FIFO is empty");
        else $error("\nFAILED: Read succeeded despite FIFO being empty");
    end else begin
        $error("\nFAILED: FIFO is not empty before read attempt.");
    end
end
endtask

// Testbench logic
initial begin
    // Initialize and reset
    resetn = 0;
    i_rreq = 0;
    i_wreq = 0;
    #20 resetn = 1;

    // Testcase: Basic Read/Write
    if ($test$plusargs("FIFO_BASE")) begin
        repeat (10) begin
            sing_wdata = $random;
            fifo_write(sing_wdata);
            fifo_read();
        end
        burst_wdata = {8'hFF, 8'hEE, 8'hAA};
        fifo_burst_write(burst_wdata);
        fifo_burst_read(3);
    end

    // Testcase: FIFO Full
    if ($test$plusargs("FIFO_FULL")) begin
        repeat (DEPTH) fifo_write($random);
        repeat (10) @(posedge clk);
        assert (!o_wready) $display("\nPASSED: FIFO is full");
        else $error("\nFAILED: FIFO is not full");
    end

    // Testcase: FIFO Empty
    if ($test$plusargs("FIFO_EMPTY")) begin
        repeat (DEPTH-1) fifo_write($random);
        repeat (DEPTH-1) fifo_read();
        repeat (10) @(posedge clk);
        assert (!o_rready) $display("\nPASSED: FIFO is empty");
        else $error("\nFAILED: FIFO is not empty");
    end

    // Testcase: FIFO Write Full
    if ($test$plusargs("FIFO_WRITEFULL")) begin
        repeat (DEPTH) fifo_write($random);
        repeat(2) @(posedge clk);
        fifo_write_full($random);
    end

    // Testcase: FIFO Read Empty
    if ($test$plusargs("FIFO_READEMPTY")) begin
        repeat (DEPTH) fifo_write($random);
        repeat (DEPTH) fifo_read();
        repeat(2) @(posedge clk);
        fifo_read_empty();
    end

    // Testcase: Reset Functionality
    if ($test$plusargs("FIFO_RESET")) begin
        repeat (10) fifo_write($random);
        repeat (9) fifo_read();
        #6 resetn = 0;
        #6 resetn = 1;
        repeat (10) @(posedge clk);
        assert ((fifo_isfull == 0)&& (fifo_isempty == 1) &&( o_rready == 0) && (o_wready ==1))
         $display("\nPASSED: Reset success");
        else $error("\nFAILED: Reset failed");
    end

    $finish;
end

endmodule
