module qdrc_infrastructure(
    /* general signals */
    clk0,
    clk180,
    clk270,
    reset0,
    reset180,
    reset270,
    /* external signals */
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
    /* phy->external signals */
    qdr_d_rise,
    qdr_d_fall,
    qdr_q_rise,
    qdr_q_fall,
    qdr_bw_n_rise,
    qdr_bw_n_fall,
    qdr_sa_buf,
    qdr_w_n_buf,
    qdr_r_n_buf,
    qdr_dll_off_n_buf,
    qdr_cq_buf,
    qdr_cq_n_buf,
    qdr_qvld_buf,
    /* phy training signals */
    dly_clk,
    dly_inc_dec_n,
    dly_en,
    dly_rst       
  );
  parameter DATA_WIDTH     = 18;
  parameter BW_WIDTH       = 2;
  parameter ADDR_WIDTH     = 21;
  parameter Q_CLK_270      = 0;

  input clk0,   clk180,   clk270;
  input reset0, reset180, reset270;

  output [DATA_WIDTH - 1:0] qdr_d;
  output   [BW_WIDTH - 1:0] qdr_bw_n;
  input  [DATA_WIDTH - 1:0] qdr_q;
  output [ADDR_WIDTH - 1:0] qdr_sa;
  output qdr_w_n;
  output qdr_r_n;
  output qdr_dll_off_n;
  output qdr_k, qdr_k_n;
  input  qdr_cq, qdr_cq_n;
  input  qdr_qvld;
  
  input  [DATA_WIDTH - 1:0] qdr_d_rise;
  input  [DATA_WIDTH - 1:0] qdr_d_fall;
  output [DATA_WIDTH - 1:0] qdr_q_rise;
  output [DATA_WIDTH - 1:0] qdr_q_fall;
  input    [BW_WIDTH - 1:0] qdr_bw_n_rise;
  input    [BW_WIDTH - 1:0] qdr_bw_n_fall;
  input  [ADDR_WIDTH - 1:0] qdr_sa_buf;
  input  qdr_w_n_buf, qdr_r_n_buf;
  input  qdr_dll_off_n_buf;
  output qdr_cq_buf, qdr_cq_n_buf;
  output qdr_qvld_buf;

  input  dly_clk;
  input  [DATA_WIDTH - 1:0] dly_inc_dec_n;
  input  [DATA_WIDTH - 1:0] dly_en;
  input  [DATA_WIDTH - 1:0] dly_rst;       

  /******************* QDR_K and QDR_K_N ********************
   * The clock is generated by an ODDR. This is done
   * to so the latency introduced by the ODDR on the data
   * line is introduced into the clock generation.
   * The clock uses clk0 while all other signals use clk270.
   */

  ODDR #(
    .DDR_CLK_EDGE ("SAME_EDGE"),
    .INIT         (1'b1),
    .SRTYPE       ("SYNC")
  ) ODDR_qdr_k (
    .Q  (qdr_k),
    .C  (clk0),
    .CE (1'b1),
    .D1 (1'b1), //Rising Edge
    .D2 (1'b0), //Falling Edge
    .R  (1'b0),
    .S  (1'b0)
  );

  /* same as qdr_k -> just inverted */
  ODDR #(
    .DDR_CLK_EDGE ("SAME_EDGE"),
    .INIT         (1'b1),
    .SRTYPE       ("SYNC")
  ) ODDR_qdr_k_n (
    .Q  (qdr_k_n),
    .C  (clk0),
    .CE (1'b1),
    .D1 (1'b0), //Rising Edge
    .D2 (1'b1), //Falling Edge
    .R  (1'b0),
    .S  (1'b0)
  );

  /******************* SDR Control Signals ********************
   *
   */

  reg [ADDR_WIDTH - 1:0] qdr_sa_reg;
  reg qdr_w_n_reg;
  reg qdr_r_n_reg;
  reg qdr_dll_off_n_reg;

  always @(posedge clk0) begin 
  /* Add delay to ease timing */
    qdr_sa_reg        <= qdr_sa_buf;
    qdr_w_n_reg       <= qdr_w_n_buf;
    qdr_r_n_reg       <= qdr_r_n_buf;
    qdr_dll_off_n_reg <= qdr_dll_off_n_buf;
  end

  /* TODO: placement constraints ? */

  ODDR #(
    .DDR_CLK_EDGE ("SAME_EDGE"),
    .INIT         (1'b1),
    .SRTYPE       ("SYNC")
  ) ODDR_addr [ADDR_WIDTH - 1:0] (
    .Q  (qdr_sa),
    .C  (clk180),
    .CE (1'b1),
    .D1 (qdr_sa_reg), //Rising Edge
    .D2 (qdr_sa_reg), //Falling Edge
    .R  (1'b0),
    .S  (1'b0)
  );

  ODDR #(
    .DDR_CLK_EDGE ("SAME_EDGE"),
    .INIT         (1'b1),
    .SRTYPE       ("SYNC")
  ) ODDR_misc_sdr [2:0] (
    .Q  ({qdr_w_n,     qdr_r_n,     qdr_dll_off_n}),
    .C  (clk180),
    .CE (1'b1),
    .D1 ({qdr_w_n_reg, qdr_r_n_reg, qdr_dll_off_n_reg}), //Rising Edge
    .D2 ({qdr_w_n_reg, qdr_r_n_reg, qdr_dll_off_n_reg}), //Falling Edge
    .R  (1'b0),
    .S  (1'b0)
  );

  /******************* DDR Data Outputs ********************
   *
   */

  reg [DATA_WIDTH - 1:0] qdr_d_rise_reg0;
  reg [DATA_WIDTH - 1:0] qdr_d_fall_reg0;
  reg   [BW_WIDTH - 1:0] qdr_bw_n_rise_reg0;
  reg   [BW_WIDTH - 1:0] qdr_bw_n_fall_reg0;

  reg [DATA_WIDTH - 1:0] qdr_d_rise_reg;
  reg [DATA_WIDTH - 1:0] qdr_d_fall_reg;
  reg   [BW_WIDTH - 1:0] qdr_bw_n_rise_reg;
  reg   [BW_WIDTH - 1:0] qdr_bw_n_fall_reg;

  always @(posedge clk0) begin
  /* Delay the write data by one cycle */
    qdr_d_rise_reg0     <= qdr_d_rise;
    qdr_d_fall_reg0     <= qdr_d_fall;
    qdr_bw_n_rise_reg0  <= qdr_bw_n_rise;
    qdr_bw_n_fall_reg0  <= qdr_bw_n_fall;
  end

  always @(posedge clk270) begin
  /* Sample DDR signals onto clk270 domain.
   * The 270 clock is used to let the data lead the clock by
   * 90 degrees behind the clock. The signals are registered
   * to ease timing requirements.
   */
    qdr_d_rise_reg     <= qdr_d_rise_reg0;
    qdr_d_fall_reg     <= qdr_d_fall_reg0;
    qdr_bw_n_rise_reg  <= qdr_bw_n_rise_reg0;
    qdr_bw_n_fall_reg  <= qdr_bw_n_fall_reg0;
  end

  ODDR #(
    .DDR_CLK_EDGE ("SAME_EDGE"),
    .INIT         (1'b1),
    .SRTYPE       ("SYNC")
  ) ODDR_qdr_d [DATA_WIDTH - 1:0] (
    .Q  (qdr_d),
    .C  (clk270),
    .CE (1'b1),
    .D1 (qdr_d_rise_reg), //Rising Edge
    .D2 (qdr_d_fall_reg), //Falling Edge
    .R  (1'b0),
    .S  (1'b0)
  );

  ODDR #(
    .DDR_CLK_EDGE ("SAME_EDGE"),
    .INIT         (1'b1),
    .SRTYPE       ("SYNC")
  ) ODDR_qdr_bw_n [BW_WIDTH - 1:0] (
    .Q  (qdr_bw_n),
    .C  (clk270),
    .CE (1'b1),
    .D1 (qdr_bw_n_rise_reg), //Rising Edge
    .D2 (qdr_bw_n_fall_reg), //Falling Edge
    .R  (1'b0),
    .S  (1'b0)
  );

  /******************* DDR Data Inputs ********************
   * IODELAY for training
   */
 
  wire [DATA_WIDTH - 1:0] qdr_q_ibuf;
  wire [DATA_WIDTH - 1:0] qdr_q_iodelay;

  IBUF ibuf_qdrq [DATA_WIDTH - 1:0](
    .I (qdr_q),
    .O (qdr_q_ibuf)
  );

  IODELAY #(
    .DELAY_SRC        ("I"),
    .IDELAY_TYPE      ("VARIABLE"),
    .REFCLK_FREQUENCY (200.0)
  ) IODELAY_qdrq [DATA_WIDTH - 1:0] (
    .C       (dly_clk),
    .CE      (dly_en),
    .DATAIN  (1'b0),
    .IDATAIN (qdr_q_ibuf),
    .INC     (dly_inc_dec_n),
    .ODATAIN (),
    .RST     (dly_rst),
    .T       (1'b0),
    .DATAOUT (qdr_q_iodelay)
  );

  wire [DATA_WIDTH - 1:0] qdr_q_rise_int;
  wire [DATA_WIDTH - 1:0] qdr_q_fall_int;

  wire qdr_cq_bufg;

  IDDR #(
    .DDR_CLK_EDGE ("SAME_EDGE_PIPELINED"),
    .INIT_Q1 (1'b0),
    .INIT_Q2 (1'b0),
    .SRTYPE ("SYNC")
  ) IDDR_qdrq [DATA_WIDTH - 1:0] (
    .C  (clk0),
    .CE (1'b1),
    .D  (qdr_q_iodelay),
    .R  (1'b0),
    .S  (1'b0),
    .Q1 (qdr_q_rise_int),
    .Q2 (qdr_q_fall_int)
  );

  assign qdr_q_rise = qdr_q_rise_int;
  assign qdr_q_fall = qdr_q_fall_int;

  /******************* SDR Inputs ********************
   * IODELAY for training
   */


  IBUF ibuf_qdr_qvld(
    .I (qdr_qvld),
    .O (qdr_qvld_buf)
  );

  IBUF ibuf_qdr_cq[1:0](
    .I ({qdr_cq,     qdr_cq_n}),
    .O ({qdr_cq_buf, qdr_cq_n_buf})
  );

  BUFR foo_bufg(
    .I(qdr_cq_buf), 
    .O(qdr_cq_bufg),
    .CE(1'b0),
    .CLR(1'b0)
    
  );


endmodule
