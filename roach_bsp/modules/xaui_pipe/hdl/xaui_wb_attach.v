`include "xaui_pipe.vh"
  /**************************** XAUI Wishbone Attachment *********************************/

module xaui_wb_attach(
  reset,
  wb_clk_i,
  wb_cyc_i, wb_stb_i, wb_we_i,
  wb_adr_i, wb_dat_i, wb_dat_o,
  wb_ack_o,

  user_loopback, user_powerdown, user_txen, user_xaui_reset_strb,

  rx_fifo_rd_en,  tx_fifo_wr_en,
  rx_fifo_status, tx_fifo_status,
  rx_fifo_data,   tx_fifo_data,

  xaui_status
`ifdef XAUI_ERROR_TEST
  , error_count, data_count
`endif
  );
`ifdef XAUI_ERROR_TEST
  input [63:0] error_count; 
  input [63:0] data_count; 
`endif

  input reset;

  input  wb_clk_i;
  input  wb_cyc_i, wb_stb_i, wb_we_i;
  input  [15:0] wb_adr_i;
  input  [31:0] wb_dat_i;
  output [31:0] wb_dat_o;
  output wb_ack_o;

  /* user mgt_control */
  output [1:0] user_loopback;
  output user_powerdown, user_txen;
  output user_xaui_reset_strb;

  /* fifo control */
  output rx_fifo_rd_en;
  output tx_fifo_wr_en;
  input   [3:0] rx_fifo_status;
  input   [3:0] tx_fifo_status;
  input  [63:0] rx_fifo_data;
  output [63:0] tx_fifo_data;

  /* xaui status */
  input  [7:0] xaui_status;

  reg  [1:0] user_loopback;
  reg user_powerdown, user_txen;
  reg user_xaui_reset_strb;

  reg [63:0] tx_fifo_data;
  reg rx_fifo_rd_en, tx_fifo_wr_en;

  reg rx_half_fifo, tx_half_fifo;

  reg wb_ack_o;
  reg [31:0] wb_dat_o;

  always @(posedge wb_clk_i) begin
    if (reset) begin
      rx_half_fifo<=1'b0;
      tx_half_fifo<=1'b0;

     /* default xaui state == power_down & loopback */
      user_powerdown<=1'b0;
      user_loopback<=2'b01;
      user_txen<=1'b1;

      user_xaui_reset_strb<=1'b0;

      wb_ack_o<=1'b0;
      rx_fifo_rd_en<=1'b0;
      tx_fifo_wr_en<=1'b0;
    end else begin
      /* strobes */
      wb_ack_o<=1'b0;
      user_xaui_reset_strb<=1'b0;
      rx_fifo_rd_en<=1'b0;
      tx_fifo_wr_en<=1'b0;

      if (wb_cyc_i & wb_stb_i & ~wb_ack_o) begin
        wb_ack_o<=1'b1;
        case (wb_adr_i[7:2]) 
          `XAUI_TXDATA_A: begin
            if (wb_we_i) begin
              tx_half_fifo<=~tx_half_fifo;
              if (~tx_half_fifo) begin
                tx_fifo_data[63:32]<=wb_dat_i;
              end else begin
                tx_fifo_data[31:0]<=wb_dat_i;
                tx_fifo_wr_en<=1'b1;
              end
            end else begin
              wb_dat_o<=32'hfeed;
            end
          end
          `XAUI_TXSTATUS_A: begin
            if (wb_we_i) begin
            end else begin
              wb_dat_o<={28'b0,tx_fifo_status};
            end
          end
          `XAUI_RXDATA_A: begin
            if (wb_we_i) begin
            end else begin
              rx_half_fifo<=~rx_half_fifo;
              if (~rx_half_fifo) begin
                wb_dat_o<=rx_fifo_data[63:32];
              end else begin
                wb_dat_o<=rx_fifo_data[31:0];
                rx_fifo_rd_en<=1'b1;
              end
            end
          end
          `XAUI_RXSTATUS_A: begin
            if (wb_we_i) begin
            end else begin
              wb_dat_o<={28'b0,rx_fifo_status};
            end
          end
          `XAUI_LINKSTATUS_A: begin
            if (wb_we_i) begin
            end else begin
              wb_dat_o<={24'b0,xaui_status};
            end
          end
          `XAUI_TXEN_A: begin
            if (wb_we_i) begin
              user_txen<=wb_dat_i[0];
            end else begin
              wb_dat_o<={31'b0, user_txen};
            end
          end
          `XAUI_POWERDOWN_A: begin
            if (wb_we_i) begin
              user_powerdown<=wb_dat_i[0];
            end else begin
              wb_dat_o<={31'b0, user_powerdown};
            end
          end
          `XAUI_LOOPBACK_A: begin
            if (wb_we_i) begin
              user_loopback<=wb_dat_i[1:0];
            end else begin
              wb_dat_o<={30'b0,user_loopback};
            end
          end
          `XAUI_RESET_A: begin
            if (wb_we_i) begin
              if (wb_dat_i[0] != 32'b0) begin
                user_xaui_reset_strb<=1'b1;
              end 
            end else begin
              wb_dat_o<=32'b0;
            end
          end
`ifdef XAUI_ERROR_TEST
          `XAUI_MGT_CHBOND_ERRORS_0_A: begin
            if (wb_we_i) begin
            end else begin
              wb_dat_o<=data_count[63:32];
            end
          end
          `XAUI_MGT_CHBOND_ERRORS_1_A: begin
            if (wb_we_i) begin
            end else begin
              wb_dat_o<=data_count[31:0];
            end
          end
          `XAUI_MGT_CHBOND_ERRORS_2_A: begin
            if (wb_we_i) begin
            end else begin
              wb_dat_o<=error_count[63:32];
            end
          end
          `XAUI_MGT_CHBOND_ERRORS_3_A: begin
            if (wb_we_i) begin
            end else begin
              wb_dat_o<=error_count[31:0];
            end
          end
`endif
          default: begin
            if (wb_we_i) begin
            end else begin
              wb_dat_o<=32'hbeefbeef;
            end
          end
        endcase
      end
    end
  end

endmodule

