`timescale 1ns/10ps
module infrastructure(
    gclk40,gclk100,gclk10,gclk_xtal,
    PLL_LOCK,
    PUB, FPGAGOOD, XTLCLK,
    RTCCLK, SELMODE, RTC_MODE,
    vcc_good
  );
  output gclk40,gclk100,gclk10,gclk_xtal;
  output PLL_LOCK;

  input  PUB;
  output FPGAGOOD;
  input  XTLCLK;
  output RTCCLK;
  input  SELMODE;
  input  [1:0] RTC_MODE;
  input  vcc_good;

  //clock infrastructure 
  wire rcclk;

  rcclock rcclock(
    .CLKOUT(rcclk)
  );

  clocks clocks(
    .POWERDOWN(vcc_good), //active low
    .CLKA(rcclk),
    .GLA(gclk100),.GLB(gclk40),.GLC(gclk10),
    .OADIVRST(1'b0),
    .LOCK(PLL_LOCK)
  );

  // RTC bits
  xtalclk xtalclk(
    .XTL(XTLCLK),
    .CLKOUT(RTCCLK),
    .SELMODE(SELMODE), .RTC_MODE(RTC_MODE),
    .gclk_xtal(gclk_xtal)
  );
  
  // Voltage regulator monitor
  vrpsm vrpsm_0(
    .PUB(PUB),.VRPU(vcc_good),.FPGAGOOD(FPGAGOOD),.RTCPSMMATCH(1'b0)
  );

endmodule
