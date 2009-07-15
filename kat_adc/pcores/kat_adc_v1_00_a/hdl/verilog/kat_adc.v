`timescale 1ns/10ps

module kat_adc #(
    parameter QDR_SIZE   = 19,
    parameter FRAME_WAIT = 13,
    parameter BACKOFF_LEN = 30
  ) (
    input         clk,
    input         rst,

    output  [3:0] leddies,

    /* Status/Control Registers */
    input  [31:0] ctrl0,
    input  [31:0] ctrl1,
    output [31:0] overrange_i1,
    output [31:0] overrange_q1,
    output [31:0] overrange_i0,
    output [31:0] overrange_q0,
    output [31:0] status0,
    output [31:0] status1,
    output [31:0] sync_count0,
    output [31:0] sync_count1,

    /* ADC0 */
    input         adc0_data_valid,
    input   [7:0] adc0_datai0,
    input   [7:0] adc0_datai1,
    input   [7:0] adc0_datai2,
    input   [7:0] adc0_datai3,
    input   [7:0] adc0_dataq0,
    input   [7:0] adc0_dataq1,
    input   [7:0] adc0_dataq2,
    input   [7:0] adc0_dataq3,
    input         adc0_outofrangei0,
    input         adc0_outofrangei1,
    input         adc0_outofrangeq0,
    input         adc0_outofrangeq1,
    input         adc0_sync0,
    input         adc0_sync1,
    input         adc0_sync2,
    input         adc0_sync3,

    /* ADC1 */
    input         adc1_data_valid,
    input   [7:0] adc1_datai0,
    input   [7:0] adc1_datai1,
    input   [7:0] adc1_datai2,
    input   [7:0] adc1_datai3,
    input   [7:0] adc1_dataq0,
    input   [7:0] adc1_dataq1,
    input   [7:0] adc1_dataq2,
    input   [7:0] adc1_dataq3,
    input         adc1_outofrangei0,
    input         adc1_outofrangei1,
    input         adc1_outofrangeq0,
    input         adc1_outofrangeq1,
    input         adc1_sync0,
    input         adc1_sync1,
    input         adc1_sync2,
    input         adc1_sync3,

    /* QDR0 */
    input         qdr0_ack,
    input         qdr0_cal_fail,
    input  [35:0] qdr0_din,
    input         qdr0_phy_ready,
    output [31:0] qdr0_address,
    output  [3:0] qdr0_be,
    output [35:0] qdr0_dout,
    output        qdr0_rd_en,
    output        qdr0_wr_en,

    /* QDR1 */
    input         qdr1_ack,
    input         qdr1_cal_fail,
    input  [35:0] qdr1_din,
    input         qdr1_phy_ready,
    output [31:0] qdr1_address,
    output  [3:0] qdr1_be,
    output [35:0] qdr1_dout,
    output        qdr1_rd_en,
    output        qdr1_wr_en,

    /* 10GE 0 */
    input         ten_gbe0_led_rx,
    input         ten_gbe0_led_tx,
    input         ten_gbe0_led_up,
    input         ten_gbe0_rx_bad_frame,
    input  [63:0] ten_gbe0_rx_data,
    input         ten_gbe0_rx_end_of_frame,
    input         ten_gbe0_rx_overrun,
    input  [31:0] ten_gbe0_rx_source_ip,
    input  [15:0] ten_gbe0_rx_source_port,
    input         ten_gbe0_rx_valid,
    input         ten_gbe0_tx_afull,
    input         ten_gbe0_tx_overflow,
    output        ten_gbe0_rst,
    output        ten_gbe0_rx_ack,
    output        ten_gbe0_rx_overrun_ack,
    output [63:0] ten_gbe0_tx_data,
    output [31:0] ten_gbe0_tx_dest_ip,
    output [15:0] ten_gbe0_tx_dest_port,
    output        ten_gbe0_tx_end_of_frame,
    output        ten_gbe0_tx_valid
  );

  /*************** Primary State Machine ****************/

  /* control signals */
  wire        capture_start;
  wire        capture_busy;
  wire        capture_write_done;
  wire        capture_read_done;
  wire  [1:0] buffer0_src;
  wire  [1:0] buffer1_src;

  reg [1:0] state;
  localparam STATE_WAIT  = 0;
  localparam STATE_WRITE = 1;
  localparam STATE_READ  = 2;

  always @(posedge clk) begin
    if (rst) begin
      state <= STATE_WAIT;
    end else begin
      case (state)
        STATE_WAIT: begin
          if (capture_start) begin
            state <= STATE_WRITE;
          end
        end
        STATE_WRITE: begin
          if (capture_write_done) begin
            state <= STATE_READ;
          end
        end
        STATE_READ: begin
          if (capture_read_done) begin
            state <= STATE_WAIT;
          end
        end
        default: begin
          state <= STATE_WAIT;
        end
      endcase
    end
  end
  assign capture_busy = state != STATE_WAIT;

  /*************** QDR write State Machine ****************/

  reg [QDR_SIZE-1:0] write_progress;
  reg [1:0] write_state;
  localparam WRITE_IDLE  = 0;
  localparam WRITE_0     = 1;
  localparam WRITE_1     = 2;

  reg write_last;

  always @(posedge clk) begin
    write_last <= 1'b0;

    if (rst) begin
      write_state <= WRITE_IDLE; 
    end else begin
      case (write_state)
        WRITE_IDLE: begin
          if (state == STATE_WRITE) begin
            write_state <= WRITE_0; 
            write_progress <= 0;
          end
        end
        WRITE_0: begin
          write_state <= WRITE_1; 
          write_progress <= write_progress + 1;
          if (write_progress == {QDR_SIZE{1'b1}}) begin
            write_last <= 1'b1;
          end
        end
        WRITE_1: begin
          if (write_last) begin
            write_state <= WRITE_IDLE; 
          end else begin
            write_state <= WRITE_0; 
          end
        end
        default: begin
          write_state <= WRITE_IDLE; 
          write_last  <= 1'b1;
        end
      endcase
    end
  end
  assign capture_write_done = write_last;

  /*************** QDR read State Machine ****************/

  reg   [3 + QDR_SIZE - 1:0] read_progress;

  reg read_state;
  localparam READ_IDLE = 0;
  localparam READ_RUN  = 1;

  reg read_en;
  reg frame_last;
  reg read_last;

  always @(posedge clk) begin
    read_en    <= 1'b0;
    read_last  <= 1'b0;

    /* state independent logic */
    frame_last    <= read_progress[11:0] == {{9{1'b1}}, 3'b0};

    if (rst) begin
      read_state    <= READ_IDLE; 
      read_progress <= 0;
    end else begin
      case (read_state)
        READ_IDLE: begin
          read_progress <= 0;
          if (state == STATE_READ) begin
            read_state    <= READ_RUN; 
          end
        end
        READ_RUN: begin
          read_progress <= read_progress + 1;
          read_en   <= read_progress[2:0] == 3'b0;
          read_last <= read_progress == {{QDR_SIZE{1'b1}}, 3'b0};
          if (read_last)
            read_state <= READ_IDLE;
        end
      endcase
    end
  end
  assign capture_read_done = read_last;

  /* Determine the tge_dvld and tge_eof signal */

  wire tge_dvld;
  reg [10:0] tge_dvld_shift; //QDR latency is 10 + 1 for input reg
  reg tge_dvld_z;

  wire tge_eof;
  reg [11:0] tge_eof_shift; //QDR latency is 10 + 1 for input reg


  always @(posedge clk) begin
    if (rst) begin
      tge_dvld_shift <= 0;
      tge_dvld_z     <= 0;
      tge_eof_shift  <= 0;
    end else begin
      tge_dvld_shift <= {tge_dvld_shift[9:0], read_en};
      tge_dvld_z     <= tge_dvld_shift[10];
      tge_eof_shift  <= {tge_eof_shift[10:0], frame_last};
    end
  end

  assign tge_dvld = tge_dvld_shift[10] | tge_dvld_z;
  assign tge_eof  = tge_eof_shift[11];

  /* qdr assignments */

  reg [31:0] qdr0_wr_data;
  reg [31:0] qdr1_wr_data;

  reg [31:0] counter0;
  reg [31:0] counter1;

  always @(posedge clk) begin
    counter0 <= counter0 + 1;
    counter1 <= counter1 + 1;

    if (!ctrl0[31]) begin
      case (buffer0_src)
        0: qdr0_wr_data <= {adc0_datai0, adc0_datai1, adc0_datai2, adc0_datai3};
        1: qdr0_wr_data <= {adc0_dataq0, adc0_dataq1, adc0_dataq2, adc0_dataq3};
        2: qdr0_wr_data <= {adc1_datai0, adc1_datai1, adc1_datai2, adc1_datai3};
        3: qdr0_wr_data <= {adc1_dataq0, adc1_dataq1, adc1_dataq2, adc1_dataq3};
      endcase
      case (buffer1_src)
        0: qdr1_wr_data <= {adc0_datai0, adc0_datai1, adc0_datai2, adc0_datai3};
        1: qdr1_wr_data <= {adc0_dataq0, adc0_dataq1, adc0_dataq2, adc0_dataq3};
        2: qdr1_wr_data <= {adc1_datai0, adc1_datai1, adc1_datai2, adc1_datai3};
        3: qdr1_wr_data <= {adc1_dataq0, adc1_dataq1, adc1_dataq2, adc1_dataq3};
      endcase
    end else begin
      qdr0_wr_data <= counter0;
      qdr1_wr_data <= counter1;
    end
  end

  reg [31:0] qdr0_addr;
  reg [31:0] qdr1_addr;

  always @(posedge clk) begin
    qdr0_addr <= state == STATE_WRITE ? write_progress : read_progress >> 3;
    qdr1_addr <= state == STATE_WRITE ? write_progress : read_progress >> 3;
  end

  reg qdr0_wr;
  reg qdr1_wr;

  always @(posedge clk) begin
    qdr0_wr <= write_state == WRITE_0;
    qdr1_wr <= write_state == WRITE_0;
  end

  reg qdr0_rd;
  reg qdr1_rd;

  always @(posedge clk) begin
    qdr0_rd <= read_en;
    qdr1_rd <= read_en;
  end

  assign qdr0_address = qdr0_addr;
  assign qdr0_be      = 4'b1111;
  assign qdr0_dout    = qdr0_wr_data;
  assign qdr0_rd_en   = qdr0_rd;
  assign qdr0_wr_en   = qdr0_wr;

  assign qdr1_address = qdr1_addr;
  assign qdr1_be      = 4'b1111;
  assign qdr1_dout    = qdr1_wr_data;
  assign qdr1_rd_en   = qdr1_rd;
  assign qdr1_wr_en   = qdr1_wr;

  /********* 10Ge Assignments **********/

  assign ten_gbe0_tx_dest_ip    = {8'd192, 8'd168, 8'd5, 8'd2};
  assign ten_gbe0_tx_dest_port  = 20000;

  reg [63:0] tge0_data;
  reg        tge0_dvld;
  reg        tge0_eof;

  always @(posedge clk) begin
    tge0_data <= {qdr0_din[31:0], qdr1_din[31:0]};

    if (rst) begin
      tge0_dvld <= 0;
      tge0_eof  <= 0;
    end else begin
      tge0_dvld <= tge_dvld;
      tge0_eof  <= tge_eof;
    end
  end

  assign ten_gbe0_tx_data         = tge0_data;
  assign ten_gbe0_tx_end_of_frame = tge0_eof;
  assign ten_gbe0_tx_valid        = tge0_dvld;

  //assign ten_gbe0_rst            = state == STATE_WAIT; /* this is a hack */
  assign ten_gbe0_rst            = 1'b0;
  assign ten_gbe0_rx_ack         = 1'b0;
  assign ten_gbe0_rx_overrun_ack = 1'b0;

  reg tge_overflow;
  always @(posedge clk) begin
    tge_overflow <= ten_gbe0_tx_overflow;
  end

  /*********** Leddies ************/

  reg [3:0] leddies_reg;
  reg [3:0] leddies_regR;//extra register for routing overhead
  always @(posedge clk) begin
    leddies_reg  <= ~{ten_gbe0_led_up, tge_overflow, state};
    leddies_regR <= leddies_reg;
  end
  assign leddies = leddies_regR;

  /****** Control and Status ******/

  reg prev_start;
  reg capture_start_reg;

  reg [1:0] capture_state;
  localparam CAP_START   = 0;
  localparam CAP_WAIT    = 1;
  localparam CAP_BACKOFF = 2;

  reg [BACKOFF_LEN-1:0] capture_backoff;
  always @(posedge clk) begin
    prev_start <= ctrl0[0];
    capture_start_reg <= 1'b0;

    if (rst || !qdr0_phy_ready || !qdr1_phy_ready) begin
      capture_state <= CAP_BACKOFF;
      capture_backoff <= 0;
    end else begin
      case (capture_state)
        CAP_START: begin
          if (ctrl0[8]) begin
            capture_start_reg <= !prev_start && ctrl0[0];
          end else begin
            capture_start_reg <= 1'b1;
            capture_state <= CAP_WAIT;
          end
        end
        CAP_WAIT: begin
          if (capture_read_done) begin
            capture_state <= CAP_BACKOFF;
            capture_backoff <= 24'b0;
          end
        end
        CAP_BACKOFF: begin
          if (capture_backoff == {BACKOFF_LEN{1'b1}}) begin
            capture_state <= CAP_START;
          end
          capture_backoff <= capture_backoff + 1;
        end
      endcase
    end
  end
  assign capture_start = capture_start_reg;

  /* Buffer Source Control */

  reg [1:0] buf0_src;
  reg [1:0] buf1_src;
  always @(posedge clk) begin
    buf0_src <= ctrl1[31] ? ctrl1[25:24] : 2'b00;
    buf1_src <= ctrl1[31] ? ctrl1[27:26] : 2'b01;
  end
  assign buffer0_src = buf0_src;
  assign buffer1_src = buf1_src;

  /* Over-range counters */

  reg [31:0] overrange_i1_cnt;
  reg [31:0] overrange_q1_cnt;
  reg [31:0] overrange_i0_cnt;
  reg [31:0] overrange_q0_cnt;

  always @(posedge clk) begin
    if (adc1_outofrangei0 || adc1_outofrangei1)
      overrange_i1_cnt <= overrange_i1_cnt + 1;
    if (adc1_outofrangeq0 || adc1_outofrangeq1)
      overrange_q1_cnt <= overrange_q1_cnt + 1;

    if (adc0_outofrangei0 || adc0_outofrangei1)
      overrange_i0_cnt <= overrange_i0_cnt + 1;
    if (adc0_outofrangeq0 || adc0_outofrangeq1)
      overrange_q0_cnt <= overrange_q0_cnt + 1;

  end

  assign overrange_i1 = overrange_i1_cnt;
  assign overrange_q1 = overrange_q1_cnt;
  assign overrange_i0 = overrange_i0_cnt;
  assign overrange_q0 = overrange_q0_cnt;

  assign status0 = {2'b0, state, 3'b0, tge_overflow, 3'b0, ten_gbe0_led_up,  3'b0, capture_busy};

  assign status1 = {24'b0, 2'b0, qdr1_cal_fail, qdr0_cal_fail, 2'b0, qdr1_phy_ready, qdr0_phy_ready};

endmodule
