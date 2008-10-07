module qdrc_phy_burst_align(
    /* Misc signals */
    clk,
    reset,

    /* State control signals */
    burst_align_start,
    burst_align_done,
    burst_align_fail,

    /* External QDR signals  */
    qdr_d_rise,
    qdr_d_fall,
    qdr_q_rise,
    qdr_q_fall,
    qdr_bw_n_rise,
    qdr_bw_n_fall,
    qdr_w_n,
    qdr_r_n,
    qdr_sa,

    /* Bit aligned Datal */
    qdr_q_rise_cal,
    qdr_q_fall_cal 
  );
  parameter DATA_WIDTH   = 18;
  parameter BW_WIDTH     = 2;
  parameter ADDR_WIDTH   = 21;
  parameter CLK_FREQ     = 200;
  parameter BURST_LENGTH = 4;
  parameter BYPASS       = 1;

  input clk, reset;

  input  burst_align_start;
  output burst_align_done, burst_align_fail;

  output [DATA_WIDTH - 1:0] qdr_d_rise;
  output [DATA_WIDTH - 1:0] qdr_d_fall;
  input  [DATA_WIDTH - 1:0] qdr_q_rise;
  input  [DATA_WIDTH - 1:0] qdr_q_fall;
  output   [BW_WIDTH - 1:0] qdr_bw_n_rise;
  output   [BW_WIDTH - 1:0] qdr_bw_n_fall;
  output qdr_w_n;
  output qdr_r_n;
  output [ADDR_WIDTH - 1:0] qdr_sa;

  output [DATA_WIDTH - 1:0] qdr_q_rise_cal;
  output [DATA_WIDTH - 1:0] qdr_q_fall_cal; 

/**************** GENERATE BYPASS PHY ************************/
generate if (BYPASS == 1) begin :bypass_burst_align
/********************* BYPASS PHY ****************************/

  assign burst_align_done = 1'b1;
  assign burst_align_fail = 1'b0;

  assign qdr_d_rise       = {DATA_WIDTH{1'b1}};
  assign qdr_d_fall       = {DATA_WIDTH{1'b0}};

  assign qdr_bw_n_rise    = {BW_WIDTH{1'b0}};
  assign qdr_bw_n_fall    = {BW_WIDTH{1'b0}};

  assign qdr_w_n          = 1'b1;
  assign qdr_r_n          = 1'b1;

  assign qdr_sa           = {ADDR_WIDTH{1'b0}};

  assign qdr_q_rise_cal   = qdr_q_rise;
  assign qdr_q_fall_cal   = qdr_q_fall;

/************** GENERATE ELSE INCLUDE PHY ********************/
end else begin                  :include_burst_align
/******************** INCLUDE PHY ****************************/

  assign burst_align_done = 1'b1;
  assign burst_align_fail = 1'b0;

  assign dly_inc_dec_n    = {DATA_WIDTH{1'b0}};
  assign dly_en           = {DATA_WIDTH{1'b0}};
  assign dly_rst          = {DATA_WIDTH{1'b0}};

  assign qdr_d_rise       = {DATA_WIDTH{1'b1}};
  assign qdr_d_fall       = {DATA_WIDTH{1'b0}};

  assign qdr_bw_n_rise    = {BW_WIDTH{1'b0}};
  assign qdr_bw_n_fall    = {BW_WIDTH{1'b0}};

  assign qdr_w_n          = 1'b1;
  assign qdr_r_n          = 1'b1;

  assign qdr_sa           = {ADDR_WIDTH{1'b0}};

  assign qdr_q_rise_cal   = qdr_q_rise;
  assign qdr_q_fall_cal   = qdr_q_fall;

end endgenerate
/******************  END GENERATE ***************************/
endmodule
