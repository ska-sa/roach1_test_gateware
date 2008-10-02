`include "parameters.v"
`include "build_parameters.v"

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
    ppc_tmr_clk, ppc_syserr, ppc_sm_cs_n,
    /* system configuration inputs */
    sys_config, user_dip, config_dip,
    /* system configuration outputs */
    boot_conf, boot_conf_en,
    eeprom_0_wp, eeprom_1_wp,
    /* system status outputs */
    sys_led_n, user_led_n,
    /* flash memory bits */
    flash_wp_n, flash_busy_n,
    /* temp sense address bit */
    tempsense_addr
  );
  input  clk_master, clk_aux;
  output clk_master_sel, clk_aux_en;

  input  reset_por_n, reset_mon, reset_debug_n;
  output ppc_reset_n, ppc_ddr2_reset_n, geth_reset_n;
  inout  por_force_n;

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
  input  ppc_sm_cs_n;

  input  [7:0] sys_config;
  input  [3:0] user_dip;
  input  [3:0] config_dip;
  
  output [2:0] boot_conf;
  output boot_conf_en;
  output eeprom_0_wp, eeprom_1_wp;

  output [1:0] sys_led_n;
  output [1:0] user_led_n;

  output flash_wp_n;
  input  flash_busy_n;

  output tempsense_addr;

  /************************ Resets ****************************/
  //common signals
  wire por_force;      //power-on-reset force signal tied to a register
  wire por_force_int;  //power-on-reset force signal on master clk domain
  wire sys_reset = !(reset_por_n && !reset_mon);
  wire geth_reset_int; //gigabit ethernet reset tied to a register

  //output assignments
  assign ppc_reset_n      = reset_debug_n && !sys_reset;
  assign ppc_ddr2_reset_n = !sys_reset;
  assign geth_reset_n     = !sys_reset && !geth_reset_int;

  /* Tri-state control for por_force_n output */
  OBUFT por_force_obuft(
    .T(!por_force_int), .I(1'b0), .O(por_force_n)
  );

  reg prev_por_force;
  reg por_force_sys;
  assign por_force_int = por_force_sys;

  always @(posedge clk_master) begin
    prev_por_force <= por_force;
    if (sys_reset) begin
      por_force_sys <= 1'b0;
    end else if (!por_force_sys) begin
      por_force_sys <= por_force && prev_por_force != por_force;
    end
  end

  /************************* LEDs *****************************/

  wire [1:0] user_led_int;

  reg [25:0] counter [1:0];

  always @(posedge clk_master) begin
    if (reset_mon) begin
      counter[0] <= 26'b0;
    end else begin
      counter[0] <= counter[0] + 1;
    end
  end

  always @(posedge epb_clk) begin
    if (reset_mon) begin
      counter[1] <= 26'b0;
    end else begin
      counter[1] <= counter[1] + 1;
    end
  end

  assign sys_led_n  = ~{!flash_busy_n, ppc_syserr ? counter[0][23] : v5c_done};
  
  assign user_led_n = ~user_led_int;


  /******************* Fixed Assignments **********************/

  assign clk_aux_en     = 1'b1;
  assign clk_master_sel = 1'b1;
  assign tempsense_addr = 1'b0; //TODO: check this
  assign ppc_tmr_clk    = clk_aux;
  
`ifdef BOOT_CONF_EEPROM
  assign boot_conf    = 3'b111;//i2c boot: eeprom address 0xa4
`elsif BOOT_CONF_FAST
  assign boot_conf    = 3'b010;
`else //default config
  assign boot_conf    =     !conf_dip[0] ? 3'b010 :
                        system_config[1] ? 3'b111 :
                                           3'b010;
`endif
  assign boot_conf_en = 1'b1;

  wire eeprom_0_wp_int, eeprom_1_wp_int, flash_wp_int;

  //assign eeprom_0_wp = user_dip[3] | eeprom_0_wp_int;
  assign eeprom_0_wp = !user_dip[3];
  //assign eeprom_1_wp = user_dip[3] | eeprom_1_wp_int;
  assign eeprom_1_wp = !user_dip[3];
  //assign flash_wp_n  = 1'b1        & !flash_wp_int;
  assign flash_wp_n  = 1'b1;

  //TODO: this must change to something more sensible

  // Signals for controlling the v5 serial configuration at startup
  //wire serial_boot_enable = config_dip[0];
  wire serial_boot_enable = 1'b0;
  wire serial_boot_sel    = config_dip[2:1];
  wire serial_conf_busy, serial_conf_disable;

  /**************** PPC External Perihperal Bus ****************/
  wire [7:0] epb_data_i;
  wire [7:0] epb_data_o;

  wire epb_data_oen;

  epb_infrastructure epb_infrastructure_inst(
    .epb_data  (epb_data),
    .epb_data_i(epb_data_o),
    .epb_data_o(epb_data_i),
    .epb_oen   (epb_data_oen)
  );
  
  wire wb_stb_o, wb_cyc_o;
  wire wb_we_o,  wb_sel_o;
  wire [4:0] wb_adr_o;
  wire [7:0] wb_dat_o;
  wire [7:0] wb_dat_i;
  wire wb_ack_i;
  wire wb_clk_i = !epb_clk; //hopefully improve timing
  wire wb_rst_i = sys_reset || !epb_reset_n;

  epb_wb_bridge #(
    .TRANS_LENGTH(1)
  ) epb_wb_bridge_inst (
    .clk(wb_clk_i), .reset(wb_rst_i),
    .epb_cs_n(epb_cs_n), .epb_oen_n(epb_oen_n), .epb_we_n(epb_we_n), .epb_be_n(epb_be_n),
    .epb_addr(epb_addr),
    .epb_data_i(epb_data_i), .epb_data_o(epb_data_o), .epb_data_oen(epb_data_oen),
    .wb_cyc_o(wb_cyc_o), .wb_stb_o(wb_stb_o), .wb_we_o(wb_we_o), .wb_sel_o(wb_sel_o),
    .wb_adr_o(wb_adr_o), .wb_dat_o(wb_dat_o), .wb_dat_i(wb_dat_i),
    .wb_ack_i(wb_ack_i)
  );

  /* V basic wishbone arbitration */
  wire wb_stb_o_0 = wb_stb_o & wb_adr_o[4:3] == 2'b00;
  wire wb_stb_o_1 = wb_stb_o & wb_adr_o[4:3] == 2'b01;
  wire wb_stb_o_2 = wb_stb_o & wb_adr_o[4:3] == 2'b10;
  wire wb_stb_o_3 = wb_stb_o & wb_adr_o[4:3] == 2'b11;

  wire wb_cyc_o_0 = wb_stb_o_0;
  wire wb_cyc_o_1 = wb_stb_o_1;
  wire wb_cyc_o_2 = wb_stb_o_2;
  wire wb_cyc_o_3 = wb_stb_o_3;

  wire [2:0] wb_adr_o_0 = wb_adr_o[2:0];
  wire [2:0] wb_adr_o_1 = wb_adr_o[2:0];
  wire [2:0] wb_adr_o_2 = wb_adr_o[2:0];
  wire [2:0] wb_adr_o_3 = wb_adr_o[2:0];

  wire [7:0] wb_dat_i_0;
  wire [7:0] wb_dat_i_1;
  wire [7:0] wb_dat_i_2;
  wire [7:0] wb_dat_i_3;

  assign wb_dat_i = wb_adr_o[4:3] == 2'b00 ? wb_dat_i_0 :
                    wb_adr_o[4:3] == 2'b01 ? wb_dat_i_1 :
                    wb_adr_o[4:3] == 2'b10 ? wb_dat_i_2 :
                    wb_adr_o[4:3] == 2'b11 ? wb_dat_i_3 :
                                             16'b0;
  wire wb_ack_i_0;
  wire wb_ack_i_1;
  wire wb_ack_i_2;
  wire wb_ack_i_3;
  assign wb_ack_i = wb_ack_i_3 | wb_ack_i_2 | wb_ack_i_1 | wb_ack_i_0;

  /*********************** Revision Control Info *************************/
  
  wire [15:0] rev_id  = `DESIGN_ID;
  wire  [7:0] rev_maj = `REV_MAJOR;
  wire  [7:0] rev_min = `REV_MINOR;
  wire [15:0] rev_rcs = `REV_RCS;

  assign wb_ack_i_3 = 1'b1; //as if it matters

  assign wb_dat_i_3 = wb_adr_o_3[2:0] == 3'b000 ? rev_id [15:8] :
                      wb_adr_o_3[2:0] == 3'b001 ? rev_id [ 7:0] :
                      wb_adr_o_3[2:0] == 3'b010 ? rev_maj[ 7:0] :
                      wb_adr_o_3[2:0] == 3'b011 ? rev_min[ 7:0] :
                      wb_adr_o_3[2:0] == 3'b100 ? rev_rcs[15:8] :
                      wb_adr_o_3[2:0] == 3'b101 ? rev_rcs[ 7:0] :
                      8'b0;

  /*************************** Misc Registers ****************************/

  misc misc_inst(
    .wb_clk_i(wb_clk_i),   .wb_rst_i(wb_rst_i),
    .wb_stb_i(wb_stb_o_0), .wb_cyc_i(wb_cyc_o_0), .wb_we_i (wb_we_o),
    .wb_adr_i(wb_adr_o_0),   .wb_dat_i(wb_dat_o),   .wb_dat_o(wb_dat_i_0),
    .wb_ack_o(wb_ack_i_0),
    
    .por_force(por_force),
    .geth_reset(geth_reset_int),
    .sys_config(sys_config),
    .user_dip(user_dip),
    .config_dip(config_dip),
    .user_led(user_led_int),

    .eeprom_0_wp(eeprom_0_wp_int),
    .eeprom_1_wp(eeprom_1_wp_int),
    .flash_wp   (flash_wp_int),
    .flash_busy (!flash_busy_n),
    .serial_conf_busy(serial_conf_busy), .serial_conf_disable(serial_conf_disable)
  );

  /********************** V5 config/SelectMap ****************************/

  wire v5c_init_n_o;
  wire v5c_init_n_oen;
  wire v5c_init_n_i;

  wire v5c_cclk_o_int;
  wire v5c_cclk_o_int_0;
  wire v5c_cclk_o_int_1;
  wire v5c_cclk_oen;

  v5c_infrastructure v5c_infrastructure_inst (
    .v5c_init_n    (v5c_init_n),
    .v5c_init_n_i  (v5c_init_n_o),
    .v5c_init_n_o  (v5c_init_n_i),
    .v5c_init_n_oen(v5c_init_n_oen), 

    .v5c_cclk    (v5c_cclk_o),
    .v5c_cclk_i  (v5c_cclk_o_int),
    .v5c_cclk_oen(v5c_cclk_oen)
  );

  wire [2:0] v5c_mode_0;
  wire [2:0] v5c_mode_1;

  wire v5c_prog_n_0;
  wire v5c_prog_n_1;

  wire v5c_init_n_o_0;
  wire v5c_init_n_o_1;
  wire v5c_init_n_oen_1;

  assign v5c_cclk_oen  = 1'b1;//serial_conf_busy;

  assign v5c_cclk_o_int = serial_conf_busy ? v5c_cclk_o_int_0 : v5c_cclk_o_int_1;
  assign v5c_cclk_o_int_1 = wb_clk_i;
  assign v5c_cclk_en_n  = 1'b1;//serial_conf_busy;
 

  assign v5c_mode = 3'b110;

  assign v5c_prog_n     = serial_conf_busy ? v5c_prog_n_0   : v5c_prog_n_1;  
  assign v5c_init_n_o   = serial_conf_busy ? v5c_init_n_o_0 : v5c_init_n_o_1;  
  assign v5c_init_n_oen = serial_conf_busy ? 1'b1           : v5c_init_n_oen_1;  

  // user interface to v5 serial conf module
  wire [7:0] user_data;
  wire user_data_strb;
  wire user_rdy;

  v5c_serial v5c_serial_inst (
    .clk(clk_master), .reset(sys_reset),
    //control ports
    .serial_boot_enable(serial_boot_enable),
    .serial_boot_busy(serial_conf_busy),
    .abort(serial_conf_disable),
    //user interface - connect to mmc
    .user_data(user_data), .user_data_strb(user_data_strb),
    .user_rdy(user_rdy),
    //select map signals
    .v5c_mode(v5c_mode_0),
    .v5c_prog_n(v5c_prog_n_0), .v5c_init_n(v5c_init_n_o_0), .v5c_done(v5c_done),
    .v5c_din(v5c_din), .v5c_cclk(v5c_cclk_o_int_0)
  );

  v5c_sm v5c_sm_inst (
    .wb_clk_i(wb_clk_i), .wb_rst_i(wb_rst_i),
    .wb_cyc_i(wb_cyc_o_1), .wb_stb_i(wb_stb_o_1), .wb_we_i(wb_we_o),
    .wb_adr_i(wb_adr_o_1), .wb_dat_i(wb_dat_o), .wb_dat_o(wb_dat_i_1),
    .wb_ack_o(wb_ack_i_1),

    .epb_clk(epb_clk),
    .sm_cs_n(ppc_sm_cs_n),

    .v5c_rdwr_n(v5c_rdwr_n), .v5c_cs_n(v5c_cs_n), .v5c_prog_n(v5c_prog_n_1),
    .v5c_done(v5c_done), .v5c_busy(v5c_dout_busy),
    .v5c_init_n_i(v5c_init_n_i), .v5c_init_n_o(v5c_init_n_o_1), .v5c_init_n_oen(v5c_init_n_oen_1),
    .v5c_mode(v5c_mode_1),

    .sm_busy(serial_conf_busy)
  );

  /************** MMC Interfaces **************/

  wire mmc_cmd_o, mmc_cmd_i, mmc_cmd_oen;
  wire [7:0] mmc_data_o;
  wire [7:0] mmc_data_i;
  wire mmc_data_oen;

  wire mmc_clk_0, mmc_clk_1;
  wire mmc_cmd_o_0, mmc_cmd_o_1;
  wire mmc_cmd_oen_0, mmc_cmd_oen_1;

  assign mmc_clk      = serial_conf_busy ? mmc_clk_0      : mmc_clk_1;
  assign mmc_cmd_o    = serial_conf_busy ? mmc_cmd_o_0    : mmc_cmd_o_1;
  assign mmc_cmd_oen  = serial_conf_busy ? mmc_cmd_oen_0  : mmc_cmd_oen_1;

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
    .wb_clk_i(wb_clk_i), .wb_rst_i(wb_rst_i),
    .wb_cyc_i(wb_cyc_o_2), .wb_stb_i(wb_stb_o_2), .wb_we_i(wb_we_o),
    .wb_adr_i(wb_adr_o_2), .wb_dat_i(wb_dat_o), .wb_dat_o(wb_dat_i_2),
    .wb_ack_o(wb_ack_i_2),

    .mmc_clk(mmc_clk_1),
    .mmc_cmd_o(mmc_cmd_o_1), .mmc_cmd_i(mmc_cmd_i), .mmc_cmd_oen(mmc_cmd_oen_1),
    .mmc_data_i(mmc_data_i), .mmc_data_o(mmc_data_o), .mmc_data_oen(mmc_data_oen),
    .mmc_cdetect(mmc_cdetect), .mmc_wp(mmc_wp)
  );
  

endmodule
