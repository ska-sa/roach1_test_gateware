`define WR_BIT 0
`define RD_BIT 1
`define COMP_BIT 2
`define A0 18:3
`define A1 34:19

`define NUM_RESTRICTIONS 3
`define RESTRICTION0 {`ACM_A + `ACM_L, `ACM_A, 1'b1, 1'b0, 1'b1}
`define RESTRICTION1 {`ALC_HARDLEVEL_A + `ALC_HARDLEVEL_L, `ALC_HARDLEVEL_A, 1'b1, 1'b0, 1'b1}
`define RESTRICTION2 {16'b0, `ALC_RBUFF_A, 1'b0, 1'b1, 1'b1}
