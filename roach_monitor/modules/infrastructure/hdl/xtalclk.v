module xtalclk(
    XTL,
    CLKOUT,
    SELMODE,
    RTC_MODE,
    gclk_xtal
  );
  input  XTL;
  output CLKOUT;
  input  SELMODE;
  input  [1:0] RTC_MODE;
  output gclk_xtal;

  wire clk_int;

  XTLOSC XTLOSC_inst_0(
  //.XTL(XTL), .CLKOUT(clk_int), .SELMODE(1'b0), 
  //.MODE({1'b0, 1'b1}), .RTCMODE(RTC_MODE)
    .XTL(XTL), .CLKOUT(clk_int), .SELMODE(1'b0), 
    .MODE({1'b0, 1'b1}), .RTCMODE(2'b0)
  );
  assign CLKOUT = 1'b0;

  CLKSRC clksrc_xtalosc (
    .A(clk_int),
    .Y(gclk_xtal)
  );
    
endmodule
