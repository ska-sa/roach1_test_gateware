`include "build_parameters.v"
`include "parameters.v"
`include "mem_layout.v"

module toplevel(
    // System signals
    sys_clk_n, sys_clk_p,
    dly_clk_n, dly_clk_p,
    aux_clk0_n, aux_clk0_p,
    aux_clk1_n, aux_clk1_p,
    led_n,
    // PPC External Peripheral Bus [EPB]
    ppc_irq,
    epb_clk_buf,
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
  input  epb_clk_buf;
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

  wire sys_clk, dly_clk, epb_clk, mgt_clk, aux_clk_0, aux_clk_1;
  wire adc0_clk_0, adc1_clk_0;

  // Ensure that the above nets are not synthesized away
  // synthesis attribute KEEP of sys_clk    is TRUE
  // synthesis attribute KEEP of mgt_clk    is TRUE
  // synthesis attribute KEEP of epb_clk    is TRUE
  // synthesis attribute KEEP of adc0_clk_0 is TRUE
  // synthesis attribute KEEP of adc1_clk_0 is TRUE

  wire sys_reset;
  wire soft_reset;

  wire clk_lock;

  /**************** Global Infrastructure ****************/

  wire idelay_ready;

  infrastructure infrastructure_inst(
    .sys_clk_n(sys_clk_n), .sys_clk_p(sys_clk_p),
    .sys_clk(sys_clk),
    .dly_clk_n(dly_clk_n), .dly_clk_p(dly_clk_p),
    .dly_clk(dly_clk),
    .epb_clk_buf(epb_clk_buf),
    .epb_clk(epb_clk),
    .idelay_rst(sys_reset), .idelay_rdy(idelay_ready),
    .aux_clk0_n(aux_clk0_n), .aux_clk0_p(aux_clk0_p),
    .aux_clk_0(aux_clk_0),
    .aux_clk1_n(aux_clk1_n), .aux_clk1_p(aux_clk1_p),
    .aux_clk_1(aux_clk_1)
  );

  /******************** Reset Block *********************/

  reset_block #(
    .DELAY(100),
    .WIDTH(32'h100)
  ) reset_block_inst(
    .clk(sys_clk), .async_reset_i(1'b0),
    .reset_i(1'b0), .reset_o(sys_reset)
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
  wire [15:0] wbm_dat_i;
  wire wbm_ack_i_0, wbm_err_i_0;

  as_wb_bridge as_wb_bridge_inst (
    .clk(sys_clk), .reset(sys_reset),
    .as_data_i(as_data_o), .as_data_o(as_data_i),
    .as_dstrb_o(as_dstrb_i), .as_busy_i(as_busy_o), .as_dstrb_i(as_dstrb_o),
    .wb_stb_o(wbm_stb_o_0), .wb_cyc_o(wbm_cyc_o_0),
    .wb_we_o(wbm_we_o_0), .wb_sel_o(wbm_sel_o_0),
    .wb_adr_o(wbm_adr_o_0), .wb_dat_o(wbm_dat_o_0), .wb_dat_i(wbm_dat_i),
    .wb_ack_i(wbm_ack_i_0), .wb_err_i(wbm_err_i_0),
    .soft_reset(soft_reset)
  );

  /******* PPC Master ********/
  assign ppc_irq = 1'b0;
  
  wire epb_cs_n_dly, epb_r_w_n_dly, epb_oe_n_dly;
  wire  [1:0] epb_be_n_dly;
  wire [22:0] epb_addr_dly;
  wire  [5:0] epb_addr_gp_dly;

  wire [15:0] epb_data_i;
  wire [15:0] epb_data_o;

  wire epb_data_oen;

  epb_infrastructure epb_infrastructure_inst(
    .epb_data_buf(epb_data),
    .epb_data_out_i(epb_data_o), .epb_data_in_o(epb_data_i),
    .epb_data_oe_n_i(epb_data_oen ? epb_oe_n_dly : 1'b1),
    .epb_oe_n_buf(epb_oe_n), .epb_oe_n(epb_oe_n_dly),
    .epb_cs_n_buf(epb_cs_n), .epb_cs_n(epb_cs_n_dly),
    .epb_r_w_n_buf(epb_r_w_n), .epb_r_w_n(epb_r_w_n_dly), 
    .epb_be_n_buf(epb_be_n), .epb_be_n(epb_be_n_dly),
    .epb_addr_buf(epb_addr), .epb_addr(epb_addr_dly),
    .epb_addr_gp_buf(epb_addr_gp), .epb_addr_gp(epb_addr_gp_dly)
  );

  wire wbm_stb_o_1, wbm_cyc_o_1, wbm_we_o_1;
  wire  [1:0] wbm_sel_o_1;
  wire [31:0] wbm_adr_o_1;
  wire [15:0] wbm_dat_o_1;
  wire wbm_ack_i_1, wbm_err_i_1;

`ifdef EPB_DIRECT_CLOCKING

  epb_wb_bridge epb_wb_bridge_inst(
    .wb_clk_i(sys_clk), .wb_rst_i(sys_reset),
    .wb_stb_o(wbm_stb_o_1), .wb_cyc_o(wbm_cyc_o_1),
    .wb_we_o(wbm_we_o_1), .wb_sel_o(wbm_sel_o_1),
    .wb_adr_o(wbm_adr_o_1), .wb_dat_o(wbm_dat_o_1), .wb_dat_i(wbm_dat_i),
    .wb_ack_i(wbm_ack_i_1), .wb_err_i(wbm_err_i_1),

    .epb_clk(epb_clk),
    .epb_data_oen(epb_data_oen),
    .epb_cs_n(epb_cs_n_dly), .epb_r_w_n(epb_r_w_n_dly),
    .epb_be_n(epb_be_n_dly), 
    .epb_addr(epb_addr_dly), .epb_addr_gp(epb_addr_gp_dly),
    .epb_data_i(epb_data_i), .epb_data_o(epb_data_o),
    .epb_rdy(epb_rdy)
  );

`else

  epb_wb_bridge_reg epb_wb_bridge_reg_inst(
    .wb_clk_i(sys_clk), .wb_rst_i(sys_reset),
    .wb_stb_o(wbm_stb_o_1), .wb_cyc_o(wbm_cyc_o_1),
    .wb_we_o(wbm_we_o_1), .wb_sel_o(wbm_sel_o_1),
    .wb_adr_o(wbm_adr_o_1), .wb_dat_o(wbm_dat_o_1), .wb_dat_i(wbm_dat_i),
    .wb_ack_i(wbm_ack_i_1), .wb_err_i(wbm_err_i_1),

    .epb_clk(epb_clk),
    .epb_data_oen(epb_data_oen),
    .epb_cs_n(epb_cs_n_dly), .epb_r_w_n(epb_r_w_n_dly),
    .epb_be_n(epb_be_n_dly), 
    .epb_addr(epb_addr_dly), .epb_addr_gp(epb_addr_gp_dly),
    .epb_data_i(epb_data_i), .epb_data_o(epb_data_o),
    .epb_rdy(epb_rdy)
  );

`endif
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
    .wbm_adr_i({wbm_adr_o_1, wbm_adr_o_0}), .wbm_dat_i({wbm_dat_o_1, wbm_dat_o_0}), .wbm_dat_o(wbm_dat_i),
    .wbm_ack_o({wbm_ack_i_1, wbm_ack_i_0}), .wbm_err_o({wbm_err_i_1, wbm_err_i_0}),
    .wbs_cyc_o(wbi_cyc_o), .wbs_stb_o(wbi_stb_o), .wbs_we_o(wbi_we_o), .wbs_sel_o(wbi_sel_o),
    .wbs_adr_o(wbi_adr_o), .wbs_dat_o(wbi_dat_o), .wbs_dat_i(wbi_dat_i),
    .wbs_ack_i(wbi_ack_i), .wbs_err_i(wbi_err_i),
   // .wbm_mask(2'b01), 
    .wbm_mask(2'b11), 
    .wbm_id(wbm_id_nc)
  );

  localparam NUM_SLAVES = 18;
  
  // Slave Indexes [SLI]
  localparam DRAM_SLI      = 17;
  localparam QDR1_SLI      = 16;
  localparam QDR0_SLI      = 15;
  localparam BLOCKRAMS_SLI = 14;
  localparam REGISTERS_SLI = 13;
  localparam TESTING_SLI   = 12;
  localparam TGE3_SLI      = 11;
  localparam TGE2_SLI      = 10;
  localparam TGE1_SLI      =  9;
  localparam TGE0_SLI      =  8;
  localparam RSRVD1_SLI    =  7;
  localparam RSRVD0_SLI    =  6;
  localparam DRAMCONF_SLI  =  5;
  localparam QDR1CONF_SLI  =  4;
  localparam QDR0CONF_SLI  =  3;
  localparam ADC1_SLI      =  2;
  localparam ADC0_SLI      =  1;
  localparam SYSBLOCK_SLI  =  0;

  localparam SLAVE_ADDR = {
                          `DRAM_A_BASE     ,
                          `QDR1_A_BASE     ,
                          `QDR0_A_BASE     ,
                          `BLOCKRAMS_A_BASE,
                          `REGISTERS_A_BASE,
                          `TESTING_A_BASE  ,
                          `TGE3_A_BASE     ,
                          `TGE2_A_BASE     ,
                          `TGE1_A_BASE     ,
                          `TGE0_A_BASE     ,
                          `RSRVD1_A_BASE   ,
                          `RSRVD0_A_BASE   ,
                          `DRAMCONF_A_BASE ,
                          `QDR1CONF_A_BASE ,
                          `QDR0CONF_A_BASE ,
                          `ADC1_A_BASE     ,
                          `ADC0_A_BASE     ,
                          `SYSBLOCK_A_BASE  
                          };

  localparam SLAVE_HIGH = {
                          `DRAM_A_HIGH     ,
                          `QDR1_A_HIGH     ,
                          `QDR0_A_HIGH     ,
                          `BLOCKRAMS_A_HIGH,
                          `REGISTERS_A_HIGH,
                          `TESTING_A_HIGH  ,
                          `TGE3_A_HIGH     ,
                          `TGE2_A_HIGH     ,
                          `TGE1_A_HIGH     ,
                          `TGE0_A_HIGH     ,
                          `RSRVD1_A_HIGH   ,
                          `RSRVD0_A_HIGH   ,
                          `DRAMCONF_A_HIGH ,
                          `QDR1CONF_A_HIGH ,
                          `QDR0CONF_A_HIGH ,
                          `ADC1_A_HIGH     ,
                          `ADC0_A_HIGH     ,
                          `SYSBLOCK_A_HIGH  
                          };


  wire [NUM_SLAVES - 1:0] wb_cyc_o;
  wire [NUM_SLAVES - 1:0] wb_stb_o;
  wire wb_we_o;
  wire  [1:0] wb_sel_o;
  wire [31:0] wb_adr_o;
  wire [15:0] wb_dat_o;
  wire [16*NUM_SLAVES - 1:0] wb_dat_i;
  wire    [NUM_SLAVES - 1:0] wb_ack_i;

  wbs_arbiter #(
    .NUM_SLAVES (NUM_SLAVES),
    .SLAVE_ADDR (SLAVE_ADDR),
    .SLAVE_HIGH (SLAVE_HIGH),
    .TIMEOUT    (1000) //10us @ 100MHz
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
    .BOARD_ID (`BOARD_ID),
    .REV_MAJOR(`REV_MAJOR),
    .REV_MINOR(`REV_MINOR),
    .REV_RCS  (`REV_RCS)
  ) sys_block_inst (
    .wb_clk_i(sys_clk), .wb_rst_i(sys_reset),
    .wb_cyc_i(wb_cyc_o[SYSBLOCK_SLI]), .wb_stb_i(wb_stb_o[SYSBLOCK_SLI]),
    .wb_we_i(wb_we_o), .wb_sel_i(wb_sel_o),
    .wb_adr_i(wb_adr_o), .wb_dat_i(wb_dat_o),
    .wb_dat_o(wb_dat_i[16*(SYSBLOCK_SLI + 1) - 1: 16*SYSBLOCK_SLI]),
    .wb_ack_o(wb_ack_i[SYSBLOCK_SLI]),
    .aux_clk({aux_clk_1, aux_clk_0})
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
    .DIFF_BOOST("FALSE")
    //.DIFF_BOOST(`MGT_DIFF_BOOST)
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
    .mgt_rxbufferr(mgt_rxbufferr[0]),
    .mgt_loopback(mgt_loopback[0]), .mgt_powerdown(mgt_powerdown[0]),
    .mgt_tx_reset(mgt_tx_reset[0]), .mgt_rx_reset(mgt_rx_reset[0]),

    .wb_clk_i(sys_clk), .wb_rst_i(sys_reset),
    .wb_cyc_i(wb_cyc_o[TGE0_SLI]), .wb_stb_i(wb_stb_o[TGE0_SLI]),
    .wb_we_i(wb_we_o), .wb_sel_i(wb_sel_o),
    .wb_adr_i(wb_adr_o), .wb_dat_i(wb_dat_o),
    .wb_dat_o(wb_dat_i[16*(TGE0_SLI + 1) - 1: 16*TGE0_SLI]),
    .wb_ack_o(wb_ack_i[TGE0_SLI])
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
    .DEFAULT_LOOPBACK(1'b0),
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
    .wb_cyc_i(wb_cyc_o[TGE0_SLI]), .wb_stb_i(wb_stb_o[TGE0_SLI]),
    .wb_we_i(wb_we_o), .wb_sel_i(wb_sel_o),
    .wb_adr_i(wb_adr_o), .wb_dat_i(wb_dat_o),
    .wb_dat_o(wb_dat_i[16*(TGE0_SLI + 1) - 1: 16*TGE0_SLI]),
    .wb_ack_o(wb_ack_i[TGE0_SLI]),
    .leds() //rx, tx, linkup
    ,.debug(debug)
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

  assign wb_ack_i[TGE0_SLI] = 1'b0;
  assign wb_dat_i[16*(TGE0_SLI + 1) - 1: 16*TGE0_SLI] = 16'b0;
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
    .mgt_rxbufferr(mgt_rxbufferr[1]),
    .mgt_loopback(mgt_loopback[1]), .mgt_powerdown(mgt_powerdown[1]),
    .mgt_tx_reset(mgt_tx_reset[1]), .mgt_rx_reset(mgt_rx_reset[1]),

    .wb_clk_i(sys_clk), .wb_rst_i(sys_reset),
    .wb_cyc_i(wb_cyc_o[TGE1_SLI]), .wb_stb_i(wb_stb_o[TGE1_SLI]),
    .wb_we_i(wb_we_o), .wb_sel_i(wb_sel_o),
    .wb_adr_i(wb_adr_o), .wb_dat_i(wb_dat_o),
    .wb_dat_o(wb_dat_i[16*(TGE1_SLI + 1) - 1: 16*TGE1_SLI]),
    .wb_ack_o(wb_ack_i[TGE1_SLI])
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
    .DEFAULT_LOOPBACK(1'b0),
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
    .wb_cyc_i(wb_cyc_o[TGE1_SLI]), .wb_stb_i(wb_stb_o[TGE1_SLI]),
    .wb_we_i(wb_we_o), .wb_sel_i(wb_sel_o),
    .wb_adr_i(wb_adr_o), .wb_dat_i(wb_dat_o),
    .wb_dat_o(wb_dat_i[16*(TGE1_SLI + 1) - 1: 16*TGE1_SLI]),
    .wb_ack_o(wb_ack_i[TGE1_SLI]),
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

  assign wb_ack_i[TGE1_SLI] = 1'b0;
  assign wb_dat_i[16*(TGE1_SLI + 1) - 1: 16*TGE1_SLI] = 16'b0;
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
    .mgt_rxbufferr(mgt_rxbufferr[2]),
    .mgt_loopback(mgt_loopback[2]), .mgt_powerdown(mgt_powerdown[2]),
    .mgt_tx_reset(mgt_tx_reset[2]), .mgt_rx_reset(mgt_rx_reset[2]),

    .wb_clk_i(sys_clk), .wb_rst_i(sys_reset),
    .wb_cyc_i(wb_cyc_o[TGE2_SLI]), .wb_stb_i(wb_stb_o[TGE2_SLI]),
    .wb_we_i(wb_we_o), .wb_sel_i(wb_sel_o),
    .wb_adr_i(wb_adr_o), .wb_dat_i(wb_dat_o),
    .wb_dat_o(wb_dat_i[16*(TGE2_SLI + 1) - 1: 16*TGE2_SLI]),
    .wb_ack_o(wb_ack_i[TGE2_SLI])
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
    .DEFAULT_LOOPBACK(1'b0),
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
    .wb_cyc_i(wb_cyc_o[TGE2_SLI]), .wb_stb_i(wb_stb_o[TGE2_SLI]),
    .wb_we_i(wb_we_o), .wb_sel_i(wb_sel_o),
    .wb_adr_i(wb_adr_o), .wb_dat_i(wb_dat_o),
    .wb_dat_o(wb_dat_i[16*(TGE2_SLI + 1) - 1: 16*TGE2_SLI]),
    .wb_ack_o(wb_ack_i[TGE2_SLI]),
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

  assign wb_ack_i[TGE2_SLI] = 1'b0;
  assign wb_dat_i[16*(TGE2_SLI + 1) - 1: 16*TGE2_SLI] = 16'b0;
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
    .wb_cyc_i(wb_cyc_o[TGE3_SLI]), .wb_stb_i(wb_stb_o[TGE3_SLI]),
    .wb_we_i(wb_we_o), .wb_sel_i(wb_sel_o),
    .wb_adr_i(wb_adr_o), .wb_dat_i(wb_dat_o),
    .wb_dat_o(wb_dat_i[16*(TGE3_SLI + 1) - 1: 16*TGE3_SLI]),
    .wb_ack_o(wb_ack_i[TGE3_SLI])
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
    .DEFAULT_LOOPBACK(1'b0),
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
    .wb_cyc_i(wb_cyc_o[TGE3_SLI]), .wb_stb_i(wb_stb_o[TGE3_SLI]),
    .wb_we_i(wb_we_o), .wb_sel_i(wb_sel_o),
    .wb_adr_i(wb_adr_o), .wb_dat_i(wb_dat_o),
    .wb_dat_o(wb_dat_i[16*(TGE3_SLI + 1) - 1: 16*TGE3_SLI]),
    .wb_ack_o(wb_ack_i[TGE3_SLI]),
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

  assign wb_ack_i[TGE3_SLI] = 1'b0;
  assign wb_dat_i[16*(TGE3_SLI + 1) - 1: 16*TGE3_SLI] = 16'b0;
`endif
`endif

  /*********** DDR2 Memory Controller ***************/

  // synthesis attribute KEEP of ddr_clk_0  is TRUE
  // synthesis attribute KEEP of ddr_clk_90 is TRUE
  wire ddr_clk_0, ddr_clk_90, ddr_clk_div;

`ifdef ENABLE_DDR2

  wire ddr_rst_0, ddr_rst_90, ddr_rst_div;
  wire ddr_usr_rst;

  ddr2_infrastructure #(
    .CLK_FREQ(`DDR2_CLK_FREQ)
  ) ddr2_infrastructure_inst (
    .reset(sys_reset | ~idelay_ready),
    .clk_in(sys_clk),
    .ddr_clk_0(ddr_clk_0), .ddr_clk_90(ddr_clk_90), .ddr_clk_div(ddr_clk_div),
    .ddr_rst_0(ddr_rst_0), .ddr_rst_90(ddr_rst_90), .ddr_rst_div(ddr_rst_div),
    .usr_clk(sys_clk), .usr_rst(ddr_usr_rst)
  );

  wire  [2:0] ddr_af_cmd;
  wire [30:0] ddr_af_addr;
  wire ddr_af_wren;
  wire ddr_af_afull;
  wire [143:0] ddr_df_data;
  wire  [17:0] ddr_df_mask;
  wire ddr_df_wren;
  wire ddr_df_afull;
  wire [143:0] ddr_rd_data;
  wire ddr_rd_dvalid;

  wire ddr_phy_ready;
  wire ddr_usr_clk;
  
  localparam DDR_PERIOD = `DDR2_CLK_FREQ == 150 ? 6666 :
                          `DDR2_CLK_FREQ == 200 ? 5000 :
                          `DDR2_CLK_FREQ == 333 ? 3003 :
                          `DDR2_CLK_FREQ == 266 ? 3759 :
                                                  3759;
  ddr2_controller #(
    .CLK_PERIOD(DDR_PERIOD)
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
    .phy_init_done(ddr_phy_ready),
    
    .ddr2_ck  ({ddr2_ck_2_p, ddr2_ck_1_p, ddr2_ck_0_p}),
    .ddr2_ck_n({ddr2_ck_2_n, ddr2_ck_1_n, ddr2_ck_0_n}),
    .ddr2_a(ddr2_a),
    .ddr2_ba(ddr2_ba),
    .ddr2_ras_n(ddr2_ras_n),
    .ddr2_cas_n(ddr2_cas_n),
    .ddr2_we_n(ddr2_we_n),
    .ddr2_cs_n({ddr2_cs_n_1, ddr2_cs_n_0}),
    .ddr2_cke({ddr2_cke_1, ddr2_cke_0}),
    .ddr2_odt({ddr2_odt_1, ddr2_odt_0}),
    .ddr2_dm(ddr2_dm),
    .ddr2_dqs(ddr2_dqs_p),
    .ddr2_dqs_n(ddr2_dqs_n),
    .ddr2_dq(ddr2_dq)
  );

  assign ddr2_par_out = ddr2_par_in;
  assign ddr2_reset_n = 1'b0;

  assign ddr2_scl = 1'b1;
  assign ddr2_sda = 1'b1;

  wire ddr_arb;

  ddr2_cpu_interface #(
    .SOFT_ADDR_BITS(8)
  ) ddr2_cpu_interface_inst (
    .ddr_clk_0(ddr_clk_0), .ddr_clk_90(ddr_clk_90),
    //memory wb slave IF
    .wb_clk_i(sys_clk), .wb_rst_i(sys_reset),

    .reg_wb_we_i(wb_we_o),
    .reg_wb_cyc_i(wb_cyc_o[DRAMCONF_SLI]), .reg_wb_stb_i(wb_stb_o[DRAMCONF_SLI]),
    .reg_wb_sel_i(wb_sel_o),
    .reg_wb_adr_i(wb_adr_o), .reg_wb_dat_i(wb_dat_o),
    .reg_wb_dat_o(wb_dat_i[16*(DRAMCONF_SLI + 1) - 1: 16*DRAMCONF_SLI]),
    .reg_wb_ack_o(wb_ack_i[DRAMCONF_SLI]),
    //memory wb slave IF
    .mem_wb_we_i(wb_we_o),
    .mem_wb_cyc_i(wb_cyc_o[DRAM_SLI]), .mem_wb_stb_i(wb_stb_o[DRAM_SLI]),
    .mem_wb_sel_i(wb_sel_o),
    .mem_wb_adr_i(wb_adr_o), .mem_wb_dat_i(wb_dat_o),
    .mem_wb_dat_o(wb_dat_i[16*(DRAM_SLI + 1) - 1: 16*DRAM_SLI]),
    .mem_wb_ack_o(wb_ack_i[DRAM_SLI]),
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
`else
  assign ddr2_dq = {72{1'bz}};
  assign ddr2_dm = 9'b0;
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

  assign ddr2_par_out = ddr2_par_in;

  assign ddr2_scl = 1'b1;
  assign ddr2_sda = 1'b1;

  IOBUFDS iobufds_dqs[8:0](
    .IO(ddr2_dqs_p),
    .IOB(ddr2_dqs_n),
    .O(), .I({9{1'b1}}), .T(1'b1)
  );

  OBUFDS obufds_inst[2:0](
    .O( {ddr2_ck_2_p, ddr2_ck_1_p, ddr2_ck_0_p}),
    .OB({ddr2_ck_2_n, ddr2_ck_1_n, ddr2_ck_0_n}),
    .I(3'b0)
  );

  assign wb_dat_i[16*(DRAMCONF_SLI + 1) - 1: 16*DRAMCONF_SLI] = 16'b0;
  assign wb_ack_i[DRAMCONF_SLI] = 1'b0;
  assign wb_dat_i[16*(DRAM_SLI + 1) - 1: 16*DRAM_SLI] = 16'b0;
  assign wb_ack_i[DRAM_SLI] = 1'b0;
  
`endif

  /***************** QDR0 ************************/

`ifdef ENABLE_QDR_INFRASTRUCTURE
  wire qdr_clk_0, qdr_clk_180, qdr_clk_270;
  wire qdr_pll_lock;
  qdr_infrastructure #(
    .CLK_FREQ(`QDR_CLK_FREQ)
  ) qdr_infrastructure_inst (
    .clk_in(sys_clk), .reset(sys_reset),
    .qdr_clk_0(qdr_clk_0), .qdr_clk_180(qdr_clk_180), .qdr_clk_270(qdr_clk_270),
    .pll_lock(qdr_pll_lock)
  );
`endif

`ifdef ENABLE_QDR0
  wire qdr0_cal_done;
  wire qdr0_usr_reset;

  wire qdr0_usr_ad_w_n;
  wire qdr0_usr_d_w_n;
  wire qdr0_usr_r_n;
  wire qdr0_usr_wr_full;
  wire qdr0_usr_rd_full;
  wire qdr0_usr_qr_valid;
  wire [17:0] qdr0_usr_dwl;
  wire [17:0] qdr0_usr_dwh;
  wire [17:0] qdr0_usr_qrl;
  wire [17:0] qdr0_usr_qrh;
  wire  [1:0] qdr0_usr_bwl_n;
  wire  [1:0] qdr0_usr_bwh_n;
  wire [21:0] qdr0_usr_ad_wr;
  wire [21:0] qdr0_usr_ad_rd;


  wire [3:0] foo_debug;
  qdr_controller #(
    .CLK_FREQ(`QDR_CLK_FREQ)
  ) qdr_controller_0 (
    .reset(sys_reset | qdr0_usr_reset),
    .clk0(qdr_clk_0), .clk180(qdr_clk_180), .clk270(qdr_clk_270),
    .pll_lock(qdr_pll_lock),
    .idelay_rdy(idelay_ready),

    .qdr_d(qdr0_d),
    .qdr_q(qdr0_q),
    .qdr_sa(qdr0_sa),
    .qdr_w_n(qdr0_w_n),
    .qdr_r_n(qdr0_r_n),
    .qdr_dll_off_n(qdr0_dll_off_n),
    .qdr_bw_n(qdr0_bw_n),
    .qdr_cq(qdr0_cq_p),
    .qdr_cq_n(qdr0_cq_n),
    .qdr_k(qdr0_k_p),
    .qdr_k_n(qdr0_k_n),

    .cal_done(qdr0_cal_done),

    .user_ad_w_n(qdr0_usr_ad_w_n), .user_d_w_n(qdr0_usr_d_w_n),
    .user_r_n(qdr0_usr_r_n),
    .user_wr_full(qdr0_usr_wr_full),
    .user_rd_full(qdr0_usr_rd_full),
    .user_qr_valid(qdr0_usr_qr_valid),
    .user_dwl(qdr0_usr_dwl),
    .user_dwh(qdr0_usr_dwh),
    .user_qrl(qdr0_usr_qrl),
    .user_qrh(qdr0_usr_qrh),
    .user_bwl_n(qdr0_usr_bwl_n),
    .user_bwh_n(qdr0_usr_bwh_n),
    .user_ad_wr(qdr0_usr_ad_wr),
    .user_ad_rd(qdr0_usr_ad_rd)
    ,.debug(foo_debug)
  );
  
  wire qdr0_usr_d_w;
  wire qdr0_usr_ad_w;
  wire qdr0_usr_r;
  assign qdr0_usr_d_w_n  = !qdr0_usr_d_w;
  assign qdr0_usr_ad_w_n = !qdr0_usr_ad_w;
  assign qdr0_usr_r_n    = !qdr0_usr_r;

  qdr_cpu_interface qdr_cpu_interface_inst_0(
    .wb_clk_i(sys_clk), .wb_rst_i(sys_reset),
    //register wb slave IF
    .reg_wb_we_i(wb_we_o),
    .reg_wb_cyc_i(wb_cyc_o[QDR0CONF_SLI]), .reg_wb_stb_i(wb_stb_o[QDR0CONF_SLI]),
    .reg_wb_sel_i(wb_sel_o),
    .reg_wb_adr_i(wb_adr_o), .reg_wb_dat_i(wb_dat_o),
    .reg_wb_dat_o(wb_dat_i[16*(QDR0CONF_SLI + 1) - 1: 16*QDR0CONF_SLI]),
    .reg_wb_ack_o(wb_ack_i[QDR0CONF_SLI]),
    //memory wb slave IF
    .mem_wb_we_i(wb_we_o),
    .mem_wb_cyc_i(wb_cyc_o[QDR0_SLI]), .mem_wb_stb_i(wb_stb_o[QDR0_SLI]),
    .mem_wb_sel_i(wb_sel_o),
    .mem_wb_adr_i(wb_adr_o), .mem_wb_dat_i(wb_dat_o),
    .mem_wb_dat_o(wb_dat_i[16*(QDR0_SLI + 1) - 1: 16*QDR0_SLI]),
    .mem_wb_ack_o(wb_ack_i[QDR0_SLI]),
    .mem_wb_burst(1'b0),
    //qdr interface

    .qdr_clk_i(qdr_clk_0),
    .qdr_rst_o(qdr0_usr_reset),
    .qdr_phy_rdy(qdr0_cal_done),

    .qdr_wr_full(qdr0_usr_wr_full), 
    .qdr_rd_full(qdr0_usr_rd_full),

    .qdr_wr_addr(qdr0_usr_ad_wr),
    .qdr_wr_data({qdr0_usr_dwh, qdr0_usr_dwl}),
    .qdr_wr_be({qdr0_usr_bwh_n, qdr0_usr_bwl_n}),
    .qdr_wr_data_en(qdr0_usr_d_w),
    .qdr_wr_addr_en(qdr0_usr_ad_w),

    .qdr_rd_addr(qdr0_usr_ad_rd),
    .qdr_rd_data({qdr0_usr_qrh, qdr0_usr_qrl}),
    .qdr_rd_valid(qdr0_usr_qr_valid),
    .qdr_rd_en(qdr0_usr_r)
    ,.debug(foo_debug)
  );

`else
  assign qdr0_d  = {18{1'b0}};
  assign qdr0_sa = {22{1'b0}};
  assign qdr0_w_n = 1'b1;
  assign qdr0_r_n = 1'b1;
  assign qdr0_dll_off_n = 1'b1;
  assign qdr0_bw_n = 2'b11;
  assign qdr0_k_p = 1'b0;
  assign qdr0_k_n = 1'b1;

  assign wb_dat_i[16*(QDR0CONF_SLI + 1) - 1: 16*QDR0CONF_SLI] = 16'b0;
  assign wb_ack_i[QDR0CONF_SLI] = 1'b0;
  assign wb_dat_i[16*(QDR0_SLI + 1) - 1: 16*QDR0_SLI] = 16'b0;
  assign wb_ack_i[QDR0_SLI] = 1'b0;
`endif

  /***************** QDR1 ************************/
`ifdef ENABLE_QDR1
  wire qdr1_cal_done;
  wire qdr1_usr_reset;

  wire qdr1_usr_ad_w_n;
  wire qdr1_usr_d_w_n;
  wire qdr1_usr_r_n;
  wire qdr1_usr_wr_full;
  wire qdr1_usr_rd_full;
  wire qdr1_usr_qr_valid;
  wire [17:0] qdr1_usr_dwl;
  wire [17:0] qdr1_usr_dwh;
  wire [17:0] qdr1_usr_qrl;
  wire [17:0] qdr1_usr_qrh;
  wire  [1:0] qdr1_usr_bwl_n;
  wire  [1:0] qdr1_usr_bwh_n;
  wire [21:0] qdr1_usr_ad_wr;
  wire [21:0] qdr1_usr_ad_rd;

  qdr_controller #(
    .CLK_FREQ(`QDR_CLK_FREQ)
  ) qdr_controller_1(
    .reset(sys_reset | qdr1_usr_reset),
    .clk0(qdr_clk_0), .clk180(qdr_clk_180), .clk270(qdr_clk_270),
    .pll_lock(qdr_pll_lock),
    .idelay_rdy(idelay_ready),

    .qdr_d(qdr1_d),
    .qdr_q(qdr1_q),
    .qdr_sa(qdr1_sa),
    .qdr_w_n(qdr1_w_n),
    .qdr_r_n(qdr1_r_n),
    .qdr_dll_off_n(qdr1_dll_off_n),
    .qdr_bw_n(qdr1_bw_n),
    .qdr_cq(qdr1_cq_p),
    .qdr_cq_n(qdr1_cq_n),
    .qdr_k(qdr1_k_p),
    .qdr_k_n(qdr1_k_n),

    .cal_done(qdr1_cal_done),

    .user_ad_w_n(qdr1_usr_ad_w_n), .user_d_w_n(qdr1_usr_d_w_n),
    .user_r_n(qdr1_usr_r_n),
    .user_wr_full(qdr1_usr_wr_full),
    .user_rd_full(qdr1_usr_rd_full),
    .user_qr_valid(qdr1_usr_qr_valid),
    .user_dwl(qdr1_usr_dwl),
    .user_dwh(qdr1_usr_dwh),
    .user_qrl(qdr1_usr_qrl),
    .user_qrh(qdr1_usr_qrh),
    .user_bwl_n(qdr1_usr_bwl_n),
    .user_bwh_n(qdr1_usr_bwh_n),
    .user_ad_wr(qdr1_usr_ad_wr),
    .user_ad_rd(qdr1_usr_ad_rd)
  );

  wire qdr1_usr_d_w;
  wire qdr1_usr_ad_w;
  wire qdr1_usr_r;
  assign qdr1_usr_d_w_n  = !qdr1_usr_d_w;
  assign qdr1_usr_ad_w_n = !qdr1_usr_ad_w;
  assign qdr1_usr_r_n    = !qdr1_usr_r;

  qdr_cpu_interface qdr_cpu_interface_inst_1(
    .wb_clk_i(sys_clk), .wb_rst_i(sys_reset),
    //memory wb slave IF
    .reg_wb_we_i(wb_we_o),
    .reg_wb_cyc_i(wb_cyc_o[QDR1CONF_SLI]), .reg_wb_stb_i(wb_stb_o[QDR1CONF_SLI]),
    .reg_wb_sel_i(wb_sel_o),
    .reg_wb_adr_i(wb_adr_o), .reg_wb_dat_i(wb_dat_o),
    .reg_wb_dat_o(wb_dat_i[16*(QDR1CONF_SLI + 1) - 1: 16*QDR1CONF_SLI]),
    .reg_wb_ack_o(wb_ack_i[QDR1CONF_SLI]),
    //memory wb slave IF
    .mem_wb_we_i(wb_we_o),
    .mem_wb_cyc_i(wb_cyc_o[QDR1_SLI]), .mem_wb_stb_i(wb_stb_o[QDR1_SLI]),
    .mem_wb_sel_i(wb_sel_o),
    .mem_wb_adr_i(wb_adr_o), .mem_wb_dat_i(wb_dat_o),
    .mem_wb_dat_o(wb_dat_i[16*(QDR1_SLI + 1) - 1: 16*QDR1_SLI]),
    .mem_wb_ack_o(wb_ack_i[QDR1_SLI]),
    .mem_wb_burst(1'b0),
    //qdr interface

    .qdr_clk_i(qdr_clk_0),
    .qdr_rst_o(qdr1_usr_reset),
    .qdr_phy_rdy(qdr1_cal_done),

    .qdr_wr_full(qdr1_usr_wr_full), 
    .qdr_rd_full(qdr1_usr_rd_full),

    .qdr_wr_addr(qdr1_usr_ad_wr),
    .qdr_wr_data({qdr1_usr_dwh, qdr1_usr_dwl}),
    .qdr_wr_be({qdr1_usr_bwh_n, qdr1_usr_bwl_n}),
    .qdr_wr_data_en(qdr1_usr_d_w),
    .qdr_wr_addr_en(qdr1_usr_ad_w),

    .qdr_rd_addr(qdr1_usr_ad_rd),
    .qdr_rd_data({qdr1_usr_qrh, qdr1_usr_qrl}),
    .qdr_rd_valid(qdr1_usr_qr_valid),
    .qdr_rd_en(qdr1_usr_r)
  );

`else

  assign qdr1_d  = {18{1'b0}};
  assign qdr1_sa = {22{1'b0}};
  assign qdr1_w_n = 1'b1;
  assign qdr1_r_n = 1'b1;
  assign qdr1_dll_off_n = 1'b1;
  assign qdr1_bw_n = 2'b11;
  assign qdr1_k_p = 1'b0;
  assign qdr1_k_n = 1'b1;

  assign wb_dat_i[16*(QDR1CONF_SLI + 1) - 1: 16*QDR1CONF_SLI] = 16'b0;
  assign wb_ack_i[QDR1CONF_SLI] = 1'b0;
  assign wb_dat_i[16*(QDR1_SLI + 1) - 1: 16*QDR1_SLI] = 16'b0;
  assign wb_ack_i[QDR1_SLI] = 1'b0;
`endif

  /********** Boot Memory ************/
  
  /* 4KB data memory */

  bram_controller #(
    .RAM_SIZE_K(4)
  ) bram_controller_bootrom (
    .wb_clk_i(sys_clk), .wb_rst_i(sys_reset),
    .wb_cyc_i(wb_cyc_o[BLOCKRAMS_SLI]), .wb_stb_i(wb_stb_o[BLOCKRAMS_SLI]),
    .wb_we_i(wb_we_o), .wb_sel_i(wb_sel_o),
    .wb_adr_i(wb_adr_o), .wb_dat_i(wb_dat_o),
    .wb_dat_o(wb_dat_i[16*(BLOCKRAMS_SLI + 1) - 1: 16*BLOCKRAMS_SLI]),
    .wb_ack_o(wb_ack_i[BLOCKRAMS_SLI])
  );

  /****************** ZDOKs **********************/

`ifdef ENABLE_IADC_0
  /****** ADC external signals ******/
  wire adc0_clk_n, adc0_clk_p;
  wire adc0_sync_n, adc0_sync_p;
  wire adc0_outofrange_i_n, adc0_outofrange_i_p, adc0_outofrange_q_n, adc0_outofrange_q_p;
  wire [7:0] adc0_data_i_even_n;
  wire [7:0] adc0_data_i_even_p;
  wire [7:0] adc0_data_i_odd_n;
  wire [7:0] adc0_data_i_odd_p;
  wire [7:0] adc0_data_q_even_n;
  wire [7:0] adc0_data_q_even_p;
  wire [7:0] adc0_data_q_odd_n;
  wire [7:0] adc0_data_q_odd_p;
  wire adc0_ddrb_n, adc0_ddrb_p;
  wire adc0_ctrl_clk, adc0_ctrl_data, adc0_ctrl_strobe_n, adc0_mode;

  /* Assign ZDOK signals */
  assign adc0_clk_n = zdok0_clk1_n;
  assign adc0_clk_p = zdok0_clk1_p;
 // zdok0_clk0_n and zdok0_clk0_p unassigned

  assign zdok0_dp_n[8]       = adc0_ctrl_clk;
  assign zdok0_dp_n[9]       = adc0_ctrl_data;
  assign zdok0_dp_p[9]       = adc0_ctrl_strobe_n;
  assign zdok0_dp_p[8]       = adc0_mode;
  assign adc0_outofrange_i_n = zdok0_dp_n[28];
  assign adc0_outofrange_i_p = zdok0_dp_p[28];
  assign adc0_outofrange_q_n = zdok0_dp_n[18];
  assign adc0_outofrange_q_p = zdok0_dp_p[18];
  assign zdok0_dp_n[19]      = adc0_ddrb_n;
  assign zdok0_dp_p[19]      = adc0_ddrb_p;
  assign adc0_sync_n         = zdok0_dp_n[37];
  assign adc0_sync_p         = zdok0_dp_p[37];

  assign adc0_data_i_even_n  = {zdok0_dp_n[36], zdok0_dp_n[34], zdok0_dp_n[32], zdok0_dp_n[30],
                                zdok0_dp_n[27], zdok0_dp_n[25], zdok0_dp_n[23], zdok0_dp_n[21]};
  assign adc0_data_i_even_p  = {zdok0_dp_p[36], zdok0_dp_p[34], zdok0_dp_p[32], zdok0_dp_p[30],
                                zdok0_dp_p[27], zdok0_dp_p[25], zdok0_dp_p[23], zdok0_dp_p[21]};

  assign adc0_data_i_odd_n   = {zdok0_dp_n[35], zdok0_dp_n[33], zdok0_dp_n[31], zdok0_dp_n[29],
                                zdok0_dp_n[26], zdok0_dp_n[24], zdok0_dp_n[22], zdok0_dp_n[20]};
  assign adc0_data_i_odd_p   = {zdok0_dp_p[35], zdok0_dp_p[33], zdok0_dp_p[31], zdok0_dp_p[29],
                                zdok0_dp_p[26], zdok0_dp_p[24], zdok0_dp_p[22], zdok0_dp_p[20]};

  assign adc0_data_q_even_n  = {zdok0_dp_n[10], zdok0_dp_n[12], zdok0_dp_n[14], zdok0_dp_n[16],
                                zdok0_dp_n[0],  zdok0_dp_n[2],  zdok0_dp_n[4],  zdok0_dp_n[6]};
  assign adc0_data_q_even_p  = {zdok0_dp_p[10], zdok0_dp_p[12], zdok0_dp_p[14], zdok0_dp_p[16],
                                zdok0_dp_p[0],  zdok0_dp_p[2],  zdok0_dp_p[4],  zdok0_dp_p[6]};

  assign adc0_data_q_odd_n   = {zdok0_dp_n[11], zdok0_dp_n[13], zdok0_dp_n[15], zdok0_dp_n[17],
                                zdok0_dp_n[1],  zdok0_dp_n[3],  zdok0_dp_n[5],  zdok0_dp_n[7]};
  assign adc0_data_q_odd_p   = {zdok0_dp_p[11], zdok0_dp_p[13], zdok0_dp_p[15], zdok0_dp_p[17],
                                zdok0_dp_p[1],  zdok0_dp_p[3],  zdok0_dp_p[5],  zdok0_dp_p[7]};

  /****** ADC internal signals ******/
  wire adc0_clk_0, adc0_clk_90;
  wire adc0_sync;
  wire  [3:0] adc0_outofrange;
  wire [63:0] adc0_data;
  wire adc0_ddrb;

  wire adc0_ctrl_clk_int, adc0_ctrl_data_int, adc0_ctrl_strobe_n_int, adc0_mode_int;

  iadc_infrastructure iadc_infrastructure_inst_0(
    .reset(sys_reset),
    .clk_lock(adc0_clk_lock),
    .adc_clk_n(adc0_clk_n),
    .adc_clk_p(adc0_clk_p),
    .adc_sync_n(adc0_sync_n),
    .adc_sync_p(adc0_sync_p),
    .adc_outofrange_i_n(adc0_outofrange_i_n),
    .adc_outofrange_i_p(adc0_outofrange_i_p),
    .adc_outofrange_q_n(adc0_outofrange_q_n),
    .adc_outofrange_q_p(adc0_outofrange_q_p),
    .adc_data_i_even_n(adc0_data_i_even_n),
    .adc_data_i_even_p(adc0_data_i_even_p),
    .adc_data_i_odd_n(adc0_data_i_odd_n),
    .adc_data_i_odd_p(adc0_data_i_odd_p),
    .adc_data_q_even_n(adc0_data_q_even_n),
    .adc_data_q_even_p(adc0_data_q_even_p),
    .adc_data_q_odd_n(adc0_data_q_odd_n),
    .adc_data_q_odd_p(adc0_data_q_odd_p),
    .adc_ddrb_n(adc0_ddrb_n),
    .adc_ddrb_p(adc0_ddrb_p),
    .adc_clk_0(adc0_clk_0),
    .adc_clk_90(adc0_clk_90),
    .adc_sync(adc0_sync),
    .adc_outofrange(adc0_outofrange),
    .adc_data(adc0_data),
    .adc_ddrb(adc0_ddrb),
    .adc_ctrl_clk_buf(adc0_ctrl_clk),
    .adc_ctrl_data_buf(adc0_ctrl_data),
    .adc_ctrl_strobe_n_buf(adc0_ctrl_strobe_n),
    .adc_mode_buf(adc0_mode),
    .adc_ctrl_clk(adc0_ctrl_clk_int),
    .adc_ctrl_data(adc0_ctrl_data_int),
    .adc_ctrl_strobe_n(adc0_ctrl_strobe_n_int),
    .adc_mode(adc0_mode_int)
  );

  iadc_controller iadc_controller_inst_0(
    /* Wishbone Interface */
    .wb_clk_i(sys_clk),
    .wb_rst_i(sys_reset),
    .wb_cyc_i(wb_cyc_o[ADC0_SLI]), .wb_stb_i(wb_stb_o[ADC0_SLI]),
    .wb_we_i(wb_we_o), .wb_sel_i(wb_sel_o),
    .wb_adr_i(wb_adr_o), .wb_dat_i(wb_dat_o),
    .wb_dat_o(wb_dat_i[16*(ADC0_SLI + 1) - 1: 16*ADC0_SLI]),
    .wb_ack_o(wb_ack_i[ADC0_SLI]),
    /* ADC inputs */
    .adc_clk_0(adc0_clk_0), .adc_clk_90(adc0_clk_90),
    .adc_data(adc0_data),
    .adc_sync(adc0_sync),
    .adc_outofrange(adc0_outofrange),

    /* ADC config bits */
    .adc_ctrl_clk(adc0_ctrl_clk_int),
    .adc_ctrl_data(adc0_ctrl_data_int),
    .adc_ctrl_strobe_n(adc0_ctrl_strobe_n_int),
    .adc_mode(adc0_mode_int),
    .adc_ddrb(adc0_ddrb)
  );

`else
  assign zdok0_dp_n = {38{1'bz}};
  assign zdok0_dp_p = {38{1'bz}};
  assign wb_dat_i[16*(ADC0_SLI + 1) - 1: 16*ADC0_SLI] = 16'b0;
  assign wb_ack_i[ADC0_SLI] = 1'b0;
`endif


`ifdef ENABLE_IADC_1
  /****** ADC external signals ******/
  wire adc1_clk_n, adc1_clk_p;
  wire adc1_sync_n, adc1_sync_p;
  wire adc1_outofrange_i_n, adc1_outofrange_i_p, adc1_outofrange_q_n, adc1_outofrange_q_p;
  wire [7:0] adc1_data_i_even_n;
  wire [7:0] adc1_data_i_even_p;
  wire [7:0] adc1_data_i_odd_n;
  wire [7:0] adc1_data_i_odd_p;
  wire [7:0] adc1_data_q_even_n;
  wire [7:0] adc1_data_q_even_p;
  wire [7:0] adc1_data_q_odd_n;
  wire [7:0] adc1_data_q_odd_p;
  wire adc1_ddrb_n, adc1_ddrb_p;
  wire adc1_ctrl_clk, adc1_ctrl_data, adc1_ctrl_strobe_n, adc1_mode;

  /* Assign ZDOK signals */
  assign adc1_clk_n = zdok1_clk1_n;
  assign adc1_clk_p = zdok1_clk1_p;
 // zdok1_clk0_n and zdok1_clk0_p unassigned

  assign zdok1_dp_n[8]       = adc1_ctrl_clk;
  assign zdok1_dp_n[9]       = adc1_ctrl_data;
  assign zdok1_dp_p[9]       = adc1_ctrl_strobe_n;
  assign zdok1_dp_p[8]       = adc1_mode;
  assign adc1_outofrange_i_n = zdok1_dp_n[28];
  assign adc1_outofrange_i_p = zdok1_dp_p[28];
  assign adc1_outofrange_q_n = zdok1_dp_n[18];
  assign adc1_outofrange_q_p = zdok1_dp_p[18];
  assign zdok1_dp_n[19]      = adc1_ddrb_n;
  assign zdok1_dp_p[19]      = adc1_ddrb_p;
  assign adc1_sync_n         = zdok1_dp_n[37];
  assign adc1_sync_p         = zdok1_dp_p[37];

  assign adc1_data_i_even_n  = {zdok1_dp_n[36], zdok1_dp_n[34], zdok1_dp_n[32], zdok1_dp_n[30],
                                zdok1_dp_n[27], zdok1_dp_n[25], zdok1_dp_n[23], zdok1_dp_n[21]};
  assign adc1_data_i_even_p  = {zdok1_dp_p[36], zdok1_dp_p[34], zdok1_dp_p[32], zdok1_dp_p[30],
                                zdok1_dp_p[27], zdok1_dp_p[25], zdok1_dp_p[23], zdok1_dp_p[21]};

  assign adc1_data_i_odd_n   = {zdok1_dp_n[35], zdok1_dp_n[33], zdok1_dp_n[31], zdok1_dp_n[29],
                                zdok1_dp_n[26], zdok1_dp_n[24], zdok1_dp_n[22], zdok1_dp_n[20]};
  assign adc1_data_i_odd_p   = {zdok1_dp_p[35], zdok1_dp_p[33], zdok1_dp_p[31], zdok1_dp_p[29],
                                zdok1_dp_p[26], zdok1_dp_p[24], zdok1_dp_p[22], zdok1_dp_p[20]};

  assign adc1_data_q_even_n  = {zdok1_dp_n[10], zdok1_dp_n[12], zdok1_dp_n[14], zdok1_dp_n[16],
                                zdok1_dp_n[0],  zdok1_dp_n[2],  zdok1_dp_n[4],  zdok1_dp_n[6]};
  assign adc1_data_q_even_p  = {zdok1_dp_p[10], zdok1_dp_p[12], zdok1_dp_p[14], zdok1_dp_p[16],
                                zdok1_dp_p[0],  zdok1_dp_p[2],  zdok1_dp_p[4],  zdok1_dp_p[6]};

  assign adc1_data_q_odd_n   = {zdok1_dp_n[11], zdok1_dp_n[13], zdok1_dp_n[15], zdok1_dp_n[17],
                                zdok1_dp_n[1],  zdok1_dp_n[3],  zdok1_dp_n[5],  zdok1_dp_n[7]};
  assign adc1_data_q_odd_p   = {zdok1_dp_p[11], zdok1_dp_p[13], zdok1_dp_p[15], zdok1_dp_p[17],
                                zdok1_dp_p[1],  zdok1_dp_p[3],  zdok1_dp_p[5],  zdok1_dp_p[7]};

  /****** ADC internal signals ******/
  wire adc1_clk_0, adc1_clk_90;
  wire adc1_sync;
  wire  [3:0] adc1_outofrange;
  wire [63:0] adc1_data;
  wire adc1_ddrb;

  wire adc1_ctrl_clk_int, adc1_ctrl_data_int, adc1_ctrl_strobe_n_int, adc1_mode_int;

  iadc_infrastructure iadc_infrastructure_inst_1(
    .reset(sys_reset),
    .clk_lock(adc1_clk_lock),
    .adc_clk_n(adc1_clk_n),
    .adc_clk_p(adc1_clk_p),
    .adc_sync_n(adc1_sync_n),
    .adc_sync_p(adc1_sync_p),
    .adc_outofrange_i_n(adc1_outofrange_i_n),
    .adc_outofrange_i_p(adc1_outofrange_i_p),
    .adc_outofrange_q_n(adc1_outofrange_q_n),
    .adc_outofrange_q_p(adc1_outofrange_q_p),
    .adc_data_i_even_n(adc1_data_i_even_n),
    .adc_data_i_even_p(adc1_data_i_even_p),
    .adc_data_i_odd_n(adc1_data_i_odd_n),
    .adc_data_i_odd_p(adc1_data_i_odd_p),
    .adc_data_q_even_n(adc1_data_q_even_n),
    .adc_data_q_even_p(adc1_data_q_even_p),
    .adc_data_q_odd_n(adc1_data_q_odd_n),
    .adc_data_q_odd_p(adc1_data_q_odd_p),
    .adc_ddrb_n(adc1_ddrb_n),
    .adc_ddrb_p(adc1_ddrb_p),
    .adc_clk_0(adc1_clk_0),
    .adc_clk_90(adc1_clk_90),
    .adc_sync(adc1_sync),
    .adc_outofrange(adc1_outofrange),
    .adc_data(adc1_data),
    .adc_ddrb(adc1_ddrb),
    .adc_ctrl_clk_buf(adc1_ctrl_clk),
    .adc_ctrl_data_buf(adc1_ctrl_data),
    .adc_ctrl_strobe_n_buf(adc1_ctrl_strobe_n),
    .adc_mode_buf(adc1_mode),
    .adc_ctrl_clk(adc1_ctrl_clk_int),
    .adc_ctrl_data(adc1_ctrl_data_int),
    .adc_ctrl_strobe_n(adc1_ctrl_strobe_n_int),
    .adc_mode(adc1_mode_int)
  );

  iadc_controller iadc_controller_inst_1(
    /* Wishbone Interface */
    .wb_clk_i(sys_clk),
    .wb_rst_i(sys_reset),
    .wb_cyc_i(wb_cyc_o[ADC1_SLI]), .wb_stb_i(wb_stb_o[ADC1_SLI]),
    .wb_we_i(wb_we_o), .wb_sel_i(wb_sel_o),
    .wb_adr_i(wb_adr_o), .wb_dat_i(wb_dat_o),
    .wb_dat_o(wb_dat_i[16*(ADC1_SLI + 1) - 1: 16*ADC1_SLI]),
    .wb_ack_o(wb_ack_i[ADC1_SLI]),
    /* ADC inputs */
    .adc_clk_0(adc1_clk_0), .adc_clk_90(adc1_clk_90),
    .adc_data(adc1_data),
    .adc_sync(adc1_sync),
    .adc_outofrange(adc1_outofrange),

    /* ADC config bits */
    .adc_ctrl_clk(adc1_ctrl_clk_int),
    .adc_ctrl_data(adc1_ctrl_data_int),
    .adc_ctrl_strobe_n(adc1_ctrl_strobe_n_int),
    .adc_mode(adc1_mode_int),
    .adc_ddrb(adc1_ddrb)
  );

`else

  assign zdok1_dp_n = {38{1'bz}};
  assign zdok1_dp_p = {38{1'bz}};

  assign wb_dat_i[16*(ADC1_SLI + 1) - 1: 16*ADC1_SLI] = 16'b0;
  assign wb_ack_i[ADC1_SLI] = 1'b0;

`endif

  /* Other Slave assignments */

  /******************* Testing ***********************/

  assign wb_dat_i[16*(TESTING_SLI + 1) - 1: 16*TESTING_SLI] = 16'b0;
  assign wb_ack_i[TESTING_SLI] = 1'b0;

  /********************* Incomplete *****************/


  assign wb_dat_i[16*(REGISTERS_SLI + 1) - 1: 16*REGISTERS_SLI] = 16'b0;
  assign wb_ack_i[REGISTERS_SLI] = 1'b0;

  assign wb_dat_i[16*(RSRVD1_SLI + 1) - 1: 16*RSRVD1_SLI] = 16'b0;
  assign wb_ack_i[RSRVD1_SLI] = 1'b0;

  assign wb_dat_i[16*(RSRVD0_SLI + 1) - 1: 16*RSRVD0_SLI] = 16'b0;
  assign wb_ack_i[RSRVD0_SLI] = 1'b0;


  /******************* GPIO ***********************/

  /******** Single Ended **********/
  assign se_gpio_a_oen_n = 1'b1;
  assign se_gpio_b_oen_n = 1'b0;

  assign se_gpio_b[0] = 1'b0;
  assign se_gpio_b[1] = 1'b0;
  assign se_gpio_b[2] = 1'b0;
  assign se_gpio_b[3] = serial_out;
  assign se_gpio_b[4] = 1'b0;
  assign se_gpio_b[5] = 1'b0;
  assign se_gpio_b[6] = 1'b0;
  assign se_gpio_b[7] = 1'b0;

  assign se_gpio_a[2:0] = {3{1'bz}};
  assign serial_in      = se_gpio_a[3];
  assign se_gpio_a[7:4] = {4{1'bz}};

  /******** Differential **********/
  assign diff_gpio_a_n = {19{1'bz}};
  assign diff_gpio_a_p = {19{1'bz}};
  assign diff_gpio_a_clk_n = 1'bz;
  assign diff_gpio_a_clk_p = 1'bz;
  assign diff_gpio_b_n = {19{1'bz}};
  assign diff_gpio_b_p = {19{1'bz}};
  assign diff_gpio_b_clk_n = 1'bz;
  assign diff_gpio_b_clk_p = 1'bz;

  /************************* LEDs ************************/

  reg [27:0] counter [2:0];
  
  assign led_n = ~{1'b1, counter[0][27], counter[1][27], counter[2][27]};

  always @(posedge sys_clk) begin
    counter[0] <= counter[0] + 1;
  end

  always @(posedge adc0_clk_0) begin
    counter[1] <= counter[1] + 1;
  end

  always @(posedge adc1_clk_0) begin
    counter[2] <= counter[2] + 1;
  end

endmodule
