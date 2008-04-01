module infrastructure(
    sys_clk_buf,
    sys_clk
  );
  input  sys_clk_buf;
  output sys_clk;

  IBUFG ibufg (
    .I(sys_clk_buf),
    .O(sys_clk)
  );

endmodule
