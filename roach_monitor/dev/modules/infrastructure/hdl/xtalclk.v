module xtalclk(
    XTL,
    CLKOUT,
    SELMODE,
    RTC_MODE
  );
  input  XTL;
  output CLKOUT;
  input  SELMODE;
  input  [1:0] RTC_MODE;

  XTLOSC XTLOSC_inst_0(
    .XTL(XTL), .CLKOUT(CLKOUT), .SELMODE(SELMODE), 
    .MODE({1'b0, 1'b0}), .RTCMODE(RTC_MODE)
  );
    
endmodule
