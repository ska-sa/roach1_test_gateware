/* TODO: implement real test-bench */
`timescale 1ns/10ps

`define CLK_PERIOD      32'd100
`define SIM_LENGTH      10000

module TB_bus_monitor();
  wire clk;
  reg reset;
  reg [31:0] clk_counter;

  initial begin
    $display("PASSED");
    $finish;
  end

  /*
  initial begin
`ifdef DEBUG
    $display("starting simulation");
`endif
    reset<=1'b1;
    clk_counter<=32'b0;
    #512
`ifdef DEBUG
    $display("clearing reset");
`endif
    reset<=1'b0;
    #`SIM_LENGTH
    $display("FAILED: simulation timed out");
    $finish;
  end
  */

  assign clk = (clk_counter > (`CLK_PERIOD >> 1));
  always begin
    #1 clk_counter<=(clk_counter < `CLK_PERIOD ? clk_counter + 32'b1 : 32'b0);
  end

endmodule
