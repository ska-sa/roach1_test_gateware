`include "xaui_pipe.vh"
  /**************************** XAUI Wishbone Attachment *********************************/

module xaui_wb_attach(
    reset,
    wb_clk_i,
    wb_cyc_i, wb_stb_i, wb_we_i, wb_sel_i,
    wb_adr_i, wb_dat_i, wb_dat_o,
    wb_ack_o,

    user_loopback, user_powerdown, user_txen, user_xaui_reset_strb,

    rx_fifo_rd_en,  tx_fifo_wr_en,
    rx_fifo_status, tx_fifo_status,
    rx_fifo_data,   tx_fifo_data,

    xaui_status,
    mgt_rxeqmix, mgt_rxeqpole,
    mgt_txpreemphasis, mgt_txdiffctrl,
    error_count, data_count
    ,debug
  );
  output [3:0] debug;
  parameter DEFAULT_POWERDOWN = 0;
  parameter DEFAULT_LOOPBACK  = 0;
  parameter DEFAULT_TXEN      = 1;

  input reset;

  input  wb_clk_i;
  input  wb_cyc_i, wb_stb_i, wb_we_i;
  input   [1:0] wb_sel_i;
  input  [31:0] wb_adr_i;
  input  [15:0] wb_dat_i;
  output [15:0] wb_dat_o;
  output wb_ack_o;

  /* user mgt_control */
  output user_loopback;
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
  input   [7:0] xaui_status;
  output  [1:0] mgt_rxeqmix;
  output  [3:0] mgt_rxeqpole;
  output  [2:0] mgt_txpreemphasis;
  output  [2:0] mgt_txdiffctrl;

  input  [63:0] error_count; 
  input  [63:0] data_count; 

  reg user_loopback;
  reg user_powerdown, user_txen;
  reg user_xaui_reset_strb;

  reg [1:0] mgt_rxeqmix;
  reg [3:0] mgt_rxeqpole;
  reg [2:0] mgt_txpreemphasis;
  reg [2:0] mgt_txdiffctrl;

  reg [63:0] tx_fifo_data;
  reg rx_fifo_rd_en, tx_fifo_wr_en;

  reg wb_ack_o;

  reg [4:0] wb_dat_o_src;
  assign wb_dat_o = wb_dat_o_src == `REG_TXDATA3    ? tx_fifo_data[63:48] :
                    wb_dat_o_src == `REG_TXDATA2    ? tx_fifo_data[47:32] :    
                    wb_dat_o_src == `REG_TXDATA1    ? tx_fifo_data[31:16] :   
                    wb_dat_o_src == `REG_TXDATA0    ? tx_fifo_data[15:0]  :   
                    wb_dat_o_src == `REG_TXADVANCE  ? 16'b0 :  
                    wb_dat_o_src == `REG_TXSTATUS   ? {12'b0, tx_fifo_status} :  
                    wb_dat_o_src == `REG_RXDATA3    ? rx_fifo_data[63:48] :  
                    wb_dat_o_src == `REG_RXDATA2    ? rx_fifo_data[47:32] :  
                    wb_dat_o_src == `REG_RXDATA1    ? rx_fifo_data[31:16] : 
                    wb_dat_o_src == `REG_RXDATA0    ? rx_fifo_data[15:0]  : 
                    wb_dat_o_src == `REG_RXADVANCE  ? 16'b0 : 
                    wb_dat_o_src == `REG_RXSTATUS   ? {12'b0, rx_fifo_status} : 
                    wb_dat_o_src == `REG_LINKSTATUS ? {8'b0, xaui_status} : 
                    wb_dat_o_src == `REG_POWERDOWN  ? {15'b0, user_powerdown} : 
                    wb_dat_o_src == `REG_LOOPBACK   ? {15'b0, user_loopback} : 
                    wb_dat_o_src == `REG_TXEN       ? {15'b0, user_txen} : 
                    wb_dat_o_src == `REG_RESET      ? 16'b0 : 
                    wb_dat_o_src == `REG_RXPHYCONF  ? {4'b0, mgt_rxeqpole, 6'b0, mgt_rxeqmix} : 
                    wb_dat_o_src == `REG_TXPHYCONF  ? {5'b0, mgt_txdiffctrl, 5'b0, mgt_txpreemphasis} : 
                    wb_dat_o_src == `REG_UNUSED + 0 ? error_count[63:48] : 
                    wb_dat_o_src == `REG_UNUSED + 1 ? error_count[47:32] : 
                    wb_dat_o_src == `REG_UNUSED + 2 ? error_count[31:16] : 
                    wb_dat_o_src == `REG_UNUSED + 3 ? error_count[15:0]  : 
                    wb_dat_o_src == `REG_UNUSED + 4 ? data_count[63:48] : 
                    wb_dat_o_src == `REG_UNUSED + 5 ? data_count[47:32] : 
                    wb_dat_o_src == `REG_UNUSED + 6 ? data_count[31:16] : 
                    wb_dat_o_src == `REG_UNUSED + 7 ? data_count[15:0]  : 
                                                      16'b0;

  reg [3:0] debug;
  always @(posedge wb_clk_i) begin
    // strobes
    wb_ack_o<=1'b0;
    user_xaui_reset_strb<=1'b0;
    rx_fifo_rd_en<=1'b0;
    tx_fifo_wr_en<=1'b0;

    if (reset) begin
      // default xaui state
      user_powerdown    <= DEFAULT_POWERDOWN;
      user_loopback     <= DEFAULT_LOOPBACK;
      user_txen         <= DEFAULT_TXEN;
      mgt_rxeqmix       <= 2'b0;
      mgt_rxeqpole      <= 4'b0;
      mgt_txpreemphasis <= 3'b0;
      mgt_txdiffctrl    <= 3'b0;
    end else begin

      if (wb_cyc_i & wb_stb_i & ~wb_ack_o) begin
        wb_ack_o<=1'b1;
        wb_dat_o_src <= wb_adr_i[5:1];

        case (wb_adr_i[5:1]) 
          `REG_TXDATA3: begin
            if (wb_we_i) begin
              if (wb_sel_i[1])
                tx_fifo_data[63:56] <= wb_dat_i[15:8];
              if (wb_sel_i[0])
                tx_fifo_data[55:48] <= wb_dat_i[7:0];
            end
          end
          `REG_TXDATA2: begin
            if (wb_we_i) begin
              if (wb_sel_i[1])
                tx_fifo_data[47:40] <= wb_dat_i[15:8];
              if (wb_sel_i[0])
                tx_fifo_data[39:32] <= wb_dat_i[7:0];
            end
          end
          `REG_TXDATA1: begin
            if (wb_we_i) begin
              if (wb_sel_i[1])
                tx_fifo_data[31:24] <= wb_dat_i[15:8];
              if (wb_sel_i[0])
                tx_fifo_data[23:16] <= wb_dat_i[7:0];
            end
          end
          `REG_TXDATA0: begin
            if (wb_we_i) begin
              if (wb_sel_i[1])
                tx_fifo_data[15:8]  <= wb_dat_i[15:8];
              if (wb_sel_i[0])
                tx_fifo_data[7:0]   <= wb_dat_i[7:0];
            end
          end
          `REG_TXADVANCE: begin
            if (wb_we_i) begin
              if (wb_sel_i[0] & wb_dat_i[0]) begin
                tx_fifo_wr_en<=1'b1;
                debug <= ~debug;
              end
            end
          end
          `REG_TXSTATUS: begin
          end
          `REG_RXDATA3: begin
          end
          `REG_RXDATA2: begin
          end
          `REG_RXDATA1: begin
          end
          `REG_RXDATA0: begin
          end
          `REG_RXADVANCE: begin
            if (wb_we_i) begin
              if (wb_sel_i[0] & wb_dat_i[0]) begin
                rx_fifo_rd_en<=1'b1;
              end
            end
          end
          `REG_RXSTATUS: begin
          end
          `REG_LINKSTATUS: begin
          end
          `REG_POWERDOWN: begin
            if (wb_we_i & wb_sel_i[0]) begin
              user_powerdown<=wb_dat_i[0];
            end
          end
          `REG_LOOPBACK: begin
            if (wb_we_i & wb_sel_i[0]) begin
              user_loopback<=wb_dat_i[0];
            end
          end
          `REG_TXEN: begin
            if (wb_we_i & wb_sel_i[0]) begin
              user_txen<=wb_dat_i[0];
            end
          end
          `REG_RESET: begin
            if (wb_we_i) begin
              if (wb_sel_i[0] & wb_dat_i[0]) begin
                user_xaui_reset_strb<=1'b1;
              end 
            end
          end
          `REG_RXPHYCONF: begin
            if (wb_we_i) begin
              if (wb_sel_i[0])
                mgt_rxeqmix <= wb_dat_i[1:0];
              if (wb_sel_i[1])
                mgt_rxeqpole <= wb_dat_i[11:8];
            end
          end
          `REG_TXPHYCONF: begin
            if (wb_we_i) begin
              if (wb_sel_i[0])
                mgt_txpreemphasis <= wb_dat_i[2:0];
              if (wb_sel_i[1])
                mgt_txdiffctrl <= wb_dat_i[10:8];
            end
          end
          `REG_UNUSED + 0: begin
          end
          `REG_UNUSED + 1: begin
          end
          `REG_UNUSED + 2: begin
          end
          `REG_UNUSED + 3: begin
          end
          `REG_UNUSED + 4: begin
          end
          `REG_UNUSED + 5: begin
          end
          `REG_UNUSED + 6: begin
          end
          `REG_UNUSED + 7: begin
          end
          default: begin
          end
        endcase
      end
    end
  end

endmodule

