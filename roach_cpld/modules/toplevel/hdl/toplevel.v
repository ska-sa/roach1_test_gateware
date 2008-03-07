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
    v5c_done, v5c_init_n, v5c_mode, v5c_cclk_o, v5c_cclk_en_n,
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
  input  v5c_done;
  inout  v5c_init_n;
  output v5c_din;
  input  v5c_dout_busy;
  output v5c_cclk_o, v5c_cclk_en_n;

  input  epb_clk, epb_reset_n;
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
  
  /**************** Common Signals ***************/
  wire prog_serial; //the serial program interface is busy
  wire serial_abort; //signal that stops the serial config stream

  /* System Configuration Bits */
  wire serial_boot_enable;    //'boot' v5 off mmc
  wire [1:0] serial_boot_sel; //select which image to boot off mmc

  wire gig_eth_reset_n;

  wire [1:0] user_led_misc;

  /************** Fixed Assignments **************/

  assign clk_master_sel = 1'b1;
  assign clk_aux_en     = 1'b1;
  assign tempsense_addr = 1'b0;

  assign ppc_tmr_clk = clk_aux;

  assign sys_led = {ppc_syserr, reset_por_n};

  assign ppc_reset_n = reset_debug_n | reset_por_n;
  assign ppc_ddr2_reset_n = reset_debug_n;
  assign geth_reset_n = (gig_eth_reset_n & reset_debug_n);
  assign ppc_gpio = flash_busy_n;

  /************** System Configuration Decode **************/

  assign boot_conf    = user_dip[2:0];
  assign eeprom_0_wp = user_dip[3];
  assign eeprom_1_wp = user_dip[3];
  assign flash_wp_n  = user_dip[3];

  assign serial_boot_enable = config_dip[0];
  assign serial_boot_sel    = config_dip[2:1];

  assign user_led = config_dip[2] ? user_led_misc : {~reset_por_n | ~epb_reset_n, v5c_done}; 


  /************** PPC External Perihperal Bus **************/
  wire [7:0] epb_data_i;
  wire [7:0] epb_data_o;

  epb_infrastructure epb_infrastructure_inst(
    .epb_data(epb_data),
    .epb_data_i(epb_data_o), .epb_data_o(epb_data_i),
    .epb_oen(~epb_oen_n)
  );

  wire lb_clk, lb_rst;
  wire lb_we_o;
  wire lb_stb_o_0, lb_stb_o_1, lb_stb_o_2;
  wire [4:0] lb_adr_o;
  wire [7:0] lb_dat_o;
  wire [7:0] lb_dat_i_0;
  wire [7:0] lb_dat_i_1;
  wire [7:0] lb_dat_i_2;

  assign lb_clk = epb_clk;
  assign lb_rst = ~reset_por_n | ~epb_reset_n;

  assign lb_we_o = ~epb_we_n;
  assign lb_stb_o_0 = ~epb_be_n & ~epb_cs_n & lb_adr_o[4:3] == 2'b00;
  assign lb_stb_o_1 = ~epb_be_n & ~epb_cs_n & lb_adr_o[4:3] == 2'b01;
  assign lb_stb_o_2 = ~epb_be_n & ~epb_cs_n & lb_adr_o[4:3] == 2'b10;

  assign lb_adr_o = epb_addr[2:0];
  assign lb_dat_o = epb_data_i;

  assign epb_data_o = epb_addr[4:3] == 2'b00 ? lb_dat_i_0 :
                      epb_addr[4:3] == 2'b01 ? lb_dat_i_1 :
                      epb_addr[4:3] == 2'b10 ? lb_dat_i_2 :
                                               16'b0;

  /************** MMC Interfaces **************/

  wire mmc_cmd_o, mmc_cmd_i, mmc_cmd_oen;
  wire [7:0] mmc_data_o;
  wire [7:0] mmc_data_i;
  wire mmc_data_oen;

  wire mmc_clk_0, mmc_clk_1;
  wire mmc_cmd_o_0, mmc_cmd_o_1;
  wire mmc_cmd_oen_0, mmc_cmd_oen_1;

  assign mmc_clk      = prog_serial ? mmc_clk_0      : mmc_clk_1;
  assign mmc_cmd_o    = prog_serial ? mmc_cmd_o_0    : mmc_cmd_o_1;
  assign mmc_cmd_oen  = prog_serial ? mmc_cmd_oen_0  : mmc_cmd_oen_1;

  wire [7:0] user_data;
  wire user_data_strb;
  wire user_rdy;

  mmc_infrastructure mmc_infrastructure_inst(
    .mmc_cmd(mmc_cmd), .mmc_data(mmc_data),
    .mmc_cmd_i(mmc_cmd_o), .mmc_cmd_o(mmc_cmd_i), .mmc_cmd_oen(mmc_cmd_oen),
    .mmc_data_i(mmc_data_o), .mmc_data_o(mmc_data_i), .mmc_data_oen(mmc_data_oen)
  );

  mmc_ro mmc_ro_inst(
    .clk(clk_master), .reset(reset_por_n),
    .mmc_clk(mmc_clk_0),
    .mmc_cmd_o(mmc_cmd_o_0), .mmc_cmd_i(mmc_cmd_i), .mmc_cmd_oen(mmc_cmd_oen_0),
    .mmc_data_i(mmc_data_i),
    .user_data_o(user_data), .user_data_strb(user_data_strb),
    .user_rdy(user_rdy),
    .boot_sel(serial_boot_sel)
  );

  mmc_bb mmc_bb_inst(
    .lb_clk(lb_clk), .lb_rst(lb_rst),
    .lb_we_i(lb_we_o), .lb_stb_i(lb_stb_o_0),
    .lb_adr_i(lb_adr_o[2:0]), .lb_dat_i(lb_dat_o), .lb_dat_o(lb_dat_i_0),
    .mmc_clk(mmc_clk_1),
    .mmc_cmd_o(mmc_cmd_o_1), .mmc_cmd_i(mmc_cmd_i), .mmc_cmd_oen(mmc_cmd_oen_1),
    .mmc_data_i(mmc_data_i), .mmc_data_o(mmc_data_o), .mmc_data_oen(mmc_data_oen),
    .mmc_cdetect(mmc_cdetect), .mmc_wp(mmc_wp)
  );

  /************** V5 Config Interfaces ******************/

  wire v5c_init_n_o;
  wire v5c_init_n_oen;
  wire v5c_init_n_i;

  wire v5c_cclk_o_int;
  wire v5c_cclk_oen;

  assign v5c_cclk_oen = prog_serial;
  assign v5c_cclk_en_n = ~v5c_cclk_oen;


  v5c_infrastructure v5c_infrastructure_inst (
    .v5c_init_n(v5c_init_n),
    .v5c_init_n_i(v5c_init_n_o), .v5c_init_n_o(v5c_init_n_i), .v5c_init_n_oen(v5c_init_n_oen), 
    .v5c_cclk(v5c_cclk_o),
    .v5c_cclk_i(v5c_cclk_o_int), .v5c_cclk_oen(v5c_cclk_oen)
  );

  wire [2:0] v5c_mode_0;
  wire [2:0] v5c_mode_1;

  wire v5c_prog_n_0;
  wire v5c_prog_n_1;

  wire v5c_init_n_o_0;
  wire v5c_init_n_o_1;
  wire v5c_init_n_oen_1;

  assign v5c_mode       = prog_serial ? v5c_mode_0     : v5c_mode_1;
  assign v5c_prog_n     = prog_serial ? v5c_prog_n_0   : v5c_prog_n_1;  
  assign v5c_init_n_o   = prog_serial ? v5c_init_n_o_0 : v5c_init_n_o_1;  
  assign v5c_init_n_oen = prog_serial ? 1'b1           : v5c_init_n_oen_1;  

  v5c_serial v5c_serial_inst (
    .clk(clk_master), .reset(reset_por_n),
    .serial_boot_enable(serial_boot_enable),
    .serial_boot_busy(prog_serial),
    .user_data(user_data), .user_data_strb(user_data_strb),
    .user_rdy(user_rdy),
    .v5c_mode(v5c_mode_0),
    .v5c_prog_n(v5c_prog_n_0), .v5c_init_n(v5c_init_n_o_0), .v5c_done(v5c_done),
    .v5c_din(v5c_din), .v5c_cclk(v5c_cclk_o_int),
    .abort(serial_abort)
  );

  v5c_sm v5c_sm_inst (
    .lb_clk(lb_clk), .lb_rst(lb_rst),
    .lb_we_i(lb_we_o), .lb_stb_i(lb_stb_o_1),
    .lb_adr_i(lb_adr_o[2:0]), .lb_dat_i(lb_dat_o), .lb_dat_o(lb_dat_i_1),

    .v5c_rdwr_n(v5c_rdwr_n), .v5c_cs_n(v5c_cs_n), .v5c_prog_n(v5c_prog_n_1),
    .v5c_done(v5c_done), .v5c_busy(v5c_dout_busy),
    .v5c_init_n_i(v5c_init_n_i), .v5c_init_n_o(v5c_init_n_o_1), .v5c_init_n_oen(v5c_init_n_oen_1),
    .v5c_mode(v5c_mode_1),

    .sm_busy(prog_serial)
  );

  /********************** Misc IO ***********************/

  misc misc_inst(
    .lb_clk(lb_clk), .lb_rst(lb_rst),
    .lb_we_i(lb_we_o), .lb_stb_i(lb_stb_o_2),
    .lb_adr_i(lb_adr_o[2:0]), .lb_dat_i(lb_dat_o), .lb_dat_o(lb_dat_i_2),
    
    .por_force_n(por_force_n), .reset_mon(reset_mon), .gig_eth_reset_n(gig_eth_reset_n),
    .sys_config(sys_config), .user_dip(user_dip), .config_dip(config_dip),
    .boot_conf_oen(boot_conf_oen),
    .user_led(user_led_misc),

    .eeprom_0_wp(eeprom_0_wp), .eeprom_1_wp(eeprom_1_wp), .flash_wp_n(flash_wp_n), .flash_busy_n(flash_busy_n),
    .serial_busy(prog_serial), .serial_abort(serial_abort)
  );

endmodule
