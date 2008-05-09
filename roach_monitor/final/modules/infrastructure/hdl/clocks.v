`define PLL_INPUT_DIVIDE    (7'd19)
`define PLL_FEEDBACK_DIVIDE (7'd38)

/*CLKA == 100, CLKB == 40, CLKC == 10*/
`define PLL_AOUT_DIVIDE     (5'd2 )
`define PLL_BOUT_DIVIDE     (5'd5 )
`define PLL_COUT_DIVIDE     (5'd20)

`define PLL_VCO_FREQ        200.00

module clocks(
    POWERDOWN,
    CLKA,
    LOCK,
    GLA,
    GLB,
    GLC,
    OADIVRST
  );
  input   POWERDOWN, CLKA;
  output  LOCK, GLA, GLB, GLC;
  input   OADIVRST;
  
  wire [6:0] fb_div;
  wire [6:0] in_div;
  wire [4:0] a_div;
  wire [4:0] b_div;
  wire [4:0] c_div;

  assign fb_div = (`PLL_FEEDBACK_DIVIDE) - 7'b1;
  assign in_div = (`PLL_INPUT_DIVIDE)    - 7'b1;
  assign a_div  = (`PLL_AOUT_DIVIDE)     - 5'b1;
  assign b_div  = (`PLL_BOUT_DIVIDE)     - 5'b1;
  assign c_div  = (`PLL_COUT_DIVIDE)     - 5'b1;
    
  PLL PLL_inst(
    /* Input Clock */
    .CLKA(CLKA), 
    /* Clock outputs, 3xGlobal, 2xlocal */
    .GLA(GLA), .GLB(GLB), .GLC(GLC),
    .YB(), .YC(),
    /* Power-down the PLL */
    .POWERDOWN(POWERDOWN), 
    /* PLL Lock */
    .LOCK(LOCK),
   
    /*PLL Reset*/
    .OADIVRST(OADIVRST), 
    /*Double CLKA clock
     * 0 - not doubled
     * 1 - doubled*/
    .OADIVHALF(1'b0),
    
    /* External Feedback signal*/
    .EXTFB(1'b0), 
    /* Feedback Input select
     * 01 - PLL
     * 10 - PLL with delay
     * 11 - external */
    .FBSEL1(1'b0), .FBSEL0(1'b1),
    /*PLL Fixed Delay Select ~ 2.29ns
     * 0 - off
     * 1 - on*/
    .XDLYSEL(1'b0),
    
    /* VCO range Select
     * 
     */
    .VCOSEL2(1'b1), .VCOSEL1(1'b1), .VCOSEL0(1'b0),
    
    /*Ouput Dividers:
     * div == O.DIV[4:0] +1 */
    .OADIV4(a_div[4]), .OADIV3(a_div[3]), .OADIV2(a_div[2]), .OADIV1(a_div[1]), .OADIV0(a_div[0]),
    .OBDIV4(b_div[4]), .OBDIV3(b_div[3]), .OBDIV2(b_div[2]), .OBDIV1(b_div[1]), .OBDIV0(b_div[0]),
    .OCDIV4(c_div[4]), .OCDIV3(c_div[3]), .OCDIV2(c_div[2]), .OCDIV1(c_div[1]), .OCDIV0(c_div[0]), 
    
    /* Delays for 3xglobal & 2x local clocks
     * 1 bit === 200ps approx ~ T*/
    .DLYGLA0(1'b0), .DLYGLA1(1'b0), .DLYGLA2(1'b0), .DLYGLA3(1'b0), .DLYGLA4(1'b0),
    .DLYGLB0(1'b0), .DLYGLB1(1'b0), .DLYGLB2(1'b0), .DLYGLB3(1'b0), .DLYGLB4(1'b0),
    .DLYGLC0(1'b0), .DLYGLC1(1'b0), .DLYGLC2(1'b0), .DLYGLC3(1'b0), .DLYGLC4(1'b0),
    .DLYYB0( 1'b0),  .DLYYB1(1'b0),  .DLYYB2(1'b0),  .DLYYB3(1'b0),  .DLYYB4(1'b0),
    .DLYYC0( 1'b0),  .DLYYC1(1'b0),  .DLYYC2(1'b0),  .DLYYC3(1'b0),  .DLYYC4(1'b0),
   
    /* Clock Output MUX
     * 000 -- External Source
     * 010 -- PLL with delay
     * 100 -- PLL*/
    .OAMUX2(1'b1), .OAMUX1(1'b0), .OAMUX0(1'b0),
    /* 001 -- External Source
     * 010 -- PLL with delay
     * 100 -- PLL*/
    .OBMUX2(1'b1), .OBMUX1(1'b0), .OBMUX0(1'b0), 
    /* 001 -- External Source
     * 010 -- PLL with delay
     * 100 -- PLL*/
    .OCMUX2(1'b1), .OCMUX1(1'b0), .OCMUX0(1'b0),
    
    /*Input Divider
     * div == FINDIV[6:0] + 1*/
    .FINDIV6(in_div[6]), .FINDIV5(in_div[5]), .FINDIV4(in_div[4]), .FINDIV3(in_div[3]),
    .FINDIV2(in_div[2]), .FINDIV1(in_div[1]), .FINDIV0(in_div[0]), 
    /*PLL FeedBack Divide -- FBDIV[6:0] + 1 */
    .FBDIV6(fb_div[6]), .FBDIV5(fb_div[5]), .FBDIV4(fb_div[4]), .FBDIV3(fb_div[3]),
    .FBDIV2(fb_div[2]), .FBDIV1(fb_div[1]), .FBDIV0(fb_div[0]),
    /*Feedback Delay
     * 1bit === 200ps*/
    .FBDLY0(1'b0), .FBDLY1(1'b0), .FBDLY2(1'b0), .FBDLY3(1'b0), .FBDLY4(1'b0)
  );
  defparam PLL_inst.VCOFREQUENCY = (`PLL_VCO_FREQ);
endmodule
