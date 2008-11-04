module iadc_infrastructure(
    reset,
    clk_lock,

    adc_clk,

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
    adc_ddrb,
    adc_dcm_reset,
    adc_ctrl_clk_buf,
    adc_ctrl_data_buf,
    adc_ctrl_strobe_n_buf,
    adc_mode_buf,
    adc_ctrl_clk,
    adc_ctrl_data,
    adc_ctrl_strobe_n,
    adc_mode
  );
  parameter ADC_CLK_PERIOD = 10; //period in ns

  /* System Ports */
  input  reset;
  output clk_lock;

  input  adc_clk;
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
  output [3:0] adc_sync;
  output  [3:0] adc_outofrange;
  output [63:0] adc_data;
  input  adc_ddrb, adc_dcm_reset;

  /* Ctrl IOB ports */
  output adc_ctrl_clk_buf;
  output adc_ctrl_data_buf;
  output adc_ctrl_strobe_n_buf;
  output adc_mode_buf;
  input  adc_ctrl_clk;
  input  adc_ctrl_data;
  input  adc_ctrl_strobe_n;
  input  adc_mode;

  /********** ADC Clock ***********/

  /* diff input buffer */
  wire adc_clk_int;

  DCM_BASE #(
    .CLKIN_PERIOD          (3.3),
    .DESKEW_ADJUST         ("SYSTEM_SYNCHRONOUS"),
    .DFS_FREQUENCY_MODE    ("HIGH"),
    .DLL_FREQUENCY_MODE    ("HIGH"),
    .DUTY_CYCLE_CORRECTION ("TRUE")
  ) DCM_BASE_inst (
    .CLK0(adc_clk_0_int),
    .CLK2X(),
    .CLK2X180(),
    .CLK90(adc_clk_90_int),
    .CLK180(),
    .CLK270(),
    .CLKDV(),
    .CLKFX(),
    .CLKFX180(),
    .LOCKED(clk_lock),
    .CLKFB(adc_clk_0),
    .CLKIN(adc_clk),
    .RST(reset || adc_dcm_reset)
  );

  /* Global buffers */

  BUFG bufg_adc_clk [1:0] (
    .I({adc_clk_0_int, adc_clk_90_int}),
    .O({adc_clk_0,     adc_clk_90})
  );

  /************ Sync Port *************/

  wire adc_sync_int;

  IBUFDS #(
    .IOSTANDARD("LVDS_25"),
    .DIFF_TERM("TRUE")
  ) ibufds_sync (
    .I(adc_sync_p), .IB(adc_sync_n),
    .O(adc_sync_int)
  );

  reg [3:0] adc_sync;

  always @(posedge adc_clk_0) begin
    adc_sync[0] <= adc_sync_int;
  end
  always @(posedge adc_clk_90) begin
    adc_sync[1] <= adc_sync_int;
  end
  always @(negedge adc_clk_0) begin
    adc_sync[2] <= adc_sync_int;
  end
  always @(negedge adc_clk_90) begin
    adc_sync[3] <= adc_sync_int;
  end



  /************ Out-of-range  *************/

  wire [1:0] adc_outofrange_int;
  IBUFDS #(
    .IOSTANDARD("LVDS_25"),
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
    .INIT_Q2(1'b0)
  ) iddr_outofrange[1:0](
    .D(adc_outofrange_int),
    .S(1'b0), .R(1'b0),
    .Q1(adc_outofrange_0), .Q2(adc_outofrange_1),
    .C(adc_clk_0),
    .CE(1'b1)
  );

  assign adc_outofrange = {adc_outofrange_1, adc_outofrange_0}; //this is most probably wrong - but hey... TODO:check


  /******************* Data Buffers/IDDRs ******************/

  wire [7:0] adc_data_i_even;
  wire [7:0] adc_data_i_odd;
  wire [7:0] adc_data_q_even;
  wire [7:0] adc_data_q_odd;

  IBUFDS #(
    .IOSTANDARD("LVDS_25"),
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
    .INIT_Q2(1'b0)
  ) iddr_data[31:0](
    .D({adc_data_i_even, adc_data_i_odd, adc_data_q_even, adc_data_q_odd}),
    .S(1'b0), .R(1'b0),
    .Q1({adc_data_i_even_R, adc_data_i_odd_R, adc_data_q_even_R, adc_data_q_odd_R}),
    .Q2({adc_data_i_even_F, adc_data_i_odd_F, adc_data_q_even_F, adc_data_q_odd_F}),
    .C(adc_clk_0),
    .CE(1'b1)
  );

  assign adc_data = {adc_data_i_even_R, adc_data_i_odd_R, adc_data_i_even_F, adc_data_i_odd_F, 
                     adc_data_q_even_R, adc_data_q_odd_R, adc_data_q_even_F, adc_data_q_odd_F}; 

  /************** Reset Output Buffer ****************/ 

  OBUFDS #(
    .IOSTANDARD("LVDS_25")
  ) ibufgds_data (
    .I (adc_ddrb),
    .O (adc_ddrb_p),
    .OB(adc_ddrb_n)
  );

  /****************** CTRL IOBs *********************/

  OBUF #(
    .IOSTANDARD("LVCMOS25"),
    .SLEW("SLOW")
  ) obuf_ctrl[3:0] (
    .I({adc_ctrl_clk,     adc_ctrl_data,     adc_ctrl_strobe_n,     adc_mode}),
    .O({adc_ctrl_clk_buf, adc_ctrl_data_buf, adc_ctrl_strobe_n_buf, adc_mode_buf})
  );

endmodule
