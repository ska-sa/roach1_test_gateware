module xaui_infrastructure(
    reset,

    mgt_refclk_t_n, mgt_refclk_t_p, 
    mgt_refclk_b_n, mgt_refclk_b_p, 
    mgt_txn_t0_n, mgt_rxn_t0_p,
    mgt_txn_t1_n, mgt_rxn_t1_p,
    mgt_txn_b0_n, mgt_rxn_b0_p,
    mgt_txn_b1_n, mgt_rxn_b1_p,

    mgt_clk_3, mgt_clk_2, mgt_clk_1, mgt_clk_0,
    mgt_tx_reset_3, mgt_tx_reset_2, mgt_tx_reset_1, mgt_tx_reset_0,
    mgt_rx_reset_3, mgt_rx_reset_2, mgt_rx_reset_1, mgt_rx_reset_0,
    mgt_rxdata_3, mgt_rxdata_2, mgt_rxdata_1, mgt_rxdata_0,
    mgt_rxcharisk_3, mgt_rxcharisk_2, mgt_rxcharisk_1, mgt_rxcharisk_0,
    mgt_txdata_3, mgt_txdata_2, mgt_txdata_1, mgt_txdata_0,
    mgt_txcharisk_3, mgt_txcharisk_2, mgt_txcharisk_1, mgt_txcharisk_0,
    mgt_code_comma_3, mgt_code_comma_2, mgt_code_comma_1, mgt_code_comma_0,
    mgt_enchansync_3, mgt_enchansync_2, mgt_enchansync_1, mgt_enchansync_0,
    mgt_enable_align_3, mgt_enable_align_2, mgt_enable_align_1, mgt_enable_align_0,
    mgt_loopback_3, mgt_loopback_2, mgt_loopback_1, mgt_loopback_0,
    mgt_powerdown_3, mgt_powerdown_2, mgt_powerdown_1, mgt_powerdown_0,
    mgt_lock_3, mgt_lock_2, mgt_lock_1, mgt_lock_0,
    mgt_syncok_3, mgt_syncok_2, mgt_syncok_1, mgt_syncok_0,
    mgt_codevalid_3, mgt_codevalid_2, mgt_codevalid_1, mgt_codevalid_0,
    mgt_rxbufferr_3, mgt_rxbufferr_2, mgt_rxbufferr_1, mgt_rxbufferr_0,
    mgt_rxeqmix_3, mgt_rxeqmix_2, mgt_rxeqmix_1, mgt_rxeqmix_0,
    mgt_rxeqpole_3, mgt_rxeqpole_2, mgt_rxeqpole_1, mgt_rxeqpole_0,
    mgt_txpreemphasis_3, mgt_txpreemphasis_2, mgt_txpreemphasis_1, mgt_txpreemphasis_0,
    mgt_txdiffctrl_3, mgt_txdiffctrl_2, mgt_txdiffctrl_1, mgt_txdiffctrl_0
  );

  localparam TXPOLARITY_HACK = 16'b0000_0000_0000_0000;
  localparam RXPOLARITY_HACK = 16'b0000_0000_0000_0000;

  wire refclk_t, refclk_t_mult_2;
  wire refclk_b, refclk_b_mult_2;

  assign mgt_clk_
  transceiver_bank #(
    .TXPOLARITY_HACK(TXPOLARITY_HACK[15:12]),
    .DIFF_BOOST(DIFF_BOOST)
  ) transceiver_bank_3 (
    .reset(reset),
    .rx_reset(mgt_rx_reset_3),
    .tx_reset(mgt_tx_reset_3),
    .mgt_clk(refclk_t),
    .mgt_clk_mult_2(refclk_t_mult_2),
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
    .rxeqmix(mgt_rxeqmix), .rxeqpole(mgt_rxeqpole_3),
    .txpreemphasis(mgt_txpreemphasis_3), .txdiffctrl(mgt_txdiffctrl_3)
  );
endmodule
