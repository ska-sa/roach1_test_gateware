`include "build_parameters.v"
`include "parameters.v"
module toplevel(
    // System signals
    sys_clk_n, sys_clk_p,
    dly_clk_n, dly_clk_p,
    aux_clk0_n, aux_clk0_p,
    aux_clk1_n, aux_clk1_p,
    led_n,
    // PPC External Peripheral Bus [EPB]
    ppc_irq,
    epb_clk,
    epb_data,
    epb_addr, epb_addr_gp,
    epb_cs_n, epb_be_n, epb_r_w_n, epb_oe_n, epb_blast_n,
    epb_rdy,
    // ZDOK Interfaces
    zdok0_dp_n, zdok0_dp_p,
    zdok0_clk0_n, zdok0_clk0_p,
    zdok0_clk1_n, zdok0_clk1_p,
    zdok1_dp_n, zdok1_dp_p,
    zdok1_clk0_n, zdok1_clk0_p,
    zdok1_clk1_n, zdok1_clk1_p,
    // QDR2 Interfaces
    qdr0_d, qdr0_q,
    qdr0_sa,
    qdr0_w_n, qdr0_r_n,
    qdr0_dll_off_n,
    qdr0_bw_n,
    qdr0_cq_p, qdr0_cq_n,
    qdr0_k_p, qdr0_k_n,
    qdr0_qvld,
    qdr1_d, qdr1_q,
    qdr1_sa,
    qdr1_w_n, qdr1_r_n,
    qdr1_dll_off_n,
    qdr1_bw_n,
    qdr1_cq_p, qdr1_cq_n,
    qdr1_k_p, qdr1_k_n,
    qdr1_qvld,
    // DDR2 SDRAM
    ddr2_dq, ddr2_dm, ddr2_dqs_n, ddr2_dqs_p,
    ddr2_a, ddr2_ba,
    ddr2_ras_n, ddr2_cas_n, ddr2_we_n,
    ddr2_reset_n,
    ddr2_cke_0, ddr2_cke_1,
    ddr2_cs_n_0, ddr2_cs_n_1,
    ddr2_odt_0, ddr2_odt_1,
    ddr2_ck_0_n, ddr2_ck_0_p,
    ddr2_ck_1_n, ddr2_ck_1_p,
    ddr2_ck_2_n, ddr2_ck_2_p,
    ddr2_scl, ddr2_sda,
    ddr2_par_in, ddr2_par_out,
    // Differential GPIO
    diff_gpio_a_n, diff_gpio_a_p,
    diff_gpio_a_clk_p, diff_gpio_a_clk_n,
    diff_gpio_b_n, diff_gpio_b_p,
    diff_gpio_b_clk_p, diff_gpio_b_clk_n,
    // Single-Ended GPIO,
    se_gpio_a, se_gpio_a_oen_n,
    se_gpio_b, se_gpio_b_oen_n,
    // MGT signals,
    mgt_ref_clk_top_n, mgt_ref_clk_top_p,
    mgt_ref_clk_bottom_n, mgt_ref_clk_bottom_p,

    mgt_tx_top_1_n, mgt_tx_top_1_p,
    mgt_tx_top_0_n, mgt_tx_top_0_p,
    mgt_tx_bottom_1_n, mgt_tx_bottom_1_p,
    mgt_tx_bottom_0_n, mgt_tx_bottom_0_p,
    mgt_rx_top_1_n, mgt_rx_top_1_p,
    mgt_rx_top_0_n, mgt_rx_top_0_p,
    mgt_rx_bottom_1_n, mgt_rx_bottom_1_p,
    mgt_rx_bottom_0_n, mgt_rx_bottom_0_p
  );
  input  sys_clk_n, sys_clk_p;
  input  dly_clk_n, dly_clk_p;
  input  aux_clk0_n, aux_clk0_p;
  input  aux_clk1_n, aux_clk1_p;
  output [3:0] led_n;

  output ppc_irq;
  input  epb_clk;
  inout  [15:0] epb_data;
  input  [22:0] epb_addr;
  input   [5:0] epb_addr_gp;
  input  epb_cs_n, epb_r_w_n, epb_oe_n, epb_blast_n;
  input   [1:0] epb_be_n;
  output epb_rdy;
  
  inout  [37:0] zdok0_dp_n;
  inout  [37:0] zdok0_dp_p;
  input  zdok0_clk0_n, zdok0_clk0_p;
  input  zdok0_clk1_n, zdok0_clk1_p;
  inout  [37:0] zdok1_dp_n;
  inout  [37:0] zdok1_dp_p;
  input  zdok1_clk0_n, zdok1_clk0_p;
  input  zdok1_clk1_n, zdok1_clk1_p;

  output [17:0] qdr0_d;
  input  [17:0] qdr0_q;
  output [21:0] qdr0_sa;
  output qdr0_w_n, qdr0_r_n;
  output qdr0_dll_off_n;
  output [1:0] qdr0_bw_n;
  input  qdr0_cq_p, qdr0_cq_n;
  output qdr0_k_p, qdr0_k_n;
  input  qdr0_qvld;

  output [17:0] qdr1_d;
  input  [17:0] qdr1_q;
  output [21:0] qdr1_sa;
  output qdr1_w_n, qdr1_r_n;
  output qdr1_dll_off_n;
  output [1:0] qdr1_bw_n;
  input  qdr1_cq_p, qdr1_cq_n;
  output qdr1_k_p, qdr1_k_n;
  input  qdr1_qvld;
  
  inout  [71:0] ddr2_dq;
  output  [8:0] ddr2_dm;
  inout   [8:0] ddr2_dqs_n;
  inout   [8:0] ddr2_dqs_p;
  output [15:0] ddr2_a;
  output  [2:0] ddr2_ba;
  output ddr2_ras_n, ddr2_cas_n, ddr2_we_n, ddr2_reset_n;
  output ddr2_cke_0, ddr2_cke_1, ddr2_cs_n_0, ddr2_cs_n_1, ddr2_odt_0, ddr2_odt_1;
  output ddr2_ck_0_n, ddr2_ck_0_p, ddr2_ck_1_n, ddr2_ck_1_p, ddr2_ck_2_n, ddr2_ck_2_p;
    
  inout  ddr2_scl, ddr2_sda;
  input  ddr2_par_in;
  output ddr2_par_out;
  
  inout  [18:0] diff_gpio_a_n;
  inout  [18:0] diff_gpio_a_p;
  inout  diff_gpio_a_clk_p, diff_gpio_a_clk_n;
  inout  [18:0] diff_gpio_b_n;
  inout  [18:0] diff_gpio_b_p;
  inout  diff_gpio_b_clk_p, diff_gpio_b_clk_n;

  inout  [7:0] se_gpio_a;
  output se_gpio_a_oen_n;
  inout  [7:0] se_gpio_b;
  output se_gpio_b_oen_n;

  input  mgt_ref_clk_top_n, mgt_ref_clk_top_p;
  input  mgt_ref_clk_bottom_n, mgt_ref_clk_bottom_p;

  output [3:0] mgt_tx_top_1_n;
  output [3:0] mgt_tx_top_1_p;
  output [3:0] mgt_tx_top_0_n;
  output [3:0] mgt_tx_top_0_p;
  output [3:0] mgt_tx_bottom_1_n;
  output [3:0] mgt_tx_bottom_1_p;
  output [3:0] mgt_tx_bottom_0_n;
  output [3:0] mgt_tx_bottom_0_p;

  input  [3:0] mgt_rx_top_1_n;
  input  [3:0] mgt_rx_top_1_p;
  input  [3:0] mgt_rx_top_0_n;
  input  [3:0] mgt_rx_top_0_p;
  input  [3:0] mgt_rx_bottom_1_n;
  input  [3:0] mgt_rx_bottom_1_p;
  input  [3:0] mgt_rx_bottom_0_n;
  input  [3:0] mgt_rx_bottom_0_p;

  /****************** Glocal Signals **********************/

  wire sys_clk, dly_clk, mgt_clk, aux_clk_0, aux_clk_1;
  // synthesis attribute KEEP of sys_clk is TRUE
  // synthesis attribute KEEP of dly_clk is TRUE
  // synthesis attribute KEEP of mgt_clk is TRUE
  // Ensure that the above nets are not synthesized away
  wire sys_reset;
  wire soft_reset;
  assign led_n = 4'b0101;

  /**************** Global Infrastructure ****************/


  wire idelay_ready_nc;

  infrastructure infrastructure_inst(
    .sys_clk_n(sys_clk_n), .sys_clk_p(sys_clk_p),
    .sys_clk(sys_clk),
    .dly_clk_n(dly_clk_n), .dly_clk_p(dly_clk_p),
    .dly_clk(dly_clk),
    .idelay_rst(sys_reset), .idelay_rdy(idelay_ready_nc),
    .aux_clk0_n(aux_clk0_n), .aux_clk0_p(aux_clk0_p),
    .aux_clk_0(aux_clk_0),
    .aux_clk1_n(aux_clk1_n), .aux_clk1_p(aux_clk1_p),
    .aux_clk_1(aux_clk_1)
  );


  /********************* Reset Block *********************/

  reset_block #(
    .DELAY(100),
    .WIDTH(10)
  ) reset_block_inst(
    .clk(sys_clk), .async_reset_i(1'b0),
    .reset_i(soft_reset), .reset_o(sys_reset)
  );

  /**************** Serial Communications ****************/
  wire serial_in, serial_out;

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

  wire [1:0] wbm_id;

  wbm_arbiter #(
    .NUM_MASTERS(2)
  ) wbm_arbiter_inst (
    .wb_clk_i(sys_clk), .wb_rst_i(sys_reset),
    .wbm_cyc_i({wbm_cyc_o_1, wbm_cyc_o_0}), .wbm_stb_i({wbm_stb_o_1, wbm_stb_o_0}), .wbm_we_i({wbm_we_o, wbm_we_o}), .wbm_sel_i({wbm_sel_o_1, wbm_sel_o_0}),
    .wbm_adr_i({wbm_adr_o_1, wbm_adr_o_0}), .wbm_dat_i({wbm_dat_o_1, wbm_dat_o_0}), .wbm_dat_o({wbm_dat_i_1, wbm_dat_i_0}),
    .wbm_ack_o({wbm_ack_i_1, wbm_ack_i_0}), .wbm_err_o({wbm_err_i_1, wbm_err_i_0}),
    .wbs_cyc_o(wbi_cyc_o), .wbs_stb_o(wbi_stb_o), .wbs_we_o(wbi_we_o), .wbs_sel_o(wbi_sel_o),
    .wbs_adr_o(wbi_adr_o), .wbs_dat_o(wbi_dat_o), .wbs_dat_i(wbi_dat_i),
    .wbs_ack_i(wbi_ack_i), .wbs_err_i(wbi_err_i),
    .wbm_mask(2'b11), //both enabled
    .wbm_id(wbm_id)
  );

  localparam NUM_SLAVES = 14;

  localparam SLAVE_ADDR = {32'h000d_0000, 32'h000c_0000, 32'h000b_0000, 32'h000a_0000, //slaves 13:10
                           32'h0009_0000, 32'h0008_0000, 32'h0007_0000, 32'h0006_0000, //slaves 9:6
                           32'h0005_0000, 32'h0004_0000, 32'h0003_0000, 32'h0002_0000, //slaves 5:2
                           32'h0001_0000, 32'h0000_0000};                              //slaves 1:0

  localparam SLAVE_HIGH = {32'h000d_ffff, 32'h000c_ffff, 32'h000b_ffff, 32'h000a_ffff, //slaves 13:10
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

  wire  [3:0] mgt_tx_reset      [3:0];
  wire  [3:0] mgt_rx_reset      [3:0];
  wire [63:0] mgt_rxdata        [3:0];
  wire  [7:0] mgt_rxcharisk     [3:0];
  wire [63:0] mgt_txdata        [3:0];
  wire  [7:0] mgt_txcharisk     [3:0];
  wire  [7:0] mgt_code_comma    [3:0];
  wire  [3:0] mgt_enable_align  [3:0];
  wire mgt_enchansync           [3:0];
  wire mgt_loopback             [3:0];
  wire mgt_powerdown            [3:0];
  wire  [3:0] mgt_rxlock        [3:0];
  wire  [3:0] mgt_syncok        [3:0];
  wire  [7:0] mgt_codevalid     [3:0];
  wire  [3:0] mgt_rxbufferr     [3:0];
  wire  [1:0] mgt_rxeqmix       [3:0];
  wire  [3:0] mgt_rxeqpole      [3:0];
  wire  [2:0] mgt_txpreemphasis [3:0];
  wire  [2:0] mgt_txdiffctrl    [3:0];

  xaui_infrastructure #(
    .DIFF_BOOST(`MGT_DIFF_BOOST)
  ) xaui_infrastructure_inst (
    .reset(sys_reset),
    .mgt_refclk_t_n(mgt_ref_clk_top_n), .mgt_refclk_t_p(mgt_ref_clk_top_p), 
    .mgt_refclk_b_n(mgt_ref_clk_bottom_n), .mgt_refclk_b_p(mgt_ref_clk_bottom_p), 

    .mgt_tx_t0_n(mgt_tx_top_0_n),    .mgt_tx_t0_p(mgt_tx_top_0_p),
    .mgt_tx_t1_n(mgt_tx_top_1_n),    .mgt_tx_t1_p(mgt_tx_top_1_p),
    .mgt_tx_b0_n(mgt_tx_bottom_0_n), .mgt_tx_b0_p(mgt_tx_bottom_0_p),
    .mgt_tx_b1_n(mgt_tx_bottom_1_n), .mgt_tx_b1_p(mgt_tx_bottom_1_p),
    .mgt_rx_t0_n(mgt_rx_top_0_n),    .mgt_rx_t0_p(mgt_rx_top_0_p),
    .mgt_rx_t1_n(mgt_rx_top_1_n),    .mgt_rx_t1_p(mgt_rx_top_1_p),
    .mgt_rx_b0_n(mgt_rx_bottom_0_n), .mgt_rx_b0_p(mgt_rx_bottom_0_p),
    .mgt_rx_b1_n(mgt_rx_bottom_1_n), .mgt_rx_b1_p(mgt_rx_bottom_1_p),

    .mgt_clk(mgt_clk), .mgt_clk_lock(mgt_clk_lock),

    .mgt_tx_reset_3(mgt_tx_reset[3]), .mgt_rx_reset_3(mgt_rx_reset[3]),
    .mgt_rxdata_3(mgt_rxdata[3]), .mgt_rxcharisk_3(mgt_rxcharisk[3]),
    .mgt_txdata_3(mgt_txdata[3]), .mgt_txcharisk_3(mgt_txcharisk[3]),
    .mgt_code_comma_3(mgt_code_comma[3]),
    .mgt_enchansync_3(mgt_enchansync[3]), .mgt_enable_align_3(mgt_enable_align[3]),
    .mgt_loopback_3(mgt_loopback[3]), .mgt_powerdown_3(mgt_powerdown[3]),
    .mgt_rxlock_3(mgt_rxlock[3]), .mgt_syncok_3(mgt_syncok[3]),
    .mgt_codevalid_3(mgt_codevalid[3]), .mgt_rxbufferr_3(mgt_rxbufferr[3]),
    .mgt_rxeqmix_3(mgt_rxeqmix[3]), .mgt_rxeqpole_3(mgt_rxeqpole[3]),
    .mgt_txpreemphasis_3(mgt_txpreemphasis[3]), .mgt_txdiffctrl_3(mgt_txdiffctrl[3]),

    .mgt_tx_reset_2(mgt_tx_reset[2]), .mgt_rx_reset_2(mgt_rx_reset[2]),
    .mgt_rxdata_2(mgt_rxdata[2]), .mgt_rxcharisk_2(mgt_rxcharisk[2]),
    .mgt_txdata_2(mgt_txdata[2]), .mgt_txcharisk_2(mgt_txcharisk[2]),
    .mgt_code_comma_2(mgt_code_comma[2]),
    .mgt_enchansync_2(mgt_enchansync[2]), .mgt_enable_align_2(mgt_enable_align[2]),
    .mgt_loopback_2(mgt_loopback[2]), .mgt_powerdown_2(mgt_powerdown[2]),
    .mgt_rxlock_2(mgt_rxlock[2]), .mgt_syncok_2(mgt_syncok[2]),
    .mgt_codevalid_2(mgt_codevalid[2]), .mgt_rxbufferr_2(mgt_rxbufferr[2]),
    .mgt_rxeqmix_2(mgt_rxeqmix[2]), .mgt_rxeqpole_2(mgt_rxeqpole[2]),
    .mgt_txpreemphasis_2(mgt_txpreemphasis[2]), .mgt_txdiffctrl_2(mgt_txdiffctrl[2]),

    .mgt_tx_reset_1(mgt_tx_reset[1]), .mgt_rx_reset_1(mgt_rx_reset[1]),
    .mgt_rxdata_1(mgt_rxdata[1]), .mgt_rxcharisk_1(mgt_rxcharisk[1]),
    .mgt_txdata_1(mgt_txdata[1]), .mgt_txcharisk_1(mgt_txcharisk[1]),
    .mgt_code_comma_1(mgt_code_comma[1]),
    .mgt_enchansync_1(mgt_enchansync[1]), .mgt_enable_align_1(mgt_enable_align[1]),
    .mgt_loopback_1(mgt_loopback[1]), .mgt_powerdown_1(mgt_powerdown[1]),
    .mgt_rxlock_1(mgt_rxlock[1]), .mgt_syncok_1(mgt_syncok[1]),
    .mgt_codevalid_1(mgt_codevalid[1]), .mgt_rxbufferr_1(mgt_rxbufferr[1]),
    .mgt_rxeqmix_1(mgt_rxeqmix[1]), .mgt_rxeqpole_1(mgt_rxeqpole[1]),
    .mgt_txpreemphasis_1(mgt_txpreemphasis[1]), .mgt_txdiffctrl_1(mgt_txdiffctrl[1]),

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
  wire tge_usr_clk               [3:0];
  wire tge_usr_rst               [3:0];
  wire tge_tx_valid              [3:0];
  wire tge_tx_ack                [3:0];
  wire tge_tx_end_of_frame       [3:0];
  wire tge_tx_discard            [3:0];
  wire [63:0] tge_tx_data        [3:0];
  wire [31:0] tge_tx_dest_ip     [3:0];
  wire [15:0] tge_tx_dest_port   [3:0];
  wire tge_rx_valid              [3:0];
  wire tge_rx_ack                [3:0];
  wire [63:0] tge_rx_data        [3:0];
  wire tge_rx_end_of_frame       [3:0];
  wire [15:0] tge_rx_size        [3:0];
  wire [31:0] tge_rx_source_ip   [3:0];
  wire [15:0] tge_rx_source_port [3:0];
  wire tge_led_up                [3:0];
  wire tge_led_rx                [3:0];
  wire tge_led_tx                [3:0];


  /******************* XAUI/TGBE 0 **********************/

`ifdef ENABLE_TEN_GB_ETH_0
  ten_gb_eth ten_gb_eth_0 (
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


  /******************* XAUI/TGBE 1 **********************/

`ifdef ENABLE_TEN_GB_ETH_1
  ten_gb_eth ten_gb_eth_1 (
    .clk(tge_usr_clk[1]), .rst(tge_usr_rst[1]),
    .tx_valid(tge_tx_valid[1]), .tx_ack(tge_tx_ack[1]),
    .tx_end_of_frame(tge_tx_end_of_frame[1]), .tx_discard(tge_tx_discard[1]),
    .tx_data(tge_tx_data[1]), .tx_dest_ip(tge_tx_dest_ip[1]),
    .tx_dest_port(tge_tx_dest_port[1]),
    .rx_valid(tge_rx_valid[1]), .rx_ack(tge_rx_ack[1]),
    .rx_data(tge_rx_data[1]), .rx_end_of_frame(tge_rx_end_of_frame[1]),
    .rx_size(tge_rx_size[1]),
    .rx_source_ip(tge_rx_source_ip[1]), .rx_source_port(tge_rx_source_port[1]),
    .led_up(tge_led_up[1]), .led_rx(tge_led_rx[1]), .led_tx(tge_led_tx[1]),

    .mgt_clk(mgt_clk),
    .mgt_txdata(mgt_txdata[1]), .mgt_txcharisk(mgt_txcharisk[1]),
    .mgt_rxdata(mgt_rxdata[1]), .mgt_rxcharisk(mgt_rxcharisk[1]),
    .mgt_enable_align(mgt_enable_align[1]),.mgt_en_chan_sync(mgt_enchansync[1]), 
    .mgt_code_valid(mgt_codevalid[1]), .mgt_code_comma(mgt_code_comma[1]),
    .mgt_rxlock(mgt_rxlock[1]), .mgt_syncok(mgt_syncok[1]),
//    .mgt_rxbufferr(mgt_rxbufferr[1]),
    .mgt_loopback(mgt_loopback[1]), .mgt_powerdown(mgt_powerdown[1]),
    .mgt_tx_reset(mgt_tx_reset[1]), .mgt_rx_reset(mgt_rx_reset[1]),

    .wb_clk_i(sys_clk), .wb_rst_i(sys_reset),
    .wb_cyc_i(wb_cyc_o[2]), .wb_stb_i(wb_stb_o[2]),
    .wb_we_i(wb_we_o), .wb_sel_i(wb_sel_o),
    .wb_adr_i(wb_adr_o), .wb_dat_i(wb_dat_o),
    .wb_dat_o(wb_dat_i[16*(2 + 1) - 1: 16*2]),
    .wb_ack_o(wb_ack_i[2])
  );

  assign mgt_rxeqmix[1]       = 2'b0; 
  assign mgt_rxeqpole[1]      = 4'b0;
  assign mgt_txpreemphasis[1] = 3'b0;
  assign mgt_txdiffctrl[1]    = 3'b0;
`else 
  // assignments if tengbe is disabled
  assign tge_tx_ack[1]          = 1'b0;
  assign tge_rx_valid[1]        = 1'b0;
  assign tge_rx_data[1]         = 64'b0;
  assign tge_rx_end_of_frame[1] = 1'b0;
  assign tge_rx_size[1]         = 16'b0;
  assign tge_rx_source_ip[1]    = 32'b0;
  assign tge_rx_source_port[1]  = 16'b0;
  assign tge_led_up[1]          = 1'b0;          
  assign tge_led_rx[1]          = 1'b0;
  assign tge_led_tx[1]          = 1'b0;
`endif

`ifdef ENABLE_XAUI_1
  xaui_pipe #(
    .DEFAULT_POWERDOWN(1'b0),
    .DEFAULT_LOOPBACK(1'b1),
    .DEFAULT_TXEN(1'b1)
  ) xaui_pipe_1 (
    .reset(sys_reset), .mgt_clk(mgt_clk),
    .mgt_txdata(mgt_txdata[1]), .mgt_txcharisk(mgt_txcharisk[1]),
    .mgt_rxdata(mgt_rxdata[1]), .mgt_rxcharisk(mgt_rxcharisk[1]),
    .mgt_enable_align(mgt_enable_align[1]),.mgt_en_chan_sync(mgt_enchansync[1]), 
    .mgt_code_valid(mgt_codevalid[1]), .mgt_code_comma(mgt_code_comma[1]),
    .mgt_rxlock(mgt_rxlock[1]), .mgt_syncok(mgt_syncok[1]),
    .mgt_rxbufferr(mgt_rxbufferr[1]),
    .mgt_loopback(mgt_loopback[1]), .mgt_powerdown(mgt_powerdown[1]),
    .mgt_tx_reset(mgt_tx_reset[1]), .mgt_rx_reset(mgt_rx_reset[1]),
    .mgt_rxeqmix(mgt_rxeqmix[1]), .mgt_rxeqpole(mgt_rxeqpole[1]),
    .mgt_txpreemphasis(mgt_txpreemphasis[1]), .mgt_txdiffctrl(mgt_txdiffctrl[1]),

    .wb_clk_i(sys_clk),
    .wb_cyc_i(wb_cyc_o[2]), .wb_stb_i(wb_stb_o[2]),
    .wb_we_i(wb_we_o), .wb_sel_i(wb_sel_o),
    .wb_adr_i(wb_adr_o), .wb_dat_i(wb_dat_o),
    .wb_dat_o(wb_dat_i[16*(2 + 1) - 1: 16*2]),
    .wb_ack_o(wb_ack_i[2]),
    .leds() //rx, tx, linkup
  );
`endif

`ifndef ENABLE_XAUI_1
`ifndef ENABLE_TEN_GB_ETH_1
  assign mgt_txdata[1]        = 64'b0;
  assign mgt_txcharisk[1]     = 8'b0;
  assign mgt_enable_align[1]  = 4'b0;
  assign mgt_enchansync[1]    = 1'b0;
  assign mgt_loopback[1]      = 1'b0;
  assign mgt_powerdown[1]     = 1'b1;
  assign mgt_tx_reset[1]      = 4'b0;
  assign mgt_rx_reset[1]      = 4'b0;
  assign mgt_rxeqmix[1]       = 2'b0; 
  assign mgt_rxeqpole[1]      = 4'b0;
  assign mgt_txpreemphasis[1] = 3'b0;
  assign mgt_txdiffctrl[1]    = 3'b0;

  assign wb_ack_i[2] = 1'b0;
  assign wb_dat_i[16*(2 + 1) - 1: 16*2] = 16'b0;
`endif
`endif

  /******************* XAUI/TGBE 2 **********************/

`ifdef ENABLE_TEN_GB_ETH_2
  ten_gb_eth ten_gb_eth_2 (
    .clk(tge_usr_clk[2]), .rst(tge_usr_rst[2]),
    .tx_valid(tge_tx_valid[2]), .tx_ack(tge_tx_ack[2]),
    .tx_end_of_frame(tge_tx_end_of_frame[2]), .tx_discard(tge_tx_discard[2]),
    .tx_data(tge_tx_data[2]), .tx_dest_ip(tge_tx_dest_ip[2]),
    .tx_dest_port(tge_tx_dest_port[2]),
    .rx_valid(tge_rx_valid[2]), .rx_ack(tge_rx_ack[2]),
    .rx_data(tge_rx_data[2]), .rx_end_of_frame(tge_rx_end_of_frame[2]),
    .rx_size(tge_rx_size[2]),
    .rx_source_ip(tge_rx_source_ip[2]), .rx_source_port(tge_rx_source_port[2]),
    .led_up(tge_led_up[2]), .led_rx(tge_led_rx[2]), .led_tx(tge_led_tx[2]),

    .mgt_clk(mgt_clk),
    .mgt_txdata(mgt_txdata[2]), .mgt_txcharisk(mgt_txcharisk[2]),
    .mgt_rxdata(mgt_rxdata[2]), .mgt_rxcharisk(mgt_rxcharisk[2]),
    .mgt_enable_align(mgt_enable_align[2]),.mgt_en_chan_sync(mgt_enchansync[2]), 
    .mgt_code_valid(mgt_codevalid[2]), .mgt_code_comma(mgt_code_comma[2]),
    .mgt_rxlock(mgt_rxlock[2]), .mgt_syncok(mgt_syncok[2]),
//    .mgt_rxbufferr(mgt_rxbufferr[2]),
    .mgt_loopback(mgt_loopback[2]), .mgt_powerdown(mgt_powerdown[2]),
    .mgt_tx_reset(mgt_tx_reset[2]), .mgt_rx_reset(mgt_rx_reset[2]),

    .wb_clk_i(sys_clk), .wb_rst_i(sys_reset),
    .wb_cyc_i(wb_cyc_o[3]), .wb_stb_i(wb_stb_o[3]),
    .wb_we_i(wb_we_o), .wb_sel_i(wb_sel_o),
    .wb_adr_i(wb_adr_o), .wb_dat_i(wb_dat_o),
    .wb_dat_o(wb_dat_i[16*(3 + 1) - 1: 16*3]),
    .wb_ack_o(wb_ack_i[3])
  );

  assign mgt_rxeqmix[2]       = 2'b0; 
  assign mgt_rxeqpole[2]      = 4'b0;
  assign mgt_txpreemphasis[2] = 3'b0;
  assign mgt_txdiffctrl[2]    = 3'b0;
`else 
  // assignments if tengbe is disabled
  assign tge_tx_ack[2]          = 1'b0;
  assign tge_rx_valid[2]        = 1'b0;
  assign tge_rx_data[2]         = 64'b0;
  assign tge_rx_end_of_frame[2] = 1'b0;
  assign tge_rx_size[2]         = 16'b0;
  assign tge_rx_source_ip[2]    = 32'b0;
  assign tge_rx_source_port[2]  = 16'b0;
  assign tge_led_up[2]          = 1'b0;          
  assign tge_led_rx[2]          = 1'b0;
  assign tge_led_tx[2]          = 1'b0;
`endif

`ifdef ENABLE_XAUI_2
  xaui_pipe #(
    .DEFAULT_POWERDOWN(1'b0),
    .DEFAULT_LOOPBACK(1'b1),
    .DEFAULT_TXEN(1'b1)
  ) xaui_pipe_2 (
    .reset(sys_reset), .mgt_clk(mgt_clk),
    .mgt_txdata(mgt_txdata[2]), .mgt_txcharisk(mgt_txcharisk[2]),
    .mgt_rxdata(mgt_rxdata[2]), .mgt_rxcharisk(mgt_rxcharisk[2]),
    .mgt_enable_align(mgt_enable_align[2]),.mgt_en_chan_sync(mgt_enchansync[2]), 
    .mgt_code_valid(mgt_codevalid[2]), .mgt_code_comma(mgt_code_comma[2]),
    .mgt_rxlock(mgt_rxlock[2]), .mgt_syncok(mgt_syncok[2]),
    .mgt_rxbufferr(mgt_rxbufferr[2]),
    .mgt_loopback(mgt_loopback[2]), .mgt_powerdown(mgt_powerdown[2]),
    .mgt_tx_reset(mgt_tx_reset[2]), .mgt_rx_reset(mgt_rx_reset[2]),
    .mgt_rxeqmix(mgt_rxeqmix[2]), .mgt_rxeqpole(mgt_rxeqpole[2]),
    .mgt_txpreemphasis(mgt_txpreemphasis[2]), .mgt_txdiffctrl(mgt_txdiffctrl[2]),

    .wb_clk_i(sys_clk),
    .wb_cyc_i(wb_cyc_o[3]), .wb_stb_i(wb_stb_o[3]),
    .wb_we_i(wb_we_o), .wb_sel_i(wb_sel_o),
    .wb_adr_i(wb_adr_o), .wb_dat_i(wb_dat_o),
    .wb_dat_o(wb_dat_i[16*(3 + 1) - 1: 16*3]),
    .wb_ack_o(wb_ack_i[3]),
    .leds() //rx, tx, linkup
  );
`endif

`ifndef ENABLE_XAUI_2
`ifndef ENABLE_TEN_GB_ETH_2
  assign mgt_txdata[2]        = 64'b0;
  assign mgt_txcharisk[2]     = 8'b0;
  assign mgt_enable_align[2]  = 4'b0;
  assign mgt_enchansync[2]    = 1'b0;
  assign mgt_loopback[2]      = 1'b0;
  assign mgt_powerdown[2]     = 1'b1;
  assign mgt_tx_reset[2]      = 4'b0;
  assign mgt_rx_reset[2]      = 4'b0;
  assign mgt_rxeqmix[2]       = 2'b0; 
  assign mgt_rxeqpole[2]      = 4'b0;
  assign mgt_txpreemphasis[2] = 3'b0;
  assign mgt_txdiffctrl[2]    = 3'b0;

  assign wb_ack_i[3] = 1'b0;
  assign wb_dat_i[16*(3 + 1) - 1: 16*3] = 16'b0;
`endif
`endif

  /******************* XAUI/TGBE 3 **********************/

`ifdef ENABLE_TEN_GB_ETH_3
  ten_gb_eth ten_gb_eth_3 (
    .clk(tge_usr_clk[3]), .rst(tge_usr_rst[3]),
    .tx_valid(tge_tx_valid[3]), .tx_ack(tge_tx_ack[3]),
    .tx_end_of_frame(tge_tx_end_of_frame[3]), .tx_discard(tge_tx_discard[3]),
    .tx_data(tge_tx_data[3]), .tx_dest_ip(tge_tx_dest_ip[3]),
    .tx_dest_port(tge_tx_dest_port[3]),
    .rx_valid(tge_rx_valid[3]), .rx_ack(tge_rx_ack[3]),
    .rx_data(tge_rx_data[3]), .rx_end_of_frame(tge_rx_end_of_frame[3]),
    .rx_size(tge_rx_size[3]),
    .rx_source_ip(tge_rx_source_ip[3]), .rx_source_port(tge_rx_source_port[3]),
    .led_up(tge_led_up[3]), .led_rx(tge_led_rx[3]), .led_tx(tge_led_tx[3]),

    .mgt_clk(mgt_clk),
    .mgt_txdata(mgt_txdata[3]), .mgt_txcharisk(mgt_txcharisk[3]),
    .mgt_rxdata(mgt_rxdata[3]), .mgt_rxcharisk(mgt_rxcharisk[3]),
    .mgt_enable_align(mgt_enable_align[3]),.mgt_en_chan_sync(mgt_enchansync[3]), 
    .mgt_code_valid(mgt_codevalid[3]), .mgt_code_comma(mgt_code_comma[3]),
    .mgt_rxlock(mgt_rxlock[3]), .mgt_syncok(mgt_syncok[3]),
//    .mgt_rxbufferr(mgt_rxbufferr[3]),
    .mgt_loopback(mgt_loopback[3]), .mgt_powerdown(mgt_powerdown[3]),
    .mgt_tx_reset(mgt_tx_reset[3]), .mgt_rx_reset(mgt_rx_reset[3]),

    .wb_clk_i(sys_clk), .wb_rst_i(sys_reset),
    .wb_cyc_i(wb_cyc_o[4]), .wb_stb_i(wb_stb_o[4]),
    .wb_we_i(wb_we_o), .wb_sel_i(wb_sel_o),
    .wb_adr_i(wb_adr_o), .wb_dat_i(wb_dat_o),
    .wb_dat_o(wb_dat_i[16*(4 + 1) - 1: 16*4]),
    .wb_ack_o(wb_ack_i[4])
  );

  assign mgt_rxeqmix[3]       = 2'b0; 
  assign mgt_rxeqpole[3]      = 4'b0;
  assign mgt_txpreemphasis[3] = 3'b0;
  assign mgt_txdiffctrl[3]    = 3'b0;
`else 
  // assignments if tengbe is disabled
  assign tge_tx_ack[3]          = 1'b0;
  assign tge_rx_valid[3]        = 1'b0;
  assign tge_rx_data[3]         = 64'b0;
  assign tge_rx_end_of_frame[3] = 1'b0;
  assign tge_rx_size[3]         = 16'b0;
  assign tge_rx_source_ip[3]    = 32'b0;
  assign tge_rx_source_port[3]  = 16'b0;
  assign tge_led_up[3]          = 1'b0;          
  assign tge_led_rx[3]          = 1'b0;
  assign tge_led_tx[3]          = 1'b0;
`endif

`ifdef ENABLE_XAUI_3
  xaui_pipe #(
    .DEFAULT_POWERDOWN(1'b0),
    .DEFAULT_LOOPBACK(1'b1),
    .DEFAULT_TXEN(1'b1)
  ) xaui_pipe_3 (
    .reset(sys_reset), .mgt_clk(mgt_clk),
    .mgt_txdata(mgt_txdata[3]), .mgt_txcharisk(mgt_txcharisk[3]),
    .mgt_rxdata(mgt_rxdata[3]), .mgt_rxcharisk(mgt_rxcharisk[3]),
    .mgt_enable_align(mgt_enable_align[3]),.mgt_en_chan_sync(mgt_enchansync[3]), 
    .mgt_code_valid(mgt_codevalid[3]), .mgt_code_comma(mgt_code_comma[3]),
    .mgt_rxlock(mgt_rxlock[3]), .mgt_syncok(mgt_syncok[3]),
    .mgt_rxbufferr(mgt_rxbufferr[3]),
    .mgt_loopback(mgt_loopback[3]), .mgt_powerdown(mgt_powerdown[3]),
    .mgt_tx_reset(mgt_tx_reset[3]), .mgt_rx_reset(mgt_rx_reset[3]),
    .mgt_rxeqmix(mgt_rxeqmix[3]), .mgt_rxeqpole(mgt_rxeqpole[3]),
    .mgt_txpreemphasis(mgt_txpreemphasis[3]), .mgt_txdiffctrl(mgt_txdiffctrl[3]),

    .wb_clk_i(sys_clk),
    .wb_cyc_i(wb_cyc_o[4]), .wb_stb_i(wb_stb_o[4]),
    .wb_we_i(wb_we_o), .wb_sel_i(wb_sel_o),
    .wb_adr_i(wb_adr_o), .wb_dat_i(wb_dat_o),
    .wb_dat_o(wb_dat_i[16*(4 + 1) - 1: 16*4]),
    .wb_ack_o(wb_ack_i[4]),
    .leds() //rx, tx, linkup
  );
`endif

`ifndef ENABLE_XAUI_3
`ifndef ENABLE_TEN_GB_ETH_3
  assign mgt_txdata[3]        = 64'b0;
  assign mgt_txcharisk[3]     = 8'b0;
  assign mgt_enable_align[3]  = 4'b0;
  assign mgt_enchansync[3]    = 1'b0;
  assign mgt_loopback[3]      = 1'b0;
  assign mgt_powerdown[3]     = 1'b1;
  assign mgt_tx_reset[3]      = 4'b0;
  assign mgt_rx_reset[3]      = 4'b0;
  assign mgt_rxeqmix[3]       = 2'b0; 
  assign mgt_rxeqpole[3]      = 4'b0;
  assign mgt_txpreemphasis[3] = 3'b0;
  assign mgt_txdiffctrl[3]    = 3'b0;

  assign wb_ack_i[4] = 1'b0;
  assign wb_dat_i[16*(4 + 1) - 1: 16*4] = 16'b0;
`endif
`endif

  /******************* GPIO ***********************/

  /******** Single Ended **********/
  assign se_gpio_a_oen_n = 1'b0;
  assign se_gpio_b_oen_n = 1'b1;

  assign se_gpio_a[0] = serial_out;
  assign se_gpio_a[7:1] = 7'b0;

  assign serial_in  = se_gpio_b[0];
  assign se_gpio_b[7:1] = {7{1'bz}};

  /******** Differential **********/
  assign diff_gpio_a_n = {19{1'bz}};
  assign diff_gpio_a_p = {19{1'bz}};
  assign diff_gpio_a_clk_n = 1'bz;
  assign diff_gpio_a_clk_p = 1'bz;
  assign diff_gpio_b_n = {19{1'bz}};
  assign diff_gpio_b_p = {19{1'bz}};
  assign diff_gpio_b_clk_n = 1'bz;
  assign diff_gpio_b_clk_p = 1'bz;

  /****************** ZDOKs **********************/
  assign zdok0_dp_n = {38{1'bz}};
  assign zdok0_dp_p = {38{1'bz}};
  assign zdok1_dp_n = {38{1'bz}};
  assign zdok1_dp_p = {38{1'bz}};

  /***************** QDR0 ************************/
  assign qdr0_d  = {18{1'b0}};
  assign qdr0_sa = {22{1'b0}};
  assign qdr0_w_n = 1'b1;
  assign qdr0_r_n = 1'b1;
  assign qdr0_dll_off_n = 1'b1;
  assign qdr0_bw_n = 2'b11;
  assign qdr0_k_p = 1'b0;
  assign qdr0_k_n = 1'b1;

  /***************** QDR1 ************************/
  assign qdr1_d  = {18{1'b0}};
  assign qdr1_sa = {22{1'b0}};
  assign qdr1_w_n = 1'b1;
  assign qdr1_r_n = 1'b1;
  assign qdr1_dll_off_n = 1'b1;
  assign qdr1_bw_n = 2'b11;
  assign qdr1_k_p = 1'b0;
  assign qdr1_k_n = 1'b1;

  /*************** DDR SDRAM ********************/

  assign ddr2_dq = {72{1'bz}};
  assign ddr2_dm = 9'b0;
  assign ddr2_dqs_n = {9{1'bz}};
  assign ddr2_dqs_p = {9{1'bz}};
  assign ddr2_a = 16'b0;
  assign ddr2_ba = 3'b0;
  assign ddr2_ras_n = 1'b1;
  assign ddr2_cas_n = 1'b1; 
  assign ddr2_we_n  = 1'b1;
  assign ddr2_reset_n = 1'b0;
  assign ddr2_cke_0 = 1'b0;
  assign ddr2_cke_1 = 1'b0;
  assign ddr2_cs_n_0 = 1'b1;
  assign ddr2_cs_n_1 = 1'b1;
  assign ddr2_odt_0 = 1'b1;
  assign ddr2_odt_1 = 1'b1;
  assign ddr2_ck_0_n = 1'b0;
  assign ddr2_ck_0_p = 1'b1;
  assign ddr2_ck_1_n = 1'b0;
  assign ddr2_ck_1_p = 1'b1;
  assign ddr2_ck_2_n = 1'b0;
  assign ddr2_ck_2_p = 1'b1;
    
  assign ddr2_scl = 1'b0;
  assign ddr2_sda = 1'b0;
  assign ddr2_par_out = 1'b0;




endmodule