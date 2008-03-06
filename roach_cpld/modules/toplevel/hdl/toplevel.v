module toplevel(
    /* primary clock inputs */
    clk_master, clk_aux,
    /* clock configuration bits */
    clk_master_sel, clk_aux_en,
    /* reset inputs */
    reset_por_n, reset_mon, reset_debug_n,
    /* reset outputs */
    ppc_reset_n, por_force_n, ppc_ddr2_reset_n, geth_reset_n,
    /* mmc interface */
    mmc_clk, mmc_cmd, mmc_data, mmc_wp, mmc_cdetect,
    /* v5 config interface */
    v5c_rdwr_n, v5c_din, v5c_dout_busy, v5c_cs_n, v5c_prog_n,
    v5c_done, v5c_init_n, v5c_mode, v5c_cclk_o, v5c_cclk_en,
    /* PPC epb interface */
    epb_clk, epb_reset_n,
    epb_data, epb_addr,
    epb_cs_n, epb_we_n, epb_be_n, epb_oen_n,
    /* PPC misc signals */
    ppc_tmr_clk, ppc_syserr, ppc_gpio,
    /* system configuration inputs */
    sys_config, user_dip, config_dip,
    /* system configuration outputs */
    boot_conf, boot_conf_oen,
    eeprom_0_wp, eeprom_1_wp,
    /* system status outputs */
    sys_led, user_led,
    /* flash memory bits */
    flash_wp_n, flash_busy_n,
    /* temp sense address bit */
    tempsense_addr
  );
  input  clk_master, clk_aux;
  output clk_master_sel, clk_aux_en;

  input  reset_por_n, reset_mon, reset_debug_n;
  output ppc_reset_n, por_force_n, ppc_ddr2_reset_n, geth_reset_n;

  output mmc_clk;
  inout  mmc_cmd;
  inout  [7:0] mmc_data;
  input  mmc_wp, mmc_cdetect;

  output [2:0] v5c_mode;
  output v5c_prog_n, v5c_cs_n, v5c_rdwr_n;
  input  v5c_done, v5c_init_n;

  output v5c_din;
  input  v5c_dout_busy;
  
  output v5c_cclk_o, v5c_cclk_en;

  output epb_clk, epb_reset_n;
  inout  [7:0] epb_data;
  input  [4:0] epb_addr;
  input  epb_cs_n, epb_we_n, epb_be_n, epb_oen_n;

  output ppc_tmr_clk;
  input  ppc_syserr;
  inout  ppc_gpio;

  input  [7:0] sys_config;
  input  [3:0] user_dip;
  input  [3:0] config_dip;
  
  output [2:0] boot_conf;
  output boot_conf_oen;
  output eeprom_0_wp, eeprom_1_wp;

  output [1:0] sys_led;
  output [1:0] user_led;

  output flash_wp_n;
  input  flash_busy_n;

  output tempsense_addr;

  /************** Fixed Assignments **************/

  assign clk_master_sel = 1'b1;
  assign clk_aux_en     = 1'b1;

  assign tempsense_addr = 1'b0;

  mmc_ro mmc_ro(
    .clk(clk_master), .reset(reset_por_n),
    .mmc_clk(mmc_clk),
    .mmc_cmd_o(ppc_tmr_clk), .mmc_cmd_i(ppc_syserr), .mmc_cmd_oen(flash_wp_n),
    .mmc_data_i(mmc_data),
    .user_data_o(epb_data), .user_data_strb(v5c_din),
    .user_rdy(epb_cs_n)
  );

endmodule
