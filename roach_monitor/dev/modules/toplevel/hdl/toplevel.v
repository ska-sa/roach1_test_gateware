`include "parameters.v"

module toplevel(
    /* ATX Power Supply Control */
//    ATX_PS_ON_N, ATX_PWR_OK,
//    ATX_LOAD_RES_OFF,
    /* Power Supply Control */
//    TRACK_2V5,
//    INHIBIT_2V5, INHIBIT_1V8, INHIBIT_1V5, INHIBIT_1V2, INHIBIT_1V0,
//    MGT_AVCC_EN, MGT_AVTTX_EN, MGT_AVCCPLL_EN,
//    MGT_AVCC_PG, MGT_AVTTX_PG, MGT_AVCCPLL_PG,
//    AUX_3V3_PG,
    /* XPORT Serial */
//    XPORT_SERIAL_IN, XPORT_SERIAL_OUT,
//    XPORT_GPIO, XPORT_RESET_N,
    /* Controller Interface */
//    CONTROLLER_I2C_SDA, CONTROLLER_I2C_SCL,
//    CONTROLLER_IRQ, CONTROLLER_RESET,
    /*System Configuration*/
//    SYS_CONFIG,
    /* Chassis Interface */
//    CHS_POWERDOWN, CHS_RESET_N,
    CHS_LED,
    /* Fan Control */
//    FAN1_SENSE,   FAN2_SENSE,   FAN3_SENSE,
//    FAN1_CONTROL, FAN2_CONTROL, FAN3_CONTROL,
    /* Debug Serial Port */
//    DEBUG_SERIAL_IN, DEBUG_SERIAL_OUT,
    /* Analogue Block Interfaces*/
//    AG, AV, AC, AT, ATRET,
    /* Fixed Fusion Signals */
    XTLCLK, PUB, VAREF
  );

//  output ATX_PS_ON_N;
//  input  ATX_PWR_OK;
//  output ATX_LOAD_RES_OFF;

//  output TRACK_2V5;
//  output INHIBIT_2V5, INHIBIT_1V8, INHIBIT_1V5, INHIBIT_1V2, INHIBIT_1V0;
//  output MGT_AVCC_EN, MGT_AVTTX_EN, MGT_AVCCPLL_EN;
//  input  MGT_AVCC_PG, MGT_AVTTX_PG, MGT_AVCCPLL_PG;
//  input  AUX_3V3_PG;

//  input  XPORT_SERIAL_IN;
//  output XPORT_SERIAL_OUT;
//  inout  XPORT_GPIO;
//  output XPORT_RESET;

//  inout  CONTROLLER_I2C_SDA;
//  input  CONTROLLER_I2C_SCL;
//  output CONTROLLER_IRQ, CONTROLLER_RESET,

//  output [7:0] SYS_CONFIG;

//  input  CHS_POWERDOWN, CHS_RESET_N;
  output [1:0] CHS_LED,

//  input  FAN1_SENSE, FAN2_SENSE, FAN3_SENSE;
//  output FAN1_CONTROL, FAN2_CONTROL, FAN3_CONTROL,

//  input  DEBUG_SERIAL_IN;
//  output DEBUG_SERIAL_OUT;

//  output [9:0] GA;
//  input  [9:0] AV;
//  input  [9:0] AC;
//  input  [9:0] AT;
//  input  [4:0] ATRET;
  
  input  XTLCLK, PUB;
  inout  VAREF;

  /*************** Global Nets ***************/

  wire hard_reset;
  wire gclk10, gclk40, gclk100;
  wire pll_lock;

  /* Debounce chassis switches */
  wire chs_powerdown, chs_reset_n;

//  debouncer #(
//    .DELAY(32'h0020_0000)
//  ) debouncer_inst[1:0] (  
//    .clk(gclk40), .reset(hard_reset),
//    .in_switch({CHS_POWERDOWN, CHS_RESET_N}), .out_switch({chs_powerdown, chs_reset_n})
//  );

  /* Reset Control */
  reset_block #(
    .DELAY(10000),
    .WIDTH(32'h2000_0000)
  ) reset_block_inst (
    .clk(gclk40),
    .async_reset_i(~pll_lock), .reset_i(1'b0),//~CHS_RESET_N,
    .reset_o(hard_reset)
  );

  /*********************** Global Infrastructure ************************/
  wire nc_fpgagood;
  wire rtcclk, selmode;
  wire [1:0] rtc_mode;

  infrastructure infrastructure_inst(
    .gclk40(gclk40),.gclk100(gclk100),.gclk10(gclk10),
    .PLL_LOCK(pll_lock),
    .PUB(PUB), .FPGAGOOD(nc_fpgagood), .XTLCLK(XTLCLK),
//    .RTCCLK(rtcclk), .SELMODE(selmode), .RTC_MODE(rtc_mode)
    .RTCCLK(rtcclk), .SELMODE(1'b1), .RTC_MODE(2'b00)
  );

  reg [31:0] counter;
  assign CHS_LED = {counter[28], hard_reset};
  always @(posedge gclk40) begin
    counter <= counter + 1;
  end

//  /********************* WishBone Master signals ***********************/
//  wire debug_wb_we_o, debug_wb_cyc_o, debug_wb_stb_o;
//  wire [15:0] debug_wb_adr_o;
//  wire [15:0] debug_wb_dat_o;
//  wire [15:0] debug_wb_dat_i;
//  wire debug_wb_ack_i, debug_wb_err_i;
//
//  wire xport_wb_we_o, xport_wb_cyc_o, xport_wb_stb_o;
//  wire [15:0] xport_wb_adr_o;
//  wire [15:0] xport_wb_dat_o;
//  wire [15:0] xport_wb_dat_i;
//  wire xport_wb_ack_i, xport_wb_err_i;
//
//  wire controller_wb_we_o, controller_wb_cyc_o, controller_wb_stb_o;
//  wire [15:0] controller_wb_adr_o;
//  wire [15:0] controller_wb_dat_o;
//  wire [15:0] controller_wb_dat_i;
//  wire controller_wb_ack_i, controller_wb_err_i;
//
//  wire dma_wb_we_o, dma_wb_cyc_o, dma_wb_stb_o;
//  wire [15:0] dma_wb_adr_o;
//  wire [15:0] dma_wb_dat_o;
//  wire [15:0] dma_wb_dat_i;
//  wire dma_wb_ack_i, dma_wb_err_i;
//
//  /********************* Serial Communications Modules ***********************/
//  /********* Debug Interface ***********/
//`ifdef ENABLE_DEBUG_INTERFACE
//   
//  wire [7:0] ds_as_data_i;
//  wire [7:0] ds_as_data_o;
//  wire ds_as_dstrb_i, ds_as_busy_o, ds_as_dstrb_o;
//
//  /* Debug UART */
//  serial_uart #(
//    .BAUD(`DEBUG_SERIAL_BAUD),
//    .CLOCK_RATE(`MASTER_CLOCK_RATE)
//  ) serial_uart_debug (
//    .clk(gclk40), .reset(hard_reset),
//    .serial_in(DEBUG_SERIAL_IN), .serial_out(DEBUG_SERIAL_OUT),
//    .as_data_i(ds_as_data_i),  .as_data_o(ds_as_data_o),
//    .as_dstrb_i(ds_as_dstrb_i), .as_busy_o(ds_as_busy_o), .as_dstrb_o(ds_as_dstrb_o)
//  );
//  /* Debug WB bridge */
//  as_wb_bridge as_wb_bridge_debug(
//    .clk(gclk40), .reset(hard_reset), 
//    .as_data_i(ds_as_data_o), .as_data_o(ds_as_data_i),
//    .as_dstrb_i(ds_as_dstrb_o), .as_busy_i(ds_as_busy_o), .as_dstrb_o(ds_as_dstrb_i),
//    .wb_we_o(debug_wb_we_o), .wb_cyc_o(debug_wb_cyc_o), .wb_stb_o(debug_wb_stb_o),
//    .wb_adr_o(debug_wb_adr_o), .wb_dat_o(debug_wb_dat_o), .wb_dat_i(debug_wb_dat_i),
//    .wb_ack_i(debug_wb_ack_i), .wb_err_i(debug_wb_err_i)
//  );
//`else
//  assign debug_wb_we_o  = 1'b0;
//  assign debug_wb_cyc_o = 1'b0;
//  assign debug_wb_stb_o = 1'b0;
//  assign debug_wb_adr_o = 16'b0;
//  assign debug_wb_dat_o = 16'b0;
//  assign DEBUG_SERIAL_OUT = 1'b0;
//`endif
//
//  /********* XPORT Interface ***********/
//`ifdef ENABLE_XPORT_INTERFACE
//  wire [7:0] xp_as_data_i;
//  wire [7:0] xp_as_data_o;
//  wire xp_as_dstrb_i, xp_as_busy_o, xp_as_dstrb_o;
//
//  /* XPORT UART */
//  serial_uart #(
//    .BAUD(`XPORT_SERIAL_BAUD),
//    .CLOCK_RATE(`MASTER_CLOCK_RATE)
//  ) serial_uart_xport (
//    .clk(gclk40), .reset(hard_reset),
//    .serial_in(XPORT_SERIAL_IN), .serial_out(XPORT_SERIAL_OUT),
//    .as_data_i(xp_as_data_i),  .as_data_o(xp_as_data_o),
//    .as_dstrb_i(xp_as_dstrb_i), .as_busy_o(xp_as_busy_o), .as_dstrb_o(xp_as_dstrb_o)
//  );
//
//  /* XPORT WB bridge */
//  as_wb_bridge as_wb_bridge_xport(
//    .clk(gclk40), .reset(hard_reset), 
//    .as_data_i(xp_as_data_o), .as_data_o(xp_as_data_i),
//    .as_dstrb_i(xp_as_dstrb_o), .as_busy_i(xp_as_busy_o), .as_dstrb_o(xp_as_dstrb_i),
//    .wb_we_o(xport_wb_we_o), .wb_cyc_o(xport_wb_cyc_o), .wb_stb_o(xport_wb_stb_o),
//    .wb_adr_o(xport_wb_adr_o), .wb_dat_o(xport_wb_dat_o), .wb_dat_i(xport_wb_dat_i),
//    .wb_ack_i(xport_wb_ack_i), .wb_err_i(xport_wb_err_i)
//  );
//`else
//  assign xport_wb_we_o  = 1'b0;
//  assign xport_wb_cyc_o = 1'b0;
//  assign xport_wb_stb_o = 1'b0;
//  assign xport_wb_adr_o = 16'b0;
//  assign xport_wb_dat_o = 16'b0;
//  assign XPORT_SERIAL_OUT = 1'b0;
//`endif
//
//  /********* Controller Interface ***********/
//`ifdef ENABLE_CONTROLLER_INTERFACE
//  wire [7:0] ctrl_as_data_i;
//  wire [7:0] ctrl_as_data_o;
//  wire ctrl_as_dstrb_i, ctrl_as_busy_o, ctrl_as_dstrb_o;
//
//  wire ctrl_scl_i, ctrl_scl_o, ctrl_scl_oen;
//  wire ctrl_sda_i, ctrl_sda_o, ctrl_sda_oen;
//  /* Controller I2C Infrastructure */
//  i2c_infrastructure i2c_infrastructure_controller(
//    .sda_i(sda_i), .sda_o(sda_o), .sda_oen(sda_oen),
//    .scl_i(scl_i), .scl_o(scl_o), .scl_oen(scl_oen),
//    .sda_pad(CONTROLLER_I2C_SDA), .scl_pad(CONTROLLER_I2C_SCL)
//  );
//
//  /* Controller I2C Slave */
//  wire nc_i2c_cmnd_strb_o;
//  i2c_slave #(
//    .FREQ(100_000),
//    .CLOCK_RATE(`MASTER_CLOCK_RATE),
//    .ADDRESS(`I2C_SLAVE_ADDRESS)
//  ) i2c_slave_controller (
//    .clk(gclk40), .reset(hard_reset),
//    .scl_i(ctrl_scl_i), .scl_o(ctrl_scl_o), .scl_oen(ctrl_scl_oen),
//    .sda_i(ctrl_sda_i), .sda_o(ctrl_sda_o), .sda_oen(ctrl_sda_oen),
//    .as_data_i(ctrl_as_data_i),  .as_data_o(ctrl_as_data_o),
//    .as_dstrb_o(ctrl_as_dstrb_o), .as_dstrb_i(ctrl_as_dstrb_i), .as_busy_o(ctrl_as_busy_o),
//    .i2c_cmnd_strb_o(nc_i2c_cmnd_strb_o)
//  );
//
//  /* Controller WB bridge */
//  as_wb_bridge as_wb_bridge_controller(
//    .clk(gclk40), .reset(hard_reset), 
//    .as_data_i(ctrl_as_data_o), .as_data_o(ctrl_as_data_i),
//    .as_dstrb_i(ctrl_as_dstrb_o), .as_busy_i(ctrl_as_busy_o), .as_dstrb_o(ctrl_as_dstrb_i),
//    .wb_we_o(controller_wb_we_o), .wb_cyc_o(controller_wb_cyc_o), .wb_stb_o(controller_wb_stb_o),
//    .wb_adr_o(controller_wb_adr_o), .wb_dat_o(controller_wb_dat_o), .wb_dat_i(controller_wb_dat_i),
//    .wb_ack_i(controller_wb_ack_i), .wb_err_i(controller_wb_err_i)
//  );
//`else
//  assign controller_wb_we_o  = 1'b0;
//  assign controller_wb_cyc_o = 1'b0;
//  assign controller_wb_stb_o = 1'b0;
//  assign controller_wb_adr_o = 16'b0;
//  assign controller_wb_dat_o = 16'b0;
//  assign CONTROLLER_I2C_SDA = 1'bz; //har har
//`endif
//
//  /*************************** DMA Engine ***********************************/
//  wire dma_done, dma_crash;
//`ifdef ENABLE_DMA_ENGINE
//  dma_engine dma_engine_inst(
//    .clk(gclk40), .reset(hard_reset),
//    .wb_cyc_o(dma_wb_cyc_o), .wb_stb_o(dma_wb_stb_o), .wb_we_o(dma_wb_we_o),
//    .wb_adr_o(dma_wb_adr_o), .wb_dat_o(dma_wb_dat_o), .wb_dat_i(dma_wb_dat_i),
//    .wb_ack_i(dma_wb_ack_i), .wb_err_i(dma_wb_err_i),
//    .dma_crash(dma_crash), .dma_done(dma_done)
//  );
//`else
//  assign dma_wb_we_o  = 1'b0;
//  assign dma_wb_cyc_o = 1'b0;
//  assign dma_wb_stb_o = 1'b0;
//  assign dma_wb_adr_o = 16'b0;
//  assign dma_wb_dat_o = 16'b0;
//  assign dma_done = 1'b1;
//`endif
//  /*********************** WishBone Master Arbiter ************************/
//
//  /* Signals that connect to WishBone slave arbiter */
//  wire wbm_cyc_o, wbs_stb_o, wbs_we_o;
//  wire [15:0] wbm_adr_o;
//  wire [15:0] wbm_dat_o;
//  wire [15:0] wbm_dat_i;
//  wire wbm_ack_i, wbm_err_i;
//  wire  [3:0] wbm_id;
//
//  wire [15:0] wbm_dat_i_int;
//  assign dma_wb_dat_i = wbm_dat_i_int;
//  assign controller_wb_dat_i = wbm_dat_i_int;
//  assign xport_wb_dat_i = wbm_dat_i_int;
//  assign debug_wb_dat_i = wbm_dat_i_int;
//
//  wbm_arbiter #(
//    .NUM_MASTERS(4)
//  ) wbm_arbiter_inst (
//    .wb_clk_i(gclk40), .wb_rst_i(hard_reset),
//
//    .wbm_cyc_i({dma_wb_cyc_o, controller_wb_cyc_o, xport_wb_cyc_o, debug_wb_cyc_o}),
//    .wbm_stb_i({dma_wb_stb_o, controller_wb_stb_o, xport_wb_stb_o, debug_wb_stb_o}),
//    .wbm_we_i ({dma_wb_we_o,  controller_wb_we_o,  xport_wb_we_o,  debug_wb_we_o}),
//    .wbm_adr_i({dma_wb_adr_o, controller_wb_adr_o, xport_wb_adr_o, debug_wb_adr_o}),
//    .wbm_dat_i({dma_wb_dat_o, controller_wb_dat_o, xport_wb_dat_o, debug_wb_dat_o}),
//    .wbm_dat_o(wbm_dat_i_int),
//
//    .wbm_ack_o({dma_wb_ack_i, controller_wb_ack_i, xport_wb_ack_i, debug_wb_ack_i}),
//    .wbm_err_o({dma_wb_err_i, controller_wb_err_i, xport_wb_err_i, debug_wb_err_i}),
//
//    .wbs_cyc_o(wbm_cyc_o), .wbs_stb_o(wbm_stb_o), .wbs_we_o(wbm_we_o),
//    .wbs_adr_o(wbm_adr_o), .wbs_dat_o(wbm_dat_o), .wbs_dat_i(wbm_dat_i),
//    .wbs_ack_i(wbm_ack_i), .wbs_err_i(wbm_err_i),
//    .wbm_id(wbm_id)
//
//    .wbm_mask({1'b1,{3{dma_done}}), //disable the other three masters when dma is not done
//  );
//
//  /******************** WishBone Slave Arbiter ****************************/
//  
//  /* Wishbone Slave Signals */
//  wire wbs_cyc_o [10:0];
//  wire wbs_stb_o [10:0];
//  wire wbs_we_o;
//  wire [15:0] wbs_adr_o;
//  wire [15:0] wbs_dat_o;
//  wire [15:0] wbs_dat_o [10:0];
//  wire wbs_ack_i [10:0];
//
//  /* Bus Monitor Signals */
//  wire bm_memv;
//  wire  [3:0] bm_wbm_id;
//  wire [15:0] bm_addr,
//  wire bm_we;
//  wire bm_timeout;
//
//  wbs_arbiter #(
//   .NUM_MASTERS(4),
//   .RESTRICTION0(`MEM_RESTRICTION_0),
//   .RESTRICTION1(`MEM_RESTRICTION_1),
//   .RESTRICTION2(`MEM_RESTRICTION_2),
//
//   .TOCONF0(`TO_CONF_0),
//   .TOCONF1(`TO_CONF_1),
//   .TODEFAULT(`TO_DEFAULT),
//
//   .A0_BASE(`MEM_SYSCONF_A),
//   .A0_HIGH(`MEM_SYSCONF_H),
//   .A1_BASE(`MEM_FROM_A),
//   .A1_HIGH(`MEM_FROM_H),
//   .A2_BASE(`MEM_ACM_A),
//   .A2_HIGH(`MEM_ACM_H),
//   .A3_BASE(`MEM_ADC_A),
//   .A3_HIGH(`MEM_ADC_H),
//   .A4_BASE(`MEM_LEVCHK_A),
//   .A4_HIGH(`MEM_LEVCHK_H),
//   .A5_BASE(`MEM_VALS_A),
//   .A5_HIGH(`MEM_VALS_H),
//   .A6_BASE(`MEM_PWRMAN_A),
//   .A6_HIGH(`MEM_PWRMAN_H),
//   .A7_BASE(`MEM_IRQC_A),
//   .A7_HIGH(`MEM_IRQ_H),
//   .A8_BASE(`MEM_FANC_A),
//   .A8_HIGH(`MEM_FANC_H),
//   .A9_BASE(`MEM_BUSMON_A),
//   .A9_HIGH(`MEM_BUSMON_H)
//   .A9_BASE(`MEM_FLASHMEM_A),
//   .A9_HIGH(`MEM_FLASHMEM_H)
//  ) wbs_arbiter_inst (
//    .wb_clk_i(gclk40), .wb_rst_i(hard_reset),
//    .wbm_cyc_i(wbm_cyc_i), .wbm_stb_i(wbm_stb_i), .wbm_we_i(wbm_we_i),
//    .wbm_adr_i(wbm_adr_i), .wbm_dat_i(wbm_dat_i), .wbm_dat_o(wbm_dat_o),
//    .wbm_ack_o(wbm_ack_o), .wbm_err_o(wbm_err_o),
//    .wbm_id(wbm_id),
//
//    .wbs_cyc_o(wbs_cyc_o), .wbs_stb_o(wbs_stb_o), .wbs_we_o(wbs_we_o),
//    .wbs_adr_o(wbs_adr_o), .wbs_dat_o(wbs_dat_o), .wbs_dat_i(wbs_dat_i),
//    .wbs_ack_i(wbs_ack_i), 
//
//    .bm_memv(bm_memv),
//    .bm_wbm_id(bm_wbm_id),
//    .bm_addr(bm_addr),
//    .bm_we(bm_we),
//    .bm_timeout(bm_timeout)
//  );





endmodule
