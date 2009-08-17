`include "parameters.v"
`include "build_parameters.v"

module toplevel(
    /* primary clock inputs */
    clk_master, clk_aux,
    /* clock configuration bits */
    clk_master_sel, clk_aux_en,
    /* reset inputs */
    reset_por_n, reset_debug_n,
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
    epb_cs_n, epb_we_n, epb_be_n, epb_oe_n,
    epb_rdy,
    /* PPC misc signals */
    ppc_tmr_clk, ppc_syserr, ppc_sm_cs_n, ppc_irq_n,
    /* system configuration inputs */
    sys_config, user_dip, config_dip,
    /* system configuration outputs */
    boot_conf, boot_conf_en_n,
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

  input  reset_por_n, reset_debug_n;
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
  input  epb_cs_n, epb_we_n, epb_be_n, epb_oe_n;
  output epb_rdy;

  output ppc_tmr_clk;
  input  ppc_syserr;
  input  ppc_sm_cs_n;
  output ppc_irq_n;

  input  [7:0] sys_config;
  input  [3:0] user_dip;
  input  [3:0] config_dip;
  
  output [2:0] boot_conf;
  output boot_conf_en_n;
  output eeprom_0_wp, eeprom_1_wp;

  output [1:0] sys_led_n;
  output [1:0] user_led_n;

  output flash_wp_n;
  input  flash_busy_n;

  output tempsense_addr;

  /************************ Resets ****************************/

  //common signals
  wire sys_reset = !(reset_por_n);
  /* system wide reset */

  wire por_force;      //power-on-reset force signal tied to a register
  wire por_force_int;  //power-on-reset force signal on master clk domain
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

  OBUFE sys_led_buf[1:0] (
    .E({v5c_done, ppc_syserr}), .I(1'b0), .O(sys_led_n)
  );
  
  OBUFE user_led_buf[1:0] (
    .E(user_led_int), .I(1'b0), .O(user_led_n)
  );

  /******************* Fixed Assignments **********************/

  assign clk_aux_en     = 1'b1;
  assign clk_master_sel = 1'b1;
  assign tempsense_addr = 1'b0;
  assign ppc_tmr_clk    = clk_aux;
  
`ifdef BOOT_CONF_EEPROM
  assign boot_conf    = 3'b111;//i2c boot: eeprom address 0xa4
`elsif BOOT_CONF_FAST
  assign boot_conf    = 3'b010;
`else //default config
  assign boot_conf    = !config_dip[1] ? 3'b001 :
                        !config_dip[0] ? 3'b010 :
                         sys_config[1] ? 3'b111 :
                                         3'b010;
`endif
  assign boot_conf_en_n = 1'b0;

  assign eeprom_0_wp = !user_dip[3];
  assign eeprom_1_wp = !user_dip[3];
  assign flash_wp_n  = 1'b1;

  /**************** PPC External Perihperal Bus ****************/
  wire [7:0] epb_data_i;
  wire [7:0] epb_data_o;

  wire epb_data_oe;
  wire epb_rdy_oe;
  wire epb_rdy_o;

  epb_infrastructure epb_infrastructure_inst(
    /* External Signals */
    .epb_data     (epb_data),
    .epb_rdy      (epb_rdy),

    /* Internal Signals */
    .epb_data_i  (epb_data_o),
    .epb_data_o  (epb_data_i),
    .epb_data_oe (epb_data_oe),
    .epb_rdy_oe  (epb_rdy_oe),
    .epb_rdy_i   (epb_rdy_o)
  /* TODO: why the 'f' are the slew rates so bad ^^^^^^ */
  );
  
  wire wb_stb_o;
  wire wb_we_o,  wb_sel_o;
  wire [4:0] wb_adr_o;
  wire [7:0] wb_dat_o;
  wire [7:0] wb_dat_i;
  wire wb_ack_i;
  wire wb_clk_i = epb_clk;
  //synthesis attribute BUFG of epb_clk is CLK
  wire wb_rst_i = 1'b0;

  epb_wb_bridge epb_wb_bridge_inst (
    .clk   (wb_clk_i),
    .reset (wb_rst_i),

    .epb_cs_n    (epb_cs_n),
    .epb_oe_n    (epb_oe_n),
    .epb_we_n    (epb_we_n),
    .epb_be_n    (epb_be_n),
    .epb_addr    (epb_addr),
    .epb_data_i  (epb_data_i),
    .epb_data_o  (epb_data_o),
    .epb_data_oe (epb_data_oe),
    .epb_rdy_o   (epb_rdy_o),
    .epb_rdy_oe  (epb_rdy_oe),

    .wb_cyc_o (),
    .wb_stb_o (wb_stb_o),
    .wb_we_o  (wb_we_o),
    .wb_sel_o (wb_sel_o),
    .wb_adr_o (wb_adr_o),
    .wb_dat_o (wb_dat_o),
    .wb_dat_i (wb_dat_i),
    .wb_ack_i (wb_ack_i)
  );

  /* V basic wishbone arbitration */
  wire wb_stb_o_0 = wb_stb_o && wb_adr_o[4:3] == 2'b00;
  wire wb_stb_o_1 = wb_stb_o && wb_adr_o[4:3] == 2'b01;
  wire wb_stb_o_2 = wb_stb_o && wb_adr_o[4:3] == 2'b10;
  wire wb_stb_o_3 = wb_stb_o && wb_adr_o[4:3] == 2'b11;

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

  wire [3:0] irq_src;

  wire ppc_irq;
  system_block #(
    .DESIGN_ID (`DESIGN_ID),
    .REV_MAJOR (`REV_MAJOR),
    .REV_MINOR (`REV_MINOR),
    .REV_RCS   (`REV_RCS)
  ) system_block (
    .wb_clk_i (wb_clk_i),
    .wb_rst_i (wb_rst_i),
    .wb_stb_i (wb_stb_o_3),
    .wb_cyc_i (wb_cyc_o_3),
    .wb_we_i  (wb_we_o),
    .wb_adr_i (wb_adr_o_3),
    .wb_dat_i (wb_dat_o),
    .wb_dat_o (wb_dat_i_3),
    .wb_ack_o (wb_ack_i_3),
    .irq_src  (irq_src),
    .irq      (ppc_irq)
  );
  assign ppc_irq_n = !ppc_irq;
  
  /*************************** Misc Registers ****************************/

  misc misc_inst(
    .wb_clk_i (wb_clk_i),
    .wb_rst_i (wb_rst_i),
    .wb_stb_i (wb_stb_o_0),
    .wb_cyc_i (wb_cyc_o_0),
    .wb_we_i  (wb_we_o),
    .wb_adr_i (wb_adr_o_0),
    .wb_dat_i (wb_dat_o),
    .wb_dat_o (wb_dat_i_0),
    .wb_ack_o (wb_ack_i_0),
    
    .por_force    (por_force),
    .geth_reset   (geth_reset_int),
    .sys_config   (sys_config),
    .user_dip     (user_dip),
    .config_dip   (config_dip),
    .user_led     (user_led_int),
    .flash_busy_n (flash_busy_n),
    .mmc_wp       (mmc_wp),
    .mmc_cdetect  (mmc_cdetect)
  );

  /********************** V5 config/SelectMap ****************************/

  wire v5c_init_n_o;
  wire v5c_init_n_oe;
  wire v5c_init_n_i;

  v5c_infrastructure v5c_infrastructure_inst (
    .v5c_init_n    (v5c_init_n),
    .v5c_init_n_i  (v5c_init_n_o),
    .v5c_init_n_o  (v5c_init_n_i),
    .v5c_init_n_oe (v5c_init_n_oe), 

    .v5c_cclk    (v5c_cclk_o),
    .v5c_cclk_i  (wb_clk_i),
    .v5c_cclk_oe (1'b1)
  );

  v5c_sm v5c_sm_inst (
    .wb_clk_i (wb_clk_i),
    .wb_rst_i (wb_rst_i),
    .wb_cyc_i (wb_cyc_o_1),
    .wb_stb_i (wb_stb_o_1),
    .wb_we_i  (wb_we_o),
    .wb_adr_i (wb_adr_o_1),
    .wb_dat_i (wb_dat_o),
    .wb_dat_o (wb_dat_i_1),
    .wb_ack_o (wb_ack_i_1),

    .sm_cs_n (ppc_sm_cs_n),

    .v5c_rdwr_n    (v5c_rdwr_n),
    .v5c_cs_n      (v5c_cs_n),
    .v5c_prog_n    (v5c_prog_n),
    .v5c_done      (v5c_done),
    .v5c_busy      (v5c_dout_busy),
    .v5c_init_n_i  (v5c_init_n_i),
    .v5c_init_n_o  (v5c_init_n_o),
    .v5c_init_n_oe (v5c_init_n_oe),
    .v5c_mode      (v5c_mode)
  );
  assign v5c_cclk_en_n = 1'b1;

  /************** MMC Interfaces **************/

  wire mmc_cmd_o, mmc_cmd_i, mmc_cmd_oe;
  wire [7:0] mmc_data_o;
  wire [7:0] mmc_data_i;
  wire mmc_data_oe;

  mmc_infrastructure mmc_infrastructure_inst(
    /* external signals */
    .mmc_cmd     (mmc_cmd),
    .mmc_data    (mmc_data),
    /* internal signals */
    .mmc_cmd_i   (mmc_cmd_o),
    .mmc_cmd_o   (mmc_cmd_i),
    .mmc_cmd_oe  (mmc_cmd_oe),
    .mmc_data_i  (mmc_data_o),
    .mmc_data_o  (mmc_data_i),
    .mmc_data_oe (mmc_data_oe)
  );

  mmc_controller mmc_controller (
    .wb_clk_i (wb_clk_i),
    .wb_rst_i (wb_rst_i),
    .wb_cyc_i (wb_cyc_o_2),
    .wb_stb_i (wb_stb_o_2),
    .wb_we_i  (wb_we_o),
    .wb_adr_i (wb_adr_o_2),
    .wb_dat_i (wb_dat_o),
    .wb_dat_o (wb_dat_i_2),
    .wb_ack_o (wb_ack_i_2),

    .mmc_clk     (mmc_clk),
    .mmc_cmd_o   (mmc_cmd_o),
    .mmc_cmd_i   (mmc_cmd_i),
    .mmc_cmd_oe  (mmc_cmd_oe),
    .mmc_dat_i   (mmc_data_i),
    .mmc_dat_o   (mmc_data_o),
    .mmc_dat_oe  (mmc_data_oe),
    .mmc_cdetect (mmc_cdetect),
    
    .irq_cdetect  (irq_src[0]),
    .irq_got_cmd  (irq_src[2]),
    .irq_got_dat  (irq_src[3]),
    .irq_got_busy (irq_src[1])
  );

endmodule
