`timescale 1ns/10ps
module infrastructure(
    reset,
    gclk40,gclk100,gclk10,
    PLL_LOCK,
    PUB, FPGAGOOD, XTLCLK,
    RTCCLK, SELMODE, RTC_MODE
  );
  input  reset;
  output gclk40,gclk100,gclk10;
  output PLL_LOCK;

  input  PUB;
  output FPGAGOOD;
  input  XTLCLK;
  output RTCCLK;
  input  SELMODE;
  input  [1:0] RTC_MODE;

  //clock infrastructure 
  wire rcclk;

  rcclock rcclock(
    .CLKOUT(rcclk)
  );

  clocks clocks(
    .POWERDOWN(1'b1),
    .CLKA(rcclk),
    .GLA(gclk100),.GLB(gclk40),.GLC(gclk10),
    .OADIVRST(1'b0),
    .LOCK(PLL_LOCK)
  );

  // RTC bits
  xtalclk xtalclk(
    .XTL(XTLCLK),
    .CLKOUT(RTCCLK),
    .SELMODE(SELMODE), .RTC_MODE(RTC_MODE)
  );
  
  // Voltage regulator monitor
  vrpsm vrpsm_0(
    .PUB(PUB),.VRPU(1'b1),.FPGAGOOD(FPGAGOOD),.RTCPSMMATCH(1'b0)
  );

endmodule
