`timescale 1ns/1ps
module tb_sfifo();

parameter WIDTH = 8;
parameter DEPTH = 32;
parameter ADDR_WIDTH = $clog2(DEPTH);

// FIFO signals
wire [WIDTH-1:0] Data_out;
wire fifo_isfull, fifo_isempty;
wire o_wready, o_rready;

reg [WIDTH-1:0] Data_in; // Ensure Data_in is `reg` since it's driven procedurally
reg i_rreq, i_wreq, clk, resetn;
reg [WIDTH-1:0] sing_wdata;
reg [WIDTH*3-1:0] burst_wdata;

// DUT instance
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
    i_wreq <= 1;
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
        fifo_write(data); // Try writing to a full FIFO
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
        fifo_read(); // Try reading from an empty FIFO
        @(posedge clk);
        assert (!o_rready) $display("\nPASSED: Read attempt blocked when FIFO is empty");
        else $error("\nFAILED: Read succeeded despite FIFO being empty");
    end else begin
        $error("\nFAILED: FIFO is not empty before read attempt.");
    end
end
endtask

// Initial block for testcases
initial begin
    // Wait for reset to be released
    resetn = 0;
    #20 resetn = 1;

    // FIFO Base Test
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

    // FIFO Full Test
    if ($test$plusargs("FIFO_FULL")) begin
        repeat (DEPTH) fifo_write($random);

        // Checker
        repeat (10) @(posedge clk);
        assert (fifo_isfull) $display("\nPASSED: FIFO is full");
        else $error("\nFAILED: FIFO is not full");
    end

    // FIFO Write Full Test
    if ($test$plusargs("FIFO_WRITEFULL")) begin
        repeat (DEPTH) fifo_write($random);

        // Try to write when FIFO is full
        sing_wdata = $random;
        fifo_write_full(sing_wdata);
    end

    // FIFO Empty Test
    if ($test$plusargs("FIFO_EMPTY")) begin
        repeat (DEPTH-1) fifo_write($random);
        repeat (DEPTH-1) fifo_read();

        // Checker
        repeat (10) @(posedge clk);
        assert (fifo_isempty) $display("\nPASSED: FIFO is empty");
        else $error("\nFAILED: FIFO is not empty");
    end

    // FIFO Read Empty Test
    if ($test$plusargs("FIFO_READEMPTY")) begin
        repeat (DEPTH) fifo_write($random);
        repeat (DEPTH) fifo_read();

        // Try to read when FIFO is empty
        fifo_read_empty();
    end

    // FIFO Reset Test
    if ($test$plusargs("FIFO_RESET")) begin
        repeat (10) fifo_write($random);
        repeat (9) fifo_read();

        // Reset FIFO
        #6 resetn = 0;
        #6 resetn = 1;

        // Check
        repeat (10) @(posedge clk);
        assert ((fifo_isfull == 0) && (fifo_isempty == 1) && (o_wready == 1) && (o_rready == 1))
            $display("\nPASSED: Reset success");
        else $error("\nFAILED: Reset failed");
    end

    $finish;
end

endmodule
