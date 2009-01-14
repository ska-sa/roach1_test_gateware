`timescale 1ns/1ps
`include "bus_monitor.vh"

module bus_monitor(
    wb_clk_i, wb_rst_i,
    wb_stb_i, wb_cyc_i, wb_we_i,
    wb_adr_i, wb_dat_i, wb_dat_o,
    wb_ack_o,

    bm_memv,
    bm_timeout,
    bm_wbm_id,
    bm_addr,
    bm_we
  );
  input  wb_clk_i, wb_rst_i;
  input  wb_stb_i, wb_cyc_i, wb_we_i;
  input  [15:0] wb_adr_i;
  input  [15:0] wb_dat_i;
  output [15:0] wb_dat_o;
  output wb_ack_o;

  input  bm_memv;
  input  bm_timeout;
  input   [1:0] bm_wbm_id;
  input  [15:0] bm_addr;
  input  bm_we;

  reg [15:0] timeout_count;
  reg [15:0] memv_count;

  reg [20:0] bm_status;

  reg wb_ack_o;

  reg [2:0] wb_dat_src;

  assign wb_dat_o = wb_dat_src == 3'd0 ? {bm_status[20:5]} :
                    wb_dat_src == 3'd1 ? {11'b0, bm_status[4:0]} :
                    wb_dat_src == 3'd2 ? timeout_count :
                    wb_dat_src == 3'd3 ? memv_count :
                    wb_dat_src == 3'd4 ? {15'b0, 1'b1} :
                    16'hdead;

  always @(posedge wb_clk_i) begin
    //strobes
    wb_ack_o <= 1'b0;
    if (wb_rst_i) begin
      timeout_count <= 16'b0;
      memv_count <= 16'b0;
      bm_status <= 32'b0;
    end else begin
      if (~wb_ack_o & wb_cyc_i & wb_stb_i) begin
        wb_ack_o <= 1'b1;
        wb_dat_src <= wb_adr_i[2:0];
        case (wb_adr_i)
          `REG_BUS_STATUS_0: begin
            if (wb_we_i)
              bm_status <= 32'b0;
          end
          `REG_BUS_STATUS_1: begin
            if (wb_we_i)
              bm_status <= 32'b0;
          end
          `REG_TIMEOUT_COUNT: begin
            if (wb_we_i)
              timeout_count <= 16'b0;
          end
          `REG_MEMV_COUNT: begin
            if (wb_we_i)
              memv_count <= 16'b0;
          end
          `REG_UART_STATUS: begin
          end
        endcase
      end
    end
    if (bm_timeout | bm_memv) begin
      bm_status <= {bm_addr, bm_we, bm_wbm_id, bm_timeout, bm_memv};
    end
    if (bm_timeout) begin
      timeout_count <= timeout_count + 1;
    end
    if (bm_memv) begin
      memv_count <= memv_count + 1;
    end
  end

endmodule
