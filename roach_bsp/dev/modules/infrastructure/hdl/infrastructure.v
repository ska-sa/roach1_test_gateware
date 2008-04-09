module infrastructure(
    reset,
    sys_clk_buf,
    sys_clk,
    dly_clk,
    dly_rdy
  );
  input  reset;
  input  sys_clk_buf;
  output sys_clk;
  output dly_clk;
  output dly_rdy;

  IBUFG ibufg (
    .I(sys_clk_buf),
    .O(sys_clk)
  );

  wire dly_clk_int;
  wire dly_clk_lock;

  wire clk_fb;
  DCM_BASE DCM_BASE_inst (
    .CLK0(clk_fb),
    .CLK180(),
    .CLK270(),
    .CLK2X(dly_clk_int),
    .CLK2X180(),
    .CLK90(),
    .CLKDV(),
    .CLKFX(),
    .CLKFX180(),
    .LOCKED(dly_clk_lock),
    .CLKFB(clk_fb),
    .CLKIN(sys_clk),
    .RST(reset)
  );

  BUFG bufg_dly (
    .I(dly_clk_int), .O(dly_clk)
  );

  wire dly_clk;

  IDELAYCTRL idelayctrl_inst(
    .REFCLK(dly_clk),
    .RST(reset | ~dly_clk_lock),
    .RDY(dly_rdy)
  );


endmodule
