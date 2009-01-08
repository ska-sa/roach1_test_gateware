
module rcclock(
    CLKOUT
  );
  output CLKOUT;

  RCOSC RCOSC1(
    .CLKOUT(CLKOUT)
  );

endmodule
