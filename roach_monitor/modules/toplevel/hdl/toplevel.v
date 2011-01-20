`include "parameters.v"
`include "memlayout.v"
`include "build_parameters.v"

module toplevel(
    /* ATX Power Supply Control */
    ATX_PS_ON_N, ATX_PWR_OK,
    ATX_LOAD_RES_OFF,
    /* Power Supply Control */
    TRACK_2V5,
    INHIBIT_2V5, INHIBIT_1V8, INHIBIT_1V5, INHIBIT_1V2, INHIBIT_1V0,
    MGT_AVCC_EN, MGT_AVTTX_EN, MGT_AVCCPLL_EN,
    MGT_AVCC_PG, MGT_AVTTX_PG, MGT_AVCCPLL_PG,
    AUX_3V3_PG,
    /* XPORT Serial */
    XPORT_SERIAL_IN, XPORT_SERIAL_OUT,
    XPORT_GPIO, XPORT_RESET_N,
    /* Controller Interface */
    CONTROLLER_I2C_SDA, CONTROLLER_I2C_SCL,
    CONTROLLER_IRQ, CONTROLLER_RESET,
    /* Debug Serial Port */
    DEBUG_SERIAL_IN, DEBUG_SERIAL_OUT,
    /*System Configuration*/
    SYS_CONFIG,
    /* Chassis Interface */
    CHS_POWERDOWN_N, CHS_RESET_N,
    CHS_LED_N,
    /* Fan Control */
    FAN1_SENSE,   FAN2_SENSE,   FAN3_SENSE,
    FAN1_CONTROL, FAN2_CONTROL, FAN3_CONTROL,
    /* Analogue Block Interfaces*/
    AG, AV, AC, AT, ATRET,
    /* Fixed Fusion Signals */
    XTLCLK, PUB, VAREF,
    /* GPIO */
    GPIO_OE1,
    GPIO_OE0,
    GPIO,
    GPIO_CC1,
    GPIO_CC0
  );
  output ATX_PS_ON_N;
  input  ATX_PWR_OK;
  output ATX_LOAD_RES_OFF;

  output TRACK_2V5;
  output INHIBIT_2V5, INHIBIT_1V8, INHIBIT_1V5, INHIBIT_1V2, INHIBIT_1V0;
  output MGT_AVCC_EN, MGT_AVTTX_EN, MGT_AVCCPLL_EN;
  input  MGT_AVCC_PG, MGT_AVTTX_PG, MGT_AVCCPLL_PG;
  input  AUX_3V3_PG;

  input  XPORT_SERIAL_IN;
  output XPORT_SERIAL_OUT;
  inout [2:0] XPORT_GPIO;
  output XPORT_RESET_N;

  inout  CONTROLLER_I2C_SDA;
  input  CONTROLLER_I2C_SCL;

  output CONTROLLER_IRQ, CONTROLLER_RESET;

  output [7:0] SYS_CONFIG;

  input  CHS_POWERDOWN_N, CHS_RESET_N;
  output [1:0] CHS_LED_N;

  input  FAN1_SENSE, FAN2_SENSE, FAN3_SENSE;
  output FAN1_CONTROL, FAN2_CONTROL, FAN3_CONTROL;

  input  DEBUG_SERIAL_IN;
  output DEBUG_SERIAL_OUT;

  output [9:0] AG;
  input  [9:0] AV;
  input  [9:0] AC;
  input  [9:0] AT;
  input  [4:0] ATRET;
  
  input  XTLCLK, PUB;
  inout  VAREF;

  inout  GPIO_OE1;
  inout  GPIO_OE0;
  inout  [7:0] GPIO;
  inout  GPIO_CC1;
  inout  GPIO_CC0;

  /*************** Global Nets ***************/

  wire hard_reset;
  wire gclk33;

  wire soft_reset;

  /************ XPORT GPIO Decode ************/
  wire XPORT_SERIAL_CTS;
  wire XPORT_SERIAL_RTS = XPORT_GPIO[0];
  wire RESET_XPORT_N    = XPORT_GPIO[1];
  assign XPORT_GPIO[2]  = XPORT_SERIAL_CTS;


  /*************** Reset Control ****************/

  wire reset_xport;
  reg RESET_XPORT_N_z;
  always @(posedge gclk33) begin
    RESET_XPORT_N_z <= RESET_XPORT_N;
  end
  assign reset_xport = RESET_XPORT_N_z != RESET_XPORT_N;

  wire hard_reset_int;
  wire por_reset;
  assign por_reset = !CHS_RESET_N;

  reset_block #(
    .DELAY(0),
    .WIDTH(32'h200_0000)
  ) reset_block_inst (
    .clk(gclk33),
    .async_reset_i(por_reset),
    .reset_i(reset_xport),
    .reset_o(hard_reset_int)
  );
  assign XPORT_RESET_N = 1'b1;
  assign hard_reset = hard_reset_int;

  /* Debounce chassis switches */
  wire chs_powerdown;

  debouncer #(
    .DELAY(32'h0020_0000)
  ) debouncer_pwr_inst (  
    .clk(gclk33),
    .rst(hard_reset),
    .in_switch(!CHS_POWERDOWN_N), .out_switch(chs_powerdown)
  );

  /******* Chassis Reset (performs soft reset in power manager) ********/
  wire chs_reset_int;
  wire chs_reset_in_switch;

  debouncer #(
    .DELAY(32'h0002_0000)
  ) debouncer_chs_rst_inst (  
    .clk(gclk33),
    .rst(1'b0),
    .in_switch(chs_reset_in_switch), .out_switch(chs_reset_int)
  );

  reg chs_reset_z;
  always @(posedge gclk33) begin
    chs_reset_z <= chs_reset_int;
  end


  wire chs_reset = chs_reset_int && (!chs_reset_z);

  /*********************** Global Infrastructure ************************/
  wire nc_fpgagood;
  wire rtcclk, selmode;
  wire [1:0] rtc_mode;

  wire gclk_xtal;
  infrastructure infrastructure_inst(
    .gclk33    (gclk33),
    .gclk_xtal (gclk_xtal),
    .PUB(PUB), .FPGAGOOD(nc_fpgagood), .XTLCLK(XTLCLK),
    .RTCCLK(rtcclk), .SELMODE(selmode), .RTC_MODE(rtc_mode), .vcc_good(AUX_3V3_PG)
  );

  /********************* WishBone Master signals ***********************/
  wire debug_wb_we_o, debug_wb_cyc_o, debug_wb_stb_o;
  wire [15:0] debug_wb_adr_o;
  wire [15:0] debug_wb_dat_o;
  wire [15:0] debug_wb_dat_i;
  wire debug_wb_ack_i, debug_wb_err_i;

  wire xport_wb_we_o, xport_wb_cyc_o, xport_wb_stb_o;
  wire [15:0] xport_wb_adr_o;
  wire [15:0] xport_wb_dat_o;
  wire [15:0] xport_wb_dat_i;
  wire xport_wb_ack_i, xport_wb_err_i;

  wire controller_wb_we_o, controller_wb_cyc_o, controller_wb_stb_o;
  wire [15:0] controller_wb_adr_o;
  wire [15:0] controller_wb_dat_o;
  wire [15:0] controller_wb_dat_i;
  wire controller_wb_ack_i, controller_wb_err_i;

  wire dma_wb_we_o, dma_wb_cyc_o, dma_wb_stb_o;
  wire [15:0] dma_wb_adr_o;
  wire [15:0] dma_wb_dat_o;
  wire [15:0] dma_wb_dat_i;
  wire dma_wb_ack_i, dma_wb_err_i;

  /********************* Serial Communications Modules ***********************/
  /********* Debug Interface ***********/
`ifdef ENABLE_DEBUG_INTERFACE
   
  wire [7:0] ds_as_data_i;
  wire [7:0] ds_as_data_o;
  wire ds_as_dstrb_i, ds_as_busy_o, ds_as_dstrb_o;

  /* Debug UART */
  serial_uart #(
    .BAUD(`DEBUG_SERIAL_BAUD),
    .CLOCK_RATE(`MASTER_CLOCK_RATE)
  ) serial_uart_debug (
    .clk(gclk33), .reset(hard_reset),
    .serial_in  (DEBUG_SERIAL_IN),   .serial_out(DEBUG_SERIAL_OUT),
    .serial_rts (1'b1),  .serial_cts(),

    /* rx */
    .as_data_i  (ds_as_data_i),
    .as_dstrb_i (ds_as_dstrb_i),
    .as_busy_i  (ds_as_busy_i),

    /* tx */
    .as_data_o  (ds_as_data_o),
    .as_dstrb_o (ds_as_dstrb_o),
    .as_busy_o  (ds_as_busy_o)
  );

  /* Debug WB bridge */
  as_wb_bridge as_wb_bridge_debug(
    .clk(gclk33),
    .reset(hard_reset), 
    .as_data_i  (ds_as_data_o),
    .as_dstrb_i (ds_as_dstrb_o),
    .as_busy_o  (ds_as_busy_i),
    .as_dstrb_o (ds_as_dstrb_i),
    .as_data_o  (ds_as_data_i),
    .as_busy_i  (ds_as_busy_o),
    .wb_we_o  (debug_wb_we_o),  .wb_cyc_o (debug_wb_cyc_o), .wb_stb_o (debug_wb_stb_o),
    .wb_adr_o (debug_wb_adr_o), .wb_dat_o (debug_wb_dat_o), .wb_dat_i (debug_wb_dat_i),
    .wb_ack_i (debug_wb_ack_i), .wb_err_i (debug_wb_err_i)
  );

`else
  assign debug_wb_we_o  = 1'b0;
  assign debug_wb_cyc_o = 1'b0;
  assign debug_wb_stb_o = 1'b0;
  assign debug_wb_adr_o = 16'b0;
  assign debug_wb_dat_o = 16'b0;
  assign DEBUG_SERIAL_OUT = 1'b1; //idle
`endif

  /********* XPORT Interface ***********/
`ifdef ENABLE_XPORT_INTERFACE
  wire [7:0] xp_as_data_i;
  wire [7:0] xp_as_data_o;
  wire xp_as_dstrb_i, xp_as_busy_o, xp_as_dstrb_o;

  /* XPORT UART */
  serial_uart #(
    .BAUD       (`XPORT_SERIAL_BAUD),
    .CLOCK_RATE (`MASTER_CLOCK_RATE)
  ) serial_uart_xport (
    .clk   (gclk33),
    .reset (hard_reset),
    .serial_in  (XPORT_SERIAL_IN),  .serial_out (XPORT_SERIAL_OUT),
    .serial_rts (XPORT_SERIAL_RTS), .serial_cts (XPORT_SERIAL_CTS),
    .as_data_i  (xp_as_data_i),
    .as_dstrb_i (xp_as_dstrb_i),
    .as_busy_o  (xp_as_busy_o),
    .as_data_o  (xp_as_data_o),
    .as_dstrb_o (xp_as_dstrb_o),
    .as_busy_i  (xp_as_busy_i)
  );

  /* XPORT WB bridge */
  as_wb_bridge #(
    .USE_INPUT_FIFO  (0),
    .USE_OUTPUT_FIFO (0)
  ) as_wb_bridge_xport (
    .clk   (gclk33),
    .reset (hard_reset), 

    .as_data_i  (xp_as_data_o),
    .as_dstrb_i (xp_as_dstrb_o),
    .as_busy_o  (xp_as_busy_i),
    .as_data_o  (),
    .as_dstrb_o (),
    .as_data_o  (xp_as_data_i),
    .as_dstrb_o (xp_as_dstrb_i),
    .as_busy_i  (xp_as_busy_o),

    .wb_we_o  (xport_wb_we_o),  .wb_cyc_o (xport_wb_cyc_o), .wb_stb_o (xport_wb_stb_o),
    .wb_adr_o (xport_wb_adr_o), .wb_dat_o (xport_wb_dat_o), .wb_dat_i (xport_wb_dat_i),
    .wb_ack_i (xport_wb_ack_i), .wb_err_i (xport_wb_err_i)
  );
`else
  assign xport_wb_we_o  = 1'b0;
  assign xport_wb_cyc_o = 1'b0;
  assign xport_wb_stb_o = 1'b0;
  assign xport_wb_adr_o = 16'b0;
  assign xport_wb_dat_o = 16'b0;
  assign XPORT_SERIAL_OUT = 1'b0;
  assign XPORT_SERIAL_CTS = 1'b1;
`endif

  /********* Controller Interface ***********/
`ifdef ENABLE_CONTROLLER_INTERFACE
  wire [7:0] ctrl_as_data_i;
  wire [7:0] ctrl_as_data_o;
  wire ctrl_as_dstrb_i, ctrl_as_busy_o, ctrl_as_dstrb_o;

  wire ctrl_scl_i, ctrl_scl_o, ctrl_scl_oen;
  wire ctrl_sda_i, ctrl_sda_o, ctrl_sda_oen;
  /* Controller I2C Infrastructure */
  
  i2c_infrastructure i2c_infrastructure_controller(
    .sda_i(ctrl_sda_i), .sda_o(ctrl_sda_o), .sda_oen(ctrl_sda_oen),
    .scl_i(ctrl_scl_i), .scl_o(ctrl_scl_o), .scl_oen(ctrl_scl_oen),
    .sda_buf(CONTROLLER_I2C_SDA), .scl_buf(CONTROLLER_I2C_SCL)
  );
  

  /* Controller I2C Slave */
  wire nc_i2c_cmnd_strb_o;
  i2c_slave #(
    .FREQ(`I2C_CLOCK_RATE),
    .CLOCK_RATE(`MASTER_CLOCK_RATE),
    .ADDRESS(`I2C_SLAVE_ADDRESS)
  ) i2c_slave_controller (
    .clk(gclk33), .reset(hard_reset),
    .scl_i(ctrl_scl_i), .scl_o(ctrl_scl_o), .scl_oen(ctrl_scl_oen),
    .sda_i(ctrl_sda_i), .sda_o(ctrl_sda_o), .sda_oen(ctrl_sda_oen),
    .as_data_i(ctrl_as_data_i),  .as_data_o(ctrl_as_data_o),
    .as_dstrb_o(ctrl_as_dstrb_o), .as_dstrb_i(ctrl_as_dstrb_i), .as_busy_o(ctrl_as_busy_o),
    .i2c_cmnd_strb_o(nc_i2c_cmnd_strb_o)
  );

  /* Controller (i2c) WB bridge */
  as_wb_bridge #(
    .USE_INPUT_FIFO  (1),
    .USE_OUTPUT_FIFO (1)
  ) as_wb_bridge_controller(
    .clk(gclk33), .reset(hard_reset), 
    .as_data_i(ctrl_as_data_o), .as_data_o(ctrl_as_data_i),
    .as_dstrb_i(ctrl_as_dstrb_o), .as_busy_i(ctrl_as_busy_o), .as_dstrb_o(ctrl_as_dstrb_i),
    .wb_we_o(controller_wb_we_o), .wb_cyc_o(controller_wb_cyc_o), .wb_stb_o(controller_wb_stb_o),
    .wb_adr_o(controller_wb_adr_o), .wb_dat_o(controller_wb_dat_o), .wb_dat_i(controller_wb_dat_i),
    .wb_ack_i(controller_wb_ack_i), .wb_err_i(controller_wb_err_i)
  );
`else
  assign controller_wb_we_o  = 1'b0;
  assign controller_wb_cyc_o = 1'b0;
  assign controller_wb_stb_o = 1'b0;
  assign controller_wb_adr_o = 16'b0;
  assign controller_wb_dat_o = 16'b0;
  assign CONTROLLER_I2C_SDA = 1'bz; //har har
`endif

  /*************************** DMA Engine ***********************************/
  wire dma_done, dma_crash;
`ifdef ENABLE_DMA_ENGINE
  dma_engine #(
    .FROM_ACM_A        (`MEM_FROM_A + 64 + 1),
    .FROM_LC_A         (`MEM_FROM_A + 1),
    .LC_THRESHS_A      (`MEM_LEVCHK_A + 64),
    .ACM_AQUADS_A      (`MEM_ACM_A + 1),
    .VS_INDIRECT_A     (`MEM_VALS_A + 32),
    .SYSCONFIG_A       (`MEM_SYSCONF_A + 5),
    .LEVELSVALID_A     (`MEM_LEVCHK_A + 128 + 1),
    .SYSTIME_A         (`MEM_SYSCONF_A + 6),
    .CRASHSRC_A        (`MEM_LEVCHK_A + 128 + 4),
    .CRASHVAL_A        (`MEM_LEVCHK_A + 128 + 5),
    .FLASH_A           (`MEM_FLASHMEM_A + 64),
    .FLASH_SYSCONFIG_A (`MEM_FLASHMEM_H)
  ) dma_engine_inst (
    .wb_clk_i(gclk33), .wb_rst_i(hard_reset),
    .wb_cyc_o(dma_wb_cyc_o), .wb_stb_o(dma_wb_stb_o), .wb_we_o(dma_wb_we_o),
    .wb_adr_o(dma_wb_adr_o), .wb_dat_o(dma_wb_dat_o), .wb_dat_i(dma_wb_dat_i),
    .wb_ack_i(dma_wb_ack_i), .wb_err_i(dma_wb_err_i),
    .dma_crash(dma_crash), .dma_done(dma_done), .soft_reset(soft_reset),
    .disable_crashes(sys_config_vector[7])
  );
`else
  assign dma_wb_we_o  = 1'b0;
  assign dma_wb_cyc_o = 1'b0;
  assign dma_wb_stb_o = 1'b0;
  assign dma_wb_adr_o = 16'b0;
  assign dma_wb_dat_o = 16'b0;
  assign dma_done = 1'b1;
`endif
  /*********************** WishBone Master Arbiter ************************/

  /* Signals that connect to WishBone slave arbiter */
  wire wbm_cyc_o, wbm_stb_o, wbm_we_o;
  wire [15:0] wbm_adr_o;
  wire [15:0] wbm_dat_o;
  wire [15:0] wbm_dat_i;
  wire wbm_ack_i, wbm_err_i;
  wire  [1:0] wbm_id;

  wire [15:0] wbm_dat_i_int;
  assign dma_wb_dat_i = wbm_dat_i_int;
  assign controller_wb_dat_i = wbm_dat_i_int;
  assign xport_wb_dat_i = wbm_dat_i_int;
  assign debug_wb_dat_i = wbm_dat_i_int;

  wbm_arbiter #(
    .NUM_MASTERS(4)
  ) wbm_arbiter_inst (
    .wb_clk_i(gclk33), .wb_rst_i(hard_reset),

    .wbm_cyc_i({dma_wb_cyc_o, controller_wb_cyc_o, xport_wb_cyc_o, debug_wb_cyc_o}),
    .wbm_stb_i({dma_wb_stb_o, controller_wb_stb_o, xport_wb_stb_o, debug_wb_stb_o}),
    .wbm_we_i ({dma_wb_we_o,  controller_wb_we_o,  xport_wb_we_o,  debug_wb_we_o}),
    .wbm_adr_i({dma_wb_adr_o, controller_wb_adr_o, xport_wb_adr_o, debug_wb_adr_o}),
    .wbm_dat_i({dma_wb_dat_o, controller_wb_dat_o, xport_wb_dat_o, debug_wb_dat_o}),
    .wbm_dat_o(wbm_dat_i_int),

    .wbm_ack_o({dma_wb_ack_i, controller_wb_ack_i, xport_wb_ack_i, debug_wb_ack_i}),
    .wbm_err_o({dma_wb_err_i, controller_wb_err_i, xport_wb_err_i, debug_wb_err_i}),

    .wbs_cyc_o(wbm_cyc_o), .wbs_stb_o(wbm_stb_o), .wbs_we_o(wbm_we_o),
    .wbs_adr_o(wbm_adr_o), .wbs_dat_o(wbm_dat_o), .wbs_dat_i(wbm_dat_i),
    .wbs_ack_i(wbm_ack_i), .wbs_err_i(wbm_err_i),
    .wbm_id(wbm_id),

    .wbm_mask({1'b1,{3{dma_done}}}) //disable the other three masters when dma is not done
  );


  /******************** WishBone Slave Arbiter ****************************/

  localparam NUM_SLAVES = 11;
  
  /* Wishbone Slave Signals */
  wire [NUM_SLAVES - 1:0] wbs_cyc_o;
  wire [NUM_SLAVES - 1:0] wbs_stb_o;
  wire wbs_we_o;
  wire [15:0] wbs_adr_o;
  wire [15:0] wbs_dat_o;
  wire [16*NUM_SLAVES - 1:0] wbs_dat_i;
  wire [NUM_SLAVES - 1:0] wbs_ack_i;

  /* Bus Monitor Signals */
  wire bm_memv;
  wire  [1:0] bm_wbm_id;
  wire [15:0] bm_addr;
  wire bm_we;
  wire bm_timeout;

  wbs_arbiter #(
   .RESTRICTION0(`MEM_RESTRICTION_0),
   .RESTRICTION1(`MEM_RESTRICTION_1),
   .RESTRICTION2(`MEM_RESTRICTION_2),

   .TOCONF0(`TO_CONF_0),
   .TOCONF1(`TO_CONF_1),
   .TODEFAULT(`TO_DEFAULT),

   .A0_BASE(`MEM_SYSCONF_A),
   .A0_HIGH(`MEM_SYSCONF_H),
   .A1_BASE(`MEM_FROM_A),
   .A1_HIGH(`MEM_FROM_H),
   .A2_BASE(`MEM_ACM_A),
   .A2_HIGH(`MEM_ACM_H),
   .A3_BASE(`MEM_ADC_A),
   .A3_HIGH(`MEM_ADC_H),
   .A4_BASE(`MEM_LEVCHK_A),
   .A4_HIGH(`MEM_LEVCHK_H),
   .A5_BASE(`MEM_VALS_A),
   .A5_HIGH(`MEM_VALS_H),
   .A6_BASE(`MEM_PWRMAN_A),
   .A6_HIGH(`MEM_PWRMAN_H),
   .A7_BASE(`MEM_IRQC_A),
   .A7_HIGH(`MEM_IRQ_H),
   .A8_BASE(`MEM_FANC_A),
   .A8_HIGH(`MEM_FANC_H),
   .A9_BASE(`MEM_GPIO_A),
   .A9_HIGH(`MEM_GPIO_H),
   .A10_BASE(`MEM_FLASHMEM_A),
   .A10_HIGH(`MEM_FLASHMEM_H)
  ) wbs_arbiter_inst (
    .wb_clk_i(gclk33), .wb_rst_i(hard_reset),
    .wbm_cyc_i(wbm_cyc_o), .wbm_stb_i(wbm_stb_o), .wbm_we_i(wbm_we_o),
    .wbm_adr_i(wbm_adr_o), .wbm_dat_i(wbm_dat_o), .wbm_dat_o(wbm_dat_i),
    .wbm_ack_o(wbm_ack_i), .wbm_err_o(wbm_err_i),
    .wbm_id(wbm_id),

    .wbs_cyc_o(wbs_cyc_o), .wbs_stb_o(wbs_stb_o), .wbs_we_o(wbs_we_o),
    .wbs_adr_o(wbs_adr_o), .wbs_dat_o(wbs_dat_o), .wbs_dat_i(wbs_dat_i),
    .wbs_ack_i(wbs_ack_i), 

    .bm_memv(bm_memv),
    .bm_wbm_id(bm_wbm_id),
    .bm_addr(bm_addr),
    .bm_we(bm_we),
    .bm_timeout(bm_timeout)
  );

  /* TODO: ENABLE defines for each module */
  /************ System Config Controller ***************/
  wire [7:0] sys_config_vector;
  assign SYS_CONFIG = sys_config_vector;

  sys_config #( 
    .BOARD_ID     (`BOARD_ID),
    .REV_MAJOR    (`REV_MAJOR),
    .REV_MINOR    (`REV_MINOR),
    .REV_RCS      (`REV_RCS),
    .RCS_UPTODATE (`RCS_UPTODATE)
  ) sys_config_inst (
    .wb_clk_i(gclk33), .wb_rst_i(hard_reset),
    .wb_cyc_i(wbs_cyc_o[0]), .wb_stb_i(wbs_stb_o[0]), .wb_we_i(wbs_we_o),
    .wb_adr_i(wbs_adr_o), .wb_dat_i(wbs_dat_o), .wb_dat_o(wbs_dat_i[16*(0 + 1) - 1:16*0]),
    .wb_ack_o(wbs_ack_i[0]),
    .sys_config_vector(sys_config_vector),
    .xtal_clk(gclk_xtal)
  );

  /************** FlashROM Controller ***************/
  wire from_clk;
  wire [6:0] from_addr;
  wire [7:0] from_data;

  flashrom_infrastructure flashrom_infrastructure_inst(
    .CLK(from_clk),
    .ADDR(from_addr),
    .DOUT(from_data)
  );

  from_controller from_controller_0(
    .wb_clk_i(gclk33), .wb_rst_i(hard_reset),
    .wb_cyc_i(wbs_cyc_o[1]), .wb_stb_i(wbs_stb_o[1]), .wb_we_i(wbs_we_o),
    .wb_adr_i(wbs_adr_o), .wb_dat_i(wbs_dat_o), .wb_dat_o(wbs_dat_i[16*(1 + 1) - 1:16*1]),
    .wb_ack_o(wbs_ack_i[1]),
    .from_clk(from_clk), .from_addr(from_addr), .from_data(from_data)
  );
  /**************** Analogue Block / ACM *************/
  wire [9:0] ag_en;

  wire ADC_START;
  wire ADC_SAMPLE;
  wire [4:0] ADC_CHNUM;
  wire ADC_CALIBRATE,ADC_BUSY,ADC_DATAVALID;
  wire [11:0] ADC_RESULT;

  wire [7:0] acm_datar;
  wire [7:0] acm_dataw;
  wire [7:0] acm_addr;
  wire acm_clk,acm_wen, acm_reset;

  wire [9:0] cmstrb;
  wire [9:0] tmstrb;
  wire tmstrb_int;
  wire adc_fast_mode;

  wire rtcmatch_nc, rtcpsmmatch_nc;

  analogue_infrastructure analogue_infrastructure_inst(
    .SYS_CLK(gclk33),
    .AG(AG),.AG_EN(ag_en),.AV(AV),.AC(AC),.AT(AT),.ATRETURN(ATRET),
    .ADC_START(ADC_START),.ADC_SAMPLE(ADC_SAMPLE),.ADC_CHNUM(ADC_CHNUM),
    .ADC_CALIBRATE(ADC_CALIBRATE),.ADC_BUSY(ADC_BUSY),.ADC_DATAVALID(ADC_DATAVALID),
    .ADC_RESULT(ADC_RESULT),.ADCRESET(hard_reset),
    .ACM_DATAR(acm_datar),.ACM_DATAW(acm_dataw),.ACM_ADDR(acm_addr),
    .ACM_CLK(acm_clk),.ACM_WEN(acm_wen), .ACM_RESET(acm_reset),       
    .RTCCLK(rtcclk),.SELMODE(selmode),
    .RTCMATCH(rtcmatch_nc),.RTCPSMMATCH(rtcpsmmatch_nc),.RTCXTLMODE(rtc_mode),
    .VAREF(VAREF),
    .cmstrb(cmstrb), .tmstrb(tmstrb), .tmstrb_int(tmstrb_int), .fast_mode(adc_fast_mode)
  );

  acm_controller acm_controller_inst(
    .wb_clk_i(gclk33), .wb_rst_i(hard_reset),
    .wb_cyc_i(wbs_cyc_o[2]), .wb_stb_i(wbs_stb_o[2]), .wb_we_i(wbs_we_o),
    .wb_adr_i(wbs_adr_o), .wb_dat_i(wbs_dat_o), .wb_dat_o(wbs_dat_i[16*(2 + 1) - 1:16*2]),
    .wb_ack_o(wbs_ack_i[2]),
    .acm_wdata(acm_dataw), .acm_rdata(acm_datar),
    .acm_addr(acm_addr),
    .acm_wen(acm_wen),
    .acm_clk(acm_clk), .acm_reset(acm_reset)
  );
  /*************** ADC Controller *********************/

  wire [11:0] adc_result;
  wire  [4:0] adc_channel;
  wire adc_strb;

  adc_controller #(
    .DEFAULT_SAMPLE_AVERAGING(`DEFAULT_SAMPLE_AVERAGING)
  ) adc_controller_inst (
    .wb_clk_i(gclk33), .wb_rst_i(hard_reset),
    .wb_cyc_i(wbs_cyc_o[3]), .wb_stb_i(wbs_stb_o[3]), .wb_we_i(wbs_we_o),
    .wb_adr_i(wbs_adr_o), .wb_dat_i(wbs_dat_o), .wb_dat_o(wbs_dat_i[16*(3 + 1) - 1:16*3]),
    .wb_ack_o(wbs_ack_i[3]),
    .adc_result(adc_result), .adc_channel(adc_channel), .adc_strb(adc_strb),
    .ADC_START(ADC_START), .ADC_CHNUM(ADC_CHNUM),
    .ADC_CALIBRATE(ADC_CALIBRATE), .ADC_DATAVALID(ADC_DATAVALID),
    .ADC_SAMPLE(ADC_SAMPLE), .ADC_BUSY(ADC_BUSY),
    .ADC_RESULT(ADC_RESULT),
    .current_stb(cmstrb), .temp_stb({tmstrb_int, tmstrb}), .fast_mode(adc_fast_mode)
  );

  /*************** Level Checker *********************/
  wire soft_viol, hard_viol;
  wire [31:0] v_in_range;

  wire  [6:0] lc_ram_raddr;
  wire  [6:0] lc_ram_waddr;
  wire [11:0] lc_ram_rdata;
  wire [11:0] lc_ram_wdata;
  wire lc_ram_wen;

  wire power_ok, power_on;

  lc_infrastructure lc_infrastructure_inst(
    .clk(gclk33), .reset(hard_reset),
    .ram_raddr(lc_ram_raddr),
    .ram_waddr(lc_ram_waddr),
    .ram_rdata(lc_ram_rdata),
    .ram_wdata(lc_ram_wdata),
    .ram_wen(lc_ram_wen)
  );

  level_checker level_checker_inst(
    .wb_clk_i(gclk33), .wb_rst_i(hard_reset),
    .wb_cyc_i(wbs_cyc_o[4]), .wb_stb_i(wbs_stb_o[4]), .wb_we_i(wbs_we_o),
    .wb_adr_i(wbs_adr_o), .wb_dat_i(wbs_dat_o), .wb_dat_o(wbs_dat_i[16*(4 + 1) - 1:16*4]),
    .wb_ack_o(wbs_ack_i[4]),
    .adc_result(adc_result), .adc_channel(adc_channel), .adc_strb(adc_strb),
    .soft_en(power_ok), .hard_en(power_ok),
    .soft_reset(soft_reset),
    .soft_viol(soft_viol), .hard_viol(hard_viol),
    .v_in_range(v_in_range),
    .ram_raddr(lc_ram_raddr), .ram_waddr(lc_ram_waddr),
    .ram_rdata(lc_ram_rdata), .ram_wdata(lc_ram_wdata),
    .ram_wen(lc_ram_wen)
  );

  /**************** Value Storage ********************/
  wire vs_ram_wen;
  wire [12:0] vs_ram_raddr;
  wire [12:0] vs_ram_waddr;
  wire [11:0] vs_ram_rdata;
  wire [11:0] vs_ram_wdata;

  vs_infrastructure vs_infrastructure (
    .clk(gclk33), .reset(hard_reset),
    .ram_raddr(vs_ram_raddr),
    .ram_waddr(vs_ram_waddr),
    .ram_rdata(vs_ram_rdata),
    .ram_wdata(vs_ram_wdata),
    .ram_wen(vs_ram_wen)
  );

  value_storage value_storage_inst (
    .wb_clk_i(gclk33), .wb_rst_i(hard_reset),
    .wb_cyc_i(wbs_cyc_o[5]), .wb_stb_i(wbs_stb_o[5]), .wb_we_i(wbs_we_o),
    .wb_adr_i(wbs_adr_o), .wb_dat_i(wbs_dat_o), .wb_dat_o(wbs_dat_i[16*(5 + 1) - 1:16*5]),
    .wb_ack_o(wbs_ack_i[5]),
    .adc_result(adc_result), .adc_channel(adc_channel), .adc_strb(adc_strb),
    .ram_wen(vs_ram_wen),
    .ram_raddr(vs_ram_raddr), .ram_waddr(vs_ram_waddr),
    .ram_rdata(vs_ram_rdata), .ram_wdata(vs_ram_wdata)
  );

  /************* Power Manager *********************/

  wire chs_powerdown_pending;
  wire cold_start;
  wire [1:0] no_power_cause;
  wire G12V_EN, G5V_EN, G3V3_EN;

  assign CONTROLLER_RESET = ~power_ok;


  reg [16:0] counter;
  always @(posedge gclk_xtal) begin
    if (hard_reset) begin
      counter <= 0;
    end else begin
      counter <= counter + 1;
    end
  end
  wire bad_power_down = no_power_cause == 2'b01 || no_power_cause == 2'b10;
  wire power_led  = power_ok ? 1'b1 : counter[14];
  wire action_led = power_ok ? CONTROLLER_IRQ :
                    bad_power_down ? counter[12] :
                    1'b0;

  assign CHS_LED_N = hard_reset ? 2'b00 : ~{action_led, power_led};

  assign cold_start = ~sys_config_vector[0];
  assign ag_en = {   1'b0,   1'b0,    1'b0, 1'b0, 1'b0,
                  G3V3_EN, G5V_EN, G12V_EN, 1'b0, 1'b0};

  power_manager #(
    .WATCHDOG_OVERFLOW_DEFAULT(`WATCHDOG_OVERFLOW_DEFAULT),
    .MAX_UNACKED_CRASHES(`MAX_UNACKED_CRASHES),
    .MAX_UNACKED_WD_OVERFLOWS(`MAX_UNACKED_WD_OVERFLOWS),
    .SYS_HEALTH_POWERUP_MASK(`SYS_HEALTH_POWERUP_MASK),
    .POWER_DOWN_WAIT(`POWER_DOWN_WAIT),
    .POST_POWERUP_WAIT(`POST_POWERUP_WAIT)
  ) power_manager_inst (
    /* Wishbone Interface */
    .wb_clk_i(gclk33), .wb_rst_i(hard_reset),
    .wb_cyc_i(wbs_cyc_o[6]), .wb_stb_i(wbs_stb_o[6]), .wb_we_i(wbs_we_o),
    .wb_adr_i(wbs_adr_o), .wb_dat_i(wbs_dat_o), .wb_dat_o(wbs_dat_i[16*(6 + 1) - 1:16*6]),
    .wb_ack_o(wbs_ack_i[6]),
    /* System Health */
    .sys_health(v_in_range), .unsafe_sys_health(hard_viol),
    /* Informational Signals */
    .power_ok(power_ok), .power_on(power_on), .no_power_cause(no_power_cause),
    /* Control Signals */
    .cold_start(cold_start), .dma_done(dma_done), .chs_power_button(chs_powerdown), .chs_reset(chs_reset),
    .soft_reset(soft_reset), .crash(dma_crash), .chs_powerdown_pending(chs_powerdown_pending),
    /* ATX Power Supply Control */
    .ATX_PS_ON_N(ATX_PS_ON_N), .ATX_PWR_OK(ATX_PWR_OK),
    .ATX_LOAD_RES_OFF(ATX_LOAD_RES_OFF),
    /* Power Supply Control */
    .TRACK_2V5(TRACK_2V5),
    .INHIBIT_2V5(INHIBIT_2V5), .INHIBIT_1V8(INHIBIT_1V8), .INHIBIT_1V5(INHIBIT_1V5),
    .INHIBIT_1V2(INHIBIT_1V2), .INHIBIT_1V0(INHIBIT_1V0),
    .MGT_AVCC_EN(MGT_AVCC_EN), .MGT_AVTTX_EN(MGT_AVTTX_EN), .MGT_AVCCPLL_EN(MGT_AVCCPLL_EN),
    .MGT_AVCC_PG(MGT_AVCC_PG), .MGT_AVTTX_PG(MGT_AVTTX_PG), .MGT_AVCCPLL_PG(MGT_AVCCPLL_PG),
    .AUX_3V3_PG(AUX_3V3_PG),
    /* FET gate drivers */
    .G12V_EN(G12V_EN), .G5V_EN(G5V_EN), .G3V3_EN(G3V3_EN)
  );
  /***************** IRQ Controller *****************/

  wire [3:0] irq_i;
  assign irq_i = {bm_timeout, bm_memv, soft_viol, chs_powerdown_pending};

  irq_controller #(
    .NUM_SOURCES(4)
  ) irq_controller_inst (
    .wb_clk_i(gclk33), .wb_rst_i(hard_reset | soft_reset),
    .wb_cyc_i(wbs_cyc_o[7]), .wb_stb_i(wbs_stb_o[7]), .wb_we_i(wbs_we_o),
    .wb_adr_i(wbs_adr_o), .wb_dat_i(wbs_dat_o), .wb_dat_o(wbs_dat_i[16*(7 + 1) - 1:16*7]),
    .wb_ack_o(wbs_ack_i[7]),
    .irq_i(irq_i), .irq_o(CONTROLLER_IRQ)
  );

  /*************** Fan Controller ********************/

  fan_controller #( 
    .NUM_FANS(3)
  ) fan_controller_inst (
    .wb_clk_i(gclk33), .wb_rst_i(hard_reset),
    .wb_cyc_i(wbs_cyc_o[8]), .wb_stb_i(wbs_stb_o[8]), .wb_we_i(wbs_we_o),
    .wb_adr_i(wbs_adr_o), .wb_dat_i(wbs_dat_o), .wb_dat_o(wbs_dat_i[16*(8 + 1) - 1:16*8]),
    .wb_ack_o(wbs_ack_i[8]),
    .adc_result(adc_result), .adc_channel(adc_channel), .adc_strb(adc_strb),
    .fan_sense({FAN3_SENSE, FAN2_SENSE, FAN1_SENSE}),
    .fan_control({FAN3_CONTROL, FAN2_CONTROL, FAN1_CONTROL})
  );

  /**************** GPIO Controller ******************/

  wire [11:0] gpio_in;
  wire [11:0] gpio_out;
  wire [11:0] gpio_oe;

  BIBUF bibuf_gpio[11:0] (
    .PAD ({GPIO_OE1, GPIO_OE0, GPIO_CC1, GPIO_CC0, GPIO}),
    .D   (gpio_out),
    .E   (gpio_oe),
    .Y   (gpio_in)
  );


  reg power_ok_z;
  always @(posedge gclk33) begin
    power_ok_z <= power_ok;
  end

  wire power_ok_negedge = !power_ok && power_ok_z;
  

  wire [11:0] sw_gpio_out;
  wire [11:0] sw_gpio_oe;
  wire [11:0] dedicated_gpio_en;

  gpio_controller #(
    .NUM_GPIO     (12),
    .OE_DEFAULTS  (12'b1100_0000_0011),
    .OUT_DEFAULTS (12'b0100_0000_0000),
    .DED_DEFAULTS (12'b0000_1000_0000)
  ) gpio_controller_inst (
    .wb_clk_i(gclk33), .wb_rst_i(hard_reset || power_ok_negedge),
    .wb_cyc_i(wbs_cyc_o[9]), .wb_stb_i(wbs_stb_o[9]), .wb_we_i(wbs_we_o),
    .wb_adr_i(wbs_adr_o), .wb_dat_i(wbs_dat_o), .wb_dat_o(wbs_dat_i[16*(9 + 1) - 1:16*9]),
    .wb_ack_o(wbs_ack_i[9]),

    .gpio_out (sw_gpio_out),
    .gpio_in  (gpio_in),
    .gpio_oe  (sw_gpio_oe),
    
    .ded_en   (dedicated_gpio_en)
  );

  wire [11:0] dedicated_gpio_oe  = 12'b0000_0000_0000;
  wire [11:0] dedicated_gpio_out = 12'b0000_0000_0000;

genvar geni;
generate for (geni=0 ; geni < 12; geni=geni + 1) begin: gpio_dedicated
  assign gpio_oe[geni]  = dedicated_gpio_en[geni] ? dedicated_gpio_oe[geni]  : sw_gpio_oe[geni];
  assign gpio_out[geni] = dedicated_gpio_en[geni] ? dedicated_gpio_out[geni] : sw_gpio_out[geni];
end endgenerate
   

  //dedicated reset is active low
  assign chs_reset_in_switch = dedicated_gpio_en[7] ? !gpio_in[7] : 1'b0;

  /***************** Bus Monitor *********************/
  /*
  no longer used
  bus_monitor bus_monitor_inst(
    .wb_clk_i(gclk33), .wb_rst_i(hard_reset),
    .wb_cyc_i(wbs_cyc_o[9]), .wb_stb_i(wbs_stb_o[9]), .wb_we_i(wbs_we_o),
    .wb_adr_i(wbs_adr_o), .wb_dat_i(wbs_dat_o), .wb_dat_o(wbs_dat_i[16*(9 + 1) - 1:16*9]),
    .wb_ack_o(wbs_ack_i[9]),

    .bm_memv(bm_memv),
    .bm_timeout(bm_timeout),
    .bm_wbm_id(bm_wbm_id),
    .bm_addr(bm_addr),
    .bm_we(bm_we)
  );
  */

  /************* FlashMem Controller *****************/

  wire [16:0] FM_ADDR;
  wire [15:0] FM_WD;
  wire FM_PAGESTATUS;
  wire FM_REN, FM_WEN, FM_PROGRAM;
  wire FM_CLK, FM_RESET;
  wire [31:0]  FM_RD; //32 bits to support full flash status read
  wire FM_BUSY;
  wire [1:0] FM_STATUS;

  flashmem flashmem_inst(
    .FM_ADDR(FM_ADDR),       
    .FM_WD(FM_WD),               
    .FM_REN(FM_REN),              
    .FM_WEN(FM_WEN),              
    .FM_PROGRAM(FM_PROGRAM),        
    .FM_CLK(FM_CLK),             
    .FM_RESET(1'b1),
    .FM_RD(FM_RD),              
    .FM_BUSY(FM_BUSY),            
    .FM_STATUS(FM_STATUS),
    .FM_PAGESTATUS(FM_PAGESTATUS)
  );

  flashmem_controller flashmem_controller_inst(
    .wb_clk_i(gclk33), .wb_rst_i(hard_reset),
    .wb_cyc_i(wbs_cyc_o[10]), .wb_stb_i(wbs_stb_o[10]), .wb_we_i(wbs_we_o),
    .wb_adr_i(wbs_adr_o), .wb_dat_i(wbs_dat_o), .wb_dat_o(wbs_dat_i[16*(10 + 1) - 1:16*10]),
    .wb_ack_o(wbs_ack_i[10]),
    .FM_CLK(FM_CLK), .FM_RESET(FM_RESET),
    .FM_ADDR(FM_ADDR), .FM_WD(FM_WD), .FM_RD(FM_RD),
    .FM_REN(FM_REN), .FM_WEN(FM_WEN), .FM_PROGRAM(FM_PROGRAM),
    .FM_BUSY(FM_BUSY), .FM_STATUS(FM_STATUS), .FM_PAGESTATUS(FM_PAGESTATUS)
  );

endmodule
