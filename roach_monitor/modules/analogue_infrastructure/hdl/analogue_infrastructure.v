`timescale 1 ns/10 ps


module analogue_infrastructure(
    SYS_CLK,
    AG,AG_EN,AV,AC,AT,ATRETURN,
    ADC_START,ADC_SAMPLE,ADC_CHNUM,ADC_CALIBRATE,ADC_BUSY,ADC_DATAVALID,ADC_RESULT,ADCRESET,
    ACM_DATAR,ACM_DATAW,ACM_ADDR,ACM_CLK,ACM_WEN, ACM_RESET,
    RTCCLK,SELMODE,RTCMATCH,RTCPSMMATCH,RTCXTLMODE,
    VAREF,
    cmstrb, tmstrb, tmstrb_int, fast_mode
  );
  input  SYS_CLK;
  
  output [9:0] AG;
  input  [9:0] AG_EN;
  input  [9:0] AV,AC,AT;
  input  [4:0] ATRETURN;
  
  input  ADC_START,ADCRESET;
  output ADC_SAMPLE;
  input  [4:0] ADC_CHNUM;
  output ADC_CALIBRATE,ADC_BUSY,ADC_DATAVALID;
  output [11:0] ADC_RESULT;
  
  output [7:0] ACM_DATAR;
  input  [7:0] ACM_DATAW;
  input  [7:0] ACM_ADDR;
  input  ACM_CLK,ACM_WEN, ACM_RESET;        
  
  input  RTCCLK;
  output [1:0] RTCXTLMODE;
  output RTCMATCH,RTCPSMMATCH,SELMODE;
  
  inout  VAREF;
  input  [9:0] cmstrb;
  input  [9:0] tmstrb;
  input  tmstrb_int;
  
  input  fast_mode;

  wire [7:0] adc_clkdivide;
  wire [7:0] adc_sampletime;

  wire [9:0] AG_net;
  wire [9:0] AV_net,AC_net,AT_net;
  wire [4:0] ATRETURN_net;

  OUTBUF_A AG0_PAD (.D(AG_net[0]), .PAD(AG[0]));
  OUTBUF_A AG1_PAD (.D(AG_net[1]), .PAD(AG[1]));
  OUTBUF_A AG2_PAD (.D(AG_net[2]), .PAD(AG[2]));
  OUTBUF_A AG3_PAD (.D(AG_net[3]), .PAD(AG[3]));
  OUTBUF_A AG4_PAD (.D(AG_net[4]), .PAD(AG[4]));
  OUTBUF_A AG5_PAD (.D(AG_net[5]), .PAD(AG[5]));
  OUTBUF_A AG6_PAD (.D(AG_net[6]), .PAD(AG[6]));
  OUTBUF_A AG7_PAD (.D(AG_net[7]), .PAD(AG[7]));
  OUTBUF_A AG8_PAD (.D(AG_net[8]), .PAD(AG[8]));
  OUTBUF_A AG9_PAD (.D(AG_net[9]), .PAD(AG[9]));
  
  INBUF_A AV0_PAD (.Y(AV_net[0]), .PAD(AV[0]));
  INBUF_A AV1_PAD (.Y(AV_net[1]), .PAD(AV[1]));
  INBUF_A AV2_PAD (.Y(AV_net[2]), .PAD(AV[2]));
  INBUF_A AV3_PAD (.Y(AV_net[3]), .PAD(AV[3]));
  INBUF_A AV4_PAD (.Y(AV_net[4]), .PAD(AV[4]));
  INBUF_A AV5_PAD (.Y(AV_net[5]), .PAD(AV[5]));
  INBUF_A AV6_PAD (.Y(AV_net[6]), .PAD(AV[6]));
  INBUF_A AV7_PAD (.Y(AV_net[7]), .PAD(AV[7]));
  INBUF_A AV8_PAD (.Y(AV_net[8]), .PAD(AV[8]));
  INBUF_A AV9_PAD (.Y(AV_net[9]), .PAD(AV[9]));
  
  INBUF_A AC0_PAD (.Y(AC_net[0]), .PAD(AC[0]));
  INBUF_A AC1_PAD (.Y(AC_net[1]), .PAD(AC[1]));
  INBUF_A AC2_PAD (.Y(AC_net[2]), .PAD(AC[2]));
  INBUF_A AC3_PAD (.Y(AC_net[3]), .PAD(AC[3]));
  INBUF_A AC4_PAD (.Y(AC_net[4]), .PAD(AC[4]));
  INBUF_A AC5_PAD (.Y(AC_net[5]), .PAD(AC[5]));
  INBUF_A AC6_PAD (.Y(AC_net[6]), .PAD(AC[6]));
  INBUF_A AC7_PAD (.Y(AC_net[7]), .PAD(AC[7]));
  INBUF_A AC8_PAD (.Y(AC_net[8]), .PAD(AC[8]));
  INBUF_A AC9_PAD (.Y(AC_net[9]), .PAD(AC[9]));
  
  INBUF_A AT0_PAD (.Y(AT_net[0]), .PAD(AT[0]));
  INBUF_A AT1_PAD (.Y(AT_net[1]), .PAD(AT[1]));
  INBUF_A AT2_PAD (.Y(AT_net[2]), .PAD(AT[2]));
  INBUF_A AT3_PAD (.Y(AT_net[3]), .PAD(AT[3]));
  INBUF_A AT4_PAD (.Y(AT_net[4]), .PAD(AT[4]));
  INBUF_A AT5_PAD (.Y(AT_net[5]), .PAD(AT[5]));
  INBUF_A AT6_PAD (.Y(AT_net[6]), .PAD(AT[6]));
  INBUF_A AT7_PAD (.Y(AT_net[7]), .PAD(AT[7]));
  INBUF_A AT8_PAD (.Y(AT_net[8]), .PAD(AT[8]));
  INBUF_A AT9_PAD (.Y(AT_net[9]), .PAD(AT[9]));
  
  INBUF_A ATRETURN0_PAD (.Y(ATRETURN_net[0]), .PAD(ATRETURN[0]));
  INBUF_A ATRETURN1_PAD (.Y(ATRETURN_net[1]), .PAD(ATRETURN[1]));
  INBUF_A ATRETURN2_PAD (.Y(ATRETURN_net[2]), .PAD(ATRETURN[2]));
  INBUF_A ATRETURN3_PAD (.Y(ATRETURN_net[3]), .PAD(ATRETURN[3]));
  INBUF_A ATRETURN4_PAD (.Y(ATRETURN_net[4]), .PAD(ATRETURN[4]));
    
  AB AB_INST (
    // digital outputs 
    .DAVOUT0(), .DACOUT0(), .DATOUT0(),
    .DAVOUT1(), .DACOUT1(), .DATOUT1(),
    .DAVOUT2(), .DACOUT2(), .DATOUT2(),
    .DAVOUT3(), .DACOUT3(), .DATOUT3(),
    .DAVOUT4(), .DACOUT4(), .DATOUT4(),
    .DAVOUT5(), .DACOUT5(), .DATOUT5(),
    .DAVOUT6(), .DACOUT6(), .DATOUT6(),
    .DAVOUT7(), .DACOUT7(), .DATOUT7(),
    .DAVOUT8(), .DACOUT8(), .DATOUT8(),
    .DAVOUT9(), .DACOUT9(), .DATOUT9(),
    //digital input enables
    .DENAV0(1'b0), .DENAC0(1'b0), .DENAT0(1'b0),
    .DENAV1(1'b0), .DENAC1(1'b0), .DENAT1(1'b0),
    .DENAV2(1'b0), .DENAC2(1'b0), .DENAT2(1'b0),
    .DENAV3(1'b0), .DENAC3(1'b0), .DENAT3(1'b0),
    .DENAV4(1'b0), .DENAC4(1'b0), .DENAT4(1'b0),
    .DENAV5(1'b0), .DENAC5(1'b0), .DENAT5(1'b0),
    .DENAV6(1'b0), .DENAC6(1'b0), .DENAT6(1'b0),
    .DENAV7(1'b0), .DENAC7(1'b0), .DENAT7(1'b0),
    .DENAV8(1'b0), .DENAC8(1'b0), .DENAT8(1'b0),
    .DENAV9(1'b0), .DENAC9(1'b0), .DENAT9(1'b0),
    //analog block pads
    .AV0(AV_net[0]), .AC0(AC_net[0]), .AT0(AT_net[0]), .AG0(AG_net[0]),
    .AV1(AV_net[1]), .AC1(AC_net[1]), .AT1(AT_net[1]), .AG1(AG_net[1]),
    .AV2(AV_net[2]), .AC2(AC_net[2]), .AT2(AT_net[2]), .AG2(AG_net[2]),
    .AV3(AV_net[3]), .AC3(AC_net[3]), .AT3(AT_net[3]), .AG3(AG_net[3]),
    .AV4(AV_net[4]), .AC4(AC_net[4]), .AT4(AT_net[4]), .AG4(AG_net[4]),
    .AV5(AV_net[5]), .AC5(AC_net[5]), .AT5(AT_net[5]), .AG5(AG_net[5]),
    .AV6(AV_net[6]), .AC6(AC_net[6]), .AT6(AT_net[6]), .AG6(AG_net[6]),
    .AV7(AV_net[7]), .AC7(AC_net[7]), .AT7(AT_net[7]), .AG7(AG_net[7]),
    .AV8(AV_net[8]), .AC8(AC_net[8]), .AT8(AT_net[8]), .AG8(AG_net[8]),
    .AV9(AV_net[9]), .AC9(AC_net[9]), .AT9(AT_net[9]), .AG9(AG_net[9]),
    .ATRETURN01(ATRETURN_net[0]), .ATRETURN23(ATRETURN_net[1]),
    .ATRETURN45(ATRETURN_net[2]), .ATRETURN67(ATRETURN_net[3]), .ATRETURN89(ATRETURN_net[4]),
    //gate driver enable
    .GDON0(AG_EN[0]), .GDON1(AG_EN[1]), .GDON2(AG_EN[2]), .GDON3(AG_EN[3]), .GDON4(AG_EN[4]),
    .GDON5(AG_EN[5]), .GDON6(AG_EN[6]), .GDON7(AG_EN[7]), .GDON8(AG_EN[8]), .GDON9(AG_EN[9]),
    //current monitor strobes
    .CMSTB0(cmstrb[0]), .CMSTB1(cmstrb[1]), .CMSTB2(cmstrb[2]), .CMSTB3(cmstrb[3]), .CMSTB4(cmstrb[4]),
    .CMSTB5(cmstrb[5]), .CMSTB6(cmstrb[6]), .CMSTB7(cmstrb[7]), .CMSTB8(cmstrb[8]), .CMSTB9(cmstrb[9]),
    //temperature monitor strobes
    .TMSTB0(tmstrb[0]), .TMSTB1(tmstrb[1]), .TMSTB2(tmstrb[2]), .TMSTB3(tmstrb[3]), .TMSTB4(tmstrb[4]),
    .TMSTB5(tmstrb[5]), .TMSTB6(tmstrb[6]), .TMSTB7(tmstrb[7]), .TMSTB8(tmstrb[8]), .TMSTB9(tmstrb[9]),
    .TMSTBINT(tmstrb_int),
    //ADC CONTROL
    .ADCRESET(ADCRESET), .ADCSTART(ADC_START), .CHNUMBER(ADC_CHNUM),
    .CALIBRATE(ADC_CALIBRATE), .SAMPLE(ADC_SAMPLE), .BUSY(ADC_BUSY),
    .DATAVALID(ADC_DATAVALID), .RESULT(ADC_RESULT),
    //Clock Divide control, Sample Time Control, Sample Mode
    //.TVC(adc_clkdivide), .STC(adc_sampletime), .MODE(4'b1001),
    .TVC(adc_clkdivide), .STC(adc_sampletime), .MODE(4'b0101),
    //Analog Configuration MUX [ACM] interface 
    .ACMRDATA(ACM_DATAR), .ACMWDATA(ACM_DATAW), .ACMADDR(ACM_ADDR), .ACMCLK(ACM_CLK), .ACMWEN(ACM_WEN), .ACMRESET(ACM_RESET),        
    //Real time clock pins
    .RTCCLK(RTCCLK), .RTCMATCH(RTCMATCH), .RTCPSMMATCH(RTCPSMMATCH), .RTCXTLSEL(SELMODE), .RTCXTLMODE(RTCXTLMODE),
    //reference pins
    .VAREFSEL(1'b0), .VAREF(VAREF), .GNDREF(1'b0),
    //System signals
    .SYSCLK(SYS_CLK), .PWRDWN(1'b0)
  );
 
  assign adc_clkdivide  = fast_mode ? 8'd1 : 8'd9;  /* quick */
  assign adc_sampletime = fast_mode ? 8'd4 : 8'd36; /* 40us */


endmodule
