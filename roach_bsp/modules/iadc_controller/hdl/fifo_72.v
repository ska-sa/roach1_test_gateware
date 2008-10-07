`timescale 1ns/10ps

module fifo_72(
	din,
	rd_clk,
	rd_en,
	rst,
	wr_clk,
	wr_en,
	almost_empty,
	almost_full,
	dout,
	empty,
	full);


input [71 : 0] din;
input rd_clk;
input rd_en;
input rst;
input wr_clk;
input wr_en;
output almost_empty;
output almost_full;
output [71 : 0] dout;
output empty;
output full;

endmodule

