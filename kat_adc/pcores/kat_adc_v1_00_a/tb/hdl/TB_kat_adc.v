`timescale 1ns/10ps

`define SIMLENGTH 100000
`define CLK_PERIOD 2

module TB_kat_adc();

  wire        clk;
  wire        rst;
  wire  [3:0] leddies;
  wire [31:0] ctrl0;
  wire [31:0] ctrl1;
  wire [31:0] overrange_i1;
  wire [31:0] overrange_q1;
  wire [31:0] overrange_i0;
  wire [31:0] overrange_q0;
  wire [31:0] status0;
  wire [31:0] status1;
  wire [31:0] sync_count0;
  wire [31:0] sync_count1;
  wire        adc0_data_valid;
  wire  [7:0] adc0_datai0;
  wire  [7:0] adc0_datai1;
  wire  [7:0] adc0_datai2;
  wire  [7:0] adc0_datai3;
  wire  [7:0] adc0_dataq0;
  wire  [7:0] adc0_dataq1;
  wire  [7:0] adc0_dataq2;
  wire  [7:0] adc0_dataq3;
  wire        adc0_outofrangei0;
  wire        adc0_outofrangei1;
  wire        adc0_outofrangeq0;
  wire        adc0_outofrangeq1;
  wire        adc0_sync0;
  wire        adc0_sync1;
  wire        adc0_sync2;
  wire        adc0_sync3;
  wire        adc1_data_valid;
  wire  [7:0] adc1_datai0;
  wire  [7:0] adc1_datai1;
  wire  [7:0] adc1_datai2;
  wire  [7:0] adc1_datai3;
  wire  [7:0] adc1_dataq0;
  wire  [7:0] adc1_dataq1;
  wire  [7:0] adc1_dataq2;
  wire  [7:0] adc1_dataq3;
  wire        adc1_outofrangei0;
  wire        adc1_outofrangei1;
  wire        adc1_outofrangeq0;
  wire        adc1_outofrangeq1;
  wire        adc1_sync0;
  wire        adc1_sync1;
  wire        adc1_sync2;
  wire        adc1_sync3;
  wire        qdr0_ack;
  wire        qdr0_cal_fail;
  wire [35:0] qdr0_din;
  wire        qdr0_phy_ready;
  wire [31:0] qdr0_address;
  wire  [3:0] qdr0_be;
  wire [35:0] qdr0_dout;
  wire        qdr0_rd_en;
  wire        qdr0_wr_en;
  wire        qdr1_ack;
  wire        qdr1_cal_fail;
  wire [35:0] qdr1_din;
  wire        qdr1_phy_ready;
  wire [31:0] qdr1_address;
  wire  [3:0] qdr1_be;
  wire [35:0] qdr1_dout;
  wire        qdr1_rd_en;
  wire        qdr1_wr_en;
  wire        ten_gbe0_led_rx;
  wire        ten_gbe0_led_tx;
  wire        ten_gbe0_led_up;
  wire        ten_gbe0_rx_bad_frame;
  wire [63:0] ten_gbe0_rx_data;
  wire        ten_gbe0_rx_end_of_frame;
  wire        ten_gbe0_rx_overrun;
  wire [31:0] ten_gbe0_rx_source_ip;
  wire [15:0] ten_gbe0_rx_source_port;
  wire        ten_gbe0_rx_valid;
  wire        ten_gbe0_tx_afull;
  wire        ten_gbe0_tx_overflow;
  wire        ten_gbe0_rst;
  wire        ten_gbe0_rx_ack;
  wire        ten_gbe0_rx_overrun_ack;
  wire [63:0] ten_gbe0_tx_data;
  wire [31:0] ten_gbe0_tx_dest_ip;
  wire [15:0] ten_gbe0_tx_dest_port;
  wire        ten_gbe0_tx_end_of_frame;
  wire        ten_gbe0_tx_valid;

  localparam QDR_DEPTH = 16*1024;

  kat_adc #(
    .QDR_SIZE (12),
    .FRAME_WAIT (8),
    .BACKOFF_LEN (8)
  ) kat_adc_inst (
    .clk(clk),
    .rst(rst),
    .leddies(leddies),
    .ctrl0(ctrl0),
    .ctrl1(ctrl1),
    .overrange_i1(overrange_i1),
    .overrange_q1(overrange_q1),
    .overrange_i0(overrange_i0),
    .overrange_q0(overrange_q0),
    .status0(status0),
    .status1(status1),
    .sync_count0(sync_count0),
    .sync_count1(sync_count1),
    .adc0_data_valid(adc0_data_valid),
    .adc0_datai0(adc0_datai0),
    .adc0_datai1(adc0_datai1),
    .adc0_datai2(adc0_datai2),
    .adc0_datai3(adc0_datai3),
    .adc0_dataq0(adc0_dataq0),
    .adc0_dataq1(adc0_dataq1),
    .adc0_dataq2(adc0_dataq2),
    .adc0_dataq3(adc0_dataq3),
    .adc0_outofrangei0(adc0_outofrangei0),
    .adc0_outofrangei1(adc0_outofrangei1),
    .adc0_outofrangeq0(adc0_outofrangeq0),
    .adc0_outofrangeq1(adc0_outofrangeq1),
    .adc0_sync0(adc0_sync0),
    .adc0_sync1(adc0_sync1),
    .adc0_sync2(adc0_sync2),
    .adc0_sync3(adc0_sync3),
    .adc1_data_valid(adc1_data_valid),
    .adc1_datai0(adc1_datai0),
    .adc1_datai1(adc1_datai1),
    .adc1_datai2(adc1_datai2),
    .adc1_datai3(adc1_datai3),
    .adc1_dataq0(adc1_dataq0),
    .adc1_dataq1(adc1_dataq1),
    .adc1_dataq2(adc1_dataq2),
    .adc1_dataq3(adc1_dataq3),
    .adc1_outofrangei0(adc1_outofrangei0),
    .adc1_outofrangei1(adc1_outofrangei1),
    .adc1_outofrangeq0(adc1_outofrangeq0),
    .adc1_outofrangeq1(adc1_outofrangeq1),
    .adc1_sync0(adc1_sync0),
    .adc1_sync1(adc1_sync1),
    .adc1_sync2(adc1_sync2),
    .adc1_sync3(adc1_sync3),
    .qdr0_ack(qdr0_ack),
    .qdr0_cal_fail(qdr0_cal_fail),
    .qdr0_din(qdr0_din),
    .qdr0_phy_ready(qdr0_phy_ready),
    .qdr0_address(qdr0_address),
    .qdr0_be(qdr0_be),
    .qdr0_dout(qdr0_dout),
    .qdr0_rd_en(qdr0_rd_en),
    .qdr0_wr_en(qdr0_wr_en),
    .qdr1_ack(qdr1_ack),
    .qdr1_cal_fail(qdr1_cal_fail),
    .qdr1_din(qdr1_din),
    .qdr1_phy_ready(qdr1_phy_ready),
    .qdr1_address(qdr1_address),
    .qdr1_be(qdr1_be),
    .qdr1_dout(qdr1_dout),
    .qdr1_rd_en(qdr1_rd_en),
    .qdr1_wr_en(qdr1_wr_en),
    .ten_gbe0_led_rx(ten_gbe0_led_rx),
    .ten_gbe0_led_tx(ten_gbe0_led_tx),
    .ten_gbe0_led_up(ten_gbe0_led_up),
    .ten_gbe0_rx_bad_frame(ten_gbe0_rx_bad_frame),
    .ten_gbe0_rx_data(ten_gbe0_rx_data),
    .ten_gbe0_rx_end_of_frame(ten_gbe0_rx_end_of_frame),
    .ten_gbe0_rx_overrun(ten_gbe0_rx_overrun),
    .ten_gbe0_rx_source_ip(ten_gbe0_rx_source_ip),
    .ten_gbe0_rx_source_port(ten_gbe0_rx_source_port),
    .ten_gbe0_rx_valid(ten_gbe0_rx_valid),
    .ten_gbe0_tx_afull(ten_gbe0_tx_afull),
    .ten_gbe0_tx_overflow(ten_gbe0_tx_overflow),
    .ten_gbe0_rst(ten_gbe0_rst),
    .ten_gbe0_rx_ack(ten_gbe0_rx_ack),
    .ten_gbe0_rx_overrun_ack(ten_gbe0_rx_overrun_ack),
    .ten_gbe0_tx_data(ten_gbe0_tx_data),
    .ten_gbe0_tx_dest_ip(ten_gbe0_tx_dest_ip),
    .ten_gbe0_tx_dest_port(ten_gbe0_tx_dest_port),
    .ten_gbe0_tx_end_of_frame(ten_gbe0_tx_end_of_frame),
    .ten_gbe0_tx_valid(ten_gbe0_tx_valid)
  );

  /****** System Signal generations ******/
  wire sys_rst, sys_clk;
  reg [31:0] clk_counter;

  reg reset;
  assign sys_rst = reset;

  initial begin
    $dumpvars;
    clk_counter <= 32'b0;

    reset <= 1'b1;
    #5000
    reset <= 1'b0;
`ifdef DEBUG
    $display("sys: reset cleared");
`endif
    #`SIMLENGTH
    $display("FAILED: simulation timed out");
    $finish;
  end

  assign sys_clk = clk_counter < ((`CLK_PERIOD) / 2);

  always begin
    #1 clk_counter <= (clk_counter == `CLK_PERIOD - 1 ? 32'b0 : clk_counter + 1);
  end

  assign rst = sys_rst;
  assign clk = sys_clk;

  /****** 10ge Buffer simulation ********/

  reg [31:0] buffer_level;

  always @(posedge clk) begin
    if (rst) begin
      buffer_level <= 0;
    end else begin
      if (ten_gbe0_tx_valid) begin
        buffer_level <= buffer_level + 1;
      end else begin
        if (buffer_level > 0) begin
          buffer_level <= buffer_level - 1;
        end
      end
      if (buffer_level >= 78) begin
        $display("FAILED: 10ge buffer overflowed");
        $finish;
      end
    end
  end

  assign ten_gbe0_tx_afull = buffer_level >= 64;
  assign ten_gbe0_tx_overflow = 0;

  reg [31:0] frame_len;
  always @(posedge clk) begin
    if (rst) begin
      frame_len <= 0;
    end else begin
      if (ten_gbe0_tx_valid) begin
        frame_len <= frame_len + 1;
        if (ten_gbe0_tx_end_of_frame) begin
          if (frame_len != 1023) begin
            $display("FAILED: frame length == %d", frame_len);
            $finish;
          end
          frame_len <= 0;
        end
      end
    end
  end


  /****** Control simulation ********/

  assign ctrl0 = 32'b0;
  assign ctrl1 = 32'b0;
  
  /********* QDR sim model ***********/

  /* qdr0 */
  qdr_controller #(
    .QDR_LATENCY (10),
    .QDR_DEPTH   (QDR_DEPTH)
  ) qdr0_controller_inst(
    .clk (clk),
    .rst (rst),
    .qdr_addr(qdr0_address),
    .qdr_wr_en(qdr0_wr_en),
    .qdr_wr_data(qdr0_dout),
    .qdr_be(qdr0_be),
    .qdr_rd_en(qdr0_rd_en),
    .qdr_rd_data(qdr0_din),
    .qdr_rdy(qdr0_phy_ready)
  );

  assign  qdr0_ack = 1'b1;
  assign  qdr0_cal_fail = 1'b0;

  /* qdr1 */
  qdr_controller #(
    .QDR_LATENCY (10),
    .QDR_DEPTH   (QDR_DEPTH)
  ) qdr1_controller_inst(
    .clk (clk),
    .rst (rst),
    .qdr_addr(qdr1_address),
    .qdr_wr_en(qdr1_wr_en),
    .qdr_wr_data(qdr1_dout),
    .qdr_be(qdr1_be),
    .qdr_rd_en(qdr1_rd_en),
    .qdr_rd_data(qdr1_din),
    .qdr_rdy(qdr1_phy_ready)
  );

  assign  qdr1_ack = 1'b1;
  assign  qdr1_cal_fail = 1'b0;

  /* adc if sim */

  reg [31:0] adc_dsim;

  always @(posedge clk) begin
    if (rst) begin
      adc_dsim <= 0;
    end else begin
      adc_dsim <= adc_dsim + 1;
    end
  end
  wire [31:0] adc0_i = adc_dsim;
  wire [31:0] adc0_q = adc_dsim + 32'h10000;
  wire [31:0] adc1_i = adc_dsim + 32'h20000;
  wire [31:0] adc1_q = adc_dsim + 32'h30000;

  assign adc0_datai0 = adc0_i[31:24];
  assign adc0_datai1 = adc0_i[23:16];
  assign adc0_datai2 = adc0_i[15:8];
  assign adc0_datai3 = adc0_i[7:0];

  assign adc0_dataq0 = adc0_q[31:24];
  assign adc0_dataq1 = adc0_q[23:16];
  assign adc0_dataq2 = adc0_q[15:8];
  assign adc0_dataq3 = adc0_q[7:0];

  assign adc1_datai0 = adc1_i[31:24];
  assign adc1_datai1 = adc1_i[23:16];
  assign adc1_datai2 = adc1_i[15:8];
  assign adc1_datai3 = adc1_i[7:0];

  assign adc1_dataq0 = adc1_q[31:24];
  assign adc1_dataq1 = adc1_q[23:16];
  assign adc1_dataq2 = adc1_q[15:8];
  assign adc1_dataq3 = adc1_q[7:0];

  /* tge */
  localparam TGE_MAX = 1024*8;

  reg tge_first;
  reg [31:0] tge_progress;
  wire [31:0] meh = ten_gbe0_tx_data[63:32];
  wire [63:0] d_expected = {tge_progress, tge_progress + 32'h10000};
  always @(posedge clk) begin
    if (rst) begin
      tge_progress <= 0;
      tge_first    <= 1;
    end else if (tge_first) begin
      if (ten_gbe0_tx_valid) begin
        tge_progress <= meh + 1;
        tge_first <= 1'b0;
      end
    end else begin
      if (ten_gbe0_tx_valid) begin
        tge_progress <= tge_progress + 1;
        if (d_expected != ten_gbe0_tx_data) begin
          $display("FAILED: data mismatch - expected = %x, got = %x", d_expected, ten_gbe0_tx_data);
          $finish;
        end
        if (tge_progress === TGE_MAX - 1) begin
          $display("PASSED");
          $finish;
        end
      end
    end
  end

endmodule
