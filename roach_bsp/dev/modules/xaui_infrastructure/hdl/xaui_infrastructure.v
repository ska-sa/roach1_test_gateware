module xaui_infrastructure(
    reset,

    mgt_refclk_b_n, mgt_refclk_b_p, 

    mgt_tx_b0_n, mgt_tx_b0_p,
    mgt_rx_b0_n, mgt_rx_b0_p,

    mgt_clk, mgt_clk_lock,

    mgt_tx_reset_0, mgt_rx_reset_0,
    mgt_rxdata_0, mgt_rxcharisk_0,
    mgt_txdata_0, mgt_txcharisk_0,
    mgt_code_comma_0,
    mgt_enchansync_0, mgt_enable_align_0,
    mgt_loopback_0, mgt_powerdown_0,
    mgt_rxlock_0, mgt_syncok_0, mgt_codevalid_0, mgt_rxbufferr_0,
    mgt_rxeqmix_0, mgt_rxeqpole_0, mgt_txpreemphasis_0, mgt_txdiffctrl_0
  );
  parameter DIFF_BOOST = "TRUE";

  input  reset;

  input  mgt_refclk_b_n, mgt_refclk_b_p;

  output [3:0] mgt_tx_b0_n;
  output [3:0] mgt_tx_b0_p;
  input  [3:0] mgt_rx_b0_n;
  input  [3:0] mgt_rx_b0_p;

  output mgt_clk, mgt_clk_lock;

  input  mgt_tx_reset_0, mgt_rx_reset_0;
  output [63:0] mgt_rxdata_0;
  output  [7:0] mgt_rxcharisk_0;
  input  [63:0] mgt_txdata_0;
  input   [7:0] mgt_txcharisk_0;
  output  [7:0] mgt_code_comma_0;
  input   [3:0] mgt_enable_align_0;
  input  mgt_enchansync_0;
  input  mgt_loopback_0, mgt_powerdown_0;
  output  [3:0] mgt_rxlock_0;
  output  [3:0] mgt_syncok_0;
  output  [7:0] mgt_codevalid_0;
  output  [3:0] mgt_rxbufferr_0;
  input   [1:0] mgt_rxeqmix_0;
  input   [3:0] mgt_rxeqpole_0;
  input   [2:0] mgt_txpreemphasis_0;
  input   [2:0] mgt_txdiffctrl_0;


  /********* Polarity Correction Hacks for RX and TX **********/

  localparam TX_POLARITY_HACK_0 = { 1'b1, //lane 3
                                   1'b0, //lane 2
                                   1'b1, //lane 1
                                   1'b0  //lane 0
                                 };
                            
  localparam RX_POLARITY_HACK_0 = { 1'b0, //lane 3
                                    1'b1, //lane 2
                                    1'b0, //lane 1
                                    1'b1  //lane 0
                                  };

  /****************** Dedicated Clock Buffers **********************/
  wire refclk_b;

  wire mgt_clk, mgt_clk_mult_2; //usr clks

  /* Dedicated MGTREFCLK ibufds */
  IBUFDS ibufds_refclk_bottom (
    .I(mgt_refclk_b_p), .IB(mgt_refclk_b_n),
    .O(refclk_b)
  );

  wire mgt_clk_int, mgt_clk_mult_2_int;

  wire refclk_b_ret;

  /* Only one user MGT clock domain, hence only one DCM */
  DCM_BASE DCM_BASE_inst (
    .CLK0(mgt_clk_int),
    .CLK180(),
    .CLK270(),
    .CLK2X(mgt_clk_mult_2_int),
    .CLK2X180(),
    .CLK90(),
    .CLKDV(),
    .CLKFX(),
    .CLKFX180(),
    .LOCKED(mgt_clk_lock),
    .CLKFB(mgt_clk),
    .CLKIN(refclk_b_ret),
    .RST(reset)
  );

  BUFG bufg_mgt(
    .I(mgt_clk_int),
    .O(mgt_clk)
  );

  BUFG bufg_mgt_mult_2(
    .I(mgt_clk_mult_2_int),
    .O(mgt_clk_mult_2)
  );

  /*********************** XAUI Bank 0 *****************************/

  /* Reorder hack due to crossed RX pairs on ROACH hardware
   * When loopback is enable behaviour must transform as if 
   * RX lanes not crossed */
  wire [63:0] mgt_rxdata_int_0;
  assign mgt_rxdata_0 = mgt_loopback_0 ? mgt_rxdata_int_0 :
                        {mgt_rxdata_int_0[15:0],  mgt_rxdata_int_0[31:16], mgt_rxdata_int_0[47:32], mgt_rxdata_int_0[63:48]};

  wire [7:0] mgt_rxcharisk_int_0;
  assign mgt_rxcharisk_0 = mgt_loopback_0 ? mgt_rxcharisk_int_0 :
                           {mgt_rxcharisk_int_0[1:0], mgt_rxcharisk_int_0[3:2], mgt_rxcharisk_int_0[5:4], mgt_rxcharisk_int_0[7:6]};

  wire [7:0] mgt_code_comma_int_0;
  assign mgt_code_comma_0 = mgt_loopback_0 ? mgt_code_comma_int_0 :
                            {mgt_code_comma_int_0[1:0], mgt_code_comma_int_0[3:2], mgt_code_comma_int_0[5:4], mgt_code_comma_int_0[7:6]};

  wire [7:0] mgt_codevalid_int_0;
  assign mgt_codevalid_0 = mgt_loopback_0 ? mgt_codevalid_int_0 :
                           {mgt_codevalid_int_0[1:0], mgt_codevalid_int_0[3:2], mgt_codevalid_int_0[5:4], mgt_codevalid_int_0[7:6]};

  wire [3:0] mgt_enable_align_int_0 = mgt_loopback_0 ? mgt_enable_align_0 :
                                      {mgt_enable_align_0[0], mgt_enable_align_0[1], mgt_enable_align_0[2], mgt_enable_align_0[3]};

  wire [3:0] mgt_rxlock_int_0;
  assign mgt_rxlock_0 = mgt_loopback_0 ? mgt_rxlock_int_0 :
                        {mgt_rxlock_int_0[0], mgt_rxlock_int_0[1], mgt_rxlock_int_0[2], mgt_rxlock_int_0[3]};

  wire [3:0] mgt_syncok_int_0;
  assign mgt_syncok_0 = mgt_loopback_0 ? mgt_syncok_int_0 :
                        {mgt_syncok_int_0[0], mgt_syncok_int_0[1], mgt_syncok_int_0[2], mgt_syncok_int_0[3]};

  wire [3:0] mgt_rxbufferr_int_0;
  assign mgt_rxbufferr_0 = mgt_loopback_0 ? mgt_rxbufferr_int_0 :
                           {mgt_rxbufferr_int_0[0], mgt_rxbufferr_int_0[1], mgt_rxbufferr_int_0[2], mgt_rxbufferr_int_0[3]};


  transceiver_bank #(
    .TX_POLARITY_HACK(TX_POLARITY_HACK_0),
    .RX_POLARITY_HACK(RX_POLARITY_HACK_0),
    .DIFF_BOOST(DIFF_BOOST)
  ) transceiver_bank_0 (
    .reset(reset),
    .rx_reset(mgt_rx_reset_0),
    .tx_reset(mgt_tx_reset_0),
    .refclk(refclk_b), .refclk_ret(refclk_b_ret),
    .mgt_clk(mgt_clk),
    .mgt_clk_mult_2(mgt_clk_mult_2),
    .txp(mgt_tx_b0_p), .txn(mgt_tx_b0_n),
    .rxp(mgt_rx_b0_p), .rxn(mgt_rx_b0_n),
    .txdata(mgt_txdata_0),
    .txcharisk(mgt_txcharisk_0),
    .rxdata(mgt_rxdata_int_0),
    .rxcharisk(mgt_rxcharisk_int_0),
    .code_comma(mgt_code_comma_int_0),
    .enchansync(mgt_enchansync_0),
    .enable_align(mgt_enable_align_int_0),
    .rxlock(mgt_rxlock_int_0),
    .syncok(mgt_syncok_int_0),
    .codevalid(mgt_codevalid_int_0),
    .rxbufferr(mgt_rxbufferr_int_0),

    .loopback(mgt_loopback_0), .powerdown(mgt_powerdown_0),
    .rxeqmix(mgt_rxeqmix_0), .rxeqpole(mgt_rxeqpole_0),
    .txpreemphasis(mgt_txpreemphasis_0), .txdiffctrl(mgt_txdiffctrl_0)
  );


endmodule
