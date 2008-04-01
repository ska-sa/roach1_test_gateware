module xaui_fifo(
    rst, 
    rd_clk,
    dout,
    rd_en,

    wr_clk,
    din,
    wr_en,
    overflow, underflow,
    almost_full, almost_empty,
    full, empty
  );
  input  rst; 
  input  rd_clk;
  output [63:0] dout;
  input  rd_en;
  input  wr_clk;
  input  [63:0] din;
  input  wr_en;
  output overflow, underflow;
  output almost_full, almost_empty;
  output full, empty;
endmodule
