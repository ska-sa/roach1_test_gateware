
module clock(
   output CLK
  );

  wire rcclk_100;

  RCOSC RCOSC1(
    .CLKOUT(rcclk_100)
  );
  wire GL;
  assign CLK = GL;

  CLKDIVDLY clkdivdly_inst(
    .CLK      (rcclk_100),
    .RESET    (1'b0),
    .GL       (GL),
    .ODIV0    (1'b0),
    .ODIV1    (1'b1),
    .ODIV2    (1'b0),
    .ODIV3    (1'b0),
    .ODIV4    (1'b0), 
    .ODIVHALF (1'b0),
    .DLYGL0   (1'b0),
    .DLYGL1   (1'b0),
    .DLYGL2   (1'b0), 
    .DLYGL3   (1'b0),
    .DLYGL4   (1'b0)
  );
                              

endmodule
