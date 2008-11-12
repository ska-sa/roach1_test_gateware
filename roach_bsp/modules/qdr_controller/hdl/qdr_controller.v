module qdr_controller (
    /* QDR Infrastructure */
    clk0,
    clk180,
    clk270,
    div_clk,
    reset, //release when clock and delay elements are stable 
    /* Physical QDR Signals */
    qdr_d,
    qdr_q,
    qdr_sa,
    qdr_w_n,
    qdr_r_n,
    qdr_dll_off_n,
    qdr_bw_n,
    qdr_cq,
    qdr_cq_n,
    qdr_k,
    qdr_k_n,
    qdr_qvld,
    /* QDR PHY ready */
    phy_rdy, cal_fail,
    /* QDR read interface */
    usr_rd_strb,
    usr_wr_strb,
    usr_addr,

    usr_rd_data,
    usr_rd_dvld,

    usr_wr_data,
    usr_wr_be /* 'byte' enable */
  );
  parameter USE_XILINX_CORE = 0;
  parameter DATA_WIDTH   = 18;
  parameter BW_WIDTH     = 2;
  parameter ADDR_WIDTH   = 21;
  parameter BURST_LENGTH = 4;
  parameter CLK_FREQ     = 200;
  parameter Q_CLK_270    = 0;

  input clk0, clk180, clk270, div_clk;
  input reset;

  output [DATA_WIDTH - 1:0] qdr_d;
  input  [DATA_WIDTH - 1:0] qdr_q;
  output [ADDR_WIDTH - 1:0] qdr_sa;
  output qdr_w_n;
  output qdr_r_n;
  output qdr_dll_off_n;
  output   [BW_WIDTH - 1:0] qdr_bw_n;
  input  qdr_cq;
  input  qdr_cq_n;
  output qdr_k;
  output qdr_k_n;
  input  qdr_qvld;

  output phy_rdy;
  output cal_fail;

  input  usr_rd_strb;
  input  usr_wr_strb;
  input    [ADDR_WIDTH - 1:0] usr_addr;

  output [2*DATA_WIDTH - 1:0] usr_rd_data;
  output usr_rd_dvld;

  input  [2*DATA_WIDTH - 1:0] usr_wr_data;
  input    [2*BW_WIDTH - 1:0] usr_wr_be;

generate if (USE_XILINX_CORE) begin : xilinx_gen

  wire user_rst_0, user_rst_180, user_rst_270;

  wire cal_done;

  wire user_r_n, user_d_w_n;
  wire user_ad_w_n;
  wire [  ADDR_WIDTH - 1:0] user_ad_wr;
  wire [  ADDR_WIDTH - 1:0] user_ad_rd;
  wire [  2*BW_WIDTH - 1:0] user_bwh_n;
  wire [  2*BW_WIDTH - 1:0] user_bwl_n;
  wire [2*DATA_WIDTH - 1:0] user_dwl;
  wire [2*DATA_WIDTH - 1:0] user_dwh;
  wire [2*DATA_WIDTH - 1:0] user_qrl;
  wire [2*DATA_WIDTH - 1:0] user_qrh;
  wire user_qr_valid;

  qdrii_top #(
    .DATA_WIDTH   (DATA_WIDTH),
    .ADDR_WIDTH   (ADDR_WIDTH),
    .BURST_LENGTH (BURST_LENGTH),
    .BW_WIDTH     (BW_WIDTH),
    .CLK_FREQ     (CLK_FREQ),
    .CLK_WIDTH    (1),
    .CQ_WIDTH     (1),
    .DEBUG_EN     (0),
    .MEMORY_WIDTH (DATA_WIDTH),
    .SIM_ONLY     (0)
  ) qdrii_top_inst (
    .clk0   (clk0),
    .clk180 (clk180),
    .clk270 (clk270),
    .user_rst_0   (user_rst_0),
    .user_rst_180 (user_rst_180),
    .user_rst_270 (user_rst_270),

    .cal_done (cal_done),

    .user_r_n    (user_r_n),
    .user_d_w_n  (user_d_w_n),
    .user_ad_wr  (user_ad_wr),
    .user_ad_rd  (user_ad_rd),
    .user_ad_w_n (user_ad_w_n),
    .user_bwh_n  (user_bwh_n),
    .user_bwl_n  (user_bwl_n),
    .user_dwl    (user_dwl),
    .user_dwh    (user_dwh),
    .user_qrl      (user_qrl),
    .user_qrh      (user_qrh),
    .user_qr_valid (user_qr_valid),

    .user_wr_full (user_wr_full),
    .user_rd_full (user_rd_full),

    .idelay_ctrl_rdy (1'b1),

    .qdr_q          (qdr_q),
    .qdr_cq         (qdr_cq),
    .qdr_cq_n       (qdr_cq_n),
    .qdr_c          (qdr_c),
    .qdr_c_n        (qdr_c_n),
    .qdr_k          (qdr_k),
    .qdr_k_n        (qdr_k_n),
    .qdr_sa         (qdr_sa),
    .qdr_bw_n       (qdr_bw_n),
    .qdr_w_n        (qdr_w_n),
    .qdr_d          (qdr_d),
    .qdr_r_n        (qdr_r_n),
    .qdr_dll_off_n  (qdr_dll_off_n)
  );

  /* Reset Registering */
  reg reset_retimed0;
  assign user_rst_0 = reset_retimed0;

  always @(posedge clk0) begin
    reset_retimed0 <= reset;
  end

  reg reset_retimed180;
  assign user_rst_180 = reset_retimed180;

  always @(posedge clk180) begin
    reset_retimed180 <= reset;
  end

  reg reset_retimed270;
  assign user_rst_270 = reset_retimed270;

  always @(posedge clk270) begin
    reset_retimed270 <= reset;
  end

  /* phy ready assignment */
  assign phy_rdy  = cal_done;
  assign cal_fail = 1'b0;

  /* user interface assigns */
  assign user_r_n    = !usr_rd_strb;
  assign user_d_w_n  = !usr_wr_strb;
  assign user_ad_w_n = !(usr_rd_strb || usr_wr_strb);
  assign user_ad_wr  = usr_addr;
  assign user_ad_rd  = usr_addr;
  assign user_bwh_n  = usr_wr_be[  BW_WIDTH - 1:0];
  assign user_bwl_n  = usr_wr_be[2*BW_WIDTH - 1:BW_WIDTH];
  assign user_dwl    = usr_wr_data[  DATA_WIDTH - 1:0];
  assign user_dwh    = usr_wr_data[2*DATA_WIDTH - 1:DATA_WIDTH];
  assign usr_rd_data[DATA_WIDTH   - 1:0         ] = user_qrl;
  assign usr_rd_data[2*DATA_WIDTH - 1:DATA_WIDTH] = user_qrh;
  assign usr_rd_dvld = user_qr_valid;

end else begin : kat_qdr_gen

  qdrc_top #(
    .DATA_WIDTH   (DATA_WIDTH  ),
    .BW_WIDTH     (BW_WIDTH    ),
    .ADDR_WIDTH   (ADDR_WIDTH  ),
    .BURST_LENGTH (BURST_LENGTH),
    .CLK_FREQ     (CLK_FREQ    ),
    .Q_CLK_270    (Q_CLK_270   )
  ) qdrc_top_inst (
    .clk0    (clk0),
    .clk180  (clk180),
    .clk270  (clk270),
    .div_clk (div_clk),
    .reset   (reset),

    .phy_rdy  (phy_rdy),
    .cal_fail (cal_fail),

    .qdr_d         (qdr_d),
    .qdr_q         (qdr_q),
    .qdr_sa        (qdr_sa),
    .qdr_w_n       (qdr_w_n),
    .qdr_r_n       (qdr_r_n),
    .qdr_bw_n      (qdr_bw_n),
    .qdr_cq        (qdr_cq),
    .qdr_cq_n      (qdr_cq_n),
    .qdr_k         (qdr_k),
    .qdr_k_n       (qdr_k_n),
    .qdr_qvld      (qdr_qvld),
    .qdr_dll_off_n (qdr_dll_off_n),

    .usr_rd_strb (usr_rd_strb),
    .usr_wr_strb (usr_wr_strb),
    .usr_addr    (usr_addr),
    .usr_rd_data (usr_rd_data),
    .usr_rd_dvld (usr_rd_dvld),
    .usr_wr_data (usr_wr_data),
    .usr_wr_be   (usr_wr_be)
  );

end endgenerate

endmodule
