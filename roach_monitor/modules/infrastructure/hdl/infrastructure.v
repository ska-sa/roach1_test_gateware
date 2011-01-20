`timescale 1ns/10ps
module infrastructure(
    gclk33, gclk_xtal,
    PUB, FPGAGOOD, XTLCLK,
    RTCCLK, SELMODE, RTC_MODE,
    vcc_good
  );
  output gclk33, gclk_xtal;

  input  PUB;
  output FPGAGOOD;
  input  XTLCLK;
  output RTCCLK;
  input  SELMODE;
  input  [1:0] RTC_MODE;
  input  vcc_good;

  //clock infrastructure 
  wire rcclk;

  clock clock(
    .CLK(gclk33)
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
