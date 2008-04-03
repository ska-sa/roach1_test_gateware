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
//  /   /         Filename: ml505_ddr2_mem_if_top_0.v
// /___/   /\     Date Last Modified: $Date: 2007/09/21 15:23:30 $
// \   \  /  \    Date Created: Wed Aug 16 2006
//  \___\/\___\
//
//Device: Virtex-5
//Design Name: DDR/DDR2
//Purpose:
//   Top-level for parameterizable (DDR or DDR2) memory interface
//Reference:
//Revision History:
//*****************************************************************************

`timescale 1ns/1ps

module ml505_ddr2_mem_if_top_0 #
  (
   parameter BANK_WIDTH     = 2,
   parameter CKE_WIDTH      = 1,
   parameter CLK_WIDTH      = 2,
   parameter COL_WIDTH      = 10,
   parameter CS_BITS        = 0,
   parameter CS_NUM         = 1,
   parameter CS_WIDTH       = 1,
   parameter DM_WIDTH       = 8,
   parameter DQ_WIDTH       = 64,
   parameter DQ_BITS        = 6,
   parameter DQ_PER_DQS     = 8,
   parameter DQS_BITS       = 3,
   parameter DQS_WIDTH      = 8,
   parameter ODT_WIDTH      = 1,
   parameter ROW_WIDTH      = 13,
   parameter APPDATA_WIDTH  = 128,
   parameter ADDITIVE_LAT   = 0,
   parameter BURST_LEN      = 4,
   parameter BURST_TYPE     = 0,
   parameter CAS_LAT        = 4,
   parameter ECC_ENABLE     = 0,
   parameter MULTI_BANK_EN  = 1,
   parameter TWO_T_TIME_EN  = 1,
   parameter ODT_TYPE       = 1,
   parameter DDR_TYPE       = 1,
   parameter REDUCE_DRV     = 0,
   parameter REG_ENABLE     = 0,
   parameter TREFI_NS       = 7800,
   parameter TRAS           = 40000,
   parameter TRCD           = 15000,
   parameter TRFC           = 105000,
   parameter TRP            = 15000,
   parameter TRTP           = 7500,
   parameter TWR            = 15000,
   parameter TWTR           = 7500,
   parameter CLK_PERIOD     = 3750,
   parameter SIM_ONLY       = 0,
   parameter DEBUG_EN       = 0,
   parameter DQS_IO_COL     = 0,
   parameter DQ_IO_MS       = 0
   )
  (
   input                                    clk0,
   input                                    clk90,
   input                                    clkdiv0,
   input                                    rst0,
   input                                    rst90,
   input                                    rstdiv0,
   input [2:0]                              app_af_cmd,
   input [30:0]                             app_af_addr,
   input                                    app_af_wren,
   input                                    app_wdf_wren,
   input [APPDATA_WIDTH-1:0]                app_wdf_data,
   input [(APPDATA_WIDTH/8)-1:0]            app_wdf_mask_data,
   output [1:0]                             rd_ecc_error,
   output                                   app_af_afull,
   output                                   app_wdf_afull,
   output                                   rd_data_valid,
   output [APPDATA_WIDTH-1:0]               rd_data_fifo_out,
   output                                   phy_init_done,
   output [CLK_WIDTH-1:0]                   ddr_ck,
   output [CLK_WIDTH-1:0]                   ddr_ck_n,
   output [ROW_WIDTH-1:0]                   ddr_addr,
   output [BANK_WIDTH-1:0]                  ddr_ba,
   output                                   ddr_ras_n,
   output                                   ddr_cas_n,
   output                                   ddr_we_n,
   output [CS_WIDTH-1:0]                    ddr_cs_n,
   output [CKE_WIDTH-1:0]                   ddr_cke,
   output [ODT_WIDTH-1:0]                   ddr_odt,
   output [DM_WIDTH-1:0]                    ddr_dm,
   inout [DQS_WIDTH-1:0]                    ddr_dqs,
   inout [DQS_WIDTH-1:0]                    ddr_dqs_n,
   inout [DQ_WIDTH-1:0]                     ddr_dq,
   // Debug signals (optional use)
   input                                    dbg_idel_up_all,
   input                                    dbg_idel_down_all,
   input                                    dbg_idel_up_dq,
   input                                    dbg_idel_down_dq,
   input                                    dbg_idel_up_dqs,
   input                                    dbg_idel_down_dqs,
   input                                    dbg_idel_up_gate,
   input                                    dbg_idel_down_gate,
   input [DQ_BITS-1:0]                      dbg_sel_idel_dq,
   input                                    dbg_sel_all_idel_dq,
   input [DQS_BITS:0]                       dbg_sel_idel_dqs,
   input                                    dbg_sel_all_idel_dqs,
   input [DQS_BITS:0]                       dbg_sel_idel_gate,
   input                                    dbg_sel_all_idel_gate,
   output [3:0]                             dbg_calib_done,
   output [3:0]                             dbg_calib_err,
   output [(6*DQ_WIDTH)-1:0]                dbg_calib_dq_tap_cnt,
   output [(6*DQS_WIDTH)-1:0]               dbg_calib_dqs_tap_cnt,
   output [(6*DQS_WIDTH)-1:0]               dbg_calib_gate_tap_cnt,
   output [DQS_WIDTH-1:0]                   dbg_calib_rd_data_sel,
   output [(5*DQS_WIDTH)-1:0]               dbg_calib_rden_dly,
   output [(5*DQS_WIDTH)-1:0]               dbg_calib_gate_dly
   );

  wire [30:0]                       af_addr;
  wire [2:0]                        af_cmd;
  wire                              af_empty;
  wire [ROW_WIDTH-1:0]              ctrl_addr;
  wire                              ctrl_af_rden;
  wire [BANK_WIDTH-1:0]             ctrl_ba;
  wire                              ctrl_cas_n;
  wire [CS_NUM-1:0]                 ctrl_cs_n;
  wire                              ctrl_ras_n;
  wire                              ctrl_rden;
  wire                              ctrl_ref_flag;
  wire                              ctrl_we_n;
  wire                              ctrl_wren;
  wire [DQS_WIDTH-1:0]              phy_calib_rden;
  wire [DQS_WIDTH-1:0]              phy_calib_rden_sel;
  wire [DQ_WIDTH-1:0]               rd_data_fall;
  wire [DQ_WIDTH-1:0]               rd_data_rise;
  wire [(2*DQ_WIDTH)-1:0]           wdf_data;
  wire [((2*DQ_WIDTH)/8)-1:0]       wdf_mask_data;
  wire                              wdf_rden;

  //***************************************************************************

  ml505_ddr2_phy_top_0 #
    (
     .BANK_WIDTH     (BANK_WIDTH),
     .CKE_WIDTH      (CKE_WIDTH),
     .CLK_WIDTH      (CLK_WIDTH),
     .COL_WIDTH      (COL_WIDTH),
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
     .TWO_T_TIME_EN  (TWO_T_TIME_EN),
     .ADDITIVE_LAT   (ADDITIVE_LAT),
     .BURST_LEN      (BURST_LEN),
     .BURST_TYPE     (BURST_TYPE),
     .CAS_LAT        (CAS_LAT),
     .ECC_ENABLE     (ECC_ENABLE),
     .ODT_TYPE       (ODT_TYPE),
     .DDR_TYPE       (DDR_TYPE),
     .REDUCE_DRV     (REDUCE_DRV),
     .REG_ENABLE     (REG_ENABLE),
     .CLK_PERIOD     (CLK_PERIOD),
     .SIM_ONLY       (SIM_ONLY),
     .DEBUG_EN       (DEBUG_EN),
     .DQS_IO_COL     (DQS_IO_COL),
     .DQ_IO_MS       (DQ_IO_MS)
     )
    u_phy_top_0
      (
       .clk0                   (clk0),
       .clk90                  (clk90),
       .clkdiv0                (clkdiv0),
       .rst0                   (rst0),
       .rst90                  (rst90),
       .rstdiv0                (rstdiv0),
       .ctrl_wren              (ctrl_wren),
       .ctrl_addr              (ctrl_addr),
       .ctrl_ba                (ctrl_ba),
       .ctrl_ras_n             (ctrl_ras_n),
       .ctrl_cas_n             (ctrl_cas_n),
       .ctrl_we_n              (ctrl_we_n),
       .ctrl_cs_n              (ctrl_cs_n),
       .ctrl_rden              (ctrl_rden),
       .ctrl_ref_flag          (ctrl_ref_flag),
       .wdf_data               (wdf_data),
       .wdf_mask_data          (wdf_mask_data),
       .wdf_rden               (wdf_rden),
       .phy_init_done          (phy_init_done),
       .phy_calib_rden         (phy_calib_rden),
       .phy_calib_rden_sel     (phy_calib_rden_sel),
       .rd_data_rise           (rd_data_rise),
       .rd_data_fall           (rd_data_fall),
       .ddr_ck                 (ddr_ck),
       .ddr_ck_n               (ddr_ck_n),
       .ddr_addr               (ddr_addr),
       .ddr_ba                 (ddr_ba),
       .ddr_ras_n              (ddr_ras_n),
       .ddr_cas_n              (ddr_cas_n),
       .ddr_we_n               (ddr_we_n),
       .ddr_cs_n               (ddr_cs_n),
       .ddr_cke                (ddr_cke),
       .ddr_odt                (ddr_odt),
       .ddr_dm                 (ddr_dm),
       .ddr_dqs                (ddr_dqs),
       .ddr_dqs_n              (ddr_dqs_n),
       .ddr_dq                 (ddr_dq),
       .dbg_idel_up_all        (dbg_idel_up_all),
       .dbg_idel_down_all      (dbg_idel_down_all),
       .dbg_idel_up_dq         (dbg_idel_up_dq),
       .dbg_idel_down_dq       (dbg_idel_down_dq),
       .dbg_idel_up_dqs        (dbg_idel_up_dqs),
       .dbg_idel_down_dqs      (dbg_idel_down_dqs),
       .dbg_idel_up_gate       (dbg_idel_up_gate),
       .dbg_idel_down_gate     (dbg_idel_down_gate),
       .dbg_sel_idel_dq        (dbg_sel_idel_dq),
       .dbg_sel_all_idel_dq    (dbg_sel_all_idel_dq),
       .dbg_sel_idel_dqs       (dbg_sel_idel_dqs),
       .dbg_sel_all_idel_dqs   (dbg_sel_all_idel_dqs),
       .dbg_sel_idel_gate      (dbg_sel_idel_gate),
       .dbg_sel_all_idel_gate  (dbg_sel_all_idel_gate),
       .dbg_calib_done         (dbg_calib_done),
       .dbg_calib_err          (dbg_calib_err),
       .dbg_calib_dq_tap_cnt   (dbg_calib_dq_tap_cnt),
       .dbg_calib_dqs_tap_cnt  (dbg_calib_dqs_tap_cnt),
       .dbg_calib_gate_tap_cnt (dbg_calib_gate_tap_cnt),
       .dbg_calib_rd_data_sel  (dbg_calib_rd_data_sel),
       .dbg_calib_rden_dly     (dbg_calib_rden_dly),
       .dbg_calib_gate_dly     (dbg_calib_gate_dly)
       );

  ml505_ddr2_usr_top_0 #
    (
     .BANK_WIDTH    (BANK_WIDTH),
     .COL_WIDTH     (COL_WIDTH),
     .CS_BITS       (CS_BITS),
     .DQ_WIDTH      (DQ_WIDTH),
     .DQ_PER_DQS    (DQ_PER_DQS),
     .DQS_WIDTH     (DQS_WIDTH),
     .APPDATA_WIDTH (APPDATA_WIDTH),
     .ECC_ENABLE    (ECC_ENABLE),
     .ROW_WIDTH     (ROW_WIDTH)
     )
    u_usr_top_0
      (
       .clk0              (clk0),
       .clk90             (clk90),
       .rst0              (rst0),
       .rd_data_in_rise   (rd_data_rise),
       .rd_data_in_fall   (rd_data_fall),
       .phy_calib_rden    (phy_calib_rden),
       .phy_calib_rden_sel(phy_calib_rden_sel),
       .rd_data_valid     (rd_data_valid),
       .rd_ecc_error      (rd_ecc_error),
       .rd_data_fifo_out  (rd_data_fifo_out),
       .app_af_cmd        (app_af_cmd),
       .app_af_addr       (app_af_addr),
       .app_af_wren       (app_af_wren),
       .ctrl_af_rden      (ctrl_af_rden),
       .af_cmd            (af_cmd),
       .af_addr           (af_addr),
       .af_empty          (af_empty),
       .app_af_afull      (app_af_afull),
       .app_wdf_wren      (app_wdf_wren),
       .app_wdf_data      (app_wdf_data),
       .app_wdf_mask_data (app_wdf_mask_data),
       .wdf_rden          (wdf_rden),
       .app_wdf_afull     (app_wdf_afull),
       .wdf_data          (wdf_data),
       .wdf_mask_data     (wdf_mask_data)
       );


  ml505_ddr2_ctrl_0 #
    (
     .BANK_WIDTH    (BANK_WIDTH),
     .COL_WIDTH     (COL_WIDTH),
     .CS_BITS       (CS_BITS),
     .CS_NUM        (CS_NUM),
     .ROW_WIDTH     (ROW_WIDTH),
     .ADDITIVE_LAT  (ADDITIVE_LAT),
     .BURST_LEN     (BURST_LEN),
     .CAS_LAT       (CAS_LAT),
     .ECC_ENABLE    (ECC_ENABLE),
     .REG_ENABLE    (REG_ENABLE),
     .MULTI_BANK_EN (MULTI_BANK_EN),
     .TWO_T_TIME_EN (TWO_T_TIME_EN),
     .TREFI_NS      (TREFI_NS),
     .TRAS          (TRAS),
     .TRCD          (TRCD),
     .TRFC          (TRFC),
     .TRP           (TRP),
     .TRTP          (TRTP),
     .TWR           (TWR),
     .TWTR          (TWTR),
     .CLK_PERIOD    (CLK_PERIOD),
     .DDR_TYPE      (DDR_TYPE)
     )
    u_ctrl_0
      (
       .clk           (clk0),
       .rst           (rst0),
       .af_cmd        (af_cmd),
       .af_addr       (af_addr),
       .af_empty      (af_empty),
       .phy_init_done (phy_init_done),
       .ctrl_ref_flag (ctrl_ref_flag),
       .ctrl_af_rden  (ctrl_af_rden),
       .ctrl_wren     (ctrl_wren),
       .ctrl_rden     (ctrl_rden),
       .ctrl_addr     (ctrl_addr),
       .ctrl_ba       (ctrl_ba),
       .ctrl_ras_n    (ctrl_ras_n),
       .ctrl_cas_n    (ctrl_cas_n),
       .ctrl_we_n     (ctrl_we_n),
       .ctrl_cs_n     (ctrl_cs_n)
       );

endmodule
