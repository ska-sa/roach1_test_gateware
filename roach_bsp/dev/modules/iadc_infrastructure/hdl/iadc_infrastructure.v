module iadc_infrastructure(
    reset,
    clk_lock,

    adc_clk_n,
    adc_clk_p,

    adc_sync_n,
    adc_sync_p,

    adc_outofrange_i_n,
    adc_outofrange_i_p,
    adc_outofrange_q_n,
    adc_outofrange_q_p,

    adc_data_i_even_n,
    adc_data_i_even_p,
    adc_data_i_odd_n,
    adc_data_i_odd_p,
    adc_data_q_even_n,
    adc_data_q_even_p,
    adc_data_q_odd_n,
    adc_data_q_odd_p,

    adc_ddrb_n,
    adc_ddrb_p,

    adc_clk_0,
    adc_clk_90,
    adc_sync,
    adc_outofrange,
    adc_data,
    adc_ddrb
  );
  parameter ADC_CLK_PERIOD = 10; //period in ns

  /* System Ports */
  input  reset;
  output clk_lock;

  /* FPGA Ports */
  input  adc_clk_n, adc_clk_p;

  input  adc_sync_n, adc_sync_p;

  input  adc_outofrange_i_n, adc_outofrange_i_p;
  input  adc_outofrange_q_n, adc_outofrange_q_p;

  input  [7:0] adc_data_i_even_n;
  input  [7:0] adc_data_i_even_p;
  input  [7:0] adc_data_i_odd_n;
  input  [7:0] adc_data_i_odd_p;
  input  [7:0] adc_data_q_even_n;
  input  [7:0] adc_data_q_even_p;
  input  [7:0] adc_data_q_odd_n;
  input  [7:0] adc_data_q_odd_p;

  output adc_ddrb_n, adc_ddrb_p;

  /* Fabric Ports */
  output adc_clk_0, adc_clk_90;
  output adc_sync;
  output  [3:0] adc_outofrange;
  output [63:0] adc_data;
  input  adc_ddrb;

  /********** ADC Clock ***********/

  /* diff input buffer */
  wire adc_clk_int;
  IBUFGDS #(
    .IOSTANDARD("LVDS"),
    .DIFF_TERM("TRUE")
  ) ibufgds_clk (
    .I(adc_clk_p), .IB(adc_clk_n),
    .O(adc_clk_int)
  );

  /* 
   * This BUFG is required to compensate for the delay introduced by the BUFG
   * on the output of the PLL by introducing additional delay on the feedback
   * line
   */
  wire pll_fb_bufg;
  wire pll_fb;
  BUFG bufg_pll_fb(
    .I(pll_fb_bufg),
    .O(pll_fb)
  );

  PLL_BASE #(
    .BANDWIDTH("OPTIMIZED"),
    .CLKFBOUT_MULT(1),
    .CLKFBOUT_PHASE(0.0),
    .CLKIN_PERIOD(ADC_CLK_PERIOD),

    .CLKOUT0_DIVIDE(1),
    .CLKOUT0_DUTY_CYCLE(0.5),
    .CLKOUT0_PHASE(0.0),

    .CLKOUT1_DIVIDE(1),
    .CLKOUT1_DUTY_CYCLE(0.5),
    .CLKOUT1_PHASE(90),

    .COMPENSATION("SYSTEM_SYNCHRONOUS"),
    .DIVCLK_DIVIDE(1),
    .REF_JITTER(0.100),
    .RESET_ON_LOSS_OF_LOCK("FALSE")
  ) PLL_BASE_inst (
   .CLKFBOUT(pll_fb),
   .CLKOUT0(adc_clk_0_int),
   .CLKOUT1(adc_clk_90_int),
   .CLKOUT2(),
   .CLKOUT3(),
   .CLKOUT4(),
   .CLKOUT5(),
   .LOCKED(clk_lock),
   .CLKFBIN(pll_fb_bufg),
   .CLKIN(adc_clk_int),
   .RST(reset)
  );

  /* Global buffers */

  BUFG bufg_adc_clk [1:0] (
    .I({adc_clk_0_int, adc_clk_90_int}),
    .O({adc_clk_0, adc_clk_90})
  );

  /************ Sync Port *************/

  IBUFDS #(
    .IOSTANDARD("LVDS"),
    .DIFF_TERM("TRUE")
  ) ibufds_sync (
    .I(adc_sync_p), .IB(adc_sync_n),
    .O(adc_sync)
  );

  /************ Out-of-range  *************/

  wire [1:0] adc_outofrange_int;
  IBUFDS #(
    .IOSTANDARD("LVDS"),
    .DIFF_TERM("TRUE")
  ) ibufds_outofrange [1:0] (
    .I({adc_outofrange_i_p, adc_outofrange_q_p}), .IB({adc_outofrange_i_n, adc_outofrange_q_n}),
    .O(adc_outofrange_int)
  );

  wire [1:0] adc_outofrange_0;
  wire [1:0] adc_outofrange_1;

  IDDR #(
    .DDR_CLK_EDGE("SAME_EDGE_PIPELINED"),
    .INIT_Q1(1'b0),
    .INIT_Q2(1'b0),
    .SRTYPE(1'b1)
  ) iddr_outofrange[1:0](
    .D(adc_outofrange_int), .DDLY(adc_outofrange_int), //this is weird -- which do I use? how do I specify which to use?
    .S(1'b0), .R(1'b0),
    .Q1(adc_outofrange_0), .Q2(adc_outofrange_1),
    .C(adc_clk), .CE(1'b1)
  );

  assign adc_outofrange = {adc_outofrange_1, adc_outofrange_0}; //this is most probably wrong - but hey... TODO:check


  /******************* Data Buffers/IDDRs ******************/

  wire [7:0] adc_data_i_even;
  wire [7:0] adc_data_i_odd;
  wire [7:0] adc_data_q_even;
  wire [7:0] adc_data_q_odd;

  IBUFDS #(
    .IOSTANDARD("LVDS"),
    .DIFF_TERM("TRUE")
  ) ibufds_data [31:0] (
    .I ({adc_data_i_even_p, adc_data_i_odd_p, adc_data_q_even_p, adc_data_q_odd_p}),
    .IB({adc_data_i_even_n, adc_data_i_odd_n, adc_data_q_even_n, adc_data_q_odd_n}),
    .O ({adc_data_i_even,   adc_data_i_odd,   adc_data_q_even,   adc_data_q_odd  })
  );

  wire [7:0] adc_data_i_even_R;
  wire [7:0] adc_data_i_even_F;
  wire [7:0] adc_data_i_odd_R;
  wire [7:0] adc_data_i_odd_F;
  wire [7:0] adc_data_q_even_R;
  wire [7:0] adc_data_q_even_F;
  wire [7:0] adc_data_q_odd_R;
  wire [7:0] adc_data_q_odd_F;

  IDDR #(
    .DDR_CLK_EDGE("SAME_EDGE_PIPELINED"),
    .INIT_Q1(1'b0),
    .INIT_Q2(1'b0),
    .SRTYPE(1'b1)
  ) iddr_outofrange[31:0](
    //this is weird -- which do I use? how do I specify which to use?
    .D   ({adc_data_i_even, adc_data_i_odd, adc_data_q_even, adc_data_q_odd}),
    .DDLY({adc_data_i_even, adc_data_i_odd, adc_data_q_even, adc_data_q_odd}),
    .S(1'b0), .R(1'b0),
    .Q1({adc_data_i_even_R, adc_data_i_odd_R, adc_data_q_even_R, adc_data_q_odd_R}),
    .Q2({adc_data_i_even_F, adc_data_i_odd_F, adc_data_q_even_F, adc_data_q_odd_F}),
    .C(adc_clk), .CE(1'b1)
  );

  assign adc_data = {adc_data_q_even_R, adc_data_q_odd_R, adc_data_q_even_F, adc_data_q_odd_F, 
                     adc_data_i_even_R, adc_data_i_odd_R, adc_data_i_even_F, adc_data_i_odd_F}; 

  /************** Reset Output Buffer ****************/ 

  OBUFDS #(
    .IOSTANDARD("LVDS")
  ) ibufgds_data (
    .I (adc_ddrb),
    .O (adc_ddrb_p),
    .OB(adc_ddrb_n)
  );


endmodule
