`define WR_BIT 0
`define RD_BIT 1

module bus_protect(
    vcheck,
    vfail, vpass,
    adr,
    wr_en,
    wbm_id
  );
  parameter RESTRICTION0 = 38'b0;
  parameter RESTRICTION1 = 38'b0;
  parameter RESTRICTION2 = 38'b0;


  input  vcheck;
  output vfail, vpass;
  input  [15:0] adr;
  input  wr_en;
  input   [3:0] wbm_id;

  wire addrmatch0 = adr >= RESTRICTION0[17:2] && adr <= RESTRICTION0[33:18] ? 1'b1 : 1'b0;
  wire addrmatch1 = adr >= RESTRICTION1[17:2] && adr <= RESTRICTION1[33:18] ? 1'b1 : 1'b0;
  wire addrmatch2 = adr >= RESTRICTION2[17:2] && adr <= RESTRICTION2[33:18] ? 1'b1 : 1'b0;

  wire [3:0] wbm_en_int0 = RESTRICTION0[34 + 4 - 1:34];
  wire [3:0] wbm_en_int1 = RESTRICTION1[34 + 4 - 1:34];
  wire [3:0] wbm_en_int2 = RESTRICTION2[34 + 4 - 1:34];

  wire wbm_en0 = (wbm_en_int0 & wbm_id) != 4'b0;
  wire wbm_en1 = (wbm_en_int1 & wbm_id) != 4'b0;
  wire wbm_en2 = (wbm_en_int2 & wbm_id) != 4'b0;

  wire err0 = wbm_en0 & addrmatch0 & (RESTRICTION0[`WR_BIT] & wr_en | RESTRICTION0[`RD_BIT] & ~wr_en);
  wire err1 = wbm_en1 & addrmatch1 & (RESTRICTION1[`WR_BIT] & wr_en | RESTRICTION1[`RD_BIT] & ~wr_en);
  wire err2 = wbm_en2 & addrmatch2 & (RESTRICTION2[`WR_BIT] & wr_en | RESTRICTION2[`RD_BIT] & ~wr_en);

  wire err = err0 | err1 | err2;

  assign vfail = vcheck & err;
  assign vpass = vcheck & ~err;

endmodule
