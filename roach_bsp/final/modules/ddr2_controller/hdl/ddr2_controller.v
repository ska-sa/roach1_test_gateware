//*****************************************************************************
// Copyright (c) 2006-2007 Xilinx, Inc.
// This design is confidential and proprietary of Xilinx, Inc.
// All Rights Reserved
//*****************************************************************************
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor: Xilinx
// \   \   \/     Version: $Name: i+IP+131489 $
//  \   \         Application: MIG
//  /   /         Filename: ml505_ddr2_ddr2_top_0.v
// /___/   /\     Date Last Modified: $Date: 2007/09/21 15:23:30 $
// \   \  /  \    Date Created: Wed Aug 16 2006
//  \___\/\___\
//
//Device: Virtex-5
//Design Name: DDR2
//Purpose:
//   System level module. This level contains just the memory controller.
//   This level will be intiantated when the user wants to remove the
//   synthesizable test bench, IDELAY control block and the clock
//   generation modules.
//Reference:
//Revision History:
//*****************************************************************************

`timescale 1ns/1ps

module ddr2_controller #
  (
   parameter BANK_WIDTH           = 2,       // # of memory bank addr bits
   parameter CKE_WIDTH            = 1,       // # of memory clock enable outputs
   parameter CLK_WIDTH            = 3,       // # of clock outputs
   parameter COL_WIDTH            = 10,      // # of memory column bits
   parameter CS_NUM               = 1,       // # of separate memory chip selects
   parameter CS_WIDTH             = 1,       // # of total memory chip selects
   parameter CS_BITS              = 1,       // set to log2(CS_NUM) (rounded up)
   parameter DM_WIDTH             = 8,       // # of data mask bits
   parameter DQ_WIDTH             = 64,      // # of data width
   parameter DQ_PER_DQS           = 8,       // # of DQ data bits per strobe
   parameter DQS_WIDTH            = 8,       // # of DQS strobes
   parameter DQ_BITS              = 7,       // set to log2(DQS_WIDTH*DQ_PER_DQS)
   parameter DQS_BITS             = 4,       // set to log2(DQS_WIDTH)
   parameter ODT_WIDTH            = 1,       // # of memory on-die term enables
   parameter ROW_WIDTH            = 13,      // # of memory row and # of addr bits
   parameter ADDITIVE_LAT         = 0,       // additive write latency 
   parameter BURST_LEN            = 4,       // burst length (in double words)
   parameter BURST_TYPE           = 0,       // burst type (=0 seq; =1 interleaved)
   parameter CAS_LAT              = 3,       // CAS latency
   parameter ECC_ENABLE           = 0,       // enable ECC (=1 enable)
   parameter APPDATA_WIDTH        = 128,     // # of usr read/write data bus bits
   parameter MULTI_BANK_EN        = 1,       // Keeps multiple banks open. (= 1 enable)
   parameter TWO_T_TIME_EN        = 1,       // 2t timing for unbuffered dimms
   parameter ODT_TYPE             = 1,       // ODT (=0(none),=1(75),=2(150),=3(50))
   parameter REDUCE_DRV           = 0,       // reduced strength mem I/O (=1 yes)
   parameter REG_ENABLE           = 0,       // registered addr/ctrl (=1 yes)
   parameter TREFI_NS             = 7800,       // auto refresh interval (ns)
   parameter TRAS                 = 40000,       // active->precharge delay
   parameter TRCD                 = 15000,       // active->read/write delay
   parameter TRFC                 = 127500,       // refresh->refresh, refresh->active delay
   parameter TRP                  = 15000,       // precharge->command delay
   parameter TRTP                 = 7500,       // read->precharge delay
   parameter TWR                  = 15000,       // used to determine write->precharge
   parameter TWTR                 = 10000,       // write->read delay
   parameter SIM_ONLY             = 0,       // = 1 to skip SDRAM power up delay
   parameter DEBUG_EN             = 0,       // Enable debug signals/controls
   parameter DQS_IO_COL           = 16'b0000000000000000,       // I/O column location of DQS groups (=0, left; =1 center, =2 right)
   parameter DQ_IO_MS             = 64'b10100101_10100101_10100101_10100101_10100101_10100101_10100101_10100101,       // Master/Slave location of DQ I/O (=0 slave) 
   parameter CLK_PERIOD           = 5000,       // Core/Memory clock period (in ps)
   parameter RST_ACT_LOW          = 1        // =1 for active low reset, =0 for active high
   )
  (
   input          clk0,
   input          clk90,
   input          clkdiv0,
   input          rst0,
   input          rst90,
   input          rstdiv0,
   input    [2:0] app_af_cmd,
   input   [30:0] app_af_addr,
   input          app_af_wren,
   input          app_wdf_wren,
   input  [143:0] app_wdf_data,
   input  [17:0] app_wdf_mask_data,
   output         app_af_afull,
   output         app_wdf_afull,
   output         rd_data_valid,
   output [143:0] rd_data_fifo_out,
   output         phy_init_done,
   output   [2:0] ddr2_ck,
   output   [2:0] ddr2_ck_n,
   output  [15:0] ddr2_a,
   output   [2:0] ddr2_ba,
   output         ddr2_ras_n,
   output         ddr2_cas_n,
   output         ddr2_we_n,
   output   [1:0] ddr2_cs_n,
   output   [1:0] ddr2_cke,
   output   [1:0] ddr2_odt,
   output   [8:0] ddr2_dm,
   inout    [8:0] ddr2_dqs,
   inout    [8:0] ddr2_dqs_n,
   inout   [71:0] ddr2_dq
   );

   wire [3:0]                             dbg_calib_done_nc;
   wire [3:0]                             dbg_calib_err_nc;
   wire [(6*DQ_WIDTH)-1:0]                dbg_calib_dq_tap_cnt_nc;
   wire [(6*DQS_WIDTH)-1:0]               dbg_calib_dqs_tap_cnt_nc;
   wire [(6*DQS_WIDTH)-1:0]               dbg_calib_gate_tap_cnt_nc;
   wire [DQS_WIDTH-1:0]                   dbg_calib_rd_data_sel_nc;
   wire [(5*DQS_WIDTH)-1:0]               dbg_calib_rden_dly_nc;
   wire [(5*DQS_WIDTH)-1:0]               dbg_calib_gate_dly_nc;

   wire [APPDATA_WIDTH-1:0] rd_data_fifo_out_int;
 
 // 72 bit case
 //  assign rd_data_fifo_out = rd_data_fifo_out_int
 // 64 bit case
 assign rd_data_fifo_out = {16'b0, rd_data_fifo_out_int};


  // memory initialization/control logic
  mem_if_top #
    (
     .BANK_WIDTH     (BANK_WIDTH),
     .CKE_WIDTH      (CKE_WIDTH),
     .CLK_WIDTH      (CLK_WIDTH),
     .COL_WIDTH      (COL_WIDTH),
     .CS_BITS        (CS_BITS),
     .CS_NUM         (CS_NUM),
     .CS_WIDTH       (CS_WIDTH),
     .DM_WIDTH       (DM_WIDTH),
     .DQ_WIDTH       (DQ_WIDTH),
     .DQ_BITS        (DQ_BITS),
     .DQ_PER_DQS     (DQ_PER_DQS),
     .DQS_BITS       (DQS_BITS),
     .DQS_WIDTH      (DQS_WIDTH),
     .ODT_WIDTH      (ODT_WIDTH),
     .ROW_WIDTH      (ROW_WIDTH),
     .APPDATA_WIDTH  (APPDATA_WIDTH),
     .ADDITIVE_LAT   (ADDITIVE_LAT),
     .BURST_LEN      (BURST_LEN),
     .BURST_TYPE     (BURST_TYPE),
     .CAS_LAT        (CAS_LAT),
     .ECC_ENABLE     (ECC_ENABLE),
     .MULTI_BANK_EN  (MULTI_BANK_EN),
     .TWO_T_TIME_EN  (TWO_T_TIME_EN),
     .ODT_TYPE       (ODT_TYPE),
     .DDR_TYPE       (1),
     .REDUCE_DRV     (REDUCE_DRV),
     .REG_ENABLE     (REG_ENABLE),
     .TREFI_NS       (TREFI_NS),
     .TRAS           (TRAS),
     .TRCD           (TRCD),
     .TRFC           (TRFC),
     .TRP            (TRP),
     .TRTP           (TRTP),
     .TWR            (TWR),
     .TWTR           (TWTR),
     .CLK_PERIOD     (CLK_PERIOD),
     .SIM_ONLY       (SIM_ONLY),
     .DEBUG_EN       (DEBUG_EN),
     .DQS_IO_COL     (DQS_IO_COL),
     .DQ_IO_MS       (DQ_IO_MS)
     )
    mem_if_top_inst
      (
       .clk0                   (clk0),
       .clk90                  (clk90),
       .clkdiv0                (clkdiv0),
       .rst0                   (rst0),
       .rst90                  (rst90),
       .rstdiv0                (rstdiv0),
       .app_af_cmd             (app_af_cmd),
       .app_af_addr            (app_af_addr),
       .app_af_wren            (app_af_wren),
       .app_wdf_wren           (app_wdf_wren),
       .app_wdf_data           (app_wdf_data[(APPDATA_WIDTH)-1:0]),
       .app_wdf_mask_data      (app_wdf_mask_data[(APPDATA_WIDTH/8)-1:0]),
       .app_af_afull           (app_af_afull),
       .app_wdf_afull          (app_wdf_afull),
       .rd_data_valid          (rd_data_valid),
       .rd_data_fifo_out       (rd_data_fifo_out_int),
       .rd_ecc_error           (rd_ecc_error),
       .phy_init_done          (phy_init_done),
       .ddr_ck                 (ddr2_ck[CLK_WIDTH-1:0]),
       .ddr_ck_n               (ddr2_ck_n[CLK_WIDTH-1:0]),
       .ddr_addr               (ddr2_a[ROW_WIDTH-1:0]),
       .ddr_ba                 (ddr2_ba[BANK_WIDTH-1:0]),
       .ddr_ras_n              (ddr2_ras_n),
       .ddr_cas_n              (ddr2_cas_n),
       .ddr_we_n               (ddr2_we_n),
       .ddr_cs_n               (ddr2_cs_n),
       .ddr_cke                (ddr2_cke[CKE_WIDTH-1:0]),
       .ddr_odt                (ddr2_odt[ODT_WIDTH-1:0]),
       .ddr_dm                 (ddr2_dm[DM_WIDTH-1:0]),
       .ddr_dqs                (ddr2_dqs[DQS_WIDTH-1:0]),
       .ddr_dqs_n              (ddr2_dqs_n[DQS_WIDTH-1:0]),
       .ddr_dq                 (ddr2_dq[DQ_WIDTH-1:0]),
       .dbg_idel_up_all        (1'b0),
       .dbg_idel_down_all      (1'b0),
       .dbg_idel_up_dq         (1'b0),
       .dbg_idel_down_dq       (1'b0),
       .dbg_idel_up_dqs        (1'b0),
       .dbg_idel_down_dqs      (1'b0),
       .dbg_idel_up_gate       (1'b0),
       .dbg_idel_down_gate     (1'b0),
       .dbg_sel_idel_dq        ({DQ_BITS{1'b0}}),
       .dbg_sel_all_idel_dq    (1'b0),
       .dbg_sel_idel_dqs       ({DQS_BITS+1{1'b0}}),
       .dbg_sel_all_idel_dqs   (1'b0),
       .dbg_sel_idel_gate      ({DQS_BITS+1{1'b0}}),
       .dbg_sel_all_idel_gate  (1'b0),
       .dbg_calib_done         (dbg_calib_done_nc),
       .dbg_calib_err          (dbg_calib_err_nc),
       .dbg_calib_dq_tap_cnt   (dbg_calib_dq_tap_cnt_nc),
       .dbg_calib_dqs_tap_cnt  (dbg_calib_dqs_tap_cnt_nc),
       .dbg_calib_gate_tap_cnt (dbg_calib_gate_tap_cnt_nc),
       .dbg_calib_rd_data_sel  (dbg_calib_rd_data_sel_nc),
       .dbg_calib_rden_dly     (dbg_calib_rden_dly_nc),
       .dbg_calib_gate_dly     (dbg_calib_gate_dly_nc)
       );

endmodule
