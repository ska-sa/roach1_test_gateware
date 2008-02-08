`define WR_BIT 0
`define RD_BIT 1
`define COMP_BIT 2
`define A0(x) (x[18:3])
`define A1(x) (x[34:19])

module bus_protect(
    vcheck,
    vfail, vpass,
    adr,
    wr_en
  );
  parameter RESTRICTION0 = 35'b0;
  parameter RESTRICTION1 = 35'b0;
  parameter RESTRICTION2 = 35'b0;

  input  vcheck;
  output vfail, vpass;
  input  [15:0] adr;
  input  wr_en;

  wire addrmatch0 = RESTRICTION0[`COMP_BIT] ? (adr >= RESTRICTION0[18:3] && adr < RESTRICTION0[34:19] ? 1'b1 : 1'b0 ) :
                    adr == RESTRICTION0[18:3];
  wire addrmatch1 = RESTRICTION1[`COMP_BIT] ? (adr >= RESTRICTION1[18:3] && adr < RESTRICTION1[34:19] ? 1'b1 : 1'b0 ) :
                    adr == RESTRICTION1[18:3];
  wire addrmatch2 = RESTRICTION2[`COMP_BIT] ? (adr >= RESTRICTION2[18:3] && adr < RESTRICTION2[34:19] ? 1'b1 : 1'b0 ) :
                    adr == RESTRICTION2[18:3];

  wire err0 = addrmatch0 & (RESTRICTION0[`WR_BIT] & wr_en | RESTRICTION0[`RD_BIT] & ~wr_en);
  wire err1 = addrmatch1 & (RESTRICTION1[`WR_BIT] & wr_en | RESTRICTION1[`RD_BIT] & ~wr_en);
  wire err2 = addrmatch2 & (RESTRICTION2[`WR_BIT] & wr_en | RESTRICTION2[`RD_BIT] & ~wr_en);

  wire err = err0 | err1 | err2;

  assign vfail = vcheck & err;
  assign vpass = vcheck & ~err;

endmodule
