`timescale 1ns/10ps
`include "memlayout.v"
`include "parameters.v"


module dma_engine(
    clk, reset,
    wb_cyc_o, wb_stb_o, wb_we_o,
    wb_adr_o, wb_dat_o, wb_dat_i,
    wb_ack_i, wb_err_i,
    dma_crash, dma_done
  );
  input  clk, reset;
  output wb_cyc_o, wb_stb_o, wb_we_o;
  output [15:0] wb_adr_o;
  output [15:0] wb_dat_o;
  input  [15:0] wb_dat_i;
  input  wb_ack_i, wb_err_i;

  input  dma_crash;
  output dma_done;

  localparam MODE_FLASH     = 3'd0;
  localparam MODE_ALC       = 3'd1;
  localparam MODE_ABCONF    = 3'd2;
  localparam MODE_SYSCONFIG = 3'd3;
  localparam MODE_DONE      = 3'd4;
 
endmodule
