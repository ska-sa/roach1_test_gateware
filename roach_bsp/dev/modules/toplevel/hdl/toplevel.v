`include "build_parameters.v"
`include "parameters.v"
module toplevel(
    usr_clk, reset_in,
    led_n,
    serial_in, serial_out,
    mgt_refclk_n, mgt_refclk_p,
    mgt_0_rx_n,
    mgt_0_rx_p,
    mgt_0_tx_n,
    mgt_0_tx_p,
    mgt_1_rx_n,
    mgt_1_rx_p,
    mgt_1_tx_n,
    mgt_1_tx_p,
    mgt_2_rx_n,
    mgt_2_rx_p,
    mgt_2_tx_n,
    mgt_2_tx_p,
    mgt_3_rx_n,
    mgt_3_rx_p,
    mgt_3_tx_n,
    mgt_3_tx_p,
    DDR2_A,
    DDR2_BA,
    DDR2_CAS_B,
    DDR2_CKE0, DDR2_CKE1,
    DDR2_CLK0_N, DDR2_CLK0_P,
    DDR2_CLK1_N, DDR2_CLK1_P,
    DDR2_CS0_B, DDR2_CS1_B,
    DDR2_D, DDR2_DM,
    DDR2_DQS_N, DDR2_DQS_P,
    DDR2_ODT0, DDR2_ODT1,
    DDR2_RAS_B, DDR2_SCL, DDR2_SDA, 
    DDR2_WE_B
  );
  input  usr_clk, reset_in;
  output [12:0] led_n;
  input  serial_in;
  output serial_out;
  input  mgt_refclk_n, mgt_refclk_p;
  input  mgt_0_rx_n;
  input  mgt_0_rx_p;
  output mgt_0_tx_n;
  output mgt_0_tx_p;
  input  mgt_1_rx_n;
  input  mgt_1_rx_p;
  output mgt_1_tx_n;
  output mgt_1_tx_p;
  input  mgt_2_rx_n;
  input  mgt_2_rx_p;
  output mgt_2_tx_n;
  output mgt_2_tx_p;
  input  mgt_3_rx_n;
  input  mgt_3_rx_p;
  output mgt_3_tx_n;
  output mgt_3_tx_p;
  inout  [63:0] DDR2_D;
  output  [7:0] DDR2_DM;
  inout   [7:0] DDR2_DQS_N;
  inout   [7:0] DDR2_DQS_P;
  output [13:0] DDR2_A;
  output  [2:0] DDR2_BA;
  output DDR2_CAS_B, DDR2_RAS_B, DDR2_WE_B;
  output DDR2_CS0_B, DDR2_CS1_B;
  output DDR2_CKE0, DDR2_CKE1;
  output DDR2_CLK0_N, DDR2_CLK0_P, DDR2_CLK1_N, DDR2_CLK1_P;
  output DDR2_ODT0, DDR2_ODT1;
  inout  DDR2_SCL, DDR2_SDA;
  
  assign DDR2_SCL = 1'b0;
  assign DDR2_SDA = 1'b0;

  /****************** Glocal Signals **********************/

  wire sys_clk;
  // synthesis attribute KEEP of sys_clk is TRUE
  // synthesis attribute KEEP of dly_clk is TRUE
  // synthesis attribute KEEP of mgt_clk is TRUE
  // Ensure that the above nets are not synthesized away
  wire sys_reset;
  wire soft_reset;

  /**************** Global Infrastructure ****************/


  wire idelay_ready;

  infrastructure infrastructure_inst(
    .reset(sys_reset),
    .sys_clk_buf(usr_clk),
    .sys_clk(sys_clk),
    .dly_clk(dly_clk),
    .dly_rdy(idelay_ready)
  );


  /********************* Reset Block *********************/

  reset_block #(
    .DELAY(100),
    .WIDTH(10)
  ) reset_block_inst(
    .clk(sys_clk), .async_reset_i(1'b0),
    .reset_i(~reset_in), .reset_o(sys_reset)
  );

  /**************** Serial Communications ****************/

  wire [7:0] as_data_i;
  wire [7:0] as_data_o;
  wire as_dstrb_i, as_busy_o, as_dstrb_o;

  serial_uart #(
    .BAUD(`SERIAL_UART_BAUD),
    .CLOCK_RATE(`MASTER_CLOCK_RATE)
  ) serial_uart_inst (
    .clk(sys_clk), .reset(sys_reset),
    .serial_in(serial_in), .serial_out(serial_out),
    .as_data_i(as_data_i),  .as_data_o(as_data_o),
    .as_dstrb_i(as_dstrb_i), .as_busy_o(as_busy_o), .as_dstrb_o(as_dstrb_o)
  );

  /**************** Wishbone Bus Control ****************/


  /*** Serial Port Master **/
  wire wbm_stb_o_0, wbm_cyc_o_0, wbm_we_o_0;
  wire  [1:0] wbm_sel_o_0;
  wire [31:0] wbm_adr_o_0;
  wire [15:0] wbm_dat_o_0;
  wire [15:0] wbm_dat_i_0;
  wire wbm_ack_i_0, wbm_err_i_0;

  as_wb_bridge as_wb_bridge_inst (
    .clk(sys_clk), .reset(sys_reset),
    .as_data_i(as_data_o), .as_data_o(as_data_i),
    .as_dstrb_o(as_dstrb_i), .as_busy_i(as_busy_o), .as_dstrb_i(as_dstrb_o),
    .wb_stb_o(wbm_stb_o_0), .wb_cyc_o(wbm_cyc_o_0), .wb_we_o(wbm_we_o_0), .wb_sel_o(wbm_sel_o_0),
    .wb_adr_o(wbm_adr_o_0), .wb_dat_o(wbm_dat_o_0), .wb_dat_i(wbm_dat_i_0),
    .wb_ack_i(wbm_ack_i_0), .wb_err_i(wbm_err_i_0),
    .soft_reset(soft_reset)
  );

  /******* PPC Master ********/
  assign ppc_irq = 1'b0;
  assign epb_data = {16{1'bz}};
  assign epb_rdy = 1'b0;
  
  wire wbm_stb_o_1, wbm_cyc_o_1, wbm_we_o_1;
  wire  [1:0] wbm_sel_o_1;
  wire [31:0] wbm_adr_o_1;
  wire [15:0] wbm_dat_o_1;
  wire [15:0] wbm_dat_i_1;
  wire wbm_ack_i_1, wbm_err_i_1;

  assign wbm_stb_o_1 = 1'b0;
  assign wbm_cyc_o_1 = 1'b0;
  assign wbm_we_o_1  = 1'b0;
  assign wbm_sel_o_1 = 2'b0;
  assign wbm_adr_o_1 = 32'b0;
  assign wbm_dat_o_1 = 16'b0;

  /** WB Master Arbitration **/

  /* Intermediate wishbone signals */
  wire wbi_cyc_o, wbi_stb_o, wbi_we_o;
  wire  [1:0] wbi_sel_o;
  wire [31:0] wbi_adr_o;
  wire [15:0] wbi_dat_o;
  wire [15:0] wbi_dat_i;
  wire wbi_ack_i, wbi_err_i;

  wire [1:0] wbm_id_nc;

  wbm_arbiter #(
    .NUM_MASTERS(2)
  ) wbm_arbiter_inst (
    .wb_clk_i(sys_clk), .wb_rst_i(sys_reset),
    .wbm_cyc_i({wbm_cyc_o_1, wbm_cyc_o_0}), .wbm_stb_i({wbm_stb_o_1, wbm_stb_o_0}), .wbm_we_i({wbm_we_o_1, wbm_we_o_0}), .wbm_sel_i({wbm_sel_o_1, wbm_sel_o_0}),
    .wbm_adr_i({wbm_adr_o_1, wbm_adr_o_0}), .wbm_dat_i({wbm_dat_o_1, wbm_dat_o_0}), .wbm_dat_o({wbm_dat_i_1, wbm_dat_i_0}),
    .wbm_ack_o({wbm_ack_i_1, wbm_ack_i_0}), .wbm_err_o({wbm_err_i_1, wbm_err_i_0}),
    .wbs_cyc_o(wbi_cyc_o), .wbs_stb_o(wbi_stb_o), .wbs_we_o(wbi_we_o), .wbs_sel_o(wbi_sel_o),
    .wbs_adr_o(wbi_adr_o), .wbs_dat_o(wbi_dat_o), .wbs_dat_i(wbi_dat_i),
    .wbs_ack_i(wbi_ack_i), .wbs_err_i(wbi_err_i),
    .wbm_mask(2'b11), //both enabled
    .wbm_id(wbm_id_nc)
  );

  localparam NUM_SLAVES = 14;

  localparam SLAVE_ADDR = {32'hffff_f000, 32'h000c_0000, 32'h000b_0000, 32'h000a_0000, //slaves 13:10
                           32'h0009_0000, 32'h0008_0000, 32'h0007_0000, 32'h0006_0000, //slaves 9:6
                           32'h0005_0000, 32'h0004_0000, 32'h0003_0000, 32'h0002_0000, //slaves 5:2
                           32'h0001_0000, 32'h0000_0000};                              //slaves 1:0

  localparam SLAVE_HIGH = {32'hffff_ffff, 32'h000c_ffff, 32'h000b_ffff, 32'h000a_ffff, //slaves 13:10
                           32'h0009_ffff, 32'h0008_ffff, 32'h0007_ffff, 32'h0006_ffff, //slaves 9:6
                           32'h0005_ffff, 32'h0004_ffff, 32'h0003_ffff, 32'h0002_ffff, //slaves 5:2
                           32'h0001_ffff, 32'h0000_ffff};                              //slaves 1:0

  wire [NUM_SLAVES - 1:0] wb_cyc_o;
  wire [NUM_SLAVES - 1:0] wb_stb_o;
  wire wb_we_o;
  wire  [1:0] wb_sel_o;
  wire [31:0] wb_adr_o;
  wire [15:0] wb_dat_o;
  wire [16*NUM_SLAVES - 1:0] wb_dat_i;
  wire    [NUM_SLAVES - 1:0] wb_ack_i;

  wire [7:0] debug_led;

  wbs_arbiter #(
    .NUM_SLAVES(NUM_SLAVES),
    .SLAVE_ADDR(SLAVE_ADDR),
    .SLAVE_HIGH(SLAVE_HIGH),
    .TIMEOUT(1000)
  ) wbs_arbiter_inst (
    .wb_clk_i(sys_clk), .wb_rst_i(sys_reset),
    .wbm_cyc_i(wbi_cyc_o), .wbm_stb_i(wbi_stb_o), .wbm_we_i(wbi_we_o), .wbm_sel_i(wbi_sel_o),
    .wbm_adr_i(wbi_adr_o), .wbm_dat_i(wbi_dat_o), .wbm_dat_o(wbi_dat_i),
    .wbm_ack_o(wbi_ack_i), .wbm_err_o(wbi_err_i),
    .wbs_cyc_o(wb_cyc_o), .wbs_stb_o(wb_stb_o), .wbs_we_o(wb_we_o), .wbs_sel_o(wb_sel_o),
    .wbs_adr_o(wb_adr_o), .wbs_dat_o(wb_dat_o), .wbs_dat_i(wb_dat_i),
    .wbs_ack_i(wb_ack_i)
    ,.debug(debug_led[7:4])
  );

  /******************* System Module *****************/

  sys_block #(
    .BOARD_ID(`BOARD_ID),
    .REV_MAJOR(`REV_MAJOR),
    .REV_MINOR(`REV_MINOR),
    .REV_RCS(`REV_RCS)
  ) sys_block_inst (
    .wb_clk_i(sys_clk), .wb_rst_i(sys_reset),
    .wb_cyc_i(wb_cyc_o[0]), .wb_stb_i(wb_stb_o[0]),
    .wb_we_i(wb_we_o), .wb_sel_i(wb_sel_o),
    .wb_adr_i(wb_adr_o), .wb_dat_i(wb_dat_o),
    .wb_dat_o(wb_dat_i[16*(0 + 1) - 1: 16*0]),
    .wb_ack_o(wb_ack_i[0]),
    .wb_toutsup_o()
  );

  /************* XAUI Infrastructure ***************/

  wire mgt_clk_lock;

  wire  [3:0] mgt_tx_reset      [0:0];
  wire  [3:0] mgt_rx_reset      [0:0];
  wire [63:0] mgt_rxdata        [0:0];
  wire  [7:0] mgt_rxcharisk     [0:0];
  wire [63:0] mgt_txdata        [0:0];
  wire  [7:0] mgt_txcharisk     [0:0];
  wire  [7:0] mgt_code_comma    [0:0];
  wire  [3:0] mgt_enable_align  [0:0];
  wire mgt_enchansync           [0:0];
  wire mgt_loopback             [0:0];
  wire mgt_powerdown            [0:0];
  wire  [3:0] mgt_rxlock        [0:0];
  wire  [3:0] mgt_syncok        [0:0];
  wire  [7:0] mgt_codevalid     [0:0];
  wire  [3:0] mgt_rxbufferr     [0:0];
  wire  [1:0] mgt_rxeqmix       [0:0];
  wire  [3:0] mgt_rxeqpole      [0:0];
  wire  [2:0] mgt_txpreemphasis [0:0];
  wire  [2:0] mgt_txdiffctrl    [0:0];

  xaui_infrastructure #(
    .DIFF_BOOST(`MGT_DIFF_BOOST)
  ) xaui_infrastructure_inst (
    .reset(sys_reset),
    .mgt_refclk_b_n(mgt_refclk_n), .mgt_refclk_b_p(mgt_refclk_p), 

    .mgt_tx_b0_n({mgt_3_tx_n, mgt_2_tx_n, mgt_1_tx_n, mgt_0_tx_n}), .mgt_tx_b0_p({mgt_3_tx_p, mgt_2_tx_p, mgt_1_tx_p, mgt_0_tx_p}),
    .mgt_rx_b0_n({mgt_3_rx_n, mgt_2_rx_n, mgt_1_rx_n, mgt_0_rx_n}), .mgt_rx_b0_p({mgt_3_rx_p, mgt_2_rx_p, mgt_1_rx_p, mgt_0_rx_p}),

    .mgt_clk(mgt_clk), .mgt_clk_lock(mgt_clk_lock),

    .mgt_tx_reset_0(mgt_tx_reset[0]), .mgt_rx_reset_0(mgt_rx_reset[0]),
    .mgt_rxdata_0(mgt_rxdata[0]), .mgt_rxcharisk_0(mgt_rxcharisk[0]),
    .mgt_txdata_0(mgt_txdata[0]), .mgt_txcharisk_0(mgt_txcharisk[0]),
    .mgt_code_comma_0(mgt_code_comma[0]),
    .mgt_enchansync_0(mgt_enchansync[0]), .mgt_enable_align_0(mgt_enable_align[0]),
    .mgt_loopback_0(mgt_loopback[0]), .mgt_powerdown_0(mgt_powerdown[0]),
    .mgt_rxlock_0(mgt_rxlock[0]), .mgt_syncok_0(mgt_syncok[0]),
    .mgt_codevalid_0(mgt_codevalid[0]), .mgt_rxbufferr_0(mgt_rxbufferr[0]),
    .mgt_rxeqmix_0(mgt_rxeqmix[0]), .mgt_rxeqpole_0(mgt_rxeqpole[0]),
    .mgt_txpreemphasis_0(mgt_txpreemphasis[0]), .mgt_txdiffctrl_0(mgt_txdiffctrl[0])
  );

  /**** Ten Gigabit Ethernet Fabric Interfaces ****/
  wire tge_usr_clk               [0:0];
  wire tge_usr_rst               [0:0];
  wire tge_tx_valid              [0:0];
  wire tge_tx_ack                [0:0];
  wire tge_tx_end_of_frame       [0:0];
  wire tge_tx_discard            [0:0];
  wire [63:0] tge_tx_data        [0:0];
  wire [31:0] tge_tx_dest_ip     [0:0];
  wire [15:0] tge_tx_dest_port   [0:0];
  wire tge_rx_valid              [0:0];
  wire tge_rx_ack                [0:0];
  wire [63:0] tge_rx_data        [0:0];
  wire tge_rx_end_of_frame       [0:0];
  wire [15:0] tge_rx_size        [0:0];
  wire [31:0] tge_rx_source_ip   [0:0];
  wire [15:0] tge_rx_source_port [0:0];
  wire tge_led_up                [0:0];
  wire tge_led_rx                [0:0];
  wire tge_led_tx                [0:0];


  /******************* XAUI/TGBE 0 **********************/

`ifdef ENABLE_TEN_GB_ETH_0
  ten_gb_eth #(
    .DEFAULT_FABRIC_MAC     (`TGE_0_DEFAULT_FABRIC_MAC),
    .DEFAULT_FABRIC_IP      (`TGE_0_DEFAULT_FABRIC_IP),
    .DEFAULT_FABRIC_GATEWAY (`TGE_0_DEFAULT_FABRIC_GATEWAY),
    .DEFAULT_FABRIC_PORT    (`TGE_0_DEFAULT_FABRIC_PORT),
    .FABRIC_RUN_ON_STARTUP  (`TGE_0_FABRIC_RUN_ON_STARTUP)
  ) ten_gb_eth_0 (
    .clk(tge_usr_clk[0]), .rst(tge_usr_rst[0]),
    .tx_valid(tge_tx_valid[0]), .tx_ack(tge_tx_ack[0]),
    .tx_end_of_frame(tge_tx_end_of_frame[0]), .tx_discard(tge_tx_discard[0]),
    .tx_data(tge_tx_data[0]), .tx_dest_ip(tge_tx_dest_ip[0]),
    .tx_dest_port(tge_tx_dest_port[0]),
    .rx_valid(tge_rx_valid[0]), .rx_ack(tge_rx_ack[0]),
    .rx_data(tge_rx_data[0]), .rx_end_of_frame(tge_rx_end_of_frame[0]),
    .rx_size(tge_rx_size[0]),
    .rx_source_ip(tge_rx_source_ip[0]), .rx_source_port(tge_rx_source_port[0]),
    .led_up(tge_led_up[0]), .led_rx(tge_led_rx[0]), .led_tx(tge_led_tx[0]),

    .mgt_clk(mgt_clk),
    .mgt_txdata(mgt_txdata[0]), .mgt_txcharisk(mgt_txcharisk[0]),
    .mgt_rxdata(mgt_rxdata[0]), .mgt_rxcharisk(mgt_rxcharisk[0]),
    .mgt_enable_align(mgt_enable_align[0]),.mgt_en_chan_sync(mgt_enchansync[0]), 
    .mgt_code_valid(mgt_codevalid[0]), .mgt_code_comma(mgt_code_comma[0]),
    .mgt_rxlock(mgt_rxlock[0]), .mgt_syncok(mgt_syncok[0]),
//    .mgt_rxbufferr(mgt_rxbufferr[0]),
    .mgt_loopback(mgt_loopback[0]), .mgt_powerdown(mgt_powerdown[0]),
    .mgt_tx_reset(mgt_tx_reset[0]), .mgt_rx_reset(mgt_rx_reset[0]),

    .wb_clk_i(sys_clk), .wb_rst_i(sys_reset),
    .wb_cyc_i(wb_cyc_o[1]), .wb_stb_i(wb_stb_o[1]),
    .wb_we_i(wb_we_o), .wb_sel_i(wb_sel_o),
    .wb_adr_i(wb_adr_o), .wb_dat_i(wb_dat_o),
    .wb_dat_o(wb_dat_i[16*(1 + 1) - 1: 16*1]),
    .wb_ack_o(wb_ack_i[1])
    ,.debug(debug_led[3:0])
  );

  assign mgt_rxeqmix[0]       = 2'b0; 
  assign mgt_rxeqpole[0]      = 4'b0;
  assign mgt_txpreemphasis[0] = 3'b0;
  assign mgt_txdiffctrl[0]    = 3'b0;

`else 
  // assignments if tengbe is disabled
  assign tge_tx_ack[0]          = 1'b0;
  assign tge_rx_valid[0]        = 1'b0;
  assign tge_rx_data[0]         = 64'b0;
  assign tge_rx_end_of_frame[0] = 1'b0;
  assign tge_rx_size[0]         = 16'b0;
  assign tge_rx_source_ip[0]    = 32'b0;
  assign tge_rx_source_port[0]  = 16'b0;
  assign tge_led_up[0]          = 1'b0;          
  assign tge_led_rx[0]          = 1'b0;
  assign tge_led_tx[0]          = 1'b0;
`endif

`ifdef ENABLE_XAUI_0
  xaui_pipe #(
    .DEFAULT_POWERDOWN(1'b0),
    .DEFAULT_LOOPBACK(1'b1),
    .DEFAULT_TXEN(1'b1)
  ) xaui_pipe_0 (
    .reset(sys_reset), .mgt_clk(mgt_clk),
    .mgt_txdata(mgt_txdata[0]), .mgt_txcharisk(mgt_txcharisk[0]),
    .mgt_rxdata(mgt_rxdata[0]), .mgt_rxcharisk(mgt_rxcharisk[0]),
    .mgt_enable_align(mgt_enable_align[0]),.mgt_en_chan_sync(mgt_enchansync[0]), 
    .mgt_code_valid(mgt_codevalid[0]), .mgt_code_comma(mgt_code_comma[0]),
    .mgt_rxlock(mgt_rxlock[0]), .mgt_syncok(mgt_syncok[0]),
    .mgt_rxbufferr(mgt_rxbufferr[0]),
    .mgt_loopback(mgt_loopback[0]), .mgt_powerdown(mgt_powerdown[0]),
    .mgt_tx_reset(mgt_tx_reset[0]), .mgt_rx_reset(mgt_rx_reset[0]),
    .mgt_rxeqmix(mgt_rxeqmix[0]), .mgt_rxeqpole(mgt_rxeqpole[0]),
    .mgt_txpreemphasis(mgt_txpreemphasis[0]), .mgt_txdiffctrl(mgt_txdiffctrl[0]),

    .wb_clk_i(sys_clk),
    .wb_cyc_i(wb_cyc_o[1]), .wb_stb_i(wb_stb_o[1]),
    .wb_we_i(wb_we_o), .wb_sel_i(wb_sel_o),
    .wb_adr_i(wb_adr_o), .wb_dat_i(wb_dat_o),
    .wb_dat_o(wb_dat_i[16*(1 + 1) - 1: 16*1]),
    .wb_ack_o(wb_ack_i[1]),
    .leds() //rx, tx, linkup
    ,.debug(debug_led[3:0])
  );
`endif

`ifndef ENABLE_XAUI_0
`ifndef ENABLE_TEN_GB_ETH_0
  assign mgt_txdata[0]        = 64'b0;
  assign mgt_txcharisk[0]     = 8'b0;
  assign mgt_enable_align[0]  = 4'b0;
  assign mgt_enchansync[0]    = 1'b0;
  assign mgt_loopback[0]      = 1'b0;
  assign mgt_powerdown[0]     = 1'b1;
  assign mgt_tx_reset[0]      = 4'b0;
  assign mgt_rx_reset[0]      = 4'b0;
  assign mgt_rxeqmix[0]       = 2'b0; 
  assign mgt_rxeqpole[0]      = 4'b0;
  assign mgt_txpreemphasis[0] = 3'b0;
  assign mgt_txdiffctrl[0]    = 3'b0;

  assign wb_ack_i[1] = 1'b0;
  assign wb_dat_i[16*(1 + 1) - 1: 16*1] = 16'b0;
`endif
`endif

/*********** DDR2 Memory Controller ***************/
  wire ddr_clk_0, ddr_clk_90, ddr_clk_div;
  wire ddr_rst_0, ddr_rst_90, ddr_rst_div;

  wire  [2:0] ddr_af_cmd;
  wire [30:0] ddr_af_addr;
  wire ddr_af_wren;
  wire ddr_af_afull;
  wire [127:0] ddr_df_data;
  wire  [15:0] ddr_df_mask;
  wire ddr_df_wren;
  wire ddr_df_afull;
  wire [127:0] ddr_rd_data;
  wire ddr_rd_dvalid;

  wire ddr_phy_ready;
  wire ddr_usr_rst;
  wire ddr_usr_clk;

  wire [6:0] debug_int;

  ddr2_infrastructure #(
    .CLK_FREQ("266")
  ) ddr2_infrastructure_inst (
    .reset(sys_reset | ~idelay_ready),
    .clk_in(sys_clk),
    .ddr_clk_0(ddr_clk_0), .ddr_clk_90(ddr_clk_90), .ddr_clk_div(ddr_clk_div),
    .ddr_rst_0(ddr_rst_0), .ddr_rst_90(ddr_rst_90), .ddr_rst_div(ddr_rst_div),
    .usr_clk(sys_clk), .usr_rst(ddr_usr_rst)
    , .debug(debug_int)
  );

  ddr2_controller #(
   // .CLK_PERIOD(5000)
  ) ddr2_controller_inst (
    .clk0(ddr_clk_0),
    .clk90(ddr_clk_90),
    .clkdiv0(ddr_clk_div),
    .rst0(ddr_rst_0),
    .rst90(ddr_rst_90),
    .rstdiv0(ddr_rst_div),

    .app_af_cmd(ddr_af_cmd),
    .app_af_addr(ddr_af_addr),
    .app_af_wren(ddr_af_wren),
    .app_wdf_wren(ddr_df_wren),
    .app_wdf_data(ddr_df_data),
    .app_wdf_mask_data(ddr_df_mask),
    .app_af_afull(ddr_af_afull),
    .app_wdf_afull(ddr_df_afull),
    .rd_data_valid(ddr_rd_dvalid),
    .rd_data_fifo_out(ddr_rd_data),
    .rd_ecc_error(),
    .phy_init_done(ddr_phy_ready),

    .ddr2_ck({DDR2_CLK1_P, DDR2_CLK0_P}),
    .ddr2_ck_n({DDR2_CLK1_N, DDR2_CLK0_N}),
    .ddr2_a(DDR2_A),
    .ddr2_ba(DDR2_BA),
    .ddr2_ras_n(DDR2_RAS_B),
    .ddr2_cas_n(DDR2_CAS_B),
    .ddr2_we_n(DDR2_WE_B),
    .ddr2_cs_n({DDR2_CS1_B, DDR2_CS0_B}),
    .ddr2_cke({DDR2_CKE1, DDR2_CKE0}),
    .ddr2_odt({DDR2_ODT1, DDR2_ODT0}),
    .ddr2_dm(DDR2_DM),
    .ddr2_dqs(DDR2_DQS_P),
    .ddr2_dqs_n(DDR2_DQS_N),
    .ddr2_dq(DDR2_D)
  );

  wire ddr_arb;

  ddr2_cpu_interface #(
    .SOFT_ADDR_BITS(8)
  ) ddr2_cpu_interface_inst (
    .ddr_clk_0(ddr_clk_0), .ddr_clk_90(ddr_clk_90),
    .debug({1'b1, debug_int}),
    //memory wb slave IF
    .wb_clk_i(sys_clk), .wb_rst_i(sys_reset),

    .reg_wb_we_i(wb_we_o), .reg_wb_cyc_i(wb_cyc_o[2]), .reg_wb_stb_i(wb_stb_o[2]),
    .reg_wb_sel_i(wb_sel_o),
    .reg_wb_adr_i(wb_adr_o), .reg_wb_dat_i(wb_dat_o),
    .reg_wb_dat_o(wb_dat_i[16*(2 + 1) - 1: 16*2]),
    .reg_wb_ack_o(wb_ack_i[2]),
    //memory wb slave IF
    .mem_wb_we_i(wb_we_o), .mem_wb_cyc_i(wb_cyc_o[3]), .mem_wb_stb_i(wb_stb_o[3]),
    .mem_wb_sel_i(wb_sel_o),
    .mem_wb_adr_i(wb_adr_o), .mem_wb_dat_i(wb_dat_o),
    .mem_wb_dat_o(wb_dat_i[16*(3 + 1) - 1: 16*3]),
    .mem_wb_ack_o(wb_ack_i[3]),
    .mem_wb_burst(1'b0),
    //ddr interface
    .ddr2_clk_o(ddr_usr_clk), .ddr2_rst_o(ddr_usr_rst),
    .ddr2_phy_rdy(ddr_phy_ready),
    .ddr2_request_o(ddr_arb), .ddr2_granted_i(ddr_arb),
    .ddr2_af_cmnd_o(ddr_af_cmd), .ddr2_af_addr_o(ddr_af_addr), .ddr2_af_wen_o(ddr_af_wren),
    .ddr2_af_afull_i(ddr_af_afull),
    .ddr2_df_data_o(ddr_df_data), .ddr2_df_mask_o(ddr_df_mask), .ddr2_df_wen_o(ddr_df_wren),
    .ddr2_df_afull_i(ddr_df_afull),
    .ddr2_data_i(ddr_rd_data), .ddr2_dvalid_i(ddr_rd_dvalid)
  );
  /********** Boot Memory ************/
  
  /* 4KB data memory */
  bram_controller #(
    .RAM_SIZE_K(4)
  ) bram_controller_bootrom (
    .wb_clk_i(sys_clk), .wb_rst_i(sys_reset),
    .wb_cyc_i(wb_cyc_o[13]), .wb_stb_i(wb_stb_o[13]),
    .wb_we_i(wb_we_o), .wb_sel_i(wb_sel_o),
    .wb_adr_i(wb_adr_o), .wb_dat_i(wb_dat_o),
    .wb_dat_o(wb_dat_i[16*(13 + 1) - 1: 16*13]),
    .wb_ack_o(wb_ack_i[13])
  );

  /********** LED flashers ************/

  reg [25:0] counter_0;
  always @(posedge ddr_clk_0) begin
     counter_0 <= counter_0 + 1; 
  end

  reg [26:0] counter_1;
  always @(posedge ddr_clk_90) begin
     counter_1 <= counter_1 + 1; 
  end


  assign led_n = {counter_0[25], counter_1[25], ~reset_in, sys_reset, 1'b0, debug_led};







endmodule
