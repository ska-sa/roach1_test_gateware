`include "parameters.v"

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
    /*System Configuration*/
    SYS_CONFIG,
    /* Chassis Interface */
    CHS_POWERDOWN, CHS_RESET_N,
    CHS_LED,
    /* Fan Control */
    FAN1_SENSE,   FAN2_SENSE,   FAN3_SENSE,
    FAN1_CONTROL, FAN2_CONTROL, FAN3_CONTROL,
    /* Debug Serial Port */
    DEBUG_SERIAL_IN, DEBUG_SERIAL_OUT,
    /* Analogue Block Interfaces*/
    AG, AV, AC, AT, ATRET,
    /* Fixed Fusion Inputs */
    XTLCLK, PUB, VAREF
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
  inout  XPORT_GPIO;
  output XPORT_RESET;

  inout  CONTROLLER_I2C_SDA;
  input  CONTROLLER_I2C_SCL;
  output CONTROLLER_IRQ, CONTROLLER_RESET,

  output [7:0] SYS_CONFIG;

  input  CHS_POWERDOWN, CHS_RESET_N;
  output [1:0] CHS_LED,

  input  FAN1_SENSE, FAN2_SENSE, FAN3_SENSE;
  output FAN1_CONTROL, FAN2_CONTROL, FAN3_CONTROL,

  input  DEBUG_SERIAL_IN;
  output DEBUG_SERIAL_OUT;

  output [9:0] GA;
  input  [9:0] AV;
  input  [9:0] AC;
  input  [9:0] AT;
  input  [4:0] ATRET;
  
  input  XTLCLK, PUB;
  inout  VAREF;

  /* Global Nets */

  wire hard_reset;
  wire gclk10, gclk40, gclk100;
  wire pll_lock;

  /* Debounce chassis switches */
  wire chs_powerdown, chs_reset_n;

  debouncer #(
    .DELAY(32'h0020_0000)
  ) debouncer_inst[1:0] (  
    .clk(gclk40), .reset(hard_reset),
    .in_switch({CHS_POWERDOWN, CHS_RESET_N}), .out_switch({chs_powerdown, chs_reset_n})
  );

  /* Reset Control */
  reset_block #(
    .DELAY(10000),
    .WIDTH(10000)
  ) reset_block_inst (
    .clk(gclk100),
    .async_reset_i(~pll_lock), .reset_i(~CHS_RESET_N),
    .reset_o(hard_reset)
  );

  /* Global Infrastructure */
  wire nc_fpgagood;
  wire rtcclk, selmode;
  wire [1:0] rtc_mode;

  infrastructure infrastructure_inst(
    .reset(reset),
    .gclk40(gclk40),.gclk100(gclk100),.gclk10(gclk10),
    .PLL_LOCK(pll_lock),
    .PUB(PUB), .FPGAGOOD(nc_fpgagood), .XTLCLK(XTLCLK),
    .RTCCLK(rtcclk), .SELMODE(selmode), .RTC_MODE(rtc_mode)
  );





endmodule
