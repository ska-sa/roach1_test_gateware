module qdr_infrastructure(
    clk_in,//200MHz
    reset,
    qdr_clk_0, qdr_clk_180, qdr_clk_270,
    pll_lock
  );
  input  clk_in, reset;
  output qdr_clk_0, qdr_clk_180, qdr_clk_270;
  output pll_lock;

  /********** Clock Generation ***********/

  wire mem_clk, mem_clk_lock;
  parameter CLK_FREQ = 266;
  
  localparam FX_MULT = CLK_FREQ == 150 ?  3 :
                       CLK_FREQ == 200 ?  2 :
                       CLK_FREQ == 250 ?  5 :
                       CLK_FREQ == 266 ?  8 :
                       CLK_FREQ == 333 ? 10 :
                       CLK_FREQ == 350 ?  7 :
                                          8;

  localparam FX_DIV  = CLK_FREQ == 150 ? 4 :
                       CLK_FREQ == 200 ? 2 :
                       CLK_FREQ == 250 ? 4 :
                       CLK_FREQ == 266 ? 6 :
                       CLK_FREQ == 333 ? 6 :
                       CLK_FREQ == 350 ? 4 :
                                         6;

  localparam CLK_PERIOD = CLK_FREQ == 150 ? 6.666 :
                          CLK_FREQ == 200 ? 5.000 :
                          CLK_FREQ == 250 ? 4.000 :
                          CLK_FREQ == 266 ? 3.760 :
                          CLK_FREQ == 333 ? 3.003 :
                          CLK_FREQ == 350 ? 2.857 :
                                            3.760;

  wire fb_clk;

  DCM_BASE #(
    .CLKFX_DIVIDE(FX_DIV),
    .CLKFX_MULTIPLY(FX_MULT),
    .CLKIN_PERIOD(10.0),
    .DFS_FREQUENCY_MODE("HIGH"),
    .DLL_FREQUENCY_MODE("HIGH")
  ) DCM_BASE_inst (
    .CLK0(fb_clk),
    .CLK180(),
    .CLK270(),
    .CLK2X(),
    .CLK2X180(),
    .CLK90(),
    .CLKDV(),
    .CLKFX(mem_clk),
    .CLKFX180(),
    .LOCKED(mem_clk_lock),
    .CLKFB(fb_clk),
    .CLKIN(clk_in),
    .RST(1'b0)
  );

  /** Generate Phase Matched Controller Clocks **/

  wire pll_fb;

  wire clk_0_int, clk_180_int, clk_270_int;
  PLL_BASE #(
    .BANDWIDTH("OPTIMIZED"),
    .CLKFBOUT_MULT(2),
    .CLKFBOUT_PHASE(0.0),
    .CLKIN_PERIOD(CLK_PERIOD),

    .CLKOUT0_DIVIDE(2),
    .CLKOUT0_DUTY_CYCLE(0.5),
    .CLKOUT0_PHASE(0.0),

    .CLKOUT1_DIVIDE(2),
    .CLKOUT1_DUTY_CYCLE(0.5),
    .CLKOUT1_PHASE(180),

    .CLKOUT2_DIVIDE(2),
    .CLKOUT2_DUTY_CYCLE(0.5),
    .CLKOUT2_PHASE(270),

    .COMPENSATION("SYSTEM_SYNCHRONOUS"),
    .DIVCLK_DIVIDE(1),
    .REF_JITTER(0.100),
    .RESET_ON_LOSS_OF_LOCK("FALSE")
  ) PLL_BASE_inst (
   .CLKFBOUT(pll_fb),
   .CLKOUT0(clk_0_int),
   .CLKOUT1(clk_180_int),
   .CLKOUT2(clk_270_int),
   .CLKOUT3(),
   .CLKOUT4(),
   .CLKOUT5(),
   .LOCKED(pll_lock),
   .CLKFBIN(pll_fb),
   .CLKIN(mem_clk),
   .RST(reset | ~mem_clk_lock)
  );

  BUFG bufg_arr[2:0](
    .I({clk_0_int, clk_180_int, clk_270_int}),
    .O({qdr_clk_0, qdr_clk_180, qdr_clk_270})
  );

endmodule
