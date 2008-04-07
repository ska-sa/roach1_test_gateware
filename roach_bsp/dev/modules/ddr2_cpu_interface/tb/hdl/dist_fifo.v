module dist_fifo(
    clk, reset,
    d_in,  wr_en,
    d_out, rd_en,
    full,  empty,
    afull, aempty
  );
  parameter WIDTH     = 32;
  parameter SIZE      = 32;
  input  clk, reset;
  input  [WIDTH - 1:0] d_in;
  input  wr_en;
  output [WIDTH - 1:0] d_out;
  input  rd_en;
  output full,  empty, afull, aempty;
 
  reg [WIDTH - 1:0] fifo_data [SIZE - 1:0];

  reg [SIZE - 1:0] fifo_head;//should be log2(SIZE + 1)
  reg [SIZE - 1:0] fifo_tail;//should be log2(SIZE + 1)
  reg fifo_empty;

  assign d_out = fifo_data[fifo_tail];

  assign empty = fifo_empty;
  assign full  = !fifo_empty && (fifo_head == fifo_tail);

  wire [SIZE - 1:0] true_diff;

  assign true_diff = fifo_head >= fifo_tail ? fifo_head - fifo_tail : fifo_head + SIZE - 1 - fifo_tail;

  assign afull  = true_diff > SIZE - 8;
  assign aempty = true_diff < 8;

  always @(posedge clk) begin
    if (reset) begin
      fifo_empty <= 1'b1;
      fifo_head  <= 5'd0;
      fifo_tail  <= 5'd0;
    end else begin
      if (wr_en & (~full | rd_en)) begin
        fifo_head <= fifo_head == SIZE - 1 ? 0 : fifo_head + 1;
        fifo_data[fifo_head] <= d_in;
        fifo_empty <= 1'b0;
      end
      if (rd_en & ~fifo_empty) begin
        fifo_tail <= fifo_tail == SIZE - 1 ? 0 : fifo_tail + 1;
        if (true_diff == 1 && ~wr_en) begin
          fifo_empty <= 1'b1;
        end
      end
    end
  end

endmodule
