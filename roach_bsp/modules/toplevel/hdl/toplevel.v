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
    mgt_rx_top_1_n, mgt_tx_top_1_p,
    mgt_rx_top_0_n, mgt_tx_top_0_p,
    mgt_rx_bottom_1_n, mgt_tx_bottom_1_p,
    mgt_rx_bottom_0_n, mgt_tx_bottom_0_p
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

  input  [3:0] mgt_rx_top_1_n;
  output [3:0] mgt_tx_top_1_p;
  input  [3:0] mgt_rx_top_0_n;
  output [3:0] mgt_tx_top_0_p;
  input  [3:0] mgt_rx_bottom_1_n;
  output [3:0] mgt_tx_bottom_1_p;
  input  [3:0] mgt_rx_bottom_0_n;
  output [3:0] mgt_tx_bottom_0_p;

  /**************** Global Infrastructure ****************/

  wire sys_clk, dly_clk, aux_clk_0, aux_clk_1;

  infrastructure infrastructure_inst(
    .sys_clk_n(sys_clk_n), .sys_clk_p(sys_clk_p),
    .sys_clk(sys_clk),
    .dly_clk_n(dly_clk_n), .dly_clk_p(dly_clk_p),
    .dly_clk(dly_clk),
    .aux_clk0_n(aux_clk0_n), .aux_clk0_p(aux_clk0_p),
    .aux_clk_0(aux_clk_0),
    .aux_clk1_n(aux_clk1_n), .aux_clk1_p(aux_clk1_p),
    .aux_clk_1(aux_clk_1)
  );

  /********************* Reset Block *********************/
  wire sys_reset;
  wire soft_reset;

  reset_block #(
    .DELAY(100),
    .WIDTH(10)
  ) reset_block_inst(
    .clk(sys_clk), .async_reset_i(1'b0),
    .reset_i(soft_reset), .reset_o(sys_reset)
  );

  /**************** Serial Communications ****************/
  wire serial_in, serial_out;

  assign se_gpio_a_oen_n = 1'b0;
  assign se_gpio_b_oen_n = 1'b1;

  assign serial_in  = se_gpio_b[0];
  assign serial_out = se_gpio_a[0];

  wire [7:0] as_data_i;
  wire [7:0] as_data_o;
  wire as_dstrb_i, as_busy_o, as_dstrb_o;

  serial_uart #(
    .BAUD(115200),
    .CLOCK_RATE(40000000)
  ) serial_uart_inst (
    .clk(sys_clk), .reset(reset),
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
    .wbm_cyc_i({wbm_cyc_o_1, wbm_cyc_o_0}), .wbm_stb_i({wbm_stb_o_1, wbm_stb_o_0}), .wbm_we_i({wbm_sel_o_1, wbm_sel_o_0}),
    .wbm_adr_i({wbm_adr_o_1, wbm_adr_o_0}), .wbm_dat_i({wbm_dat_o_1, wbm_dat_o_0}), .wbm_dat_o({wbm_dat_i_1, wbm_dat_i_0}),
    .wbm_ack_o({wbm_ack_i_1, wbm_ack_i_0}), .wbm_err_o({wbm_err_i_1, wbm_err_i_0}),
    .wbs_cyc_o(wbi_cyc_o), .wbs_stb_o(wbi_stb_o), .wbs_we_o(wbi_we_o),
    .wbs_adr_o(wbi_adr_o), .wbs_dat_o(wbi_dat_o), .wbs_dat_i(wbi_dat_i),
    .wbs_ack_i(wbi_ack_i), .wbs_err_i(wbi_err_i),
    .wbm_mask(2'b11), //both enabled
    .wbm_id(wbm_id)
  );

  localparam NUM_SLAVES = 14;

  localparam SLAVE_ADDR = {32'h000d_0000, 32'h000c_0000, 32'h000b_0000, 32'h000a_0000 //slaves 13:10
                           32'h0009_0000, 32'h0008_0000, 32'h0007_0000, 32'h0006_0000 //slaves 9:6
                           32'h0005_0000, 32'h0004_0000, 32'h0003_0000, 32'h0002_0000 //slaves 5:2
                           32'h0001_0000, 32'h0000_0000};                             //slaves 1:0

  localparam SLAVE_HIGH = {32'h000d_ffff, 32'h000c_ffff, 32'h000b_ffff, 32'h000a_ffff //slaves 13:10
                           32'h0009_ffff, 32'h0008_ffff, 32'h0007_ffff, 32'h0006_ffff //slaves 9:6
                           32'h0005_ffff, 32'h0004_ffff, 32'h0003_ffff, 32'h0002_ffff //slaves 5:2
                           32'h0001_ffff, 32'h0000_ffff};                             //slaves 1:0

  wire [NUM_SLAVES - 1:0] wbs_cyc_o;
  wire [NUM_SLAVES - 1:0] wbs_stb_o;

  wire wbs_we_o;
  wire  [1:0] wbs_sel_o;
  wire [31:0] wbs_adr_o;
  wire [15:0] wbs_dat_o;

  wire [16*NUM_SLAVES - 1:0] wbs_dat_i;
  wire    [NUM_SLAVES - 1:0] wbs_ack_i;

  wbs_arbiter #(
    .NUM_SLAVES(NUM_SLAVES),
    .SLAVE_ADDR(SLAVE_ADDR),
    .SLAVE_HIGH(SLAVE_HIGH),
    .TIMEOUT(1000)
  ) wbs_arbiter_inst (
    .wb_clk_i(sys_clk), .wb_rst_i(sys_reset),
    .wbm_cyc_i(wbi_cyc_o), .wbm_stb_i(wbi_stb_o), .wbm_we_i(wbi_we_o),
    .wbm_adr_i(wbi_adr_o), .wbm_dat_i(wbi_dat_o), .wbm_dat_o(wbi_dat_i),
    .wbm_ack_o(wbi_ack_i), .wbm_err_o(wbi_err_i),
    .wbs_cyc_o(wbs_cyc_o), .wbs_stb_o(wbs_stb_o), .wbs_we_o(wbs_we_o),
    .wbs_adr_o(wbs_adr_o), .wbs_dat_o(wbs_dat_o), .wbs_dat_i(wbs_dat_i),
    .wbs_ack_i(wbs_ack_i)
  );

  /******************* System Module *****************/

  sys_block #(
    .BOARD_ID(`BOARD_ID),
    .REV_MAJOR(`REV_MAJOR),
    .REV_MINOR(`REV_MINOR),
    .REV_RCS(`REV_RCS)
  ) sys_block_inst (
    .wb_clk_i(sys_clk), .wb_rst_i(sys_reset),
    .wb_cyc_i(wb_cyc_i[0]), .wb_stb_i(wb_stb_i[0]),
    .wb_we_i(wb_we_i), .wb_sel_i(wb_sel_i),
    .wb_adr_i(wb_adr_i), .wb_dat_i(wb_dat_i),
    .wb_dat_o(wb_dat_o[16*(0 + 1) - 1: 16*0]),
    .wb_ack_o(wb_ack_o[0]),
    .wb_toutsup_o() 
  );

endmodule
