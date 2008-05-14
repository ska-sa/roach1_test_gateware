module qdr_controller #(
    parameter ADDR_WIDTH              = 21,       // # of memory component addr bits
    parameter BURST_LENGTH            = 2,       // Burst Length type of memory component
    parameter BW_WIDTH                = 2,       // # of Byte Write Control bits
    parameter CLK_FREQ                = 200,       // Core/Memory clock frequency (in MHz)
    parameter CLK_WIDTH               = 1,       // # of clock outputs
    parameter CQ_WIDTH                = 1,       // # of CQ bits 
    parameter DATA_WIDTH              = 18,       // Design Data Width 
    parameter MEMORY_WIDTH            = 18,       // # of memory component's data width
    parameter SIM_ONLY                = 0,       // = 1 to skip SRAM power up delay
    parameter DEBUG_EN                = 0,       // Enable debug signals/controls. When this parameter is changed from 0 to 1,
    // make sure to uncomment the coregen commands in ise_flow.bat or create_ise.bat files in par folder.
    parameter RST_ACT_LOW             = 0        // =1 for active low reset, =0 for active high
  ) (
    input                              reset,
    input                              idelay_rdy,
    input                              pll_lock,
    input                              clk0,
    input                              clk180,
    input                              clk270,

    output [DATA_WIDTH-1:0]            qdr_d,
    input  [DATA_WIDTH-1:0]            qdr_q,
    output [ADDR_WIDTH-1:0]            qdr_sa,
    output                             qdr_w_n,
    output                             qdr_r_n,
    output                             qdr_dll_off_n,
    output [BW_WIDTH-1:0]              qdr_bw_n,
    input  [CQ_WIDTH-1:0]              qdr_cq,
    input  [CQ_WIDTH-1:0]              qdr_cq_n,
    output [CLK_WIDTH-1:0]             qdr_k,
    output [CLK_WIDTH-1:0]             qdr_k_n,

    output                             cal_done,

    input                              user_ad_w_n,
    input                              user_d_w_n,
    input                              user_r_n,
    output                             user_wr_full,
    output                             user_rd_full,
    output                             user_qr_valid,
    input  [DATA_WIDTH-1:0]            user_dwl,
    input  [DATA_WIDTH-1:0]            user_dwh,
    output [DATA_WIDTH-1:0]            user_qrl,
    output [DATA_WIDTH-1:0]            user_qrh,
    input  [BW_WIDTH-1:0]              user_bwl_n,
    input  [BW_WIDTH-1:0]              user_bwh_n,
    input  [ADDR_WIDTH-1:0]            user_ad_wr,
    input  [ADDR_WIDTH-1:0]            user_ad_rd
  );

  localparam STROBE_WIDTH = 1;

  wire                        dbg_init_count_done_nc;
  wire [STROBE_WIDTH-1:0]     dbg_q_init_delay_done_nc;
  wire [(6*STROBE_WIDTH)-1:0] dbg_q_init_delay_done_tap_count_nc;
  wire [STROBE_WIDTH-1:0]     dbg_cq_cal_done_nc;
  wire [(6*STROBE_WIDTH)-1:0] dbg_cq_cal_tap_count_nc;
  wire [STROBE_WIDTH-1:0]     dbg_we_cal_done_nc;
  wire [STROBE_WIDTH-1:0]     dbg_cq_q_data_valid_nc;
  wire                        dbg_data_valid_nc;

  wire qdr_c_nc;
  wire qdr_c_n_nc;

  wire user_rst_0, user_rst_180, user_rst_270;

  qdr2_top #(
    .ADDR_WIDTH             (ADDR_WIDTH),
    .BURST_LENGTH           (BURST_LENGTH),
    .BW_WIDTH               (BW_WIDTH),
    .CLK_FREQ               (CLK_FREQ),
    .CLK_WIDTH              (CLK_WIDTH),
    .CQ_WIDTH               (CQ_WIDTH),
    .DATA_WIDTH             (DATA_WIDTH),
    .MEMORY_WIDTH           (MEMORY_WIDTH),
    .SIM_ONLY               (SIM_ONLY),
    .STROBE_WIDTH           (STROBE_WIDTH)
  ) u_qdr2_top (
    .qdr_d                  (qdr_d),
    .qdr_q                  (qdr_q),
    .qdr_sa                 (qdr_sa),
    .qdr_w_n                (qdr_w_n),
    .qdr_r_n                (qdr_r_n),
    .qdr_dll_off_n          (qdr_dll_off_n),
    .qdr_bw_n               (qdr_bw_n),
    .cal_done               (cal_done),
    .user_rst_0             (user_rst_0),
    .user_rst_180           (user_rst_180),
    .user_rst_270           (user_rst_270),
    .idelay_ctrl_rdy        (idelay_rdy),
    .clk0                   (clk0),
    .clk180                 (clk180),
    .clk270                 (clk270),
    .user_ad_w_n            (user_ad_w_n),
    .user_d_w_n             (user_d_w_n),
    .user_r_n               (user_r_n),
    .user_wr_full           (user_wr_full),
    .user_rd_full           (user_rd_full),
    .user_qr_valid          (user_qr_valid),
    .user_dwl               (user_dwl),
    .user_dwh               (user_dwh),
    .user_qrl               (user_qrl),
    .user_qrh               (user_qrh),
    .user_bwl_n             (user_bwl_n),
    .user_bwh_n             (user_bwh_n),
    .user_ad_wr             (user_ad_wr),
    .user_ad_rd             (user_ad_rd),
    .qdr_cq                 (qdr_cq),
    .qdr_cq_n               (qdr_cq_n),
    .qdr_k                  (qdr_k),
    .qdr_k_n                (qdr_k_n),
    .qdr_c                  (qdr_c_nc),
    .qdr_c_n                (qdr_c_n_nc),
    //Debug Signals
    .dbg_init_count_done             (dbg_init_count_done_nc),
    .dbg_q_init_delay_done           (dbg_q_init_delay_done_nc),
    .dbg_q_init_delay_done_tap_count (dbg_q_init_delay_done_tap_count_nc),
    .dbg_cq_cal_done                 (dbg_cq_cal_done_nc),
    .dbg_cq_cal_tap_count            (dbg_cq_cal_tap_count_nc),
    .dbg_we_cal_done                 (dbg_we_cal_done_nc),
    .dbg_cq_q_data_valid             (dbg_cq_q_data_valid_nc),
    .dbg_data_valid                  (dbg_data_valid_nc)
  );

  reg [3:0] reset_reg_0;
  assign user_rst_0 = reset_reg_0[3];

  always @(posedge clk0 or negedge pll_lock) begin
    if (~pll_lock) begin //aync reset
      reset_reg_0 <= 4'b1111;
    end else if (reset) begin
      reset_reg_0 <= 4'b1111;
    end else begin
      reset_reg_0 <= reset_reg_0 << 1;
    end
  end

  reg [3:0] reset_reg_180;
  assign user_rst_180 = reset_reg_180[3];

  always @(posedge clk180 or negedge pll_lock) begin
    if (~pll_lock) begin //aync reset
      reset_reg_180 <= 4'b1111;
    end else if (reset) begin
      reset_reg_180 <= 4'b1111;
    end else begin
      reset_reg_180 <= reset_reg_180 << 1;
    end
  end

  reg [3:0] reset_reg_270;
  assign user_rst_270 = reset_reg_270[3];

  always @(posedge clk270 or negedge pll_lock) begin
    if (~pll_lock) begin //aync reset
      reset_reg_270 <= 4'b1111;
    end else if (reset) begin
      reset_reg_270 <= 4'b1111;
    end else begin
      reset_reg_270 <= reset_reg_270 << 1;
    end
  end

endmodule
