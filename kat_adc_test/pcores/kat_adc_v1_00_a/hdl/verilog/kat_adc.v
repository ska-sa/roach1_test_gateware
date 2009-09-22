`timescale 1ns/10ps

module kat_adc #(
    parameter QDR_SIZE   = 12
  ) (
    input         clk,
    input         rst,

    output  [3:0] leddies,

    /* Status/Control Registers */
    input  [31:0] ctrl,
    output [31:0] overrange,
    output [31:0] status,
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
    input   [1:0] adc0_outofrange,
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
    input   [1:0] adc1_outofrange,
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
    output        qdr1_wr_en
  );

  /*************** Primary State Machine ****************/

  /* control signals */
  wire        capture_start;
  wire        capture_busy;
  wire        capture_write_done;
  wire  [1:0] buffer0_src;
  wire  [1:0] buffer1_src;

  reg [0:0] state;
  localparam STATE_WAIT  = 0;
  localparam STATE_WRITE = 1;
//synthesis attribute MAX_FANOUT of state is 20

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

  reg wr_start;
  always @(posedge clk) begin
    wr_start <= capture_start && state == STATE_WAIT;
  end

  reg [(QDR_SIZE + 1) - 1:0] write_progress;
  always @(posedge clk) begin
    if (wr_start) begin
      write_progress <= 0;
    end else begin
      write_progress <= write_progress + 1;
    end
  end

  reg [(QDR_SIZE + 1)- 1:0] write_progress_z;
  always @(posedge clk) begin
    write_progress_z <= write_progress;
  end

  reg wr_valid;
  reg wr_start_z;
  reg wr_last;
  always @(posedge clk) begin
    wr_start_z <= wr_start;
    if (rst) begin
      wr_valid <= 1'b0;
    end else begin
      if (wr_start_z) begin
        wr_valid <= 1'b1;
      end
      if (wr_last) begin
        wr_valid <= 1'b0;
      end
    end

    wr_last <= write_progress_z == ({QDR_SIZE{1'b1}} - 1);
  end

  assign capture_write_done = wr_last && wr_valid;

  /*********** QDR assignments ***************/

  reg [31:0] qdr0_wr_data;
  reg [31:0] qdr1_wr_data;


  always @(posedge clk) begin
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
  end

  reg [31:0] qdr0_wr_data_z;
  reg [31:0] qdr1_wr_data_z;

  always @(posedge clk) begin
    qdr0_wr_data_z <= qdr0_wr_data;
    qdr1_wr_data_z <= qdr1_wr_data;
  end

  reg [31:0] qdr0_addr;
  reg [31:0] qdr1_addr;

  always @(posedge clk) begin
    qdr0_addr <= write_progress_z[QDR_SIZE:1];
    qdr1_addr <= write_progress_z[QDR_SIZE:1];
  end

  reg qdr0_wr;
  reg qdr1_wr;

  always @(posedge clk) begin
    qdr0_wr <= wr_valid && write_progress_z[0];
    qdr1_wr <= wr_valid && write_progress_z[0];
  end

  assign qdr0_address = qdr0_addr;
  assign qdr0_be      = 4'b1111;
  assign qdr0_dout    = {1'b0, qdr0_wr_data_z[31:24], 1'b0, qdr0_wr_data_z[23:16], 1'b0, qdr0_wr_data_z[15:8], 1'b0, qdr0_wr_data_z[7:0]};
  assign qdr0_rd_en   = 1'b0;
  assign qdr0_wr_en   = qdr0_wr;

  assign qdr1_address = qdr1_addr;
  assign qdr1_be      = 4'b1111;
  assign qdr1_dout    = {1'b0, qdr1_wr_data_z[31:24], 1'b0, qdr1_wr_data_z[23:16], 1'b0, qdr1_wr_data_z[15:8], 1'b0, qdr1_wr_data_z[7:0]};
  assign qdr1_rd_en   = 1'b0;
  assign qdr1_wr_en   = qdr1_wr;

  /*********** Leddies ************/

  reg [3:0] leddies_reg;
  reg [3:0] leddies_regR;  //extra register for iobuf
  reg [3:0] leddies_regRR; //extra register for routing overhead

  //sythesis attribute KEEP of leddies_reg   is TRUE
  //sythesis attribute KEEP of leddies_regR  is TRUE
  //sythesis attribute KEEP of leddies_regRR is TRUE
  //synthesis attribute shreg_extract of leddies_reg   is NO
  //synthesis attribute shreg_extract of leddies_regR  is NO
  //synthesis attribute shreg_extract of leddies_regRR is NO

  // make sure the stupid synthesis bastard compiler doesn't change my registers into a shifter - FFFFFFFFFFFUUUUUUU...

  reg [25:0] flasher;
  always @(posedge clk) begin
    flasher <= flasher + 1;
  end

  always @(posedge clk) begin
    leddies_reg  <= ~{flasher[25], 2'b00, state};
    leddies_regR <= leddies_reg;
    leddies_regRR <= leddies_regR;
  end
  assign leddies = leddies_regRR;

  /****** Control ******/

  /* Capture on positive edge on ctrl[0] */

  wire usr_capture_start = ctrl[0];
  reg usr_capture_start_z;

  always @(posedge clk) begin
    usr_capture_start_z <= usr_capture_start;
  end
  assign capture_start = usr_capture_start && !usr_capture_start_z;
  
  /* Buffer Source Control */

  reg [1:0] buf0_src;
  reg [1:0] buf1_src;
  always @(posedge clk) begin
    buf0_src <= ctrl[9:8];
    buf1_src <= ctrl[13:12];
  end
  assign buffer0_src = buf0_src;
  assign buffer1_src = buf1_src;

  /* Over-range latch */

  reg [1:0] overrange0;
  reg [1:0] overrange1;

  always @(posedge clk) begin
    if (rst || ctrl[4]) begin
      overrange0 <= 2'b0;
      overrange1 <= 2'b0;
    end else begin
      overrange0 <= overrange0 | adc0_outofrange;
      overrange1 <= overrange1 | adc1_outofrange;
    end
  end
  assign overrange = {16'b0, 6'b0, overrange1, 6'b0, overrange0};

  /********** Status *********/
  assign status = {31'b0, capture_busy};

  /******* Sync counter ******/
  wire sync0 =  adc0_sync0 || adc0_sync1 || adc0_sync2 || adc0_sync3;
  wire sync1 =  adc1_sync0 || adc1_sync1 || adc1_sync2 || adc1_sync3;

  reg sync0_z;
  reg sync1_z;

  always @(posedge clk) begin
    sync0_z <= sync0;
    sync1_z <= sync1;
  end

  reg [15:0] sync_counter0;
  reg [15:0] sync_counter1;

  always @(posedge clk) begin
    sync_counter0 <= sync_counter0 + 1;
    sync_counter1 <= sync_counter1 + 1;
  end

  assign sync_count0 = sync_counter0;
  assign sync_count1 = sync_counter1;

endmodule
