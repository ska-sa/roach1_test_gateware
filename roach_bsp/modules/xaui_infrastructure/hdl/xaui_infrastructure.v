module xaui_infrastructure(
    reset,

    mgt_refclk_t_n, mgt_refclk_t_p, 
    mgt_refclk_b_n, mgt_refclk_b_p, 

    mgt_txn_t0_n, mgt_txn_t0_p,
    mgt_txn_t1_n, mgt_txn_t1_p,
    mgt_txn_b0_n, mgt_txn_b0_p,
    mgt_txn_b1_n, mgt_txn_b1_p,
    mgt_rxn_t0_n, mgt_rxn_t0_p,
    mgt_rxn_t1_n, mgt_rxn_t1_p,
    mgt_rxn_b0_n, mgt_rxn_b0_p,
    mgt_rxn_b1_n, mgt_rxn_b1_p,

    mgt_clk, mgt_clk_lock,

    mgt_tx_reset_3, mgt_rx_reset_3,
    mgt_rxdata_3, mgt_rxcharisk_3,
    mgt_txdata_3, mgt_txcharisk_3,
    mgt_code_comma_3,
    mgt_enchansync_3, mgt_enable_align_3,
    mgt_loopback_3, mgt_powerdown_3,
    mgt_lock_3, mgt_syncok_3, mgt_codevalid_3, mgt_rxbufferr_3,
    mgt_rxeqmix_3, mgt_rxeqpole_3, mgt_txpreemphasis_3, mgt_txdiffctrl_3,
    mgt_tx_reset_2, mgt_rx_reset_2,
    mgt_rxdata_2, mgt_rxcharisk_2,
    mgt_txdata_2, mgt_txcharisk_2,
    mgt_code_comma_2,
    mgt_enchansync_2, mgt_enable_align_2,
    mgt_loopback_2, mgt_powerdown_2,
    mgt_lock_2, mgt_syncok_2, mgt_codevalid_2, mgt_rxbufferr_2,
    mgt_rxeqmix_2, mgt_rxeqpole_2, mgt_txpreemphasis_2, mgt_txdiffctrl_2,
    mgt_tx_reset_1, mgt_rx_reset_1,
    mgt_rxdata_1, mgt_rxcharisk_1,
    mgt_txdata_1, mgt_txcharisk_1,
    mgt_code_comma_1,
    mgt_enchansync_1, mgt_enable_align_1,
    mgt_loopback_1, mgt_powerdown_1,
    mgt_lock_1, mgt_syncok_1, mgt_codevalid_1, mgt_rxbufferr_1,
    mgt_rxeqmix_1, mgt_rxeqpole_1, mgt_txpreemphasis_1, mgt_txdiffctrl_1,
    mgt_tx_reset_0, mgt_rx_reset_0,
    mgt_rxdata_0, mgt_rxcharisk_0,
    mgt_txdata_0, mgt_txcharisk_0,
    mgt_code_comma_0,
    mgt_enchansync_0, mgt_enable_align_0,
    mgt_loopback_0, mgt_powerdown_0,
    mgt_lock_0, mgt_syncok_0, mgt_codevalid_0, mgt_rxbufferr_0,
    mgt_rxeqmix_0, mgt_rxeqpole_0, mgt_txpreemphasis_0, mgt_txdiffctrl_0
  );

  input  reset;

  input  mgt_refclk_t_n, mgt_refclk_t_p;
  input  mgt_refclk_b_n, mgt_refclk_b_p;

  output [3:0] mgt_txn_t0_n;
  output [3:0] mgt_txn_t0_p;
  output [3:0] mgt_txn_t1_n;
  output [3:0] mgt_txn_t1_p;
  output [3:0] mgt_txn_b0_n;
  output [3:0] mgt_txn_b0_p;
  output [3:0] mgt_txn_b1_n;
  output [3:0] mgt_txn_b1_p;
  input  [3:0] mgt_rxn_t0_n;
  input  [3:0] mgt_rxn_t0_p;
  input  [3:0] mgt_rxn_t1_n;
  input  [3:0] mgt_rxn_t1_p;
  input  [3:0] mgt_rxn_b0_n;
  input  [3:0] mgt_rxn_b0_p;
  input  [3:0] mgt_rxn_b1_n;
  input  [3:0] mgt_rxn_b1_p;

  output mgt_clk, mgt_clk_lock;

  input  mgt_tx_reset_3, mgt_rx_reset_3;
  output [63:0] mgt_rxdata_3;
  output  [7:0] mgt_rxcharisk_3;
  input  [63:0] mgt_txdata_3;
  input   [7:0] mgt_txcharisk_3;
  output  [7:0] mgt_code_comma_3;
  input   [3:0] mgt_enchansync_3;
  input  mgt_enable_align_3;
  input  mgt_loopback_3, mgt_powerdown_3;
  output  [3:0] mgt_lock_3;
  output  [3:0] mgt_syncok_3;
  output  [7:0] mgt_codevalid_3;
  output  [3:0] mgt_rxbufferr_3;
  input   [1:0] mgt_rxeqmix_3;
  input   [3:0] mgt_rxeqpole_3;
  input   [2:0] mgt_txpreemphasis_3;
  input   [2:0] mgt_txdiffctrl_3;

  input  mgt_tx_reset_2, mgt_rx_reset_2;
  output [63:0] mgt_rxdata_2;
  output  [7:0] mgt_rxcharisk_2;
  input  [63:0] mgt_txdata_2;
  input   [7:0] mgt_txcharisk_2;
  output  [7:0] mgt_code_comma_2;
  input   [3:0] mgt_enchansync_2;
  input  mgt_enable_align_2;
  input  mgt_loopback_2, mgt_powerdown_2;
  output  [3:0] mgt_lock_2;
  output  [3:0] mgt_syncok_2;
  output  [7:0] mgt_codevalid_2;
  output  [3:0] mgt_rxbufferr_2;
  input   [1:0] mgt_rxeqmix_2;
  input   [3:0] mgt_rxeqpole_2;
  input   [2:0] mgt_txpreemphasis_2;
  input   [2:0] mgt_txdiffctrl_2;

  input  mgt_tx_reset_1, mgt_rx_reset_1;
  output [63:0] mgt_rxdata_1;
  output  [7:0] mgt_rxcharisk_1;
  input  [63:0] mgt_txdata_1;
  input   [7:0] mgt_txcharisk_1;
  output  [7:0] mgt_code_comma_1;
  input   [3:0] mgt_enchansync_1;
  input  mgt_enable_align_1;
  input  mgt_loopback_1, mgt_powerdown_1;
  output  [3:0] mgt_lock_1;
  output  [3:0] mgt_syncok_1;
  output  [7:0] mgt_codevalid_1;
  output  [3:0] mgt_rxbufferr_1;
  input   [1:0] mgt_rxeqmix_1;
  input   [3:0] mgt_rxeqpole_1;
  input   [2:0] mgt_txpreemphasis_1;
  input   [2:0] mgt_txdiffctrl_1;

  input  mgt_tx_reset_0, mgt_rx_reset_0;
  output [63:0] mgt_rxdata_0;
  output  [7:0] mgt_rxcharisk_0;
  input  [63:0] mgt_txdata_0;
  input   [7:0] mgt_txcharisk_0;
  output  [7:0] mgt_code_comma_0;
  input   [3:0] mgt_enchansync_0;
  input  mgt_enable_align_0;
  input  mgt_loopback_0, mgt_powerdown_0;
  output  [3:0] mgt_lock_0;
  output  [3:0] mgt_syncok_0;
  output  [7:0] mgt_codevalid_0;
  output  [3:0] mgt_rxbufferr_0;
  input   [1:0] mgt_rxeqmix_0;
  input   [3:0] mgt_rxeqpole_0;
  input   [2:0] mgt_txpreemphasis_0;
  input   [2:0] mgt_txdiffctrl_0;


  /********* Polarity Correction Hacks for RX and TX **********/

  localparam RXPOLARITY_HACK_3 = { 1'b0, //lane 3
                                   1'b1, //lane 2
                                   1'b0, //lane 1
                                   1'b1  //lane 0
                                 };
  localparam RXPOLARITY_HACK_2 = { 1'b0, //lane 3
                                   1'b1, //lane 2
                                   1'b0, //lane 1
                                   1'b1  //lane 0
                                 };
  localparam RXPOLARITY_HACK_1 = { 1'b0, //lane 3
                                   1'b1, //lane 2
                                   1'b0, //lane 1
                                   1'b1  //lane 0
                                 };
  localparam RXPOLARITY_HACK_0 = { 1'b0, //lane 3
                                   1'b1, //lane 2
                                   1'b0, //lane 1
                                   1'b1  //lane 0
                                 };
  localparam TXPOLARITY_HACK_3 = { 1'b1, //lane 3
                                   1'b0, //lane 2
                                   1'b1, //lane 1
                                   1'b0  //lane 0
                                 };
  localparam TXPOLARITY_HACK_2 = { 1'b1, //lane 3
                                   1'b0, //lane 2
                                   1'b1, //lane 1
                                   1'b0  //lane 0
                                 };
  localparam TXPOLARITY_HACK_1 = { 1'b1, //lane 3
                                   1'b0, //lane 2
                                   1'b1, //lane 1
                                   1'b0  //lane 0
                                 };
  localparam TXPOLARITY_HACK_0 = { 1'b1, //lane 3
                                   1'b0, //lane 2
                                   1'b1, //lane 1
                                   1'b0  //lane 0
                                 };
                            

  /****************** Dedicated Clock Buffers **********************/
  wire refclk_t; //fancy mgt refclks
  wire refclk_b;

  wire mgt_clk, mgt_clk_mult_2; //usr clks

  /* Dedicated MGTREFCLK ibufds */
  IBUFDS ibufds_refclk_top (
    .I(mgt_refclk_t_p), .IB(mgt_refclk_t_n),
    .O(refclk_t)
  );
  IBUFDS ibufds_refclk_bottom (
    .I(mgt_refclk_b_p), .IB(mgt_refclk_b_n),
    .O(refclk_b)
  );

  wire mgt_clk_int, mgt_clk_mult_2_int;

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
    .CLKFB(mgt_clk_int),
    .CLKIN(refclk_t),
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

  wire [3:0] mgt_enable_align_int_0 = mgt_loopback_0 ? mgt_enable_align_int_0 :
                                      {mgt_enable_align_int_0[0], mgt_enable_align_int_0[1], mgt_enable_align_int_0[2], mgt_enable_align_int_0[3]};

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
    .TXPOLARITY_HACK(TXPOLARITY_HACK_0),
    .RXPOLARITY_HACK(RXPOLARITY_HACK_0),
    .DIFF_BOOST(DIFF_BOOST)
  ) transceiver_bank_0 (
    .reset(reset),
    .rx_reset(mgt_rx_reset_0),
    .tx_reset(mgt_tx_reset_0),
    .refclk(refclk_b),
    .mgt_clk(mgt_clk),
    .mgt_clk_mult_2(mgt_clk_mult_2),
    .txp(mgt_txp_b_0), .txn(mgt_txn_b_0),
    .rxp(mgt_rxp_b_0), .rxn(mgt_rxn_b_0),
    .txdata(txdata_0),
    .txcharisk(txcharisk_0),

    .rxdata(mgt_rxdata_int_0),
    .rxcharisk(mgt_rxcharisk_int_0),
    .code_comma(mgt_code_comma_int_0),
    .enchansync(mgt_enchansync_0),
    .enable_align(mgt_enable_align_int_0),
    .rxlock(mt_rxlock_int_0),
    .syncok(mgt_syncok_int_0),
    .codevalid(mgt_codevalid_int_0),
    .rxbufferr(mgt_rxbufferr_int_0),

    .loopback(mgt_loopback_0), .powerdown(mgt_powerdown_0),
    .rxeqmix(mgt_rxeqmix_0), .rxeqpole(mgt_rxeqpole_0),
    .txpreemphasis(mgt_txpreemphasis_0), .txdiffctrl(mgt_txdiffctrl_0)
  );

  /*********************** XAUI Bank 1 *****************************/

  /* Reorder hack due to crossed RX pairs on ROACH hardware
   * When loopback is enable behaviour must transform as if 
   * RX lanes not crossed */
  wire [63:0] mgt_rxdata_int_1;
  assign mgt_rxdata_1 = mgt_loopback_1 ? mgt_rxdata_int_1 :
                        {mgt_rxdata_int_1[15:0],  mgt_rxdata_int_1[31:16], mgt_rxdata_int_1[47:32], mgt_rxdata_int_1[63:48]};

  wire [7:0] mgt_rxcharisk_int_1;
  assign mgt_rxcharisk_1 = mgt_loopback_1 ? mgt_rxcharisk_int_1 :
                           {mgt_rxcharisk_int_1[1:0], mgt_rxcharisk_int_1[3:2], mgt_rxcharisk_int_1[5:4], mgt_rxcharisk_int_1[7:6]};

  wire [7:0] mgt_code_comma_int_1;
  assign mgt_code_comma_1 = mgt_loopback_1 ? mgt_code_comma_int_1 :
                            {mgt_code_comma_int_1[1:0], mgt_code_comma_int_1[3:2], mgt_code_comma_int_1[5:4], mgt_code_comma_int_1[7:6]};

  wire [7:0] mgt_codevalid_int_1;
  assign mgt_codevalid_1 = mgt_loopback_1 ? mgt_codevalid_int_1 :
                           {mgt_codevalid_int_1[1:0], mgt_codevalid_int_1[3:2], mgt_codevalid_int_1[5:4], mgt_codevalid_int_1[7:6]};

  wire [3:0] mgt_enable_align_int_1 = mgt_loopback_1 ? mgt_enable_align_int_1 :
                                      {mgt_enable_align_int_1[0], mgt_enable_align_int_1[1], mgt_enable_align_int_1[2], mgt_enable_align_int_1[3]};

  wire [3:0] mgt_rxlock_int_1;
  assign mgt_rxlock_1 = mgt_loopback_1 ? mgt_rxlock_int_1 :
                        {mgt_rxlock_int_1[0], mgt_rxlock_int_1[1], mgt_rxlock_int_1[2], mgt_rxlock_int_1[3]};

  wire [3:0] mgt_syncok_int_1;
  assign mgt_syncok_1 = mgt_loopback_1 ? mgt_syncok_int_1 :
                        {mgt_syncok_int_1[0], mgt_syncok_int_1[1], mgt_syncok_int_1[2], mgt_syncok_int_1[3]};

  wire [3:0] mgt_rxbufferr_int_1;
  assign mgt_rxbufferr_1 = mgt_loopback_1 ? mgt_rxbufferr_int_1 :
                           {mgt_rxbufferr_int_1[0], mgt_rxbufferr_int_1[1], mgt_rxbufferr_int_1[2], mgt_rxbufferr_int_1[3]};

  transceiver_bank #(
    .TXPOLARITY_HACK(TXPOLARITY_HACK_1),
    .RXPOLARITY_HACK(RXPOLARITY_HACK_1),
    .DIFF_BOOST(DIFF_BOOST)
  ) transceiver_bank_1 (
    .reset(reset),
    .rx_reset(mgt_rx_reset_1),
    .tx_reset(mgt_tx_reset_1),
    .refclk(refclk_b),
    .mgt_clk(mgt_clk),
    .mgt_clk_mult_2(mgt_clk_mult_2),
    .txp(mgt_txp_b_1), .txn(mgt_txn_b_1),
    .rxp(mgt_rxp_b_1), .rxn(mgt_rxn_b_1),
    .txdata(txdata_1),
    .txcharisk(txcharisk_1),

    .rxdata(mgt_rxdata_int_1),
    .rxcharisk(mgt_rxcharisk_int_1),
    .code_comma(mgt_code_comma_int_1),
    .enchansync(mgt_enchansync_1),
    .enable_align(mgt_enable_align_int_1),
    .rxlock(mt_rxlock_int_1),
    .syncok(mgt_syncok_int_1),
    .codevalid(mgt_codevalid_int_1),
    .rxbufferr(mgt_rxbufferr_int_1),

    .loopback(mgt_loopback_1), .powerdown(mgt_powerdown_1),
    .rxeqmix(mgt_rxeqmix_1), .rxeqpole(mgt_rxeqpole_1),
    .txpreemphasis(mgt_txpreemphasis_1), .txdiffctrl(mgt_txdiffctrl_1)
  );
  /*********************** XAUI Bank 2 *****************************/

  /* Reorder hack due to crossed RX pairs on ROACH hardware
   * When loopback is enable behaviour must transform as if 
   * RX lanes not crossed */
  wire [63:0] mgt_rxdata_int_2;
  assign mgt_rxdata_2 = mgt_loopback_2 ? mgt_rxdata_int_2 :
                        {mgt_rxdata_int_2[15:0],  mgt_rxdata_int_2[31:16], mgt_rxdata_int_2[47:32], mgt_rxdata_int_2[63:48]};

  wire [7:0] mgt_rxcharisk_int_2;
  assign mgt_rxcharisk_2 = mgt_loopback_2 ? mgt_rxcharisk_int_2 :
                           {mgt_rxcharisk_int_2[1:0], mgt_rxcharisk_int_2[3:2], mgt_rxcharisk_int_2[5:4], mgt_rxcharisk_int_2[7:6]};

  wire [7:0] mgt_code_comma_int_2;
  assign mgt_code_comma_2 = mgt_loopback_2 ? mgt_code_comma_int_2 :
                            {mgt_code_comma_int_2[1:0], mgt_code_comma_int_2[3:2], mgt_code_comma_int_2[5:4], mgt_code_comma_int_2[7:6]};

  wire [7:0] mgt_codevalid_int_2;
  assign mgt_codevalid_2 = mgt_loopback_2 ? mgt_codevalid_int_2 :
                           {mgt_codevalid_int_2[1:0], mgt_codevalid_int_2[3:2], mgt_codevalid_int_2[5:4], mgt_codevalid_int_2[7:6]};

  wire [3:0] mgt_enable_align_int_2 = mgt_loopback_2 ? mgt_enable_align_int_2 :
                                      {mgt_enable_align_int_2[0], mgt_enable_align_int_2[1], mgt_enable_align_int_2[2], mgt_enable_align_int_2[3]};

  wire [3:0] mgt_rxlock_int_2;
  assign mgt_rxlock_2 = mgt_loopback_2 ? mgt_rxlock_int_2 :
                        {mgt_rxlock_int_2[0], mgt_rxlock_int_2[1], mgt_rxlock_int_2[2], mgt_rxlock_int_2[3]};

  wire [3:0] mgt_syncok_int_2;
  assign mgt_syncok_2 = mgt_loopback_2 ? mgt_syncok_int_2 :
                        {mgt_syncok_int_2[0], mgt_syncok_int_2[1], mgt_syncok_int_2[2], mgt_syncok_int_2[3]};

  wire [3:0] mgt_rxbufferr_int_2;
  assign mgt_rxbufferr_2 = mgt_loopback_2 ? mgt_rxbufferr_int_2 :
                           {mgt_rxbufferr_int_2[0], mgt_rxbufferr_int_2[1], mgt_rxbufferr_int_2[2], mgt_rxbufferr_int_2[3]};

  transceiver_bank #(
    .TXPOLARITY_HACK(TXPOLARITY_HACK_2),
    .RXPOLARITY_HACK(RXPOLARITY_HACK_2),
    .DIFF_BOOST(DIFF_BOOST)
  ) transceiver_bank_2 (
    .reset(reset),
    .rx_reset(mgt_rx_reset_2),
    .tx_reset(mgt_tx_reset_2),
    .refclk(refclk_b),
    .mgt_clk(mgt_clk),
    .mgt_clk_mult_2(mgt_clk_mult_2),
    .txp(mgt_txp_t_0), .txn(mgt_txn_t_0),
    .rxp(mgt_rxp_t_0), .rxn(mgt_rxn_t_0),
    .txdata(txdata_2),
    .txcharisk(txcharisk_2),

    .rxdata(mgt_rxdata_int_2),
    .rxcharisk(mgt_rxcharisk_int_2),
    .code_comma(mgt_code_comma_int_2),
    .enchansync(mgt_enchansync_2),
    .enable_align(mgt_enable_align_int_2),
    .rxlock(mt_rxlock_int_2),
    .syncok(mgt_syncok_int_2),
    .codevalid(mgt_codevalid_int_2),
    .rxbufferr(mgt_rxbufferr_int_2),

    .loopback(mgt_loopback_2), .powerdown(mgt_powerdown_2),
    .rxeqmix(mgt_rxeqmix_2), .rxeqpole(mgt_rxeqpole_2),
    .txpreemphasis(mgt_txpreemphasis_2), .txdiffctrl(mgt_txdiffctrl_2)
  );


  /*********************** XAUI Bank 3 *****************************/

  /* Reorder hack due to crossed RX pairs on ROACH hardware
   * When loopback is enable behaviour must transform as if 
   * RX lanes not crossed */
  wire [63:0] mgt_rxdata_int_3;
  assign mgt_rxdata_3 = mgt_loopback_3 ? mgt_rxdata_int_3 :
                        {mgt_rxdata_int_3[15:0],  mgt_rxdata_int_3[31:16], mgt_rxdata_int_3[47:32], mgt_rxdata_int_3[63:48]};

  wire [7:0] mgt_rxcharisk_int_3;
  assign mgt_rxcharisk_3 = mgt_loopback_3 ? mgt_rxcharisk_int_3 :
                           {mgt_rxcharisk_int_3[1:0], mgt_rxcharisk_int_3[3:2], mgt_rxcharisk_int_3[5:4], mgt_rxcharisk_int_3[7:6]};

  wire [7:0] mgt_code_comma_int_3;
  assign mgt_code_comma_3 = mgt_loopback_3 ? mgt_code_comma_int_3 :
                            {mgt_code_comma_int_3[1:0], mgt_code_comma_int_3[3:2], mgt_code_comma_int_3[5:4], mgt_code_comma_int_3[7:6]};

  wire [7:0] mgt_codevalid_int_3;
  assign mgt_codevalid_3 = mgt_loopback_3 ? mgt_codevalid_int_3 :
                           {mgt_codevalid_int_3[1:0], mgt_codevalid_int_3[3:2], mgt_codevalid_int_3[5:4], mgt_codevalid_int_3[7:6]};

  wire [3:0] mgt_enable_align_int_3 = mgt_loopback_3 ? mgt_enable_align_int_3 :
                                      {mgt_enable_align_int_3[0], mgt_enable_align_int_3[1], mgt_enable_align_int_3[2], mgt_enable_align_int_3[3]};

  wire [3:0] mgt_rxlock_int_3;
  assign mgt_rxlock_3 = mgt_loopback_3 ? mgt_rxlock_int_3 :
                        {mgt_rxlock_int_3[0], mgt_rxlock_int_3[1], mgt_rxlock_int_3[2], mgt_rxlock_int_3[3]};

  wire [3:0] mgt_syncok_int_3;
  assign mgt_syncok_3 = mgt_loopback_3 ? mgt_syncok_int_3 :
                        {mgt_syncok_int_3[0], mgt_syncok_int_3[1], mgt_syncok_int_3[2], mgt_syncok_int_3[3]};

  wire [3:0] mgt_rxbufferr_int_3;
  assign mgt_rxbufferr_3 = mgt_loopback_3 ? mgt_rxbufferr_int_3 :
                           {mgt_rxbufferr_int_3[0], mgt_rxbufferr_int_3[1], mgt_rxbufferr_int_3[2], mgt_rxbufferr_int_3[3]};


  transceiver_bank #(
    .TXPOLARITY_HACK(TXPOLARITY_HACK_3),
    .RXPOLARITY_HACK(RXPOLARITY_HACK_3),
    .DIFF_BOOST(DIFF_BOOST)
  ) transceiver_bank_3 (
    .reset(reset),
    .rx_reset(mgt_rx_reset_3),
    .tx_reset(mgt_tx_reset_3),
    .refclk(refclk_b),
    .mgt_clk(mgt_clk),
    .mgt_clk_mult_2(mgt_clk_mult_2),
    .txp(mgt_txp_t_1), .txn(mgt_txn_t_1),
    .rxp(mgt_rxp_t_1), .rxn(mgt_rxn_t_1),
    .txdata(txdata_3),
    .txcharisk(txcharisk_3),

    .rxdata(mgt_rxdata_int_3),
    .rxcharisk(mgt_rxcharisk_int_3),
    .code_comma(mgt_code_comma_int_3),
    .enchansync(mgt_enchansync_3),
    .enable_align(mgt_enable_align_int_3),
    .rxlock(mt_rxlock_int_3),
    .syncok(mgt_syncok_int_3),
    .codevalid(mgt_codevalid_int_3),
    .rxbufferr(mgt_rxbufferr_int_3),

    .loopback(mgt_loopback_3), .powerdown(mgt_powerdown_3),
    .rxeqmix(mgt_rxeqmix_3), .rxeqpole(mgt_rxeqpole_3),
    .txpreemphasis(mgt_txpreemphasis_3), .txdiffctrl(mgt_txdiffctrl_3)
  );

endmodule
