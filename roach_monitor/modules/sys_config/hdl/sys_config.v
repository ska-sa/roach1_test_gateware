`include "sys_config.vh"
module sys_config(
    wb_clk_i, wb_rst_i,
    wb_stb_i, wb_cyc_i, wb_we_i,
    wb_adr_i, wb_dat_i, wb_dat_o,
    wb_ack_o,
    sys_config_vector,
    xtal_clk,
    rtc_alarm
  );
  parameter BOARD_ID     = 0;
  parameter REV_MAJOR    = 0;
  parameter REV_MINOR    = 0;
  parameter REV_RCS      = 0;
  parameter RCS_UPTODATE = 0;

  input  wb_clk_i, wb_rst_i;
  input  wb_stb_i, wb_cyc_i, wb_we_i;
  input  [15:0] wb_adr_i;
  input  [15:0] wb_dat_i;
  output [15:0] wb_dat_o;
  output wb_ack_o;

  output  [7:0] sys_config_vector;
  input  xtal_clk;
  output rtc_alarm;

  reg wb_ack_o;
  reg [7:0] sys_config_vector;

  reg [3:0] wb_dat_src;

  reg [47:0] current_time_reg;
  reg [14:0] ticker_reg;

  reg [47:0] current_time_buffer;

  reg rtc_init_strb;

  assign wb_dat_o = wb_dat_src == `REG_BOARD_ID     ? BOARD_ID                 :
                    wb_dat_src == `REG_REV_MAJOR    ? REV_MAJOR                :
                    wb_dat_src == `REG_REV_MINOR    ? REV_MINOR                :
                    wb_dat_src == `REG_REV_RCS      ? REV_RCS                  :
                    wb_dat_src == `REG_RCS_UPTODATE ? RCS_UPTODATE             :
                    wb_dat_src == `REG_SYS_CONFIG   ? {8'b0,sys_config_vector} :
                    wb_dat_src == `REG_TIME_SEC_2   ? current_time_reg[47:32]  :
                    wb_dat_src == `REG_TIME_SEC_1   ? current_time_reg[31:16]  :
                    wb_dat_src == `REG_TIME_SEC_0   ? current_time_reg[15:0 ]  :
                    wb_dat_src == `REG_TIME_TICKER  ? {1'b0, ticker_reg}       :
                    16'b0;

  always @(posedge wb_clk_i) begin
    //strobes
    wb_ack_o      <= 1'b0;
    rtc_init_strb <= 1'b0;

    if (wb_rst_i) begin
      sys_config_vector <= 8'd0;
    end else begin
      if (wb_cyc_i & wb_stb_i & ~wb_ack_o) begin
        wb_ack_o   <=1'b1;
        wb_dat_src <= wb_adr_i[3:0];
        case (wb_adr_i)
          `REG_BOARD_ID: begin
          end
          `REG_REV_MAJOR: begin
          end
          `REG_REV_MINOR: begin
          end
          `REG_REV_RCS: begin
          end
          `REG_RCS_UPTODATE: begin
          end
          `REG_SYS_CONFIG: begin
            if (wb_we_i) begin
              sys_config_vector <= wb_dat_i[7:0];
            end
          end
          `REG_TIME_SEC_2: begin
            if (wb_we_i) begin
              current_time_buffer[47:32] <= wb_dat_i;
            end
          end
          `REG_TIME_SEC_1: begin
            if (wb_we_i) begin
              current_time_buffer[31:16] <= wb_dat_i;
            end
          end
          `REG_TIME_SEC_0: begin
            if (wb_we_i) begin
              current_time_buffer[15:0]  <= wb_dat_i;
              rtc_init_strb <= 1'b1;
            end
          end
          `REG_TIME_TICKER: begin
          end
        endcase
      end
    end
  end

  /* Real-Time Clock */

  reg [14:0] rtc_second_ticker;

  reg [47:0] current_time; /* seconds since 1970 */

  /* rtc value load handshaking registers */
  /* these should probably be registered to their respective clock domains */

  reg rtc_ack;
  reg rtc_got;

  always @(posedge xtal_clk) begin /* 32.768 kHz */
    if (rtc_got) begin
      rtc_ack <= 1'b1;
      rtc_second_ticker <= 15'd0;
      current_time <= current_time_buffer;
    end else begin
      rtc_ack <= 1'b0;
      rtc_second_ticker <= rtc_second_ticker + 1;

      if (rtc_second_ticker == 15'h7f_ff) begin
        current_time <= current_time + 1;
      end
    end
  end

  always @(posedge wb_clk_i) begin
    /* cross clock domains */
    current_time_reg <= current_time;
    ticker_reg       <= rtc_second_ticker;

    /* handshake for value loading */
    if (wb_rst_i) begin
      rtc_got <= 1'b0;
      ticker_reg <= 7'b0001111;
    end else begin
      if (rtc_init_strb)
        rtc_got <= 1'b1;
      if (rtc_ack)
        rtc_got <= 1'b0;
    end
  end

endmodule
