`timescale 1ns/1ps
module TB_fan_controller();
  reg clk;
  reg rst;
  wire f0,f1,f2;

  fan_controller fan_controller_inst(
    .wb_clk_i(clk),
    .wb_rst_i(rst),
    .fan_control({f2,f1,f0})
  );

  initial begin
    $dumpvars;
    clk <= 1'b0;
    rst <= 1'b1;
    #40
    rst <= 1'b0;
    #400000
    $display("PASSED");
    $finish;
  end

  initial begin
  end

  always begin
    #1 clk <= ~clk;
  end
endmodule
