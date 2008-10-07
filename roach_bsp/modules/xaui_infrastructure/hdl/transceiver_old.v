module transceiver(
    //mgt resets and clocks
    reset, rx_reset, tx_reset,
    refclk, refclk_ret,
    mgt_clk, mgt_clk_mult_2,
    //mgt rx/tx
    txp_1, txn_1,
    txp_0, txn_0,
    rxp_1, rxn_1,
    rxp_0, rxn_0,
    //Channel bonding
    chbondi_1, chbondi_0,
    chbondo_1, chbondo_0,
    //xaui TX/RX ports
    rxdata_1, rxdata_0, 
    rxcharisk_1, rxcharisk_0,
    txdata_1, txdata_0, 
    txcharisk_1, txcharisk_0,
    code_comma_1, code_comma_0,
    //xaui align/sync control
    enchansync_1, enchansync_0,
    enable_align_1, enable_align_0,
    //xaui misc control bits
    loopback, powerdown,
    //xaui status bits
    rxlock_1, rxlock_0,
    syncok_1, syncok_0,
    codevalid_1, codevalid_0,
    rxbufferr_1, rxbufferr_0,
    //testing ports
    rxeqmix, rxeqpole,
    txpreemphasis, txdiffctrl
  );

  parameter TX_POLARITY_HACK_0 = 1'b0;
  parameter TX_POLARITY_HACK_1 = 1'b0;
  parameter RX_POLARITY_HACK_0 = 1'b0;
  parameter RX_POLARITY_HACK_1 = 1'b0;

  parameter CHAN_BOND_LEVEL_1 = "OFF";
  parameter CHAN_BOND_LEVEL_0 = "OFF";
  parameter CHAN_BOND_MODE_1  = "OFF";
  parameter CHAN_BOND_MODE_0  = "OFF";

  parameter DIFF_BOOST = "FALSE";

  input  reset, rx_reset, tx_reset;
  input  refclk, mgt_clk, mgt_clk_mult_2;
  output refclk_ret;

  output txp_1, txn_1, txp_0, txn_0;
  input  rxp_1, rxn_1, rxp_0, rxn_0;

  input   [2:0] chbondi_1;
  input   [2:0] chbondi_0;
  output  [2:0] chbondo_1;
  output  [2:0] chbondo_0;

  output [15:0] rxdata_1;
  output [15:0] rxdata_0;
  output  [1:0] rxcharisk_1;
  output  [1:0] rxcharisk_0;
  output  [1:0] code_comma_1;
  output  [1:0] code_comma_0;

  input  [15:0] txdata_1;
  input  [15:0] txdata_0; 
  input   [1:0] txcharisk_1;
  input   [1:0] txcharisk_0;
  
  input  enchansync_1, enchansync_0;
  input  enable_align_1, enable_align_0;
  
  input  loopback, powerdown;

  output rxlock_1, rxlock_0;
  output syncok_1, syncok_0;
  output [1:0] codevalid_1;
  output [1:0] codevalid_0;
  output rxbufferr_1, rxbufferr_0;

  input  [1:0] rxeqmix;
  input  [3:0] rxeqpole;
  input  [2:0] txpreemphasis;
  input  [2:0] txdiffctrl;

  /*********** Loopback Definitions *************/
  localparam LOOPTYPE_NEAR_PARALLEL = 0;
  localparam LOOPTYPE_NEAR_SERIAL   = 1;
  localparam LOOPTYPE_FAR_PARALLEL  = 2;
  localparam LOOPTYPE_FAR_SERIAL    = 3;
  localparam LOOPTYPE = LOOPTYPE_NEAR_PARALLEL;

  wire [2:0] loopback_int = loopback == 1'b0                   ? 3'b000 : 
                            LOOPTYPE == LOOPTYPE_NEAR_PARALLEL ? 3'b001 :
                            LOOPTYPE == LOOPTYPE_NEAR_SERIAL   ? 3'b010 :
                            LOOPTYPE == LOOPTYPE_FAR_SERIAL    ? 3'b100 :
                            LOOPTYPE == LOOPTYPE_FAR_PARALLEL  ? 3'b110 :
                                                                 3'b000;
  /************* Polarity Hacks ******************/
  wire polarity_hack_rx_0 = loopback ? 1'b0 : RX_POLARITY_HACK_0;
  wire polarity_hack_rx_1 = loopback ? 1'b0 : RX_POLARITY_HACK_1;
  wire polarity_hack_tx_0 = loopback ? 1'b0 : TX_POLARITY_HACK_0;
  wire polarity_hack_tx_1 = loopback ? 1'b0 : TX_POLARITY_HACK_1;


  /*********** Powerdown Definitions *************/
  wire [1:0] powerdown_int = powerdown ? 2'b11 : 2'b00;

  /************* Elec idle RX Clock Recovery Reset **********/
  /*
   * As describe in UG196 v1.6 Figure 5-9, page 80
   *
   */

  wire resetdone_0, resetdone_1, elecidle_0, elecidle_1;
  wire elecidle_reset_0 = resetdone_0 & elecidle_0;
  wire elecidle_reset_1 = resetdone_1 & elecidle_1;

  wire rxenelecidleresetb = ~(elecidle_reset_0 | elecidle_reset_1);

  /************ XAUI status bits generation *****************/

  wire [2:0] rxbufstatus_1, rxbufstatus_0;

  assign rxbufferr_1 = rxbufstatus_1 == 3'b110 || rxbufstatus_1 == 3'b101;
  assign rxbufferr_0 = rxbufstatus_0 == 3'b110 || rxbufstatus_0 == 3'b101;
   
  wire rxlossofsync_1;
  wire rxlossofsync_0;
  wire rxlossofsync_1_nc;
  wire rxlossofsync_0_nc;
  assign syncok_1 = !rxlossofsync_1;
  assign syncok_0 = !rxlossofsync_0;


  wire [1:0] rxnotintable_1;
  wire [1:0] rxnotintable_0;
  wire [1:0] rxdisperr_1;
  wire [1:0] rxdisperr_0;
  assign codevalid_1 = ~(rxnotintable_1 | rxdisperr_1);
  assign codevalid_0 = ~(rxnotintable_0 | rxdisperr_0);

  wire pll_lock_det;
  assign rxlock_1 = pll_lock_det;
  assign rxlock_0 = pll_lock_det;


  GTP_DUAL #(
    //---------------------- Tile and PLL Attributes ----------------------
    .CLK25_DIVIDER(10),
    .CLKINDC_B("TRUE"),   
    .OOB_CLK_DIVIDER(6),
    .OVERSAMPLE_MODE("FALSE"),
    .PLL_DIVSEL_FB(2),
    .PLL_DIVSEL_REF(1),
    .PLL_TXDIVSEL_COMM_OUT(1),
    .TX_SYNC_FILTERB(1),
    //----------------- TX Buffering and Phase Alignment ------------------   
    .TX_BUFFER_USE_0("TRUE"),
    .TX_XCLK_SEL_0("TXOUT"),
    .TXRX_INVERT_0(5'b00000),        
    .TX_BUFFER_USE_1("TRUE"),
    .TX_XCLK_SEL_1("TXOUT"),
    .TXRX_INVERT_1(5'b00000),        
    //------------------- TX Serial Line Rate settings --------------------   
    .PLL_TXDIVSEL_OUT_0(1), .PLL_TXDIVSEL_OUT_1(1), 
    //------------------- TX Driver and OOB signalling --------------------  
    .TX_DIFF_BOOST_0(DIFF_BOOST), .TX_DIFF_BOOST_1(DIFF_BOOST), 
    //---------------- TX Pipe Control for PCI Express/SATA ---------------
    .COM_BURST_VAL_0(4'b1111), .COM_BURST_VAL_1(4'b1111),
    //---------- RX Driver,OOB signalling,Coupling and Eq.,CDR ------------  
    //.AC_CAP_DIS_0("TRUE"),
    // NOTE: ROACH REV 0 HACK
    .AC_CAP_DIS_0("FALSE"),
    .OOBDETECT_THRESHOLD_0(3'b001),
    .PMA_CDR_SCAN_0(27'h6c07640), 
    .PMA_RX_CFG_0(25'h09f0089),
    .RCV_TERM_GND_0("FALSE"),
    // NOTE: ROACH REV 0 HACK
    // .RCV_TERM_MID_0("FALSE"),
    .RCV_TERM_MID_0("TRUE"),
    .RCV_TERM_VTTRX_0("FALSE"), //use 2/3 term as recommended in ug196
    .TERMINATION_IMP_0(50),

    // NOTE: ROACH REV 0 HACK
    //.AC_CAP_DIS_1("TRUE"),
    .AC_CAP_DIS_1("FALSE"),
    .OOBDETECT_THRESHOLD_1(3'b001),
    .PMA_CDR_SCAN_1(27'h6c07640), 
    .PMA_RX_CFG_1(25'h09f0089),  
    .RCV_TERM_GND_1("FALSE"),
    // NOTE: ROACH REV 0 HACK
    // .RCV_TERM_MID_1("FALSE"),
    .RCV_TERM_MID_1("TRUE"),
    .RCV_TERM_VTTRX_1("FALSE"),
    .TERMINATION_IMP_1(50),

 // .PCS_COM_CFG(28'h1680a0e),  -- this seems to not be supported in ise-9.2
 // but is referenced in documentation
    .TERMINATION_CTRL(5'b10100),
    .TERMINATION_OVRD("FALSE"),
    //------------------- RX Serial Line Rate Settings --------------------   
    .PLL_RXDIVSEL_OUT_0(1),
    .PLL_SATA_0("FALSE"),
    .PLL_RXDIVSEL_OUT_1(1),
    .PLL_SATA_1("FALSE"),
    //------------------------- PRBS Detection ----------------------------  
    .PRBS_ERR_THRESHOLD_0(32'h00000001),
    .PRBS_ERR_THRESHOLD_1(32'h00000001),
    //------------------- Comma Detection and Alignment -------------------  
    .ALIGN_COMMA_WORD_0(1),
    .COMMA_10B_ENABLE_0(10'h7f),
    .COMMA_DOUBLE_0("FALSE"),
    .DEC_MCOMMA_DETECT_0("TRUE"),
    .DEC_PCOMMA_DETECT_0("TRUE"),
    .DEC_VALID_COMMA_ONLY_0("TRUE"),
    .MCOMMA_10B_VALUE_0(10'h283),
    .MCOMMA_DETECT_0("TRUE"),
    .PCOMMA_10B_VALUE_0(10'h17c),
    .PCOMMA_DETECT_0("TRUE"),
    .RX_SLIDE_MODE_0("PCS"),
    .ALIGN_COMMA_WORD_1(1),
    .COMMA_10B_ENABLE_1(10'h7f),
    .COMMA_DOUBLE_1("FALSE"),
    .DEC_MCOMMA_DETECT_1("TRUE"),
    .DEC_PCOMMA_DETECT_1("TRUE"),
    .DEC_VALID_COMMA_ONLY_1("TRUE"),
    .MCOMMA_10B_VALUE_1(10'h283),
    .MCOMMA_DETECT_1("TRUE"),
    .PCOMMA_10B_VALUE_1(10'h17c),
    .PCOMMA_DETECT_1("TRUE"),
    .RX_SLIDE_MODE_1("PCS"),
    //------------------- RX Loss-of-sync State Machine -------------------  
    .RX_LOSS_OF_SYNC_FSM_0("TRUE"),
    .RX_LOS_INVALID_INCR_0(1),
    .RX_LOS_THRESHOLD_0(4),
    .RX_LOSS_OF_SYNC_FSM_1("TRUE"),
    .RX_LOS_INVALID_INCR_1(1),
    .RX_LOS_THRESHOLD_1(4),
    //------------ RX Elastic Buffer and Phase alignment ports ------------   
    .RX_BUFFER_USE_0("TRUE"),
    .RX_XCLK_SEL_0("RXREC"),
    .RX_BUFFER_USE_1("TRUE"),
    .RX_XCLK_SEL_1("RXREC"),
    //--------------------- Clock Correction Attributes -------------------   
    .CLK_CORRECT_USE_0("TRUE"),
    .CLK_COR_ADJ_LEN_0(1),
    .CLK_COR_DET_LEN_0(1),
    .CLK_COR_INSERT_IDLE_FLAG_0("FALSE"),
    .CLK_COR_KEEP_IDLE_0("FALSE"),
    .CLK_COR_MAX_LAT_0(18),
    .CLK_COR_MIN_LAT_0(16),
    .CLK_COR_PRECEDENCE_0("TRUE"),
    .CLK_COR_REPEAT_WAIT_0(0),
    .CLK_COR_SEQ_1_1_0(10'b0100011100), //Clock correction on K28.0 : xaui idle
    .CLK_COR_SEQ_1_2_0(10'b0000000000),
    .CLK_COR_SEQ_1_3_0(10'b0000000000),
    .CLK_COR_SEQ_1_4_0(10'b0000000000),
    .CLK_COR_SEQ_1_ENABLE_0(4'b0001),
    .CLK_COR_SEQ_2_1_0(10'b0000000000),
    .CLK_COR_SEQ_2_2_0(10'b0000000000),
    .CLK_COR_SEQ_2_3_0(10'b0000000000),
    .CLK_COR_SEQ_2_4_0(10'b0000000000),
    .CLK_COR_SEQ_2_ENABLE_0(4'b0000),
    .CLK_COR_SEQ_2_USE_0("FALSE"),
    .RX_DECODE_SEQ_MATCH_0("TRUE"),
    .CLK_CORRECT_USE_1("TRUE"),
    .CLK_COR_ADJ_LEN_1(1),
    .CLK_COR_DET_LEN_1(1),
    .CLK_COR_INSERT_IDLE_FLAG_1("FALSE"),
    .CLK_COR_KEEP_IDLE_1("FALSE"),
    .CLK_COR_MAX_LAT_1(18),
    .CLK_COR_MIN_LAT_1(16),
    .CLK_COR_PRECEDENCE_1("TRUE"),
    .CLK_COR_REPEAT_WAIT_1(0),
    .CLK_COR_SEQ_1_1_1(10'b0100011100),
    .CLK_COR_SEQ_1_2_1(10'b0000000000),
    .CLK_COR_SEQ_1_3_1(10'b0000000000),
    .CLK_COR_SEQ_1_4_1(10'b0000000000),
    .CLK_COR_SEQ_1_ENABLE_1(4'b0001),
    .CLK_COR_SEQ_2_1_1(10'b0000000000),
    .CLK_COR_SEQ_2_2_1(10'b0000000000),
    .CLK_COR_SEQ_2_3_1(10'b0000000000),
    .CLK_COR_SEQ_2_4_1(10'b0000000000),
    .CLK_COR_SEQ_2_ENABLE_1(4'b0000),
    .CLK_COR_SEQ_2_USE_1("FALSE"),
    .RX_DECODE_SEQ_MATCH_1("TRUE"),
    //-------------------- Channel Bonding Attributes ---------------------   
    .CHAN_BOND_1_MAX_SKEW_0(7),
    .CHAN_BOND_2_MAX_SKEW_0(7),
    .CHAN_BOND_LEVEL_0(CHAN_BOND_LEVEL_0),
    .CHAN_BOND_MODE_0(CHAN_BOND_MODE_0),
    .CHAN_BOND_SEQ_1_1_0(10'b0101111100),
    .CHAN_BOND_SEQ_1_2_0(10'b0000000000),
    .CHAN_BOND_SEQ_1_3_0(10'b0000000000),
    .CHAN_BOND_SEQ_1_4_0(10'b0000000000),
    .CHAN_BOND_SEQ_1_ENABLE_0(4'b0001),
    .CHAN_BOND_SEQ_2_1_0(10'b0000000000),
    .CHAN_BOND_SEQ_2_2_0(10'b0000000000),
    .CHAN_BOND_SEQ_2_3_0(10'b0000000000),
    .CHAN_BOND_SEQ_2_4_0(10'b0000000000),
    .CHAN_BOND_SEQ_2_ENABLE_0(4'b0000),
    .CHAN_BOND_SEQ_2_USE_0("FALSE"),  
    .CHAN_BOND_SEQ_LEN_0(1),
    .PCI_EXPRESS_MODE_0("FALSE"),     
    .CHAN_BOND_1_MAX_SKEW_1(7),
    .CHAN_BOND_2_MAX_SKEW_1(7),
    .CHAN_BOND_LEVEL_1(CHAN_BOND_LEVEL_1), 
    .CHAN_BOND_MODE_1(CHAN_BOND_MODE_1),
    .CHAN_BOND_SEQ_1_1_1(10'b0101111100),
    .CHAN_BOND_SEQ_1_2_1(10'b0000000000),
    .CHAN_BOND_SEQ_1_3_1(10'b0000000000),
    .CHAN_BOND_SEQ_1_4_1(10'b0000000000),
    .CHAN_BOND_SEQ_1_ENABLE_1(4'b0001),
    .CHAN_BOND_SEQ_2_1_1(10'b0000000000),
    .CHAN_BOND_SEQ_2_2_1(10'b0000000000),
    .CHAN_BOND_SEQ_2_3_1(10'b0000000000),
    .CHAN_BOND_SEQ_2_4_1(10'b0000000000),
    .CHAN_BOND_SEQ_2_ENABLE_1(4'b0000),
    .CHAN_BOND_SEQ_2_USE_1("FALSE"),  
    .CHAN_BOND_SEQ_LEN_1(1),
    .PCI_EXPRESS_MODE_1("FALSE"),
    //---------------- RX Attributes for PCI Express/SATA ---------------
    .RX_STATUS_FMT_0("PCIE"),
    .SATA_BURST_VAL_0(3'b100),
    .SATA_IDLE_VAL_0(3'b100),
    .SATA_MAX_BURST_0(7),
    .SATA_MAX_INIT_0(22),
    .SATA_MAX_WAKE_0(7),
    .SATA_MIN_BURST_0(4),
    .SATA_MIN_INIT_0(12),
    .SATA_MIN_WAKE_0(4),
    .TRANS_TIME_FROM_P2_0(16'h0060),
    .TRANS_TIME_NON_P2_0(16'h0025),
    .TRANS_TIME_TO_P2_0(16'h0100),
    .RX_STATUS_FMT_1("PCIE"),
    .SATA_BURST_VAL_1(3'b100),
    .SATA_IDLE_VAL_1(3'b100),
    .SATA_MAX_BURST_1(7),
    .SATA_MAX_INIT_1(22),
    .SATA_MAX_WAKE_1(7),
    .SATA_MIN_BURST_1(4),
    .SATA_MIN_INIT_1(12),
    .SATA_MIN_WAKE_1(4),
    .TRANS_TIME_FROM_P2_1(16'h0060),
    .TRANS_TIME_NON_P2_1(16'h0025),
    .TRANS_TIME_TO_P2_1(16'h0100)         
  ) 
  gtp_dual_i 
  (
    //---------------------- Loopback and Powerdown Ports ----------------------
    .LOOPBACK0(loopback_int), .LOOPBACK1(loopback_int),
    .RXPOWERDOWN0(powerdown_int), .RXPOWERDOWN1(powerdown_int),
    .TXPOWERDOWN0(powerdown_int), .TXPOWERDOWN1(powerdown_int),
    //--------------------- Receive Ports - 8b10b Decoder ----------------------
    .RXCHARISCOMMA0(code_comma_0), .RXCHARISCOMMA1(code_comma_1),
    .RXCHARISK0(rxcharisk_0), .RXCHARISK1(rxcharisk_1),
    .RXDEC8B10BUSE0(1'b1), .RXDEC8B10BUSE1(1'b1),
    .RXDISPERR0(rxdisperr_0), .RXDISPERR1(rxdisperr_1),
    .RXNOTINTABLE0(rxnotintable_0), .RXNOTINTABLE1(rxnotintable_1),
    .RXRUNDISP0(), .RXRUNDISP1(),
    //----------------- Receive Ports - Channel Bonding Ports ------------------
    .RXCHANBONDSEQ0(), .RXCHANBONDSEQ1(),
    .RXCHBONDI0(chbondi_0), .RXCHBONDI1(chbondi_1),
    .RXCHBONDO0(chbondo_0), .RXCHBONDO1(chbondo_1),
    .RXENCHANSYNC0(enchansync_0), .RXENCHANSYNC1(enchansync_1),
    //----------------- Receive Ports - Clock Correction Ports -----------------
    .RXCLKCORCNT0(), .RXCLKCORCNT1(),
    //------------- Receive Ports - Comma Detection and Alignment --------------
    .RXBYTEISALIGNED0(), .RXBYTEISALIGNED1(),
    .RXBYTEREALIGN0(), .RXBYTEREALIGN1(),
    .RXCOMMADET0(), .RXCOMMADET1(),
    .RXCOMMADETUSE0(1'b1), .RXCOMMADETUSE1(1'b1),
    .RXENMCOMMAALIGN0(enable_align_0), .RXENMCOMMAALIGN1(enable_align_1),
    .RXENPCOMMAALIGN0(enable_align_0), .RXENPCOMMAALIGN1(enable_align_1),
    .RXSLIDE0(1'b0), .RXSLIDE1(1'b0),
    //--------------------- Receive Ports - PRBS Detection ---------------------
    .PRBSCNTRESET0(1'b0), .PRBSCNTRESET1(1'b0),
    .RXENPRBSTST0(2'b00), .RXENPRBSTST1(2'b00),
    .RXPRBSERR0(), .RXPRBSERR1(),
    //----------------- Receive Ports - RX Data Path interface -----------------
    .RXDATA0(rxdata_0), .RXDATA1(rxdata_1),
    .RXDATAWIDTH0(1'b1), .RXDATAWIDTH1(1'b1),
    .RXRECCLK0(), .RXRECCLK1(),
    .RXRESET0(1'b0), .RXRESET1(1'b0), //this is replaced with CDRRESET
    .RXUSRCLK0(mgt_clk_mult_2),
    .RXUSRCLK1(mgt_clk_mult_2),
    .RXUSRCLK20(mgt_clk),
    .RXUSRCLK21(mgt_clk),
    //----- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
    .RXCDRRESET0(rx_reset | reset), .RXCDRRESET1(rx_reset | reset),
    .RXELECIDLE0(elecidle_0), .RXELECIDLE1(elecidle_1),
    .RXELECIDLERESET0(elecidle_reset_0 | reset), .RXELECIDLERESET1(elecidle_reset_1 | reset),
    //.RXENEQB0(1'b0), .RXENEQB1(1'b0), /*TODO: make this playable with */
    .RXENEQB0(1'b1), .RXENEQB1(1'b1),
    .RXEQMIX0(rxeqmix), .RXEQMIX1(rxeqmix),
    .RXEQPOLE0(rxeqpole), .RXEQPOLE1(rxeqpole),
    .RXN0(rxn_0), .RXN1(rxn_1),
    .RXP0(rxp_0), .RXP1(rxp_1),
    //------ Receive Ports - RX Elastic Buffer and Phase Alignment Ports -------
    .RXBUFRESET0(rx_reset | reset), .RXBUFRESET1(rx_reset | reset),
    .RXBUFSTATUS0(rxbufstatus_0), .RXBUFSTATUS1(rxbufstatus_1),
    .RXCHANISALIGNED0(), .RXCHANISALIGNED1(),
    .RXCHANREALIGN0(), .RXCHANREALIGN1(),
    .RXPMASETPHASE0(1'b0), .RXPMASETPHASE1(1'b0),
    .RXSTATUS0(), .RXSTATUS1(),
    //------------- Receive Ports - RX Loss-of-sync State Machine --------------
    .RXLOSSOFSYNC0({rxlossofsync_0, rxlossofsync_0_nc}), .RXLOSSOFSYNC1({rxlossofsync_1, rxlossofsync_1_nc}),
    //-------------------- Receive Ports - RX Oversampling ---------------------
    .RXENSAMPLEALIGN0(1'b0), .RXENSAMPLEALIGN1(1'b0),
    .RXOVERSAMPLEERR0(), .RXOVERSAMPLEERR1(),
    //------------ Receive Ports - RX Pipe Control for PCI Express -------------
    .PHYSTATUS0(), .PHYSTATUS1(), .RXVALID0(), .RXVALID1(),
    //--------------- Receive Ports - RX Polarity Control Ports ----------------
    .RXPOLARITY0(polarity_hack_rx_0), .RXPOLARITY1(polarity_hack_rx_1),
    //----------- Shared Ports - Dynamic Reconfiguration Port (DRP) ------------
    .DADDR(7'b0), .DCLK(1'b0), .DEN(1'b0), .DI(16'b0), .DO(), .DRDY(), .DWE(1'b0),
    //------------------- Shared Ports - Tile and PLL Ports --------------------
    .CLKIN(refclk), .GTPRESET(reset),
    .GTPTEST(4'b0), .INTDATAWIDTH(1'b1),
    .PLLLKDET(pll_lock_det),
    .PLLLKDETEN(1'b1), .PLLPOWERDOWN(1'b0),
    .REFCLKOUT(refclk_ret), .REFCLKPWRDNB(1'b1),
    .RESETDONE0(resetdone_0), .RESETDONE1(resetdone_1),
    .RXENELECIDLERESETB(rxenelecidleresetb & ~reset),
    .TXENPMAPHASEALIGN(1'b0), .TXPMASETPHASE(1'b0),
    //-------------- Transmit Ports - 8b10b Encoder Control Ports --------------
    .TXBYPASS8B10B0(2'b0), .TXBYPASS8B10B1(2'b0),
    .TXCHARDISPMODE0(2'b0), .TXCHARDISPMODE1(2'b0),
    .TXCHARDISPVAL0(2'b0), .TXCHARDISPVAL1(2'b0),
    .TXCHARISK0(txcharisk_0), .TXCHARISK1(txcharisk_1),
    .TXENC8B10BUSE0(1'b1), .TXENC8B10BUSE1(1'b1),
    .TXKERR0(), .TXKERR1(),
    .TXRUNDISP0(), .TXRUNDISP1(),
    //----------- Transmit Ports - TX Buffering and Phase Alignment ------------
    .TXBUFSTATUS0(), .TXBUFSTATUS1(),
    //---------------- Transmit Ports - TX Data Path interface -----------------
    .TXDATA0(txdata_0), .TXDATA1(txdata_1),
    .TXDATAWIDTH0(1'b1), .TXDATAWIDTH1(1'b1),
    .TXOUTCLK0(), .TXOUTCLK1(),
    .TXRESET0(tx_reset | reset), .TXRESET1(tx_reset | reset),
    .TXUSRCLK0(mgt_clk_mult_2), .TXUSRCLK1(mgt_clk_mult_2),
    .TXUSRCLK20(mgt_clk), .TXUSRCLK21(mgt_clk),
    //------------- Transmit Ports - TX Driver and OOB signalling --------------
    //.TXBUFDIFFCTRL0(txdiffctrl), .TXBUFDIFFCTRL1(txdiffctrl),
    //.TXDIFFCTRL0(txdiffctrl), .TXDIFFCTRL1(txdiffctrl),
    .TXBUFDIFFCTRL0(3'b100), .TXBUFDIFFCTRL1(3'b100),
    .TXDIFFCTRL0(3'b100), .TXDIFFCTRL1(3'b100),
    .TXINHIBIT0(1'b0), .TXINHIBIT1(1'b0),
    .TXN0(txn_0), .TXN1(txn_1), .TXP0(txp_0), .TXP1(txp_1),
    //.TXPREEMPHASIS0(txpreemphasis), .TXPREEMPHASIS1(txpreemphasis),
    .TXPREEMPHASIS0(3'b011), .TXPREEMPHASIS1(3'b011),
    //------------------- Transmit Ports - TX PRBS Generator -------------------
    .TXENPRBSTST0(2'b0), .TXENPRBSTST1(2'b0),
    //------------------ Transmit Ports - TX Polarity Control ------------------
    .TXPOLARITY0(polarity_hack_tx_0), .TXPOLARITY1(polarity_hack_tx_1),
    //--------------- Transmit Ports - TX Ports for PCI Express ----------------
    .TXDETECTRX0(1'b0), .TXDETECTRX1(1'b0), .TXELECIDLE0(1'b0), .TXELECIDLE1(1'b0),
    //------------------- Transmit Ports - TX Ports for SATA -------------------
    .TXCOMSTART0(1'b0), .TXCOMSTART1(1'b0),
    .TXCOMTYPE0(1'b0), .TXCOMTYPE1(1'b0)
  );
endmodule
