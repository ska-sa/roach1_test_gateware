module infrastructure(
    sys_clk_n, sys_clk_p,
    sys_clk,
    dly_clk_n, dly_clk_p,
    dly_clk,
    aux_clk0_n, aux_clk0_p,
    aux_clk_0,
    aux_clk1_n, aux_clk1_p,
    aux_clk_1
  );
  input  sys_clk_n, sys_clk_p;
  output sys_clk;
  input  dly_clk_n, dly_clk_p;
  output dly_clk;
  input  aux_clk0_n, aux_clk0_p;
  output aux_clk_0;
  input  aux_clk1_n, aux_clk1_p;
  output aux_clk_1;

  wire [3:0] clk_int;
  IBUFDS #(
    .DIFF_TERM("TRUE"),
    .IOSTANDARD("LVDS_25")
  ) ibufds_arr_inst[3:0] (
    .I({sys_clk_p, dly_clk_p, aux_clk1_p, aux_clk0_p}),
    .IB({sys_clk_n, dly_clk_n, aux_clk1_n, aux_clk0_n}),
    .O(clk_int)
  );

  BUFG BUFG_arr_inst[3:0](
    .I(clk_int),
    .O({sys_clk, dly_clk, aux_clk_1, aux_clk_0})
  );

endmodule
