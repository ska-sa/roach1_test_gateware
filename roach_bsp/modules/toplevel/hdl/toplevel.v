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
  input   ddr2_par_in;
  output  ddr2_par_out;
  
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

endmodule
