module qdr_infrastructure(
    clk_in, reset,
    qdr_clk_0, qdr_clk_180, qdr_clk_270,
    pll_lock
  );
  input  clk_in, reset;
  output qdr_clk_0, qdr_clk_180, qdr_clk_270;
  output pll_lock;

  /********** Clock Generation ***********/

  wire mem_clk, mem_clk_lock;
  parameter CLK_FREQ = 266;
  
  //scale DCM output clocks to > 400MHz and < 1000MHz for PLL
  localparam FX_MULT = CLK_FREQ == 150 ?  3*3 :
                       CLK_FREQ == 200 ?  2*2 :
                       CLK_FREQ == 250 ?  5*2 :
                       CLK_FREQ == 266 ?  8*2 :
                       CLK_FREQ == 333 ? 10*2 :
                                          8*2;

  localparam FX_DIV  = CLK_FREQ == 150 ? 2 :
                       CLK_FREQ == 200 ? 1 :
                       CLK_FREQ == 250 ? 2 :
                       CLK_FREQ == 266 ? 3 :
                       CLK_FREQ == 333 ? 3 :
                                         3;

  //divide the clocks down to the intended value in the PLL
  localparam PLL_DIV = CLK_FREQ == 150 ? 3 :
                       CLK_FREQ == 200 ? 2 :
                       CLK_FREQ == 250 ? 2 :
                       CLK_FREQ == 266 ? 2 :
                       CLK_FREQ == 333 ? 2 :
                                         2;


  localparam CLK_PERIOD = CLK_FREQ == 150 ? 6666.0/3.0 :
                          CLK_FREQ == 200 ? 5000.0/2.0 :
                          CLK_FREQ == 250 ? 4000.0/2.0 :
                          CLK_FREQ == 266 ? 3760.0/2.0 :
                          CLK_FREQ == 333 ? 3003.0/2.0 :
                                            3760.0/2.0;

  wire fb_clk;

  DCM_BASE #(
    .CLKFX_DIVIDE(FX_DIV),
    .CLKFX_MULTIPLY(FX_MULT),
    .CLKIN_PERIOD(10.0)
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
    .RST(reset)
  );

  /** Generate Phase Matched Controller Clocks **/

  wire pll_fb;

  wire clk_0_int, clk_180_int, clk_270_int;
  PLL_BASE #(
    .BANDWIDTH("OPTIMIZED"),
    .CLKFBOUT_MULT(1),
    .CLKFBOUT_PHASE(0.0),
    .CLKIN_PERIOD(CLK_PERIOD/1000.00),

    .CLKOUT0_DIVIDE(PLL_DIV),
    .CLKOUT0_DUTY_CYCLE(0.5),
    .CLKOUT0_PHASE(0.0),

    .CLKOUT1_DIVIDE(PLL_DIV),
    .CLKOUT1_DUTY_CYCLE(0.5),
    .CLKOUT1_PHASE(180),

    .CLKOUT2_DIVIDE(PLL_DIV),
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
