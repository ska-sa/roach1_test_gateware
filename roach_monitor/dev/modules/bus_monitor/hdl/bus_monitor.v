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
  parameter NUM_MASTERS = 4;

  input  wb_clk_i, wb_rst_i;
  input  wb_stb_i, wb_cyc_i, wb_we_i;
  input  [15:0] wb_adr_i;
  input  [15:0] wb_dat_i;
  output [15:0] wb_dat_o;
  output wb_ack_o;

  input  bm_memv;
  input  bm_timeout;
  input  [NUM_MASTERS - 1:0] bm_wbm_id;
  input  [15:0] bm_addr;
  input  bm_we;

  reg [15:0] timeout_count;
  reg [15:0] memv_count;

  reg [31:0] bm_status;

  reg wb_ack_o;

  assign wb_dat_o = wb_adr_i == `REG_BUS_STATUS_0   ? {bm_status[15:0]} :
                    wb_adr_i == `REG_BUS_STATUS_1   ? {bm_status[31:16]} :
                    wb_adr_i == `REG_TIMEOUT_COUNT  ? timeout_count :
                    wb_adr_i == `REG_MEMV_COUNT ? memv_count :
                    16'b0;

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
        if (wb_we_i) begin
          case (wb_adr_i)
            `REG_BUS_STATUS_0: begin
              bm_status <= 32'b0;
            end
            `REG_BUS_STATUS_1: begin
              bm_status <= 32'b0;
            end
            `REG_TIMEOUT_COUNT: begin
              timeout_count <= 16'b0;
            end
            `REG_MEMV_COUNT: begin
              memv_count <= 16'b0;
            end
          endcase
        end
      end
    end
    if (bm_timeout | bm_memv) begin
      bm_status = {bm_addr, 3'b0, bm_we, bm_wbm_id, 2'b0, bm_timeout, bm_memv};
    end
    if (bm_timeout) begin
      timeout_count <= timeout_count + 1;
    end
    if (bm_memv) begin
      memv_count <= memv_count + 1;
    end
  end

endmodule
