//---- MODULE FIFO4K18 ----
/*---------------------------------------------------------------
 CELL NAME : FIFO4K18
 CELL TYPE : FIFO
-----------------------------------------------------------------*/

module FIFO4K18 (AEVAL11, AEVAL10, AEVAL9, AEVAL8, AEVAL7, AEVAL6, 
                 AEVAL5, AEVAL4, AEVAL3, AEVAL2, AEVAL1, AEVAL0, 
                 AFVAL11, AFVAL10, AFVAL9, AFVAL8, AFVAL7, AFVAL6, 
                 AFVAL5, AFVAL4, AFVAL3, AFVAL2, AFVAL1, AFVAL0, 
                 REN, RBLK, RCLK, RESET, RPIPE, WEN, WBLK, WCLK,
                 RW2, RW1, RW0, WW2, WW1, WW0, ESTOP, FSTOP,
                 WD17, WD16, WD15, WD14, WD13, WD12, WD11, WD10, 
                 WD9, WD8, WD7, WD6, WD5, WD4, WD3, WD2, WD1, WD0, 
                 RD17, RD16, RD15, RD14, RD13, RD12, RD11, RD10, 
                 RD9, RD8, RD7, RD6, RD5, RD4, RD3, RD2, RD1, RD0, 
                 FULL, AFULL, EMPTY, AEMPTY
                );
`ifdef WARNING_MSGS_ON
  parameter WARNING_MSGS_ON = 1; 
`else
  parameter WARNING_MSGS_ON = 0; 
`endif

input AEVAL11, AEVAL10, AEVAL9, AEVAL8, AEVAL7, AEVAL6;
input AEVAL5, AEVAL4, AEVAL3, AEVAL2, AEVAL1, AEVAL0;
input AFVAL11, AFVAL10, AFVAL9, AFVAL8, AFVAL7, AFVAL6;
input AFVAL5, AFVAL4, AFVAL3, AFVAL2, AFVAL1, AFVAL0;
input REN, RBLK, RCLK, RESET, RPIPE, WEN, WBLK, WCLK;
input RW2, RW1, RW0, WW2, WW1, WW0, ESTOP, FSTOP;
input WD17, WD16, WD15, WD14, WD13, WD12, WD11, WD10;
input WD9, WD8, WD7, WD6, WD5, WD4, WD3, WD2, WD1, WD0;

output RD17, RD16, RD15, RD14, RD13, RD12, RD11, RD10;
output RD9, RD8, RD7, RD6, RD5, RD4, RD3, RD2, RD1, RD0;
output FULL, AFULL, EMPTY, AEMPTY;

reg FULLP, AFULLP, EMPTYP, AEMPTYP;
reg [18:0] FIFO[0:512];
reg NOTIFY_REG;

wire AEVAL11_int, AEVAL10_int, AEVAL9_int, AEVAL8_int, AEVAL7_int;
wire AEVAL6_int, AEVAL5_int, AEVAL4_int, AEVAL3_int, AEVAL2_int;
wire AEVAL1_int, AEVAL0_int;
wire AFVAL11_int, AFVAL10_int, AFVAL9_int, AFVAL8_int, AFVAL7_int;
wire AFVAL6_int, AFVAL5_int, AFVAL4_int, AFVAL3_int, AFVAL2_int;
wire AFVAL1_int, AFVAL0_int;
wire REN_int, RBLK_int, RCLK_int, RESET_int, RPIPE_int;
wire WEN_int, WBLK_int, WCLK_int;
wire RW2_int, RW1_int, RW0_int;
wire WW2_int, WW1_int, WW0_int;
wire ESTOP_int, FSTOP_int;  
wire WD17_int, WD16_int, WD15_int, WD14_int, WD13_int, WD12_int;
wire WD11_int, WD10_int, WD9_int, WD8_int, WD7_int, WD6_int;
wire WD5_int, WD4_int, WD3_int, WD2_int, WD1_int, WD0_int;

reg RDP17, RDP16, RDP15, RDP14, RDP13, RDP12, RDP11, RDP10, RDP9;
reg RDP8, RDP7, RDP6, RDP5, RDP4, RDP3, RDP2, RDP1, RDP0;

reg RD17_stg, RD16_stg, RD15_stg, RD14_stg, RD13_stg, RD12_stg;
reg RD11_stg, RD10_stg, RD9_stg, RD8_stg, RD7_stg;
reg RD6_stg, RD5_stg, RD4_stg, RD3_stg, RD2_stg, RD1_stg, RD0_stg;

`define RDATAP_WIDTH_18 {RDP17, RDP16, RDP15, RDP14, RDP13, RDP12, RDP11, RDP10, RDP9, RDP8, RDP7, RDP6, RDP5, RDP4, RDP3, RDP2, RDP1, RDP0}
`define RWIDTH_CFG_VECTOR {RW2_int, RW1_int, RW0_int}
`define WWIDTH_CFG_VECTOR {WW2_int, WW1_int, WW0_int}
`define AEMPTY_CFG_VECTOR {AEVAL11_int, AEVAL10_int, AEVAL9_int, AEVAL8_int, AEVAL7_int, AEVAL6_int, AEVAL5_int, AEVAL4_int, AEVAL3_int, AEVAL2_int, AEVAL1_int, AEVAL0_int}
`define AFULL_CFG_VECTOR  {AFVAL11_int, AFVAL10_int, AFVAL9_int, AFVAL8_int, AFVAL7_int, AFVAL6_int, AFVAL5_int, AFVAL4_int, AFVAL3_int, AFVAL2_int, AFVAL1_int, AFVAL0_int}

integer MAX_DEPTH;

reg [4095:0] MEM;
reg [511 :0] MEM9;

wire WENABLE; 
wire RENABLE; 

buf AFU0  (AFVAL0_int,  AFVAL0);
buf AFU1  (AFVAL1_int,  AFVAL1);
buf AFU2  (AFVAL2_int,  AFVAL2);
buf AFU3  (AFVAL3_int,  AFVAL3);
buf AFU4  (AFVAL4_int,  AFVAL4);
buf AFU5  (AFVAL5_int,  AFVAL5);
buf AFU6  (AFVAL6_int,  AFVAL6);
buf AFU7  (AFVAL7_int,  AFVAL7);
buf AFU8  (AFVAL8_int,  AFVAL8);
buf AFU9  (AFVAL9_int,  AFVAL9);
buf AFU10 (AFVAL10_int, AFVAL10);
buf AFU11 (AFVAL11_int, AFVAL11);

buf AEU0  (AEVAL0_int,  AEVAL0);
buf AEU1  (AEVAL1_int,  AEVAL1);
buf AEU2  (AEVAL2_int,  AEVAL2);
buf AEU3  (AEVAL3_int,  AEVAL3);
buf AEU4  (AEVAL4_int,  AEVAL4);
buf AEU5  (AEVAL5_int,  AEVAL5);
buf AEU6  (AEVAL6_int,  AEVAL6);
buf AEU7  (AEVAL7_int,  AEVAL7);
buf AEU8  (AEVAL8_int,  AEVAL8);
buf AEU9  (AEVAL9_int,  AEVAL9);
buf AEU10 (AEVAL10_int, AEVAL10);
buf AEU11 (AEVAL11_int, AEVAL11);

buf WDU0  (WD0_int,     WD0);
buf WDU1  (WD1_int,     WD1);
buf WDU2  (WD2_int,     WD2);
buf WDU3  (WD3_int,     WD3);
buf WDU4  (WD4_int,     WD4);
buf WDU5  (WD5_int,     WD5);
buf WDU6  (WD6_int,     WD6);
buf WDU7  (WD7_int,     WD7);
buf WDU8  (WD8_int,     WD8);
buf WDU9  (WD9_int,     WD9);
buf WDU10 (WD10_int,    WD10);
buf WDU11 (WD11_int,    WD11);
buf WDU12 (WD12_int,    WD12);
buf WDU13 (WD13_int,    WD13);
buf WDU14 (WD14_int,    WD14);
buf WDU15 (WD15_int,    WD15);
buf WDU16 (WD16_int,    WD16);
buf WDU17 (WD17_int,    WD17);

buf WWU2  (WW2_int,     WW2);
buf WWU1  (WW1_int,     WW1);
buf WWU0  (WW0_int,     WW0);

buf RWU2  (RW2_int,     RW2);
buf RWU1  (RW1_int,     RW1);
buf RWU0  (RW0_int,     RW0);

buf RENU  (REN_int,     REN);
buf WENU  (WEN_int,     WEN);
buf RBLKU (RBLK_int,    RBLK);
buf WBLKU (WBLK_int,    WBLK);

buf WCLKU (WCLK_int,    WCLK);
buf RCLKU (RCLK_int,    RCLK);

buf RESETU (RESET_int,  RESET);
buf ESTOPU (ESTOP_int,  ESTOP);
buf FSTOPU (FSTOP_int,  FSTOP);
buf RPIPEU (RPIPE_int,  RPIPE);


pmos RDU0  (RD0,  RDP0,  0);
pmos RDU1  (RD1,  RDP1,  0);
pmos RDU2  (RD2,  RDP2,  0);
pmos RDU3  (RD3,  RDP3,  0);
pmos RDU4  (RD4,  RDP4,  0);
pmos RDU5  (RD5,  RDP5,  0);
pmos RDU6  (RD6,  RDP6,  0);
pmos RDU7  (RD7,  RDP7,  0);
pmos RDU8  (RD8,  RDP8,  0);
pmos RDU9  (RD9,  RDP9,  0);
pmos RDU10 (RD10, RDP10, 0);
pmos RDU11 (RD11, RDP11, 0);
pmos RDU12 (RD12, RDP12, 0);
pmos RDU13 (RD13, RDP13, 0);
pmos RDU14 (RD14, RDP14, 0);
pmos RDU15 (RD15, RDP15, 0);
pmos RDU16 (RD16, RDP16, 0);
pmos RDU17 (RD17, RDP17, 0);

pmos AEMPTYU (AEMPTY, AEMPTYP, 0);
pmos EMPTYU  (EMPTY,  EMPTYP,  0);
pmos AFULLU  (AFULL,  AFULLP,  0);
pmos FULLU   (FULL,   FULLP,   0);

integer MAX_ADDR;
integer WADDR;
integer WADDR_P1;
integer WADDR_P2;
integer RADDR;
integer RADDR_P1;
integer RADDR_P2;
integer BIT_WADDR;
integer BIT_RADDR;
integer WADDR_wrap;
integer WADDR_wrap_P1;
integer WADDR_wrap_P2;
integer RADDR_wrap;
integer RADDR_wrap_P1;
integer RADDR_wrap_P2;

integer AEVAL;
integer AFVAL;

integer wdepth;
integer rdepth;

initial begin
  MAX_DEPTH     <= 4096;
  WADDR         <= 0;
  WADDR_P1      <= 0;
  WADDR_P2      <= 0;
  RADDR         <= 0;
  RADDR_P1      <= 0;
  RADDR_P2      <= 0;
  WADDR_wrap    <= 0;
  WADDR_wrap_P1 <= 0;
  WADDR_wrap_P2 <= 0;
  RADDR_wrap    <= 0;
  RADDR_wrap_P1 <= 1;
  RADDR_wrap_P2 <= 1;
  EMPTYP        <= 1'bx;
  AEMPTYP       <= 1'bx;
  FULLP         <= 1'bx;
  AFULLP        <= 1'bx;
  `RDATAP_WIDTH_18 <= 18'bx;
end

assign WENABLE = RESET_int & ~WEN_int & ~WBLK_int; 
assign RENABLE = RESET_int &  REN_int & ~RBLK_int; 

always @(WCLK_int === 1'bx ) begin
  if ($time > 0) begin
    if (WENABLE == 1'b1) begin
            if ( WARNING_MSGS_ON )
      $display("Warning : WCLK went unknown at time %0.1f\n", $realtime);
    end
  end
end

always @(RCLK_int === 1'bx ) begin
  if ($time > 0) begin
    if (RENABLE == 1'b1) begin
            if ( WARNING_MSGS_ON )
      $display("Warning : RCLK went unknown at time %0.1f\n", $realtime);
    end
  end
end

// FIFO RESET behavior section

always @(RESET_int) begin
  if (RESET_int == 1'b0) begin
    WADDR         <= 0;
    WADDR_P1      <= 0;
    WADDR_P2      <= 0;
    WADDR_wrap    <= 0;
    WADDR_wrap_P1 <= 0;
    WADDR_wrap_P2 <= 0;
    RADDR         <= 0;
    RADDR_P1      <= 0;
    RADDR_P2      <= 0;
    RADDR_wrap    <= 0;
    RADDR_wrap_P1 <= 1;
    RADDR_wrap_P2 <= 1;
    FULLP         <= 1'b0;
    EMPTYP        <= 1'b1;
    AFULLP        <= 1'b0;
    AEMPTYP       <= 1'b1;
    `RDATAP_WIDTH_18 <= 18'b0;
    RD0_stg       <= 1'b0;
    RD1_stg       <= 1'b0;
    RD2_stg       <= 1'b0;
    RD3_stg       <= 1'b0;
    RD4_stg       <= 1'b0;
    RD5_stg       <= 1'b0;
    RD6_stg       <= 1'b0;
    RD7_stg       <= 1'b0;
    RD8_stg       <= 1'b0;
    RD9_stg       <= 1'b0;
    RD10_stg      <= 1'b0;
    RD11_stg      <= 1'b0;
    RD12_stg      <= 1'b0;
    RD13_stg      <= 1'b0;
    RD14_stg      <= 1'b0;
    RD15_stg      <= 1'b0;
    RD16_stg      <= 1'b0;
    RD17_stg      <= 1'b0;
  end else if (RESET_int == 1'bx) begin
    if ($time > 0) begin
            if ( WARNING_MSGS_ON )
      $display("Warning : RESET went unknown at time %0.1f\n", $realtime);
    end
  end
end

// FIFO WRITE behavior section

always @(posedge WCLK_int ) begin
  if (RESET_int == 1'b1) begin
    // Synchronizer needs two WCLKs to generate empty flag
    RADDR_P2 = RADDR_P1;
    RADDR_P1 = RADDR;
    RADDR_wrap_P2 = RADDR_wrap_P1;
    if (RADDR_wrap == 0) 
      RADDR_wrap_P1 = 1;
    else
      RADDR_wrap_P1 = 0;

    if ((WBLK_int == 1'b0) && (WEN_int == 1'b0)) begin
      if ( ! ((FULLP == 1'b1) && (FSTOP_int == 1'b1))) begin
        case (`WWIDTH_CFG_VECTOR)
          3'b000 : begin
            MEM[WADDR] <= WD0_int;
            wdepth = 4096;
            if (WADDR < wdepth - 1 ) begin
              WADDR = #0 WADDR + 1;
            end else begin
              WADDR = #0 0;
              WADDR_wrap = 1 - WADDR_wrap;
            end
          end
          3'b001 : begin
            MEM[(WADDR * 2) + 0] <= WD0_int;
            MEM[(WADDR * 2) + 1] <= WD1_int;
            wdepth = 2048;
            if (WADDR < wdepth - 1 ) begin
              WADDR = #0 WADDR + 1;
            end else begin
              WADDR = #0 0;
              WADDR_wrap = 1 - WADDR_wrap;
            end
          end
          3'b010 : begin
            MEM[(WADDR * 4) + 0] <= WD0_int;
            MEM[(WADDR * 4) + 1] <= WD1_int;
            MEM[(WADDR * 4) + 2] <= WD2_int;
            MEM[(WADDR * 4) + 3] <= WD3_int;
            wdepth = 1024; 
            if (WADDR < wdepth - 1 ) begin
              WADDR = #0 WADDR + 1;
            end else begin
              WADDR = #0 0;
              WADDR_wrap = 1 - WADDR_wrap;
            end
          end
          3'b011 : begin
            MEM[(WADDR * 8) + 0] <= WD0_int;
            MEM[(WADDR * 8) + 1] <= WD1_int;
            MEM[(WADDR * 8) + 2] <= WD2_int;
            MEM[(WADDR * 8) + 3] <= WD3_int;
            MEM[(WADDR * 8) + 4] <= WD4_int;
            MEM[(WADDR * 8) + 5] <= WD5_int;
            MEM[(WADDR * 8) + 6] <= WD6_int;
            MEM[(WADDR * 8) + 7] <= WD7_int;
            MEM9[WADDR] = WD8_int;
            wdepth = 512; 
            if (WADDR < wdepth - 1 ) begin
              WADDR = #0 WADDR + 1;
            end else begin
              WADDR = #0 0;
              WADDR_wrap = 1 - WADDR_wrap;
            end
          end
          3'b100 : begin
            MEM[(WADDR * 16) + 0] <= WD0_int;
            MEM[(WADDR * 16) + 1] <= WD1_int;
            MEM[(WADDR * 16) + 2] <= WD2_int;
            MEM[(WADDR * 16) + 3] <= WD3_int;
            MEM[(WADDR * 16) + 4] <= WD4_int;
            MEM[(WADDR * 16) + 5] <= WD5_int;
            MEM[(WADDR * 16) + 6] <= WD6_int;
            MEM[(WADDR * 16) + 7] <= WD7_int;
            MEM9[WADDR *   2 + 0] <= WD8_int;
            MEM[(WADDR * 16) + 8] <= WD9_int;
            MEM[(WADDR * 16) + 9] <= WD10_int;
            MEM[(WADDR * 16) + 10] <= WD11_int;
            MEM[(WADDR * 16) + 11] <= WD12_int;
            MEM[(WADDR * 16) + 12] <= WD13_int;
            MEM[(WADDR * 16) + 13] <= WD14_int;
            MEM[(WADDR * 16) + 14] <= WD15_int;
            MEM[(WADDR * 16) + 15] <= WD16_int;
            MEM9[WADDR * 2 + 1] <= WD17_int;
            wdepth = 256; 
            if (WADDR < wdepth - 1 ) begin
              WADDR = #0 WADDR + 1;
            end else begin
              WADDR = #0 0;
              WADDR_wrap = 1 - WADDR_wrap;
            end
          end
          default: begin
            if ( WARNING_MSGS_ON )
            $display("Warning: Illegal Write port width configuration");
          end
        endcase
      end // not (FULL and FSTOP)
    end // WBLK = 0 and WEN = 0
    else if (WBLK_int == 1'bx) begin
            if ( WARNING_MSGS_ON )
      $display("Warning: WBLK signal unknown.");
    end else if (WEN_int == 1'bx) begin
            if ( WARNING_MSGS_ON )
      $display("Warning: WEN signal unknown.");
    end
    fifo_flags(`AFULL_CFG_VECTOR, `AEMPTY_CFG_VECTOR, `RWIDTH_CFG_VECTOR,
               `WWIDTH_CFG_VECTOR);
  end // if RESET deasserted
end  // Write section

// FIFO READ behavior section

always @(posedge RCLK_int) begin
  if (RESET_int == 1'b1) begin
    // Synchronizer needs two RCLKs to generate empty flag
    WADDR_P2 = WADDR_P1;
    WADDR_P1 = WADDR;
    WADDR_wrap_P2 = WADDR_wrap_P1;
    WADDR_wrap_P1 = WADDR_wrap;

    if (RPIPE_int == 1'b1) begin // Pipelining on
      RDP0  <= RD0_stg;
      RDP1  <= RD1_stg;
      RDP2  <= RD2_stg;
      RDP3  <= RD3_stg;
      RDP4  <= RD4_stg;
      RDP5  <= RD5_stg;
      RDP6  <= RD6_stg;
      RDP7  <= RD7_stg;
      RDP8  <= RD8_stg;
      RDP9  <= RD9_stg;
      RDP10 <= RD10_stg;
      RDP11 <= RD11_stg;
      RDP12 <= RD12_stg;
      RDP13 <= RD13_stg;
      RDP14 <= RD14_stg;
      RDP15 <= RD15_stg;
      RDP16 <= RD16_stg;
      RDP17 <= RD17_stg;
    end
    else if (RPIPE_int === 1'bx ) begin // RPIPE unknown
            if ( WARNING_MSGS_ON )
      $display("Warning: RPIPE signal unknown.");
      RDP0  <= 1'bx;
      RDP1  <= 1'bx;
      RDP2  <= 1'bx;
      RDP3  <= 1'bx;
      RDP4  <= 1'bx;
      RDP5  <= 1'bx;
      RDP6  <= 1'bx;
      RDP7  <= 1'bx;
      RDP8  <= 1'bx;
      RDP9  <= 1'bx;
      RDP10 <= 1'bx;
      RDP11 <= 1'bx;
      RDP12 <= 1'bx;
      RDP13 <= 1'bx;
      RDP14 <= 1'bx;
      RDP15 <= 1'bx;
      RDP16 <= 1'bx;
      RDP17 <= 1'bx;
    end

    if ((RBLK_int == 1'b0) && (REN_int == 1'b1)) begin
      if ( ! ((EMPTYP == 1'b1) && (ESTOP_int == 1'b1))) begin // OK to Read
        if (RPIPE_int == 1'b0) begin // Pipelining off 
          case (`RWIDTH_CFG_VECTOR)
            3'b000 : begin
              RDP0  <= MEM[RADDR];
              rdepth = 4096;
              if (RADDR < rdepth - 1) begin
                RADDR = #0 RADDR + 1;
              end else begin
                RADDR = #0 0;
                RADDR_wrap = 1 - RADDR_wrap;
              end
            end
            3'b001 : begin
              RDP0  <= MEM[(RADDR * 2) + 0];
              RDP1  <= MEM[(RADDR * 2) + 1];
              rdepth = 2048;
              if (RADDR < rdepth - 1) begin
                RADDR = #0 RADDR + 1;
              end else begin
                RADDR = #0 0;
                RADDR_wrap = 1 - RADDR_wrap;
              end
            end
            3'b010 : begin
              RDP0  <= MEM[(RADDR * 4) + 0];
              RDP1  <= MEM[(RADDR * 4) + 1];
              RDP2  <= MEM[(RADDR * 4) + 2];
              RDP3  <= MEM[(RADDR * 4) + 3];
              rdepth = 1024;
              if (RADDR < rdepth - 1) begin
                RADDR = #0 RADDR + 1;
              end else begin
                RADDR = #0 0;
                RADDR_wrap = 1 - RADDR_wrap;
              end
            end
            3'b011 : begin
              RDP0  <= MEM[(RADDR * 8) + 0];
              RDP1  <= MEM[(RADDR * 8) + 1];
              RDP2  <= MEM[(RADDR * 8) + 2];
              RDP3  <= MEM[(RADDR * 8) + 3];
              RDP4  <= MEM[(RADDR * 8) + 4];
              RDP5  <= MEM[(RADDR * 8) + 5];
              RDP6  <= MEM[(RADDR * 8) + 6];
              RDP7  <= MEM[(RADDR * 8) + 7];
              RDP8  <= MEM9[RADDR];
              rdepth = 512;
              if (RADDR < rdepth - 1) begin
                RADDR = #0 RADDR + 1;
              end else begin
                RADDR = #0 0;
                RADDR_wrap = 1 - RADDR_wrap;
              end
            end
            3'b100 : begin
              RDP0  <= MEM[(RADDR * 16) + 0];
              RDP1  <= MEM[(RADDR * 16) + 1];
              RDP2  <= MEM[(RADDR * 16) + 2];
              RDP3  <= MEM[(RADDR * 16) + 3];
              RDP4  <= MEM[(RADDR * 16) + 4];
              RDP5  <= MEM[(RADDR * 16) + 5];
              RDP6  <= MEM[(RADDR * 16) + 6];
              RDP7  <= MEM[(RADDR * 16) + 7];
              RDP8  <= MEM9[RADDR*2 +0];
              RDP9  <= MEM[(RADDR * 16) + 8];
              RDP10 <= MEM[(RADDR * 16) + 9];
              RDP11 <= MEM[(RADDR * 16) + 10];
              RDP12 <= MEM[(RADDR * 16) + 11];
              RDP13 <= MEM[(RADDR * 16) + 12];
              RDP14 <= MEM[(RADDR * 16) + 13];
              RDP15 <= MEM[(RADDR * 16) + 14];
              RDP16 <= MEM[(RADDR * 16) + 15];
              RDP17 <= MEM9[RADDR * 2 + 1];
              rdepth = 256;
              if (RADDR < rdepth - 1) begin
                RADDR = #0 RADDR + 1;
              end else begin
                RADDR = #0 0;
                RADDR_wrap = 1 - RADDR_wrap;
              end
            end
            default: begin
            if ( WARNING_MSGS_ON )
              $display("Warning: Illegal Read port width configuration");
            end
          endcase
        end else if (RPIPE_int == 1'b1) begin // Pipelining on
          case (`RWIDTH_CFG_VECTOR)
            3'b000 : begin
              RD0_stg  <= MEM[RADDR];
              rdepth = 4096;
              if (RADDR < rdepth - 1) begin
                RADDR = #0 RADDR + 1;
              end else begin
                RADDR = #0 0;
                RADDR_wrap = 1 - RADDR_wrap;
              end
            end
            3'b001 : begin
              RD0_stg  <= MEM[(RADDR * 2) + 0];
              RD1_stg  <= MEM[(RADDR * 2) + 1];
              rdepth = 2048;
              if (RADDR < rdepth - 1) begin
                RADDR = #0 RADDR + 1;
              end else begin
                RADDR = #0 0;
                RADDR_wrap = 1 - RADDR_wrap;
              end
            end
            3'b010 : begin
              RD0_stg  <= MEM[(RADDR * 4) + 0];
              RD1_stg  <= MEM[(RADDR * 4) + 1];
              RD2_stg  <= MEM[(RADDR * 4) + 2];
              RD3_stg  <= MEM[(RADDR * 4) + 3];
              rdepth = 1024;
              if (RADDR < rdepth - 1) begin
                RADDR = #0 RADDR + 1;
              end else begin
                RADDR = #0 0;
                RADDR_wrap = 1 - RADDR_wrap;
              end
            end
            3'b011 : begin
              RD0_stg  <= MEM[(RADDR * 8) + 0];
              RD1_stg  <= MEM[(RADDR * 8) + 1];
              RD2_stg  <= MEM[(RADDR * 8) + 2];
              RD3_stg  <= MEM[(RADDR * 8) + 3];
              RD4_stg  <= MEM[(RADDR * 8) + 4];
              RD5_stg  <= MEM[(RADDR * 8) + 5];
              RD6_stg  <= MEM[(RADDR * 8) + 6];
              RD7_stg  <= MEM[(RADDR * 8) + 7];
              RD8_stg  <= MEM9[RADDR];
              rdepth = 512;
              if (RADDR < rdepth - 1) begin
                RADDR = #0 RADDR + 1;
              end else begin
                RADDR = #0 0;
                RADDR_wrap = 1 - RADDR_wrap;
              end
            end
            3'b100 : begin
              RD0_stg  <= MEM[(RADDR * 16) + 0];
              RD1_stg  <= MEM[(RADDR * 16) + 1];
              RD2_stg  <= MEM[(RADDR * 16) + 2];
              RD3_stg  <= MEM[(RADDR * 16) + 3];
              RD4_stg  <= MEM[(RADDR * 16) + 4];
              RD5_stg  <= MEM[(RADDR * 16) + 5];
              RD6_stg  <= MEM[(RADDR * 16) + 6];
              RD7_stg  <= MEM[(RADDR * 16) + 7];
              RD8_stg  <= MEM9[RADDR*2 +0];
              RD9_stg  <= MEM[(RADDR * 16) + 8];
              RD10_stg <= MEM[(RADDR * 16) + 9];
              RD11_stg <= MEM[(RADDR * 16) + 10];
              RD12_stg <= MEM[(RADDR * 16) + 11];
              RD13_stg <= MEM[(RADDR * 16) + 12];
              RD14_stg <= MEM[(RADDR * 16) + 13];
              RD15_stg <= MEM[(RADDR * 16) + 14];
              RD16_stg <= MEM[(RADDR * 16) + 15];
              RD17_stg <= MEM9[RADDR * 2 + 1];
              rdepth = 256;
              if (RADDR < rdepth - 1) begin
                RADDR = #0 RADDR + 1;
              end else begin
                RADDR = #0 0;
                RADDR_wrap = 1 - RADDR_wrap;
              end
            end
            default: begin
            if ( WARNING_MSGS_ON )
              $display("Warning: Illegal Write port width configuration");
            end
          endcase
        end // RPIPE == 1
      end // if (EMPTY and ESTOP)
    end // if REN = 1 and RBLK = 0
    else if (RBLK_int == 1'bx) begin
            if ( WARNING_MSGS_ON )
      $display("Warning: RBLK signal unknown.");
    end else if (REN_int == 1'bx) begin
            if ( WARNING_MSGS_ON )
      $display("Warning: REN signal unknown.");
    end
    fifo_flags(`AFULL_CFG_VECTOR, `AEMPTY_CFG_VECTOR, `RWIDTH_CFG_VECTOR,
               `WWIDTH_CFG_VECTOR);
  end // if RESET deasserted
end // Read section
  

function integer get_Almost_Empty_value;
    input [11:0] addr_signal;
    integer value;
  begin
    value =  addr_signal[11] * 2048 + addr_signal[10] * 1024 
           + addr_signal[9] *  512  + addr_signal[8]  * 256
           + addr_signal[7] *  128  + addr_signal[6]  * 64 
           + addr_signal[5] *  32   + addr_signal[4]  * 16
           + addr_signal[3] *  8    + addr_signal[2]  * 4 
           + addr_signal[1] *  2    + addr_signal[0] * 1;

    get_Almost_Empty_value = value;
  end
endfunction

 
function integer get_Almost_FULL_value;
    input [11:0] addr_signal;
    integer value;
  begin
    value =  addr_signal[11] * 2048 + addr_signal[10] * 1024 
           + addr_signal[9] *  512  + addr_signal[8]  * 256
           + addr_signal[7] *  128  + addr_signal[6]  * 64 
           + addr_signal[5] *  32   + addr_signal[4]  * 16
           + addr_signal[3] *  8    + addr_signal[2]  * 4 
           + addr_signal[1] *  2    + addr_signal[0] * 1;
 
    get_Almost_FULL_value = value;
  end
endfunction


task fifo_flags;

  input [11:0] afval_cfg_bus;
  input [11:0] aeval_cfg_bus;
  input [2:0]  rwidth_cfg_bus; 
  input [2:0]  wwidth_cfg_bus;
 
  integer rbit_add;
  integer rbit_p2;
  integer wbit_add;
  integer wbit_p2;
  integer AFVAL, AEVAL;
  
  begin

    rbit_add = bit_raddress(RADDR, rwidth_cfg_bus);
    rbit_p2  = bit_raddress(RADDR_P2, rwidth_cfg_bus);
    wbit_add = bit_waddress(WADDR, wwidth_cfg_bus);
    wbit_p2  = bit_waddress(WADDR_P2, wwidth_cfg_bus);
    AEVAL    = get_Almost_Empty_value(aeval_cfg_bus);
    AFVAL    = get_Almost_FULL_value(afval_cfg_bus);

    // Pipelined addresses used for FULL and EMPTY calculations

    if ((WADDR_wrap == RADDR_wrap_P2) && (wbit_add == rbit_p2))
      FULLP = 1'b1;
    else
      FULLP = 1'b0;

    if ((RADDR_wrap == WADDR_wrap_P2) && (wbit_p2 == rbit_add))
      EMPTYP = 1'b1;
    else
      EMPTYP = 1'b0;
      
    // Non-pipelined addresses used for AFULL and AEMPTY calculations

    if (FULLP == 1'b1)
      AEMPTYP = 1'b0;
    else if (wbit_add >= rbit_add) begin
      if ((wbit_add - rbit_add) > AEVAL) 
        AEMPTYP = 1'b0;
      else
        AEMPTYP = 1'b1;
    end else begin
      if ((MAX_DEPTH + wbit_add - rbit_add) > AEVAL)  
        AEMPTYP = 1'b0;
      else
        AEMPTYP = 1'b1;
    end

    if (EMPTYP == 1'b1) 
      AFULLP = 1'b0;
    else if (FULLP == 1'b1) 
      AFULLP = 1'b1;
    else if (wbit_add >= rbit_add) begin
      if ((wbit_add - rbit_add) < AFVAL) 
        AFULLP = 1'b0;
      else
        AFULLP = 1'b1;
    end else begin
      if ((MAX_DEPTH + wbit_add - rbit_add) < AFVAL) 
        AFULLP = 1'b0;
      else
        AFULLP = 1'b1;
    end

  end

endtask

/*
task increment_waddress_counter; // not used - why???
  inout WADDR;
  inout waddr_wrap;
  input [2:0] wwidth_cfg_bus;
  input fflag;
  input fstop;

  integer WADDR;
  integer wdepth;

  begin
    wdepth = get_max_address(wwidth_cfg_bus);
    if (fflag == 1'b0) begin
      if (WADDR < wdepth -1 ) begin
        WADDR <= WADDR + 1;
      end else begin
        WADDR <= (WADDR + 1) % wdepth;
        waddr_wrap =1- waddr_wrap;
      end
    end else if ((fflag == 1'b1) && (fstop == 1'b0)) begin
      if (WADDR < wdepth-1 ) begin
        WADDR <= WADDR + 1;
      end else begin
        WADDR <= (WADDR + 1) % wdepth;
        waddr_wrap =1 - waddr_wrap;
      end
    end
  end
endtask


task increment_raddress_counter; // not used - why???
  input [2:0] width_cfg_bus;
  input flag;
  input stop;

  integer depth;

  begin
    depth = get_max_address(width_cfg_bus);
    if (flag == 1'b0) begin
      if (RADDR < depth -1 ) begin
        RADDR <= RADDR + 1;
      end else begin
        RADDR <= (RADDR + 1) % depth;
        RADDR_wrap =1-RADDR_wrap;
      end
    end else if ((flag == 1'b1) && (stop == 1'b0)) begin
      if (RADDR < depth-1 ) begin
        RADDR <= RADDR + 1;
      end else begin
        RADDR <= (RADDR + 1) % depth;
        RADDR_wrap =1 - RADDR_wrap;
      end
    end
  end
endtask
*/

function integer bit_waddress;
  input WADDR;
  input [2:0] width_cfg_bus;
  integer BIT_WADDR;
  integer WADDR;
  
  begin
  
    case(width_cfg_bus)
      3'b000 : begin
           BIT_WADDR = 1 * WADDR;
           end
      3'b001  : begin
           BIT_WADDR = 2 * WADDR;
           end
      3'b010 : begin
           BIT_WADDR = 4 * WADDR;
           end
      3'b011 : begin
           BIT_WADDR = 8 * WADDR;
           end
      3'b100 : begin
           BIT_WADDR = 16 * WADDR;
           end
      default: begin
            if ( WARNING_MSGS_ON )
           $display("Warning: Illegal port width configuration");
           BIT_WADDR = 0;
           end
    endcase
    bit_waddress = BIT_WADDR;
  end
endfunction


function integer bit_raddress;
  input RADDR;
  input [2:0] width_cfg_bus;
  integer BIT_RADDR;
  integer RADDR;

  begin
 
    case(width_cfg_bus)
      3'b000 : begin
           BIT_RADDR = 1 * RADDR;
           end
      3'b001  : begin
           BIT_RADDR = 2 * RADDR;
           end
      3'b010 : begin
           BIT_RADDR = 4 * RADDR;
           end
      3'b011 : begin
           BIT_RADDR = 8 * RADDR;
           end
      3'b100 : begin
           BIT_RADDR = 16 * RADDR;
           end
      default: begin
            if ( WARNING_MSGS_ON )
            $display("Warning: Illegal port width configuration");
            BIT_RADDR = 0;
           end
    endcase
    bit_raddress = BIT_RADDR;
  end
endfunction


function integer get_max_address;
  input [2:0] width_cfg_bus;
  integer max_address;

  begin
    case(width_cfg_bus)
       3'b000 : begin
                  max_address = 4096;
                end
       3'b001 : begin
                  max_address = 2048;
                end
       3'b010 : begin
                  max_address = 1024;
                end
       3'b011 : begin
                  max_address = 512;
                end
       3'b100 : begin
                  max_address = 256;
                end
       default: begin
            if ( WARNING_MSGS_ON )
                 $display("Warning: Illegal port width configuration");
                 max_address = 0;
                end
    endcase
    get_max_address = max_address;
  end
endfunction


endmodule
//---- END MODULE FIFO4K18 ----

