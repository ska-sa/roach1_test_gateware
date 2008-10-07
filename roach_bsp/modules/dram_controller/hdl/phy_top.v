//*****************************************************************************
// DISCLAIMER OF LIABILITY
// 
// This text/file contains proprietary, confidential
// information of Xilinx, Inc., is distributed under license
// from Xilinx, Inc., and may be used, copied and/or
// disclosed only pursuant to the terms of a valid license
// agreement with Xilinx, Inc. Xilinx hereby grants you a 
// license to use this text/file solely for design, simulation, 
// implementation and creation of design files limited 
// to Xilinx devices or technologies. Use with non-Xilinx 
// devices or technologies is expressly prohibited and 
// immediately terminates your license unless covered by
// a separate agreement.
//
// Xilinx is providing this design, code, or information 
// "as-is" solely for use in developing programs and 
// solutions for Xilinx devices, with no obligation on the 
// part of Xilinx to provide support. By providing this design, 
// code, or information as one possible implementation of 
// this feature, application or standard, Xilinx is making no 
// representation that this implementation is free from any 
// claims of infringement. You are responsible for 
// obtaining any rights you may require for your implementation. 
// Xilinx expressly disclaims any warranty whatsoever with 
// respect to the adequacy of the implementation, including 
// but not limited to any warranties or representations that this
// implementation is free from claims of infringement, implied 
// warranties of merchantability or fitness for a particular 
// purpose.
//
// Xilinx products are not intended for use in life support
// appliances, devices, or systems. Use in such applications is
// expressly prohibited.
//
// Any modifications that are made to the Source Code are 
// done at the users sole risk and will be unsupported.
//
// Copyright (c) 2006-2007 Xilinx, Inc. All rights reserved.
//
// This copyright and support notice must be retained as part 
// of this text at all times. 
//*****************************************************************************
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor: Xilinx
// \   \   \/     Version: 2.1
//  \   \         Application: MIG
//  /   /         Filename: phy_top.v
// /___/   /\     Date Last Modified: $Date: 2007/11/28 13:20:56 $
// \   \  /  \    Date Created: Wed Aug 16 2006
//  \___\/\___\
//
//Device: Virtex-5
//Design Name: DDR2
//Purpose:
//   Top-level for memory physical layer (PHY) interface
//Reference:
//Revision History:
//*****************************************************************************

`timescale 1ns/1ps

module phy_top #
  (
   // Following parameters are for 72-bit RDIMM design (for ML561 Reference 
   // board design). Actual values may be different. Actual parameters values 
   // are passed from design top module ddr2_sdram module. Please refer to
   // the ddr2_sdram module for actual values.
   parameter BANK_WIDTH     = 2,
   parameter CLK_WIDTH      = 1,
   parameter CKE_WIDTH      = 1,
   parameter COL_WIDTH      = 10,
   parameter CS_NUM         = 1,
   parameter CS_WIDTH       = 1,
   parameter DM_WIDTH       = 9,
   parameter DQ_WIDTH       = 72,
   parameter DQ_BITS        = 7,
   parameter DQ_PER_DQS     = 8,
   parameter DQS_WIDTH      = 9,
   parameter DQS_BITS       = 4,
   parameter ODT_WIDTH      = 1,
   parameter ROW_WIDTH      = 14,
   parameter ADDITIVE_LAT   = 0,
   parameter TWO_T_TIME_EN  = 0,
   parameter BURST_LEN      = 4,
   parameter BURST_TYPE     = 0,
   parameter CAS_LAT        = 5,
   parameter ECC_ENABLE     = 0,
   parameter ODT_TYPE       = 1,
   parameter DDR_TYPE       = 1,
   parameter REDUCE_DRV     = 0,
   parameter REG_ENABLE     = 1,
   parameter CLK_PERIOD     = 3000,
   parameter SIM_ONLY       = 0,
   parameter DEBUG_EN       = 0,
   parameter DQS_IO_COL     = 0,
   parameter DQ_IO_MS       = 0
   )
  (
   input                                  clk0,
   input                                  clk90,
   input                                  clkdiv0,
   input                                  rst0,
   input                                  rst90,
   input                                  rstdiv0,
   input                                  ctrl_wren,
   input [ROW_WIDTH-1:0]                  ctrl_addr,
   input [BANK_WIDTH-1:0]                 ctrl_ba,
   input                                  ctrl_ras_n,
   input                                  ctrl_cas_n,
   input                                  ctrl_we_n,
   input [CS_NUM-1:0]                     ctrl_cs_n,
   input                                  ctrl_rden,
   input                                  ctrl_ref_flag,
   input [(2*DQ_WIDTH)-1:0]               wdf_data,
   input [(2*DQ_WIDTH/8)-1:0]             wdf_mask_data,
   output                                 wdf_rden,
   output                                 phy_init_done,
   output [DQS_WIDTH-1:0]                 phy_calib_rden,
   output [DQS_WIDTH-1:0]                 phy_calib_rden_sel,
   output [DQ_WIDTH-1:0]                  rd_data_rise,
   output [DQ_WIDTH-1:0]                  rd_data_fall,
   output [CLK_WIDTH-1:0]                 ddr_ck,
   output [CLK_WIDTH-1:0]                 ddr_ck_n,
   output [ROW_WIDTH-1:0]                 ddr_addr,
   output [BANK_WIDTH-1:0]                ddr_ba,
   output                                 ddr_ras_n,
   output                                 ddr_cas_n,
   output                                 ddr_we_n,
   output [CS_WIDTH-1:0]                  ddr_cs_n,
   output [CKE_WIDTH-1:0]                 ddr_cke,
   output [ODT_WIDTH-1:0]                 ddr_odt,
   output [DM_WIDTH-1:0]                  ddr_dm,
   inout [DQS_WIDTH-1:0]                  ddr_dqs,
   inout [DQS_WIDTH-1:0]                  ddr_dqs_n,
   inout [DQ_WIDTH-1:0]                   ddr_dq,
   // Debug signals (optional use)
   input                                  dbg_idel_up_all,
   input                                  dbg_idel_down_all,
   input                                  dbg_idel_up_dq,
   input                                  dbg_idel_down_dq,
   input                                  dbg_idel_up_dqs,
   input                                  dbg_idel_down_dqs,
   input                                  dbg_idel_up_gate,
   input                                  dbg_idel_down_gate,
   input [DQ_BITS-1:0]                    dbg_sel_idel_dq,
   input                                  dbg_sel_all_idel_dq,
   input [DQS_BITS:0]                     dbg_sel_idel_dqs,
   input                                  dbg_sel_all_idel_dqs,
   input [DQS_BITS:0]                     dbg_sel_idel_gate,
   input                                  dbg_sel_all_idel_gate,
   output [3:0]                           dbg_calib_done,
   output [3:0]                           dbg_calib_err,
   output [(6*DQ_WIDTH)-1:0]              dbg_calib_dq_tap_cnt,
   output [(6*DQS_WIDTH)-1:0]             dbg_calib_dqs_tap_cnt,
   output [(6*DQS_WIDTH)-1:0]             dbg_calib_gate_tap_cnt,
   output [DQS_WIDTH-1:0]                 dbg_calib_rd_data_sel,
   output [(5*DQS_WIDTH)-1:0]             dbg_calib_rden_dly,
   output [(5*DQS_WIDTH)-1:0]             dbg_calib_gate_dly
   );

  wire [3:0]               calib_done;
  wire                     calib_ref_done;
  wire                     calib_ref_req;
  wire [3:0]               calib_start;
  wire                     dm_ce;
  wire [1:0]               dq_oe_n;
  wire                     dqs_oe_n;
  wire                     dqs_rst_n;
  wire [(DQ_WIDTH/8)-1:0]  mask_data_fall;
  wire [(DQ_WIDTH/8)-1:0]  mask_data_rise;
  wire                     odt;
  wire [ROW_WIDTH-1:0]     phy_init_addr;
  wire [BANK_WIDTH-1:0]    phy_init_ba;
  wire                     phy_init_cas_n;
  wire [CKE_WIDTH-1:0]     phy_init_cke;
  wire [CS_NUM-1:0]        phy_init_cs_n;
  wire                     phy_init_data_sel;
  wire                     phy_init_ras_n;
  wire                     phy_init_rden;
  wire                     phy_init_we_n;
  wire                     phy_init_wren;
  wire [DQ_WIDTH-1:0]      wr_data_fall;
  wire [DQ_WIDTH-1:0]      wr_data_rise;

  // synthesis attribute X_CORE_INFO of phy_top is "mig_v2_1_ddr2_v5, Coregen 10.1i_ip0";

  // synthesis attribute CORE_GENERATION_INFO of ddr2_sdram is "ddr2_v5,mig_v2_1,{component_name=ddr2_v5, bank_width=3, cke_width=1, clk_width=3, col_width=10, cs_num=1, cs_width=1, dm_width=8, dq_width=64, dq_per_dqs=8, dqs_width=8, odt_width=1, row_width=13, additive_lat=0, burst_len=4, burst_type=0, cas_lat=3, ecc_enable=0, multi_bank_en=1, two_t_time_en=1, odt_type=1, reduce_drv=0, reg_enable=0, trefi_ns=7800, tras=40000, trcd=15000, trfc=127500, trp=15000, trtp=7500, twr=15000, twtr=10000, clk_period=5000, rst_act_low=1}";

  //***************************************************************************

  phy_write #
    (
     .DQ_WIDTH     (DQ_WIDTH),
     .ADDITIVE_LAT (ADDITIVE_LAT),
     .CAS_LAT      (CAS_LAT),
     .ECC_ENABLE   (ECC_ENABLE),
     .ODT_TYPE     (ODT_TYPE),
     .REG_ENABLE   (REG_ENABLE),
     .DDR_TYPE     (DDR_TYPE)
     )
    u_phy_write
      (
       .clk0                    (clk0),
       .clk90                   (clk90),
       .rst90                   (rst90),
       .wdf_data                (wdf_data),
       .wdf_mask_data           (wdf_mask_data),
       .ctrl_wren               (ctrl_wren),
       .phy_init_wren           (phy_init_wren),
       .phy_init_data_sel       (phy_init_data_sel),
       .dm_ce                   (dm_ce),
       .dq_oe_n                 (dq_oe_n),
       .dqs_oe_n                (dqs_oe_n),
       .dqs_rst_n               (dqs_rst_n),
       .wdf_rden                (wdf_rden),
       .odt                     (odt),
       .wr_data_rise            (wr_data_rise),
       .wr_data_fall            (wr_data_fall),
       .mask_data_rise          (mask_data_rise),
       .mask_data_fall          (mask_data_fall)
       );

  phy_io #
    (
     .CLK_WIDTH      (CLK_WIDTH),
     .DM_WIDTH       (DM_WIDTH),
     .DQ_WIDTH       (DQ_WIDTH),
     .DQ_BITS        (DQ_BITS),
     .DQ_PER_DQS     (DQ_PER_DQS),
     .DQS_BITS       (DQS_BITS),
     .DQS_WIDTH      (DQS_WIDTH),
     .ODT_WIDTH      (ODT_WIDTH),
     .ADDITIVE_LAT   (ADDITIVE_LAT),
     .CAS_LAT        (CAS_LAT),
     .REG_ENABLE     (REG_ENABLE),
     .CLK_PERIOD     (CLK_PERIOD),
     .DDR_TYPE       (DDR_TYPE),
     .SIM_ONLY       (SIM_ONLY),
     .DEBUG_EN       (DEBUG_EN),
     .DQS_IO_COL     (DQS_IO_COL),
     .DQ_IO_MS       (DQ_IO_MS)
     )
    u_phy_io
      (
       .clk0                   (clk0),
       .clk90                  (clk90),
       .clkdiv0                (clkdiv0),
       .rst0                   (rst0),
       .rst90                  (rst90),
       .rstdiv0                (rstdiv0),
       .dm_ce                  (dm_ce),
       .dq_oe_n                (dq_oe_n),
       .dqs_oe_n               (dqs_oe_n),
       .dqs_rst_n              (dqs_rst_n),
       .calib_start            (calib_start),
       .ctrl_rden              (ctrl_rden),
       .phy_init_rden          (phy_init_rden),
       .calib_ref_done         (calib_ref_done),
       .calib_done             (calib_done),
       .calib_ref_req          (calib_ref_req),
       .calib_rden             (phy_calib_rden),
       .calib_rden_sel         (phy_calib_rden_sel),
       .wr_data_rise           (wr_data_rise),
       .wr_data_fall           (wr_data_fall),
       .mask_data_rise         (mask_data_rise),
       .mask_data_fall         (mask_data_fall),
       .rd_data_rise           (rd_data_rise),
       .rd_data_fall           (rd_data_fall),
       .ddr_ck                 (ddr_ck),
       .ddr_ck_n               (ddr_ck_n),
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

  phy_ctl_io #
    (
     .BANK_WIDTH    (BANK_WIDTH),
     .CKE_WIDTH     (CKE_WIDTH),
     .COL_WIDTH     (COL_WIDTH),
     .CS_NUM        (CS_NUM),
     .CS_WIDTH      (CS_WIDTH),
     .TWO_T_TIME_EN (TWO_T_TIME_EN),
     .ODT_WIDTH     (ODT_WIDTH),
     .ROW_WIDTH     (ROW_WIDTH),
     .DDR_TYPE      (DDR_TYPE)
     )
    u_phy_ctl_io
      (
       .clk0                    (clk0),
       .clk90                   (clk90),
       .rst0                    (rst0),
       .rst90                   (rst90),
       .ctrl_addr               (ctrl_addr),
       .ctrl_ba                 (ctrl_ba),
       .ctrl_ras_n              (ctrl_ras_n),
       .ctrl_cas_n              (ctrl_cas_n),
       .ctrl_we_n               (ctrl_we_n),
       .ctrl_cs_n               (ctrl_cs_n),
       .phy_init_addr           (phy_init_addr),
       .phy_init_ba             (phy_init_ba),
       .phy_init_ras_n          (phy_init_ras_n),
       .phy_init_cas_n          (phy_init_cas_n),
       .phy_init_we_n           (phy_init_we_n),
       .phy_init_cs_n           (phy_init_cs_n),
       .phy_init_cke            (phy_init_cke),
       .phy_init_data_sel       (phy_init_data_sel),
       .odt                     (odt),
       .ddr_addr                (ddr_addr),
       .ddr_ba                  (ddr_ba),
       .ddr_ras_n               (ddr_ras_n),
       .ddr_cas_n               (ddr_cas_n),
       .ddr_we_n                (ddr_we_n),
       .ddr_cke                 (ddr_cke),
       .ddr_cs_n                (ddr_cs_n),
       .ddr_odt                 (ddr_odt)
       );

  phy_init #
    (
     .BANK_WIDTH   (BANK_WIDTH),
     .CKE_WIDTH    (CKE_WIDTH),
     .COL_WIDTH    (COL_WIDTH),
     .CS_NUM       (CS_NUM),
     .DQ_WIDTH     (DQ_WIDTH),
     .ODT_WIDTH    (ODT_WIDTH),
     .ROW_WIDTH    (ROW_WIDTH),
     .ADDITIVE_LAT (ADDITIVE_LAT),
     .BURST_LEN    (BURST_LEN),
     .BURST_TYPE   (BURST_TYPE),
     .TWO_T_TIME_EN(TWO_T_TIME_EN),
     .CAS_LAT      (CAS_LAT),
     .ODT_TYPE     (ODT_TYPE),
     .REDUCE_DRV   (REDUCE_DRV),
     .REG_ENABLE   (REG_ENABLE),
     .DDR_TYPE     (DDR_TYPE),
     .SIM_ONLY     (SIM_ONLY)
     )
    u_phy_init
      (
       .clk0                    (clk0),
       .clkdiv0                 (clkdiv0),
       .rst0                    (rst0),
       .rstdiv0                 (rstdiv0),
       .calib_done              (calib_done),
       .ctrl_ref_flag           (ctrl_ref_flag),
       .calib_ref_req           (calib_ref_req),
       .calib_start             (calib_start),
       .calib_ref_done          (calib_ref_done),
       .phy_init_wren           (phy_init_wren),
       .phy_init_rden           (phy_init_rden),
       .phy_init_addr           (phy_init_addr),
       .phy_init_ba             (phy_init_ba),
       .phy_init_ras_n          (phy_init_ras_n),
       .phy_init_cas_n          (phy_init_cas_n),
       .phy_init_we_n           (phy_init_we_n),
       .phy_init_cs_n           (phy_init_cs_n),
       .phy_init_cke            (phy_init_cke),
       .phy_init_done           (phy_init_done),
       .phy_init_data_sel       (phy_init_data_sel)
       );

endmodule
