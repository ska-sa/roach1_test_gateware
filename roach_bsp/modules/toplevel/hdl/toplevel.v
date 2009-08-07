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
    ppc_irq_n,
    epb_clk_buf,
    epb_data,
    epb_addr, epb_addr_gp, 
    epb_cs_n, epb_cs_n_alt,
    epb_be_n, epb_r_w_n, epb_oe_n, epb_blast_n,
    epb_rdy,
    epb_cs_alt_n,
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
    // DRAM SDRAM
    dram_dq, dram_dm, dram_dqs_n, dram_dqs_p,
    dram_a, dram_ba,
    dram_ras_n, dram_cas_n, dram_we_n,
    dram_reset_n,
    dram_cke_0, dram_cke_1,
    dram_cs_n_0, dram_cs_n_1,
    dram_odt_0, dram_odt_1,
    dram_ck_0_n, dram_ck_0_p,
    dram_ck_1_n, dram_ck_1_p,
    dram_ck_2_n, dram_ck_2_p,
    dram_scl, dram_sda,
    dram_par_in, dram_par_out,
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

  output ppc_irq_n;
  input  epb_clk_buf;
  inout  [15:0] epb_data;
  input  [22:0] epb_addr;
  input   [5:0] epb_addr_gp;
  input  epb_cs_n, epb_cs_n_alt, epb_r_w_n, epb_oe_n, epb_blast_n;
  input   [1:0] epb_be_n;
  output epb_rdy;
  input  epb_cs_alt_n;
  
  inout  [37:0] zdok0_dp_n;
  inout  [37:0] zdok0_dp_p;
  inout  zdok0_clk0_n, zdok0_clk0_p;
  inout  zdok0_clk1_n, zdok0_clk1_p;
  inout  [37:0] zdok1_dp_n;
  inout  [37:0] zdok1_dp_p;
  inout  zdok1_clk0_n, zdok1_clk0_p;
  inout  zdok1_clk1_n, zdok1_clk1_p;

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
  
  inout  [71:0] dram_dq;
  output  [8:0] dram_dm;
  inout   [8:0] dram_dqs_n;
  inout   [8:0] dram_dqs_p;
  output [15:0] dram_a;
  output  [2:0] dram_ba;
  output dram_ras_n, dram_cas_n, dram_we_n, dram_reset_n;
  output dram_cke_0, dram_cke_1, dram_cs_n_0, dram_cs_n_1, dram_odt_0, dram_odt_1;
  output dram_ck_0_n, dram_ck_0_p, dram_ck_1_n, dram_ck_1_p, dram_ck_2_n, dram_ck_2_p;
    
  inout  dram_scl, dram_sda;
  input  dram_par_in;
  output dram_par_out;
  
  inout  [18:0] diff_gpio_a_n;
  inout  [18:0] diff_gpio_a_p;
  inout  diff_gpio_a_clk_p, diff_gpio_a_clk_n;
  inout  [18:0] diff_gpio_b_n;
  inout  [18:0] diff_gpio_b_p;
  inout  diff_gpio_b_clk_p, diff_gpio_b_clk_n;

  inout  [7:0] se_gpio_a;
  inout  se_gpio_a_oen_n;
  inout  [7:0] se_gpio_b;
  inout  se_gpio_b_oen_n;

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

  wire sys_clk, dly_clk, epb_clk, mgt_clk_0, mgt_clk_1, aux_clk_0, aux_clk_1;
  wire dram_clk;
  wire qdr_clk_0,  qdr_clk_1;  

  // Ensure that the above nets are not synthesized away
  // synthesis attribute KEEP of sys_clk    is TRUE
  // synthesis attribute KEEP of mgt_clk_0  is TRUE
  // synthesis attribute KEEP of mgt_clk_1  is TRUE
  // synthesis attribute KEEP of epb_clk    is TRUE

  /* global system reset on sys_clk domain */
  wire sys_reset;  
  /* signal from system block to used to issue software system reset */
  wire soft_reset; 
  /* Clock used for wishbone modules */
  wire wb_clk = sys_clk;

  /* L-E-D-s signals */
  wire [15:0] leddies;
  wire [15:0] app_irq;

  /**************** Global Infrastructure ****************/

  wire idelay_ready;

  infrastructure infrastructure_inst(
    .sys_clk_n (sys_clk_n),
    .sys_clk_p (sys_clk_p),
    .sys_clk   (sys_clk),

    .dly_clk_n (dly_clk_n),
    .dly_clk_p (dly_clk_p),
    .dly_clk   (dly_clk),

    .epb_clk_buf (epb_clk_buf),
    .epb_clk     (epb_clk),

    .aux_clk0_n (aux_clk0_n),
    .aux_clk0_p (aux_clk0_p),
    .aux_clk_0  (aux_clk_0),
    .aux_clk1_n (aux_clk1_n),
    .aux_clk1_p (aux_clk1_p),
    .aux_clk_1  (aux_clk_1),

    .idelay_rst (sys_reset),
    .idelay_rdy (idelay_ready)
  );

  /******************** Reset Block *********************/

  reset_block #(
    .DELAY (100),
    .WIDTH (32'h100)
  ) reset_block_inst(
    .clk           (sys_clk),
    .async_reset_i (1'b0),
    .reset_i       (1'b0),
    .reset_o       (sys_reset)
  );

  /**************** Serial Communications ****************/
  wire [7:0] as_data_i;
  wire [7:0] as_data_o;
  wire as_dstrb_i, as_busy_o, as_dstrb_o;

  serial_uart #(
    .BAUD       (`SERIAL_UART_BAUD),
    .CLOCK_RATE (`SYS_CLOCK_RATE)
  ) serial_uart_inst (
    .clk   (wb_clk),
    .reset (sys_reset),

    .serial_in  (1'b0),
    .serial_out (serial_out),

    .as_data_i (as_data_i),
    .as_data_o (as_data_o),

    .as_dstrb_i (as_dstrb_i),
    .as_busy_o  (as_busy_o),
    .as_dstrb_o (as_dstrb_o)
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
    .clk   (wb_clk),
    .reset (sys_reset),

    .as_data_i  (as_data_o),
    .as_data_o  (as_data_i),
    .as_dstrb_o (as_dstrb_i),
    .as_busy_i  (as_busy_o),
    .as_dstrb_i (as_dstrb_o),

    .wb_cyc_o (wbm_cyc_o_0),
    .wb_stb_o (wbm_stb_o_0),
    .wb_sel_o (wbm_sel_o_0),
    .wb_we_o  (wbm_we_o_0),
    .wb_adr_o (wbm_adr_o_0),
    .wb_dat_o (wbm_dat_o_0),
    .wb_dat_i (wbm_dat_i),
    .wb_ack_i (wbm_ack_i_0),
    .wb_err_i (wbm_err_i_0)
  );

  /******* PPC Master ********/
  wire epb_cs_n_dly, epb_r_w_n_dly, epb_oe_n_dly;
  wire  [1:0] epb_be_n_dly;
  wire [22:0] epb_addr_dly;
  wire  [5:0] epb_addr_gp_dly;

  wire [15:0] epb_data_i;
  wire [15:0] epb_data_o;

  wire epb_data_oe_n;

  /* The EPB infrastructure includes delay elements on the input
   * pins and bidirectional buffers for the data
   */

  epb_infrastructure epb_infrastructure_inst(
    .epb_data_buf    (epb_data),
    .epb_data_out_i  (epb_data_o),
    .epb_data_in_o   (epb_data_i),
    .epb_data_oe_n_i (epb_data_oe_n),
    .epb_oe_n_buf    (epb_oe_n),
    .epb_oe_n        (epb_oe_n_dly),
    .epb_cs_n_buf    (epb_cs_n),
    .epb_cs_n        (epb_cs_n_dly),
    .epb_r_w_n_buf   (epb_r_w_n),
    .epb_r_w_n       (epb_r_w_n_dly), 
    .epb_be_n_buf    (epb_be_n),
    .epb_be_n        (epb_be_n_dly),
    .epb_addr_buf    (epb_addr),
    .epb_addr        (epb_addr_dly),
    .epb_addr_gp_buf (epb_addr_gp),
    .epb_addr_gp     (epb_addr_gp_dly)
  );

  wire wbm_stb_o_1, wbm_cyc_o_1, wbm_we_o_1;
  wire  [1:0] wbm_sel_o_1;
  wire [31:0] wbm_adr_o_1;
  wire [15:0] wbm_dat_o_1;
  wire wbm_ack_i_1, wbm_err_i_1;

  epb_wb_bridge_reg epb_wb_bridge_reg_inst(
    .wb_clk_i (wb_clk),
    .wb_rst_i (sys_reset),

    .wb_cyc_o (wbm_cyc_o_1),
    .wb_stb_o (wbm_stb_o_1),
    .wb_sel_o (wbm_sel_o_1),
    .wb_we_o  (wbm_we_o_1),
    .wb_adr_o (wbm_adr_o_1),
    .wb_dat_o (wbm_dat_o_1),
    .wb_dat_i (wbm_dat_i),
    .wb_ack_i (wbm_ack_i_1),
    .wb_err_i (wbm_err_i_1),

    .epb_clk       (epb_clk),
    .epb_cs_n      (epb_cs_n_dly),
    .epb_oe_n      (epb_oe_n_dly),
    .epb_r_w_n     (epb_r_w_n_dly),
    .epb_be_n      (epb_be_n_dly), 
    .epb_addr      (epb_addr_dly),
    .epb_addr_gp   (epb_addr_gp_dly),
    .epb_data_i    (epb_data_i),
    .epb_data_o    (epb_data_o),
    .epb_data_oe_n (epb_data_oe_n),
    .epb_rdy       (epb_rdy)
  );

  /** WB Master Arbitration **/

  /* Intermediate wishbone signals */
  wire wbi_cyc_o, wbi_stb_o, wbi_we_o;
  wire  [1:0] wbi_sel_o;
  wire [31:0] wbi_adr_o;
  wire [15:0] wbi_dat_o;
  wire [15:0] wbi_dat_i;
  wire wbi_ack_i, wbi_err_i;

  wbm_arbiter #(
    .NUM_MASTERS (2)
  ) wbm_arbiter_inst (
    .wb_clk_i (wb_clk),
    .wb_rst_i (sys_reset),

    .wbm_cyc_i ({wbm_cyc_o_1, wbm_cyc_o_0}),
    .wbm_stb_i ({wbm_stb_o_1, wbm_stb_o_0}),
    .wbm_sel_i ({wbm_sel_o_1, wbm_sel_o_0}),
    .wbm_we_i  ({wbm_we_o_1,  wbm_we_o_0 }),
    .wbm_adr_i ({wbm_adr_o_1, wbm_adr_o_0}),
    .wbm_dat_i ({wbm_dat_o_1, wbm_dat_o_0}),
    .wbm_dat_o (wbm_dat_i),
    .wbm_ack_o ({wbm_ack_i_1, wbm_ack_i_0}),
    .wbm_err_o ({wbm_err_i_1, wbm_err_i_0}),

    .wbs_cyc_o (wbi_cyc_o),
    .wbs_stb_o (wbi_stb_o),
    .wbs_sel_o (wbi_sel_o),
    .wbs_we_o  (wbi_we_o),
    .wbs_adr_o (wbi_adr_o),
    .wbs_dat_o (wbi_dat_o),
    .wbs_dat_i (wbi_dat_i),
    .wbs_ack_i (wbi_ack_i),
    .wbs_err_i (wbi_err_i),
    .wbm_mask  (2'b11), 
    .wbm_id    ()
  );

  localparam NUM_SLAVES = 18;
  
  // Slave Indexes [SLI]
  localparam DRAM_SLI      = 17;
  localparam QDR1_SLI      = 16;
  localparam QDR0_SLI      = 15;
  localparam BLOCKRAM_SLI = 14;
  localparam APP_SLI       = 13;
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
                          `BLOCKRAM_A_BASE,
                          `APP_A_BASE,
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
                          `BLOCKRAM_A_HIGH,
                          `APP_A_HIGH,
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
    .wb_clk_i (wb_clk),
    .wb_rst_i (sys_reset),
    .wbm_cyc_i (wbi_cyc_o),
    .wbm_stb_i (wbi_stb_o),
    .wbm_sel_i (wbi_sel_o),
    .wbm_we_i  (wbi_we_o),
    .wbm_adr_i (wbi_adr_o),
    .wbm_dat_i (wbi_dat_o),
    .wbm_dat_o (wbi_dat_i),
    .wbm_ack_o (wbi_ack_i),
    .wbm_err_o (wbi_err_i),
    .wbs_cyc_o (wb_cyc_o),
    .wbs_stb_o (wb_stb_o),
    .wbs_sel_o (wb_sel_o),
    .wbs_we_o  (wb_we_o),
    .wbs_adr_o (wb_adr_o),
    .wbs_dat_o (wb_dat_o),
    .wbs_dat_i (wb_dat_i),
    .wbs_ack_i (wb_ack_i)
  );

  /******************* System Module *****************/
   
  sys_block #(
    .BOARD_ID     (`BOARD_ID),
    .REV_MAJOR    (`REV_MAJOR),
    .REV_MINOR    (`REV_MINOR),
    .REV_RCS      (`REV_RCS),
    .RCS_UPTODATE (`RCS_UPTODATE)
  ) sys_block_inst (
    .wb_clk_i   (wb_clk),
    .wb_rst_i   (sys_reset),
    .wb_cyc_i   (wb_cyc_o[SYSBLOCK_SLI]),
    .wb_stb_i   (wb_stb_o[SYSBLOCK_SLI]),
    .wb_sel_i   (wb_sel_o),
    .wb_we_i    (wb_we_o),
    .wb_adr_i   (wb_adr_o),
    .wb_dat_i   (wb_dat_o),
    .wb_dat_o   (wb_dat_i[16*(SYSBLOCK_SLI + 1) - 1: 16*SYSBLOCK_SLI]),
    .wb_ack_o   (wb_ack_i[SYSBLOCK_SLI]),
    .soft_reset (soft_reset),
    .irq_n      (ppc_irq_n),
    .app_irq    (app_irq)
  );

  /************* XAUI Infrastructure ***************/

  wire mgt_clk_lock_0;
  wire mgt_clk_lock_1;

  /* mgt phy signals */
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

    .mgt_clk_0(mgt_clk_0), .mgt_clk_lock_0(mgt_clk_lock_0),
    .mgt_clk_1(mgt_clk_1), .mgt_clk_lock_1(mgt_clk_lock_1),

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

  /**** Ten Gigabit Ethernet "Fabric" Interface signals ****/
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
  wire xaui_reset_0;
  wire  [7:0] xaui_status_0;
  wire [63:0] xaui_xgmii_txd_0;
  wire  [7:0] xaui_xgmii_txc_0;
  wire [63:0] xaui_xgmii_rxd_0;
  wire  [7:0] xaui_xgmii_rxc_0;

  xaui_phy xaui_phy_0(
    .clk   (mgt_clk_0), //check me
    .reset (sys_reset),
    /* mgt signals */
    .mgt_txdata       (mgt_txdata[0]),
    .mgt_txcharisk    (mgt_txcharisk[0]),
    .mgt_rxdata       (mgt_rxdata[0]),
    .mgt_rxcharisk    (mgt_rxcharisk[0]),
    .mgt_enable_align (mgt_enable_align[0]),
    .mgt_en_chan_sync (mgt_enchansync[0]), 
    .mgt_code_valid   (mgt_codevalid[0]),
    .mgt_rxbufferr    (mgt_rxbufferr[0]),
    .mgt_code_comma   (mgt_code_comma[0]),
    .mgt_rxlock       (mgt_rxlock[0]),
    .mgt_syncok       (mgt_syncok[0]),
    .mgt_loopback     (mgt_loopback[0]),
    .mgt_powerdown    (mgt_powerdown[0]),
    .mgt_tx_reset     (mgt_tx_reset[0]),
    .mgt_rx_reset     (mgt_rx_reset[0]),
    /* XAUI signals */
    .xgmii_txd   (xaui_xgmii_txd_0),
    .xgmii_txc   (xaui_xgmii_txc_0),
    .xgmii_rxd   (xaui_xgmii_rxd_0),
    .xgmii_rxc   (xaui_xgmii_rxc_0),
    .xaui_reset  (xaui_reset_0),
    .xaui_status (xaui_status_0)
  );

  ten_gb_eth ten_gb_eth_0 (
     /* "Fabric" interface signals */
    .clk             (tge_usr_clk[0]),
    .rst             (tge_usr_rst[0]),
    .tx_valid        (tge_tx_valid[0]),
    .tx_ack          (tge_tx_ack[0]),
    .tx_end_of_frame (tge_tx_end_of_frame[0]),
    .tx_discard      (tge_tx_discard[0]),
    .tx_data         (tge_tx_data[0]),
    .tx_dest_ip      (tge_tx_dest_ip[0]),
    .tx_dest_port    (tge_tx_dest_port[0]),
    .rx_valid        (tge_rx_valid[0]),
    .rx_ack          (tge_rx_ack[0]),
    .rx_data         (tge_rx_data[0]),
    .rx_end_of_frame (tge_rx_end_of_frame[0]),
    .rx_size         (tge_rx_size[0]),
    .rx_source_ip    (tge_rx_source_ip[0]),
    .rx_source_port  (tge_rx_source_port[0]),
    .led_up          (tge_led_up[0]),
    .led_rx          (tge_led_rx[0]),
    .led_tx          (tge_led_tx[0]),

     /* XAUI signals  */
    .xaui_clk    (mgt_clk_0),
    .xgmii_txd   (xaui_xgmii_txd_0),
    .xgmii_txc   (xaui_xgmii_txc_0),
    .xgmii_rxd   (xaui_xgmii_rxd_0),
    .xgmii_rxc   (xaui_xgmii_rxc_0),
    .xaui_reset  (xaui_reset_0),
    .xaui_status (xaui_status_0),

    /* MGT config signals */
    .mgt_rxeqmix       (mgt_rxeqmix[0]),
    .mgt_rxeqpole      (mgt_rxeqpole[0]),
    .mgt_txpreemphasis (mgt_txpreemphasis[0]),
    .mgt_txdiffctrl    (mgt_txdiffctrl[0]),

  
     /* Wishbone IF  */
    .wb_clk_i (wb_clk),
    .wb_rst_i (sys_reset),
    .wb_cyc_i (wb_cyc_o[TGE0_SLI]),
    .wb_stb_i (wb_stb_o[TGE0_SLI]),
    .wb_we_i  (wb_we_o),
    .wb_sel_i (wb_sel_o),
    .wb_adr_i (wb_adr_o),
    .wb_dat_i (wb_dat_o),
    .wb_dat_o (wb_dat_i[16*(TGE0_SLI + 1) - 1: 16*TGE0_SLI]),
    .wb_ack_o (wb_ack_i[TGE0_SLI])
  );

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

  /******************* XAUI/TGBE 1 **********************/

`ifdef ENABLE_TEN_GB_ETH_1
  wire xaui_reset_1;
  wire  [7:0] xaui_status_1;
  wire [63:0] xaui_xgmii_txd_1;
  wire  [7:0] xaui_xgmii_txc_1;
  wire [63:0] xaui_xgmii_rxd_1;
  wire  [7:0] xaui_xgmii_rxc_1;

  xaui_phy xaui_phy_1(
    .clk   (mgt_clk_0),
    .reset (sys_reset),
    /* mgt signals */
    .mgt_txdata       (mgt_txdata[1]),
    .mgt_txcharisk    (mgt_txcharisk[1]),
    .mgt_rxdata       (mgt_rxdata[1]),
    .mgt_rxcharisk    (mgt_rxcharisk[1]),
    .mgt_enable_align (mgt_enable_align[1]),
    .mgt_en_chan_sync (mgt_enchansync[1]), 
    .mgt_code_valid   (mgt_codevalid[1]),
    .mgt_rxbufferr    (mgt_rxbufferr[1]),
    .mgt_code_comma   (mgt_code_comma[1]),
    .mgt_rxlock       (mgt_rxlock[1]),
    .mgt_syncok       (mgt_syncok[1]),
    .mgt_loopback     (mgt_loopback[1]),
    .mgt_powerdown    (mgt_powerdown[1]),
    .mgt_tx_reset     (mgt_tx_reset[1]),
    .mgt_rx_reset     (mgt_rx_reset[1]),
    /* XAUI signals */
    .xgmii_txd   (xaui_xgmii_txd_1),
    .xgmii_txc   (xaui_xgmii_txc_1),
    .xgmii_rxd   (xaui_xgmii_rxd_1),
    .xgmii_rxc   (xaui_xgmii_rxc_1),
    .xaui_reset  (xaui_reset_1),
    .xaui_status (xaui_status_1)
  );

  ten_gb_eth ten_gb_eth_1 (
     /* "Fabric" interface signals */
    .clk             (tge_usr_clk[1]),
    .rst             (tge_usr_rst[1]),
    .tx_valid        (tge_tx_valid[1]),
    .tx_ack          (tge_tx_ack[1]),
    .tx_end_of_frame (tge_tx_end_of_frame[1]),
    .tx_discard      (tge_tx_discard[1]),
    .tx_data         (tge_tx_data[1]),
    .tx_dest_ip      (tge_tx_dest_ip[1]),
    .tx_dest_port    (tge_tx_dest_port[1]),
    .rx_valid        (tge_rx_valid[1]),
    .rx_ack          (tge_rx_ack[1]),
    .rx_data         (tge_rx_data[1]),
    .rx_end_of_frame (tge_rx_end_of_frame[1]),
    .rx_size         (tge_rx_size[1]),
    .rx_source_ip    (tge_rx_source_ip[1]),
    .rx_source_port  (tge_rx_source_port[1]),
    .led_up          (tge_led_up[1]),
    .led_rx          (tge_led_rx[1]),
    .led_tx          (tge_led_tx[1]),

     /* XAUI signals  */
    .xaui_clk    (mgt_clk_0),
    .xgmii_txd   (xaui_xgmii_txd_1),
    .xgmii_txc   (xaui_xgmii_txc_1),
    .xgmii_rxd   (xaui_xgmii_rxd_1),
    .xgmii_rxc   (xaui_xgmii_rxc_1),
    .xaui_reset  (xaui_reset_1),
    .xaui_status (xaui_status_1),

    /* MGT config signals */
    .mgt_rxeqmix       (mgt_rxeqmix[1]),
    .mgt_rxeqpole      (mgt_rxeqpole[1]),
    .mgt_txpreemphasis (mgt_txpreemphasis[1]),
    .mgt_txdiffctrl    (mgt_txdiffctrl[1]),

  
     /* Wishbone IF  */
    .wb_clk_i (wb_clk),
    .wb_rst_i (sys_reset),
    .wb_cyc_i (wb_cyc_o[TGE1_SLI]),
    .wb_stb_i (wb_stb_o[TGE1_SLI]),
    .wb_we_i  (wb_we_o),
    .wb_sel_i (wb_sel_o),
    .wb_adr_i (wb_adr_o),
    .wb_dat_i (wb_dat_o),
    .wb_dat_o (wb_dat_i[16*(TGE1_SLI + 1) - 1: 16*TGE1_SLI]),
    .wb_ack_o (wb_ack_i[TGE1_SLI])
  );

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

  /******************* XAUI/TGBE 2 **********************/

`ifdef ENABLE_TEN_GB_ETH_2
  wire xaui_reset_2;
  wire  [7:0] xaui_status_2;
  wire [63:0] xaui_xgmii_txd_2;
  wire  [7:0] xaui_xgmii_txc_2;
  wire [63:0] xaui_xgmii_rxd_2;
  wire  [7:0] xaui_xgmii_rxc_2;

  xaui_phy xaui_phy_2(
    .clk   (mgt_clk_1),
    .reset (sys_reset),
    /* mgt signals */
    .mgt_txdata       (mgt_txdata[2]),
    .mgt_txcharisk    (mgt_txcharisk[2]),
    .mgt_rxdata       (mgt_rxdata[2]),
    .mgt_rxcharisk    (mgt_rxcharisk[2]),
    .mgt_enable_align (mgt_enable_align[2]),
    .mgt_en_chan_sync (mgt_enchansync[2]), 
    .mgt_code_valid   (mgt_codevalid[2]),
    .mgt_rxbufferr    (mgt_rxbufferr[2]),
    .mgt_code_comma   (mgt_code_comma[2]),
    .mgt_rxlock       (mgt_rxlock[2]),
    .mgt_syncok       (mgt_syncok[2]),
    .mgt_loopback     (mgt_loopback[2]),
    .mgt_powerdown    (mgt_powerdown[2]),
    .mgt_tx_reset     (mgt_tx_reset[2]),
    .mgt_rx_reset     (mgt_rx_reset[2]),
    /* XAUI signals */
    .xgmii_txd   (xaui_xgmii_txd_2),
    .xgmii_txc   (xaui_xgmii_txc_2),
    .xgmii_rxd   (xaui_xgmii_rxd_2),
    .xgmii_rxc   (xaui_xgmii_rxc_2),
    .xaui_reset  (xaui_reset_2),
    .xaui_status (xaui_status_2)
  );

  ten_gb_eth ten_gb_eth_2 (
     /* "Fabric" interface signals */
    .clk             (tge_usr_clk[2]),
    .rst             (tge_usr_rst[2]),
    .tx_valid        (tge_tx_valid[2]),
    .tx_ack          (tge_tx_ack[2]),
    .tx_end_of_frame (tge_tx_end_of_frame[2]),
    .tx_discard      (tge_tx_discard[2]),
    .tx_data         (tge_tx_data[2]),
    .tx_dest_ip      (tge_tx_dest_ip[2]),
    .tx_dest_port    (tge_tx_dest_port[2]),
    .rx_valid        (tge_rx_valid[2]),
    .rx_ack          (tge_rx_ack[2]),
    .rx_data         (tge_rx_data[2]),
    .rx_end_of_frame (tge_rx_end_of_frame[2]),
    .rx_size         (tge_rx_size[2]),
    .rx_source_ip    (tge_rx_source_ip[2]),
    .rx_source_port  (tge_rx_source_port[2]),
    .led_up          (tge_led_up[2]),
    .led_rx          (tge_led_rx[2]),
    .led_tx          (tge_led_tx[2]),

     /* XAUI signals  */
    .xaui_clk    (mgt_clk_1),
    .xgmii_txd   (xaui_xgmii_txd_2),
    .xgmii_txc   (xaui_xgmii_txc_2),
    .xgmii_rxd   (xaui_xgmii_rxd_2),
    .xgmii_rxc   (xaui_xgmii_rxc_2),
    .xaui_reset  (xaui_reset_2),
    .xaui_status (xaui_status_2),

    /* MGT config signals */
    .mgt_rxeqmix       (mgt_rxeqmix[2]),
    .mgt_rxeqpole      (mgt_rxeqpole[2]),
    .mgt_txpreemphasis (mgt_txpreemphasis[2]),
    .mgt_txdiffctrl    (mgt_txdiffctrl[2]),
  
     /* Wishbone IF  */
    .wb_clk_i (wb_clk),
    .wb_rst_i (sys_reset),
    .wb_cyc_i (wb_cyc_o[TGE2_SLI]),
    .wb_stb_i (wb_stb_o[TGE2_SLI]),
    .wb_we_i  (wb_we_o),
    .wb_sel_i (wb_sel_o),
    .wb_adr_i (wb_adr_o),
    .wb_dat_i (wb_dat_o),
    .wb_dat_o (wb_dat_i[16*(TGE2_SLI + 1) - 1: 16*TGE2_SLI]),
    .wb_ack_o (wb_ack_i[TGE2_SLI])
  );

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

  /******************* XAUI/TGBE 3 **********************/

`ifdef ENABLE_TEN_GB_ETH_3
  wire xaui_reset_3;
  wire  [7:0] xaui_status_3;
  wire [63:0] xaui_xgmii_txd_3;
  wire  [7:0] xaui_xgmii_txc_3;
  wire [63:0] xaui_xgmii_rxd_3;
  wire  [7:0] xaui_xgmii_rxc_3;

  xaui_phy xaui_phy_3(
    .clk   (mgt_clk_1),
    .reset (sys_reset),
    /* mgt signals */
    .mgt_txdata       (mgt_txdata[3]),
    .mgt_txcharisk    (mgt_txcharisk[3]),
    .mgt_rxdata       (mgt_rxdata[3]),
    .mgt_rxcharisk    (mgt_rxcharisk[3]),
    .mgt_enable_align (mgt_enable_align[3]),
    .mgt_en_chan_sync (mgt_enchansync[3]), 
    .mgt_code_valid   (mgt_codevalid[3]),
    .mgt_rxbufferr    (mgt_rxbufferr[3]),
    .mgt_code_comma   (mgt_code_comma[3]),
    .mgt_rxlock       (mgt_rxlock[3]),
    .mgt_syncok       (mgt_syncok[3]),
    .mgt_loopback     (mgt_loopback[3]),
    .mgt_powerdown    (mgt_powerdown[3]),
    .mgt_tx_reset     (mgt_tx_reset[3]),
    .mgt_rx_reset     (mgt_rx_reset[3]),
    /* XAUI signals */
    .xgmii_txd   (xaui_xgmii_txd_3),
    .xgmii_txc   (xaui_xgmii_txc_3),
    .xgmii_rxd   (xaui_xgmii_rxd_3),
    .xgmii_rxc   (xaui_xgmii_rxc_3),
    .xaui_reset  (xaui_reset_3),
    .xaui_status (xaui_status_3)
  );

  ten_gb_eth ten_gb_eth_3 (
     /* "Fabric" interface signals */
    .clk             (tge_usr_clk[3]),
    .rst             (tge_usr_rst[3]),
    .tx_valid        (tge_tx_valid[3]),
    .tx_ack          (tge_tx_ack[3]),
    .tx_end_of_frame (tge_tx_end_of_frame[3]),
    .tx_discard      (tge_tx_discard[3]),
    .tx_data         (tge_tx_data[3]),
    .tx_dest_ip      (tge_tx_dest_ip[3]),
    .tx_dest_port    (tge_tx_dest_port[3]),
    .rx_valid        (tge_rx_valid[3]),
    .rx_ack          (tge_rx_ack[3]),
    .rx_data         (tge_rx_data[3]),
    .rx_end_of_frame (tge_rx_end_of_frame[3]),
    .rx_size         (tge_rx_size[3]),
    .rx_source_ip    (tge_rx_source_ip[3]),
    .rx_source_port  (tge_rx_source_port[3]),
    .led_up          (tge_led_up[3]),
    .led_rx          (tge_led_rx[3]),
    .led_tx          (tge_led_tx[3]),

     /* XAUI signals  */
    .xaui_clk    (mgt_clk_1),
    .xgmii_txd   (xaui_xgmii_txd_3),
    .xgmii_txc   (xaui_xgmii_txc_3),
    .xgmii_rxd   (xaui_xgmii_rxd_3),
    .xgmii_rxc   (xaui_xgmii_rxc_3),
    .xaui_reset  (xaui_reset_3),
    .xaui_status (xaui_status_3),

    /* MGT config signals */
    .mgt_rxeqmix       (mgt_rxeqmix[3]),
    .mgt_rxeqpole      (mgt_rxeqpole[3]),
    .mgt_txpreemphasis (mgt_txpreemphasis[3]),
    .mgt_txdiffctrl    (mgt_txdiffctrl[3]),

     /* Wishbone IF  */
    .wb_clk_i (wb_clk),
    .wb_rst_i (sys_reset),
    .wb_cyc_i (wb_cyc_o[TGE3_SLI]),
    .wb_stb_i (wb_stb_o[TGE3_SLI]),
    .wb_we_i  (wb_we_o),
    .wb_sel_i (wb_sel_o),
    .wb_adr_i (wb_adr_o),
    .wb_dat_i (wb_dat_o),
    .wb_dat_o (wb_dat_i[16*(TGE3_SLI + 1) - 1: 16*TGE3_SLI]),
    .wb_ack_o (wb_ack_i[TGE3_SLI])
  );

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

  /*********** DRAM Memory Controller ***************/

  /* TODO: modify dram controller to support double write/reads
   *       ie 144*2 bit fifo read out at half-a-time rate on 

  /**** DRAM "Fabric" Interface signals ****/

  wire dram_rdy;

  wire dram_cmd_valid;
  wire dram_cmd_ack;
  wire dram_cmd_rnw;
  wire [31:0] dram_cmd_addr;
  wire [31:0] dram_cmd_tag;
  wire [144*`DRAM_WIDTH_MULTIPLIER - 1:0] dram_wr_data;
  wire [ 18*`DRAM_WIDTH_MULTIPLIER - 1:0] dram_wr_be;

  wire dram_rd_ack;
  wire dram_rd_valid;
  wire [144*`DRAM_WIDTH_MULTIPLIER - 1:0] dram_rd_data;
  wire [31:0] dram_rd_tag;

`ifdef ENABLE_DRAM
  wire dram_clk0, dram_clk90, dram_clk_div;
  wire dram_rst_0, dram_rst_90, dram_rst_div;

  assign dram_clk = dram_clk0;

  wire dram_usr_rst;

  dram_infrastructure #(
    .CLK_FREQ(`DRAM_CLK_FREQ)
  ) dram_infrastructure_inst (
    .reset        (sys_reset | ~idelay_ready),
    .clk_in       (dly_clk),
    .dram_clk_0   (dram_clk0),
    .dram_clk_90  (dram_clk90),
    .dram_clk_div (dram_clk_div),
    .dram_rst_0   (dram_rst_0),
    .dram_rst_90  (dram_rst_90),
    .dram_rst_div (dram_rst_div),
    .usr_clk      (wb_clk),
    .usr_rst      (dram_usr_rst)
  );

  /* Master DRAM interface */
  wire dram_cmd_valid_master;
  wire dram_cmd_ack_master = 1'b1; /* TODO: implement acks in controller */
  wire dram_cmd_rnw_master;
  wire [31:0] dram_cmd_addr_master;
  wire [31:0] dram_cmd_tag_master;
  wire [144*`DRAM_WIDTH_MULTIPLIER - 1:0] dram_wr_data_master;
  wire [ 18*`DRAM_WIDTH_MULTIPLIER - 1:0] dram_wr_be_master;
  wire [144*`DRAM_WIDTH_MULTIPLIER - 1:0] dram_rd_data_master;
  wire [31:0] dram_rd_tag_master = 32'b0; /* TODO(perhaps): implement tags in controller */
  wire dram_rd_valid_master;

  /* DRAM Phy signals */
  wire dram_phy_rdy;
  wire dram_cal_fail;

  assign dram_rdy = dram_phy_rdy;
  
  dram_controller #(
    .CLK_FREQ      (`DRAM_CLK_FREQ)
  ) dram_controller_inst (
    .clk0    (dram_clk0),
    .clk90   (dram_clk90),
    .clkdiv0 (dram_clk_div),
    .rst0    (dram_rst_0),
    .rst90   (dram_rst_90),
    .rstdiv0 (dram_rst_div),

    .phy_rdy  (dram_phy_ready),
    .cal_fail (dram_cal_fail),

    .app_cmd_addr  (dram_cmd_addr_master),
    .app_cmd_rnw   (dram_cmd_rnw_master),
    .app_cmd_valid (dram_cmd_valid_master),
    .app_wr_data   (dram_wr_data_master),
    .app_wr_be     (dram_wr_be_master),
    .app_rd_data   (dram_rd_data_master),
    .app_rd_valid  (dram_rd_valid_master),

    .dram_ck    ({dram_ck_2_p, dram_ck_1_p, dram_ck_0_p}),
    .dram_ck_n  ({dram_ck_2_n, dram_ck_1_n, dram_ck_0_n}),
    .dram_a     (dram_a),
    .dram_ba    (dram_ba),
    .dram_ras_n (dram_ras_n),
    .dram_cas_n (dram_cas_n),
    .dram_we_n  (dram_we_n),
    .dram_cs_n  ({dram_cs_n_1, dram_cs_n_0}),
    .dram_cke   ({dram_cke_1,  dram_cke_0}),
    .dram_odt   ({dram_odt_1,  dram_odt_0}),
    .dram_dm    (dram_dm),
    .dram_dqs   (dram_dqs_p),
    .dram_dqs_n (dram_dqs_n),
    .dram_dq    (dram_dq)
  );

  /* These signals are unused and tied-off */
  assign dram_par_out = dram_par_in; /* this is done only to avoid a warning */
  assign dram_reset_n = 1'b1;
  assign dram_scl     = 1'b1;
  assign dram_sda     = 1'b1;

  /* CPU DRAM interface */
  wire dram_cmd_valid_cpu;
  wire dram_cmd_rnw_cpu;
  wire [31:0] dram_cmd_addr_cpu;
  wire [144*`DRAM_WIDTH_MULTIPLIER - 1:0] dram_wr_data_cpu;
  wire [ 18*`DRAM_WIDTH_MULTIPLIER - 1:0] dram_wr_be_cpu;
  wire [144*`DRAM_WIDTH_MULTIPLIER - 1:0] dram_rd_data_cpu;
  wire dram_rd_valid_cpu;

  dram_cpu_interface #(
    .CLK_FREQ(`DRAM_CLK_FREQ),
    .DQ_WIDTH(72)
  ) dram_cpu_interface_inst (
    //memory wb slave IF
    .wb_clk_i (wb_clk),
    .wb_rst_i (sys_reset),

    .reg_wb_cyc_i (wb_cyc_o[DRAMCONF_SLI]),
    .reg_wb_stb_i (wb_stb_o[DRAMCONF_SLI]),
    .reg_wb_sel_i (wb_sel_o),
    .reg_wb_we_i  (wb_we_o),
    .reg_wb_adr_i (wb_adr_o),
    .reg_wb_dat_i (wb_dat_o),
    .reg_wb_dat_o (wb_dat_i[16*(DRAMCONF_SLI + 1) - 1: 16*DRAMCONF_SLI]),
    .reg_wb_ack_o (wb_ack_i[DRAMCONF_SLI]),
    //memory wb slave IF
    .mem_wb_cyc_i (wb_cyc_o[DRAM_SLI]),
    .mem_wb_stb_i (wb_stb_o[DRAM_SLI]),
    .mem_wb_sel_i (wb_sel_o),
    .mem_wb_we_i  (wb_we_o),
    .mem_wb_adr_i (wb_adr_o),
    .mem_wb_dat_i (wb_dat_o),
    .mem_wb_dat_o (wb_dat_i[16*(DRAM_SLI + 1) - 1: 16*DRAM_SLI]),
    .mem_wb_ack_o (wb_ack_i[DRAM_SLI]),
    //dram interface
    .dram_clk0  (dram_clk0),
    .dram_clk90 (dram_clk90),
    .dram_rst_o (dram_usr_rst),

    .dram_phy_rdy  (dram_phy_ready),
    .dram_cal_fail (dram_cal_fail),

    .dram_cmd_valid (dram_cmd_valid_cpu),
    .dram_cmd_rnw   (dram_cmd_rnw_cpu),
    .dram_cmd_addr  (dram_cmd_addr_cpu),
    .dram_wr_data   (dram_wr_data_cpu),
    .dram_wr_be     (dram_wr_be_cpu),
    .dram_rd_data   (dram_rd_data_cpu),
    .dram_rd_valid  (dram_rd_valid_cpu),

    .dram_arb_grant (dram_arb_grant)  /* Basic Arbitration Signal */
  );

`ifdef DRAM_ARB_BASIC
  assign dram_cmd_addr_master  = dram_arb_grant ? dram_cmd_addr  : dram_cmd_addr_cpu;
  assign dram_cmd_rnw_master   = dram_arb_grant ? dram_cmd_rnw   : dram_cmd_rnw_cpu;
  assign dram_cmd_valid_master = dram_arb_grant ? dram_cmd_valid : dram_cmd_valid_cpu;
  assign dram_wr_data_master   = dram_arb_grant ? dram_wr_data   : dram_wr_data_cpu;
  assign dram_wr_be_master     = dram_arb_grant ? dram_wr_be     : dram_wr_be_cpu;

  assign dram_rd_valid         = dram_arb_grant ? dram_rd_valid_master : 1'b0;
  assign dram_rd_data          = dram_rd_data_master;

  assign dram_rd_valid_cpu     = dram_arb_grant ? 1'b0 : dram_rd_valid_master;
  assign dram_rd_data_cpu      = dram_rd_data_master;

`else 
  multiport_dram #(
    .C_NUM_PORTS    (2),
    .C_PORTS_WIDTH  (1),
    .C_WIDE_DATA    (`DRAM_WIDTH_MULTIPLIER == 2),
    .C_HALF_BURST   (`DRAM_HALF_BURST),
    .C_BURST_WINDOW (160),
    .C_BWIND_WIDTH  (8)
  ) multiport_dram_inst (
   // System inputs
   .Clk (dram_clk0),
   .Rst (dram_rst_0),

   // Memory interface in 0 (non-shared)
   .In0_Cmd_Address (dram_cmd_addr),
   .In0_Cmd_RNW     (dram_cmd_rnw),
   .In0_Cmd_Valid   (dram_cmd_valid),
   .In0_Cmd_Tag     (dram_cmd_tag),
   .In0_Cmd_Ack     (dram_cmd_ack),
   .In0_Rd_Dout     (dram_rd_data),
   .In0_Rd_Tag      (dram_rd_tag),
   .In0_Rd_Ack      (dram_rd_ack),
   .In0_Rd_Valid    (dram_rd_valid),
   .In0_Wr_Din      (dram_wr_data),
   .In0_Wr_BE       (dram_wr_be),

   // Memory interface in 1 (non-shared)
   .In1_Cmd_Address (dram_cmd_addr_cpu),
   .In1_Cmd_RNW     (dram_cmd_rnw_cpu),
   .In1_Cmd_Valid   (dram_cmd_valid_cpu),
   .In1_Cmd_Tag     (32'b0),
   .In1_Cmd_Ack     (), //ack unsed
   .In1_Rd_Dout     (dram_rd_data_cpu),
   .In1_Rd_Tag      (), //tag unused
   .In1_Rd_Ack      (1'b1),
   .In1_Rd_Valid    (dram_rd_valid_cpu),
   .In1_Wr_Din      (dram_wr_data_cpu),
   .In1_Wr_BE       (dram_wr_be_cpu),

   // Memory interface out (shared)
   .Out_Cmd_Address (dram_cmd_addr_master),
   .Out_Cmd_RNW     (dram_cmd_rnw_master),
   .Out_Cmd_Valid   (dram_cmd_valid_master),
   .Out_Cmd_Tag     (dram_cmd_tag_master),
   .Out_Cmd_Ack     (dram_cmd_ack_master),
   .Out_Rd_Dout     (dram_rd_data_master),
   .Out_Rd_Tag      (dram_rd_tag_master),
   .Out_Rd_Ack      (dram_rd_ack_master),
   .Out_Rd_Valid    (dram_rd_valid_master),
   .Out_Wr_Din      (dram_wr_data_master),
   .Out_Wr_BE       (dram_wr_be_master)
  );
`endif

`else
  /* Tie off the external signals */
  assign dram_dq = {72{1'bz}};
  assign dram_dm = 9'b0;
  assign dram_a = 16'b0;
  assign dram_ba = 3'b0;
  assign dram_ras_n = 1'b1;
  assign dram_cas_n = 1'b1; 
  assign dram_we_n  = 1'b1;
  assign dram_reset_n = 1'b0;
  assign dram_cke_0 = 1'b0;
  assign dram_cke_1 = 1'b0;
  assign dram_cs_n_0 = 1'b1;
  assign dram_cs_n_1 = 1'b1;
  assign dram_odt_0 = 1'b1;
  assign dram_odt_1 = 1'b1;
  assign dram_par_out = dram_par_in;
  assign dram_scl = 1'b1;
  assign dram_sda = 1'b1;

  IOBUFDS iobufds_dqs[8:0](
    .IO(dram_dqs_p),
    .IOB(dram_dqs_n),
    .O(), .I({9{1'b1}}), .T(1'b1)
  );

  OBUFDS obufds_inst[2:0](
    .O( {dram_ck_2_p, dram_ck_1_p, dram_ck_0_p}),
    .OB({dram_ck_2_n, dram_ck_1_n, dram_ck_0_n}),
    .I(3'b0)
  );

  /* Tie off the fabric signals */
  assign dram_rd_data  = {144*`DRAM_WIDTH_MULTIPLIER{1'b0}};
  assign dram_rd_valid = 1'b0;
  assign dram_cmd_ack  = 1'b0;
  assign dram_rd_tag   = 32'b0;

  /* Tie off the wb signals */
  assign wb_dat_i[16*(DRAMCONF_SLI + 1) - 1: 16*DRAMCONF_SLI] = 16'b0;
  assign wb_ack_i[DRAMCONF_SLI] = 1'b0;
  assign wb_dat_i[16*(DRAM_SLI + 1) - 1: 16*DRAM_SLI] = 16'b0;
  assign wb_ack_i[DRAM_SLI] = 1'b0;
`endif


  /**** QDR 0 & 1 "Fabric" Interface signals ****/

  wire qdr0_rdy;
  wire qdr0_cmd_valid;
  wire qdr0_cmd_ack;
  wire qdr0_cmd_rnw;
  wire [31:0] qdr0_cmd_addr;
  wire [36*`QDR0_WIDTH_MULTIPLIER - 1:0] qdr0_wr_data;
  wire [ 4*`QDR0_WIDTH_MULTIPLIER - 1:0] qdr0_wr_be;
  wire qdr0_rd_valid;
  wire qdr0_rd_ack;
  wire [36*`QDR0_WIDTH_MULTIPLIER - 1:0] qdr0_rd_data;

  wire qdr1_rdy;
  wire qdr1_cmd_valid;
  wire qdr1_cmd_ack;
  wire qdr1_cmd_rnw;
  wire [31:0] qdr1_cmd_addr;
  wire [36*`QDR1_WIDTH_MULTIPLIER - 1:0] qdr1_wr_data;
  wire [ 4*`QDR1_WIDTH_MULTIPLIER - 1:0] qdr1_wr_be;
  wire qdr1_rd_valid;
  wire qdr1_rd_ack;
  wire [36*`QDR1_WIDTH_MULTIPLIER - 1:0] qdr1_rd_data;


`ifdef ENABLE_QDR_INFRASTRUCTURE
  /***************** QDR Common Infrastructure *********************/
  wire qdr_clk0, qdr_clk180, qdr_clk270;
  wire qdr_pll_lock;

  assign qdr_clk_0 = qdr_clk0;
  assign qdr_clk_1 = qdr_clk0;

  qdr_infrastructure #(
    .CLK_FREQ(`QDR_CLK_FREQ)
  ) qdr_infrastructure_inst (
    .clk_in (dly_clk),
    .reset  (sys_reset),
    .qdr_clk_0   (qdr_clk0),
    .qdr_clk_180 (qdr_clk180),
    .qdr_clk_270 (qdr_clk270),
    .pll_lock    (qdr_pll_lock)
  );
`endif

`ifdef ENABLE_QDR0
  wire qdr0_usr_reset;
  wire qdr0_phy_rdy;
  wire qdr0_cal_fail;
  assign qdr0_rdy = qdr0_phy_rdy;

  wire [31:0] qdr0_cmd_addr_master;
  wire qdr0_rd_strb_master;
  wire qdr0_rd_valid_master;
  wire [36*`QDR0_WIDTH_MULTIPLIER - 1:0] qdr0_rd_data_master;
  wire qdr0_wr_strb_master;
  wire [36*`QDR0_WIDTH_MULTIPLIER - 1:0] qdr0_wr_data_master;
  wire [ 4*`QDR0_WIDTH_MULTIPLIER - 1:0] qdr0_wr_be_master;

  qdr_controller #(
    .DATA_WIDTH   (18),
    .BW_WIDTH     (2),
    .ADDR_WIDTH   (21),
    .BURST_LENGTH (4),
    .CLK_FREQ     (`QDR_CLK_FREQ)
    //.USE_XILINX_CORE (0)
  ) qdr_controller_0 (
    .reset (sys_reset || qdr0_usr_reset || !qdr_pll_lock || !idelay_ready),

    .clk0    (qdr_clk0),
    .clk180  (qdr_clk180),
    .clk270  (qdr_clk270),
    .div_clk (epb_clk),

    .qdr_d         (qdr0_d),
    .qdr_q         (qdr0_q),
    .qdr_sa        (qdr0_sa),
    .qdr_w_n       (qdr0_w_n),
    .qdr_r_n       (qdr0_r_n),
    .qdr_dll_off_n (qdr0_dll_off_n),
    .qdr_bw_n      (qdr0_bw_n),
    .qdr_cq        (qdr0_cq_p),
    .qdr_cq_n      (qdr0_cq_n),
    .qdr_k         (qdr0_k_p),
    .qdr_k_n       (qdr0_k_n),
    .qdr_qvld      (qdr0_qvld),

    .phy_rdy  (qdr0_phy_rdy),
    .cal_fail (qdr0_cal_fail),

    .usr_rd_strb (qdr0_rd_strb_master),
    .usr_rd_data (qdr0_rd_data_master),
    .usr_rd_dvld (qdr0_rd_valid_master),
    .usr_wr_strb (qdr0_wr_strb_master),
    .usr_wr_data (qdr0_wr_data_master),
    .usr_wr_be   (qdr0_wr_be_master),
    .usr_addr    (qdr0_cmd_addr_master)
  );

  wire [31:0] qdr0_cmd_addr_cpu;
  wire qdr0_cmd_ack_cpu; //unused
  wire qdr0_rd_strb_cpu;
  wire qdr0_rd_valid_cpu;
  wire [36*`QDR0_WIDTH_MULTIPLIER - 1:0] qdr0_rd_data_cpu;
  wire qdr0_wr_strb_cpu;
  wire [36*`QDR0_WIDTH_MULTIPLIER - 1:0] qdr0_wr_data_cpu;
  wire [ 4*`QDR0_WIDTH_MULTIPLIER - 1:0] qdr0_wr_be_cpu;

  qdr_cpu_interface #(
    .CLK_FREQ(`QDR_CLK_FREQ)
  ) qdr_cpu_interface_0 (
    //memory wb slave IF
    .wb_clk_i (wb_clk),
    .wb_rst_i (sys_reset),
    .reg_wb_cyc_i (wb_cyc_o[QDR0CONF_SLI]),
    .reg_wb_stb_i (wb_stb_o[QDR0CONF_SLI]),
    .reg_wb_sel_i (wb_sel_o),
    .reg_wb_we_i  (wb_we_o), 
    .reg_wb_adr_i (wb_adr_o),
    .reg_wb_dat_i (wb_dat_o),
    .reg_wb_dat_o (wb_dat_i[16*(QDR0CONF_SLI + 1) - 1: 16*QDR0CONF_SLI]),
    .reg_wb_ack_o (wb_ack_i[QDR0CONF_SLI]),
    //memory wb slave IF
    .mem_wb_cyc_i (wb_cyc_o[QDR0_SLI]),
    .mem_wb_stb_i (wb_stb_o[QDR0_SLI]),
    .mem_wb_sel_i (wb_sel_o),
    .mem_wb_we_i  (wb_we_o), 
    .mem_wb_adr_i (wb_adr_o),
    .mem_wb_dat_i (wb_dat_o),
    .mem_wb_dat_o (wb_dat_i[16*(QDR0_SLI + 1) - 1: 16*QDR0_SLI]),
    .mem_wb_ack_o (wb_ack_i[QDR0_SLI]),
    //qdr interface

    .qdr_clk_i (qdr_clk0),
    .qdr_rst_o (qdr0_usr_reset),

    .qdr_phy_rdy  (qdr0_phy_rdy),
    .qdr_cal_fail (qdr0_cal_fail),

    .qdr_addr    (qdr0_cmd_addr_cpu),
    .qdr_wr_en   (qdr0_wr_strb_cpu),
    .qdr_wr_data (qdr0_wr_data_cpu),
    .qdr_wr_be   (qdr0_wr_be_cpu),
    .qdr_rd_en   (qdr0_rd_strb_cpu),
    .qdr_rd_dvld (qdr0_rd_valid_cpu),
    .qdr_rd_data (qdr0_rd_data_cpu)
  );

  multiport_qdr #(
    .C_WIDE_DATA     (`QDR0_WIDTH_MULTIPLIER == 2)
  ) multiport_qdr_0 (
   // System inputs
   .clk (qdr_clk0),
   .rst (qdr0_usr_reset | reset),

   // Memory interface in 0 (non-shared)
   .in0_cmd_addr (qdr0_cmd_addr),
   .in0_cmd_ack  (qdr0_cmd_ack),
   .in0_wr_strb  (qdr0_cmd_valid && !qdr0_cmd_rnw),
   .in0_wr_data  (qdr0_wr_data),
   .in0_wr_be    (qdr0_wr_be),
   .in0_rd_strb  (qdr0_cmd_valid &&  qdr0_cmd_rnw),
   .in0_rd_dvld  (qdr0_rd_valid),
   .in0_rd_data  (qdr0_rd_data),

   // Memory interface in 1 (non-shared)
   .in1_cmd_addr (qdr0_cmd_addr_cpu),
   .in1_cmd_ack  (qdr0_cmd_ack_cpu),
   .in1_wr_strb  (qdr0_wr_strb_cpu),
   .in1_wr_data  (qdr0_wr_data_cpu),
   .in1_wr_be    (qdr0_wr_be_cpu),
   .in1_rd_strb  (qdr0_rd_strb_cpu),
   .in1_rd_dvld  (qdr0_rd_valid_cpu),
   .in1_rd_data  (qdr0_rd_data_cpu),

   // Memory interface out (shared)
   .out_cmd_addr (qdr0_cmd_addr_master),
   .out_wr_strb  (qdr0_wr_strb_master),
   .out_wr_data  (qdr0_wr_data_master),
   .out_wr_be    (qdr0_wr_be_master),
   .out_rd_strb  (qdr0_rd_strb_master),
   .out_rd_dvld  (qdr0_rd_valid_master),
   .out_rd_data  (qdr0_rd_data_master)
 );

`else
  //Tie off various interfaces
  assign qdr0_d         = {18{1'b0}};
  assign qdr0_sa        = {22{1'b0}};
  assign qdr0_w_n       = 1'b1;
  assign qdr0_r_n       = 1'b1;
  assign qdr0_dll_off_n = 1'b1;
  assign qdr0_bw_n      = 2'b11;
  assign qdr0_k_p       = 1'b0;
  assign qdr0_k_n       = 1'b1;

  assign wb_dat_i[16*(QDR0CONF_SLI + 1) - 1: 16*QDR0CONF_SLI] = 16'b0;
  assign wb_ack_i[QDR0CONF_SLI] = 1'b0;
  assign wb_dat_i[16*(QDR0_SLI + 1) - 1: 16*QDR0_SLI] = 16'b0;
  assign wb_ack_i[QDR0_SLI] = 1'b0;

  assign qdr0_cmd_ack  = 1'b0;
  assign qdr0_rd_valid = 1'b0;
  assign qdr0_rd_data  = {36*`QDR0_WIDTH_MULTIPLIER{1'b0}};
`endif

  /***************** QDR1 ************************/

`ifdef ENABLE_QDR1
  wire qdr1_usr_reset;
  wire qdr1_phy_rdy;
  wire qdr1_cal_fail;
  assign qdr1_rdy = qdr1_phy_rdy;

  wire [31:0] qdr1_cmd_addr_master;
  wire qdr1_rd_strb_master;
  wire qdr1_rd_valid_master;
  wire [36*`QDR1_WIDTH_MULTIPLIER - 1:0] qdr1_rd_data_master;
  wire qdr1_wr_strb_master;
  wire [36*`QDR1_WIDTH_MULTIPLIER - 1:0] qdr1_wr_data_master;
  wire [ 4*`QDR1_WIDTH_MULTIPLIER - 1:0] qdr1_wr_be_master;

  qdr_controller #(
    .DATA_WIDTH   (18),
    .BW_WIDTH     (2),
    .ADDR_WIDTH   (21),
    .BURST_LENGTH (4),
    .CLK_FREQ     (`QDR_CLK_FREQ)
    //.USE_XILINX_CORE (0)
  ) qdr_controller_1 (
    .reset (sys_reset || qdr1_usr_reset || !qdr_pll_lock || !idelay_ready),

    .clk0    (qdr_clk0),
    .clk180  (qdr_clk180),
    .clk270  (qdr_clk270),
    .div_clk (epb_clk),

    .qdr_d         (qdr1_d),
    .qdr_q         (qdr1_q),
    .qdr_sa        (qdr1_sa),
    .qdr_w_n       (qdr1_w_n),
    .qdr_r_n       (qdr1_r_n),
    .qdr_dll_off_n (qdr1_dll_off_n),
    .qdr_bw_n      (qdr1_bw_n),
    .qdr_cq        (qdr1_cq_p),
    .qdr_cq_n      (qdr1_cq_n),
    .qdr_k         (qdr1_k_p),
    .qdr_k_n       (qdr1_k_n),
    .qdr_qvld      (qdr1_qvld),

    .phy_rdy  (qdr1_phy_rdy),
    .cal_fail (qdr1_cal_fail),

    .usr_rd_strb (qdr1_rd_strb_master),
    .usr_rd_data (qdr1_rd_data_master),
    .usr_rd_dvld (qdr1_rd_valid_master),
    .usr_wr_strb (qdr1_wr_strb_master),
    .usr_wr_data (qdr1_wr_data_master),
    .usr_wr_be   (qdr1_wr_be_master),
    .usr_addr    (qdr1_cmd_addr_master)
  );

  wire [31:0] qdr1_cmd_addr_cpu;
  wire qdr1_cmd_ack_cpu; //unused
  wire qdr1_rd_strb_cpu;
  wire qdr1_rd_valid_cpu;
  wire [36*`QDR1_WIDTH_MULTIPLIER - 1:0] qdr1_rd_data_cpu;
  wire qdr1_wr_strb_cpu;
  wire [36*`QDR1_WIDTH_MULTIPLIER - 1:0] qdr1_wr_data_cpu;
  wire [ 4*`QDR1_WIDTH_MULTIPLIER - 1:0] qdr1_wr_be_cpu;

  qdr_cpu_interface #(
    .CLK_FREQ(`QDR_CLK_FREQ)
  ) qdr_cpu_interface_1 (
    //memory wb slave IF
    .wb_clk_i (wb_clk),
    .wb_rst_i (sys_reset),

    .reg_wb_cyc_i (wb_cyc_o[QDR1CONF_SLI]),
    .reg_wb_stb_i (wb_stb_o[QDR1CONF_SLI]),
    .reg_wb_sel_i (wb_sel_o),
    .reg_wb_we_i  (wb_we_o), 
    .reg_wb_adr_i (wb_adr_o),
    .reg_wb_dat_i (wb_dat_o),
    .reg_wb_dat_o (wb_dat_i[16*(QDR1CONF_SLI + 1) - 1: 16*QDR1CONF_SLI]),
    .reg_wb_ack_o (wb_ack_i[QDR1CONF_SLI]),
    //memory wb slave IF
    .mem_wb_cyc_i (wb_cyc_o[QDR1_SLI]),
    .mem_wb_stb_i (wb_stb_o[QDR1_SLI]),
    .mem_wb_sel_i (wb_sel_o),
    .mem_wb_we_i  (wb_we_o), 
    .mem_wb_adr_i (wb_adr_o),
    .mem_wb_dat_i (wb_dat_o),
    .mem_wb_dat_o (wb_dat_i[16*(QDR1_SLI + 1) - 1: 16*QDR1_SLI]),
    .mem_wb_ack_o (wb_ack_i[QDR1_SLI]),
    //qdr interface

    .qdr_clk_i (qdr_clk0),
    .qdr_rst_o (qdr1_usr_reset),

    .qdr_phy_rdy  (qdr1_phy_rdy),
    .qdr_cal_fail (qdr1_cal_fail),

    .qdr_addr    (qdr1_cmd_addr_cpu),
    .qdr_wr_en   (qdr1_wr_strb_cpu),
    .qdr_wr_data (qdr1_wr_data_cpu),
    .qdr_wr_be   (qdr1_wr_be_cpu),
    .qdr_rd_en   (qdr1_rd_strb_cpu),
    .qdr_rd_dvld (qdr1_rd_valid_cpu),
    .qdr_rd_data (qdr1_rd_data_cpu)
  );

  multiport_qdr #(
    .C_WIDE_DATA     (`QDR1_WIDTH_MULTIPLIER == 2)
  ) multiport_qdr_1 (
   // System inputs
   .clk (qdr_clk0),
   .rst (reset | qdr1_usr_reset),

   // Memory interface in 0 (non-shared)
   .in0_cmd_addr (qdr1_cmd_addr),
   .in0_cmd_ack  (qdr1_cmd_ack),
   .in0_wr_strb  (qdr1_cmd_valid && !qdr1_cmd_rnw),
   .in0_wr_data  (qdr1_wr_data),
   .in0_wr_be    (qdr1_wr_be),
   .in0_rd_strb  (qdr1_cmd_valid &&  qdr1_cmd_rnw),
   .in0_rd_dvld  (qdr1_rd_valid),
   .in0_rd_data  (qdr1_rd_data),

   // Memory interface in 1 (non-shared)
   .in1_cmd_addr (qdr1_cmd_addr_cpu),
   .in1_cmd_ack  (qdr1_cmd_ack_cpu),
   .in1_wr_strb  (qdr1_wr_strb_cpu),
   .in1_wr_data  (qdr1_wr_data_cpu),
   .in1_wr_be    (qdr1_wr_be_cpu),
   .in1_rd_strb  (qdr1_rd_strb_cpu),
   .in1_rd_dvld  (qdr1_rd_valid_cpu),
   .in1_rd_data  (qdr1_rd_data_cpu),

   // Memory interface out (shared)
   .out_cmd_addr (qdr1_cmd_addr_master),
   .out_wr_strb  (qdr1_wr_strb_master),
   .out_wr_data  (qdr1_wr_data_master),
   .out_wr_be    (qdr1_wr_be_master),
   .out_rd_strb  (qdr1_rd_strb_master),
   .out_rd_dvld  (qdr1_rd_valid_master),
   .out_rd_data  (qdr1_rd_data_master)
 );

`else
  //Tie off various interfaces
  assign qdr1_d         = {18{1'b0}};
  assign qdr1_sa        = {22{1'b0}};
  assign qdr1_w_n       = 1'b1;
  assign qdr1_r_n       = 1'b1;
  assign qdr1_dll_off_n = 1'b1;
  assign qdr1_bw_n      = 2'b11;
  assign qdr1_k_p       = 1'b0;
  assign qdr1_k_n       = 1'b1;

  assign wb_dat_i[16*(QDR1CONF_SLI + 1) - 1: 16*QDR1CONF_SLI] = 16'b0;
  assign wb_ack_i[QDR1CONF_SLI] = 1'b0;
  assign wb_dat_i[16*(QDR1_SLI + 1) - 1: 16*QDR1_SLI] = 16'b0;
  assign wb_ack_i[QDR1_SLI] = 1'b0;

  assign qdr1_cmd_ack  = 1'b0;
  assign qdr1_rd_valid = 1'b0;
  assign qdr1_rd_data  = {36*`QDR1_WIDTH_MULTIPLIER{1'b0}};
`endif

  /********************* ZDOK *********************/

  /* ZDOK 0 */

  gpio_test #(
    .GPIO_COUNT (80)
  ) gpio_zdok0 (
    .wb_clk_i (wb_clk),
    .wb_rst_i (sys_reset),
    .wb_cyc_i (wb_cyc_o[ADC0_SLI]),
    .wb_stb_i (wb_stb_o[ADC0_SLI]),
    .wb_sel_i (wb_sel_o),
    .wb_we_i  (wb_we_o), 
    .wb_adr_i (wb_adr_o),
    .wb_dat_i (wb_dat_o),
    .wb_dat_o (wb_dat_i[16*(ADC0_SLI + 1) - 1: 16*ADC0_SLI]),
    .wb_ack_o (wb_ack_i[ADC0_SLI]),
    .gpio     ({zdok0_clk1_p, zdok0_dp_p[37:29], zdok0_clk0_p, zdok0_dp_p[28:0],
                zdok0_clk1_n, zdok0_dp_n[37:29], zdok0_clk0_n, zdok0_dp_n[28:0]})
  );

  /* ZDOK 1 */

  gpio_test #(
    .GPIO_COUNT (80)
  ) gpio_zdok1 (
    .wb_clk_i (wb_clk),
    .wb_rst_i (sys_reset),
    .wb_cyc_i (wb_cyc_o[ADC1_SLI]),
    .wb_stb_i (wb_stb_o[ADC1_SLI]),
    .wb_sel_i (wb_sel_o),
    .wb_we_i  (wb_we_o), 
    .wb_adr_i (wb_adr_o),
    .wb_dat_i (wb_dat_o),
    .wb_dat_o (wb_dat_i[16*(ADC1_SLI + 1) - 1: 16*ADC1_SLI]),
    .wb_ack_o (wb_ack_i[ADC1_SLI]),
    .gpio     ({zdok1_clk1_p, zdok1_dp_p[37:29], zdok1_clk0_p, zdok1_dp_p[28:0],
                zdok1_clk1_n, zdok1_dp_n[37:29], zdok1_clk0_n, zdok1_dp_n[28:0]})
  );


  /******************* GPIO ***********************/


  gpio_test #(
    .GPIO_COUNT (80+9+9)
  ) gpio_miscgpio (
    .wb_clk_i (wb_clk),
    .wb_rst_i (sys_reset),
    .wb_cyc_i (wb_cyc_o[RSRVD0_SLI]),
    .wb_stb_i (wb_stb_o[RSRVD0_SLI]),
    .wb_sel_i (wb_sel_o),
    .wb_we_i  (wb_we_o), 
    .wb_adr_i (wb_adr_o),
    .wb_dat_i (wb_dat_o),
    .wb_dat_o (wb_dat_i[16*(RSRVD0_SLI + 1) - 1: 16*RSRVD0_SLI]),
    .wb_ack_o (wb_ack_i[RSRVD0_SLI]),
    .gpio     ({se_gpio_a, se_gpio_a_oen_n, se_gpio_b, se_gpio_b_oen_n, diff_gpio_a_clk_p, diff_gpio_a_p, diff_gpio_a_clk_n, diff_gpio_a_n, diff_gpio_b_clk_p, diff_gpio_b_p, diff_gpio_b_clk_n, diff_gpio_b_n})
  );


/******************* ROACH Application *****************/

`ifdef ENABLE_APPLICATION

  roach_app #(
    .DRAM_WIDTH_MULTIPLIER(`DRAM_WIDTH_MULTIPLIER),
    .QDR0_WIDTH_MULTIPLIER(`QDR0_WIDTH_MULTIPLIER),
    .QDR1_WIDTH_MULTIPLIER(`QDR1_WIDTH_MULTIPLIER)
  ) roach_app_inst (
    .sys_reset(sys_reset),

    /* input clocks */
    .sys_clk  (sys_clk),
    .dram_clk (dram_clk),
    .qdr0_clk (qdr_clk_0),
    .qdr1_clk (qdr_clk_0),
    .tge_clk  (mgt_clk_0),
    .aux_clk  ({aux_clk_1, aux_clk_0}),
    .aux_sync ({aux_clk_1, aux_clk_0}),

    /* Wishbone Interface */
    .wb_clk_i (wb_clk),
    .wb_rst_i (sys_reset),
    .wb_cyc_i (wb_cyc_o[APP_SLI]),
    .wb_stb_i (wb_stb_o[APP_SLI]),
    .wb_sel_i (wb_sel_o),
    .wb_we_i  (wb_we_o),
    .wb_adr_i (wb_adr_o),
    .wb_dat_i (wb_dat_o),
    .wb_dat_o (wb_dat_i[16*(APP_SLI + 1) - 1: 16*APP_SLI]),
    .wb_ack_o (wb_ack_i[APP_SLI]),

    /* 4 x TGE interfaces */
    .tge_usr_clk         ({        tge_usr_clk[3],         tge_usr_clk[2],         tge_usr_clk[1],         tge_usr_clk[0]}),
    .tge_usr_rst         ({        tge_usr_rst[3],         tge_usr_rst[2],         tge_usr_rst[1],         tge_usr_rst[0]}),
    .tge_tx_valid        ({       tge_tx_valid[3],        tge_tx_valid[2],        tge_tx_valid[1],        tge_tx_valid[0]}),
    .tge_tx_ack          ({         tge_tx_ack[3],          tge_tx_ack[2],          tge_tx_ack[1],          tge_tx_ack[0]}),
    .tge_tx_end_of_frame ({tge_tx_end_of_frame[3], tge_tx_end_of_frame[2], tge_tx_end_of_frame[1], tge_tx_end_of_frame[0]}),
    .tge_tx_discard      ({     tge_tx_discard[3],      tge_tx_discard[2],      tge_tx_discard[1],      tge_tx_discard[0]}),
    .tge_tx_data         ({        tge_tx_data[3],         tge_tx_data[2],         tge_tx_data[1],         tge_tx_data[0]}),
    .tge_tx_dest_ip      ({     tge_tx_dest_ip[3],      tge_tx_dest_ip[2],      tge_tx_dest_ip[1],      tge_tx_dest_ip[0]}),
    .tge_tx_dest_port    ({   tge_tx_dest_port[3],    tge_tx_dest_port[2],    tge_tx_dest_port[1],    tge_tx_dest_port[0]}),
    .tge_rx_valid        ({       tge_rx_valid[3],        tge_rx_valid[2],        tge_rx_valid[1],        tge_rx_valid[0]}),
    .tge_rx_ack          ({         tge_rx_ack[3],          tge_rx_ack[2],          tge_rx_ack[1],          tge_rx_ack[0]}),
    .tge_rx_data         ({        tge_rx_data[3],         tge_rx_data[2],         tge_rx_data[1],         tge_rx_data[0]}),
    .tge_rx_end_of_frame ({tge_rx_end_of_frame[3], tge_rx_end_of_frame[2], tge_rx_end_of_frame[1], tge_rx_end_of_frame[0]}),
    .tge_rx_size         ({        tge_rx_size[3],         tge_rx_size[2],         tge_rx_size[1],         tge_rx_size[0]}),
    .tge_rx_source_ip    ({   tge_rx_source_ip[3],    tge_rx_source_ip[2],    tge_rx_source_ip[1],    tge_rx_source_ip[0]}),
    .tge_rx_source_port  ({ tge_rx_source_port[3],  tge_rx_source_port[2],  tge_rx_source_port[1],  tge_rx_source_port[0]}),
    .tge_led_up          ({         tge_led_up[3],          tge_led_up[2],          tge_led_up[1],          tge_led_up[0]}),
    .tge_led_rx          ({         tge_led_rx[3],          tge_led_rx[2],          tge_led_rx[1],          tge_led_rx[0]}),
    .tge_led_tx          ({         tge_led_tx[3],          tge_led_tx[2],          tge_led_tx[1],          tge_led_tx[0]}),

    /* DRAM Interfaces */
    .dram_usrclk (), /* TODO: implement fifo to cross between DDR2 clk and user clk */

    .dram_rdy       (dram_rdy),
    .dram_cmd_valid (dram_cmd_valid),
    .dram_cmd_ack   (dram_cmd_ack),
    .dram_cmd_rnw   (dram_cmd_rnw),
    .dram_cmd_addr  (dram_cmd_addr),
    .dram_wr_data   (dram_wr_data),
    .dram_wr_be     (dram_wr_be),
    .dram_rd_valid  (dram_rd_valid),
    .dram_rd_ack    (dram_rd_ack),
    .dram_rd_data   (dram_rd_data),

    /* QDR0 Interfaces */
    .qdr0_usrclk(), /* TODO: implement qdr clock infrastucture at usr_clk freq */
                    /* TODO: implement alternate qdr implementation with fifo
                     * to cross between QDR clk and user clk*/

    .qdr0_rdy       (qdr0_rdy),
    .qdr0_cmd_valid (qdr0_cmd_valid),
    .qdr0_cmd_ack   (qdr0_cmd_ack),
    .qdr0_cmd_rnw   (qdr0_cmd_rnw),
    .qdr0_cmd_addr  (qdr0_cmd_addr),
    .qdr0_wr_data   (qdr0_wr_data),
    .qdr0_wr_be     (qdr0_wr_be),
    .qdr0_rd_valid  (qdr0_rd_valid),
    .qdr0_rd_ack    (qdr0_rd_ack),
    .qdr0_rd_data   (qdr0_rd_data),

    /* QDR1 Interfaces */
    .qdr1_usrclk(), /* TODO: implement qdr clock infrastucture at usr_clk freq */
                    /* TODO: implement alternate qdr implementation with fifo
                     * to cross between QDR clk and user clk*/

    .qdr1_rdy       (qdr1_rdy),
    .qdr1_cmd_valid (qdr1_cmd_valid),
    .qdr1_cmd_ack   (qdr1_cmd_ack),
    .qdr1_cmd_rnw   (qdr1_cmd_rnw),
    .qdr1_cmd_addr  (qdr1_cmd_addr),
    .qdr1_wr_data   (qdr1_wr_data),
    .qdr1_wr_be     (qdr1_wr_be),
    .qdr1_rd_valid  (qdr1_rd_valid),
    .qdr1_rd_ack    (qdr1_rd_ack),
    .qdr1_rd_data   (qdr1_rd_data),

    /* GPIO */
    .gpio_a    (),
    .gpio_a_oe (),
    .gpio_b    (),
    .gpio_b_oe (), /* TODO: give se gpio to application */

    /* Diff GPIO */
    .diff_gpio_a_n     (diff_gpio_a_n),
    .diff_gpio_a_p     (diff_gpio_a_p),
    .diff_gpio_a_clk_n (diff_gpio_a_clk_n), 
    .diff_gpio_a_clk_p (diff_gpio_a_clk_p), 
    .diff_gpio_b_n     (diff_gpio_b_n),
    .diff_gpio_b_p     (diff_gpio_b_p),
    .diff_gpio_b_clk_n (diff_gpio_b_clk_n), 
    .diff_gpio_b_clk_p (diff_gpio_b_clk_p), 

    /* Misc */
    .led (leddies),
    .irq (app_irq)
  );
  
  // synthesis attribute box_type of roach_app is "user_black_box";
  // synthesis attribute read_cores of roach_app is "No";


`else
  /* tie off various signals */
  assign wb_dat_i[16*(APP_SLI + 1) - 1: 16*APP_SLI] = 16'b0;
  assign wb_ack_i[APP_SLI] = 1'b0;

  assign tge_usr_clk[0]         = 1'b0;
  assign tge_usr_rst[0]         = 1'b0;
  assign tge_tx_valid[0]        = 1'b0;
  assign tge_tx_end_of_frame[0] = 1'b0;
  assign tge_tx_discard[0]      = 1'b0;
  assign tge_tx_data[0]         = 64'b0; 
  assign tge_tx_dest_ip[0]      = 32'b0;
  assign tge_tx_dest_port[0]    = 16'b0;
  assign tge_rx_ack[0]          = 1'b0;

  assign tge_usr_clk[1]         = 1'b0;
  assign tge_usr_rst[1]         = 1'b0;
  assign tge_tx_valid[1]        = 1'b0;
  assign tge_tx_end_of_frame[1] = 1'b0;
  assign tge_tx_discard[1]      = 1'b0;
  assign tge_tx_data[1]         = 64'b0; 
  assign tge_tx_dest_ip[1]      = 32'b0;
  assign tge_tx_dest_port[1]    = 16'b0;
  assign tge_rx_ack[1]          = 1'b0;

  assign tge_usr_clk[2]         = 1'b0;
  assign tge_usr_rst[2]         = 1'b0;
  assign tge_tx_valid[2]        = 1'b0;
  assign tge_tx_end_of_frame[2] = 1'b0;
  assign tge_tx_discard[2]      = 1'b0;
  assign tge_tx_data[2]         = 64'b0; 
  assign tge_tx_dest_ip[2]      = 32'b0;
  assign tge_tx_dest_port[2]    = 16'b0;
  assign tge_rx_ack[2]          = 1'b0;

  assign tge_usr_clk[3]         = 1'b0;
  assign tge_usr_rst[3]         = 1'b0;
  assign tge_tx_valid[3]        = 1'b0;
  assign tge_tx_end_of_frame[3] = 1'b0;
  assign tge_tx_discard[3]      = 1'b0;
  assign tge_tx_data[3]         = 64'b0; 
  assign tge_tx_dest_ip[3]      = 32'b0;
  assign tge_tx_dest_port[3]    = 16'b0;
  assign tge_rx_ack[3]          = 1'b0;

  assign dram_cmd_valid = 1'b0;
  assign dram_cmd_rnw   = 1'b0;
  assign dram_cmd_addr  = 32'b0;
  assign dram_cmd_tag   = 32'b0;
  assign dram_wr_data   = {144*`DRAM_WIDTH_MULTIPLIER{1'b0}};
  assign dram_wr_be     = { 18*`DRAM_WIDTH_MULTIPLIER{1'b0}};

  assign qdr0_cmd_valid = 1'b0;
  assign qdr0_cmd_rnw   = 1'b0;
  assign qdr0_cmd_addr  = 32'b0;
  assign qdr0_wr_data   = {36*`QDR0_WIDTH_MULTIPLIER{1'b0}};
  assign qdr0_wr_be     = { 4*`QDR0_WIDTH_MULTIPLIER{1'b0}};
  assign qdr0_rd_ack    = 1'b0;

  assign qdr1_cmd_valid = 1'b0;
  assign qdr1_cmd_rnw   = 1'b0;
  assign qdr1_cmd_addr  = 32'b0;
  assign qdr1_wr_data   = {36*`QDR1_WIDTH_MULTIPLIER{1'b0}};
  assign qdr1_wr_be     = { 4*`QDR1_WIDTH_MULTIPLIER{1'b0}};
  assign qdr1_rd_ack    = 1'b0;

`endif


/********************* Incomplete WB Slaves *******************/
  /* Other Slave assignments */


  assign wb_dat_i[16*(BLOCKRAM_SLI + 1) - 1: 16*BLOCKRAM_SLI] = 16'b0;
  assign wb_ack_i[BLOCKRAM_SLI] = 1'b0;


  assign wb_dat_i[16*(RSRVD1_SLI + 1) - 1: 16*RSRVD1_SLI] = 16'b0;
  assign wb_ack_i[RSRVD1_SLI] = 1'b0;

  assign wb_dat_i[16*(TESTING_SLI + 1) - 1: 16*TESTING_SLI] = 16'b0;
  assign wb_ack_i[TESTING_SLI] = 1'b0;

  /************************* LEDs ************************/

  assign led_n = ~{4'b1001};
  //assign led_n = ~{qdr0_phy_rdy, qdr1_phy_rdy, qdr0_cal_fail, qdr1_cal_fail};

endmodule
