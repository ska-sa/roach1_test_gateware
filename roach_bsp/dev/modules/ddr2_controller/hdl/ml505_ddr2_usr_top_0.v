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
//  /   /         Filename: ml505_ddr2_usr_top_0.v
// /___/   /\     Date Last Modified: $Date: 2007/09/21 15:23:30 $
// \   \  /  \    Date Created: Mon Aug 28 2006
//  \___\/\___\
//
//Device: Virtex-5
//Design Name: DDR2
//Purpose:
//   This module interfaces with the user. The user should provide the data
//   and  various commands.
//Reference:
//Revision History:
//*****************************************************************************

`timescale 1ns/1ps

module ml505_ddr2_usr_top_0 #
  (
   parameter BANK_WIDTH     = 2,
   parameter CS_BITS        = 0,
   parameter COL_WIDTH      = 10,
   parameter DQ_WIDTH       = 64,
   parameter DQ_PER_DQS     = 8,
   parameter APPDATA_WIDTH  = 128,
   parameter ECC_ENABLE     = 0,
   parameter DQS_WIDTH      = 8,
   parameter ROW_WIDTH      = 13
   )
  (
   input                                     clk0,
   input                                     clk90,
   input                                     rst0,
   input [DQ_WIDTH-1:0]                      rd_data_in_rise,
   input [DQ_WIDTH-1:0]                      rd_data_in_fall,
   input [DQS_WIDTH-1:0]                     phy_calib_rden,
   input [DQS_WIDTH-1:0]                     phy_calib_rden_sel,
   output                                    rd_data_valid,
   output [APPDATA_WIDTH-1:0]                rd_data_fifo_out,
   input                                     app_clk,
   input [2:0]                               app_af_cmd,
   input [30:0]                              app_af_addr,
   input                                     app_af_wren,
   input                                     ctrl_af_rden,
   output [2:0]                              af_cmd,
   output [30:0]                             af_addr,
   output                                    af_empty,
   output                                    app_af_afull,
   output [1:0]                              rd_ecc_error,
   input                                     app_wdf_wren,
   input [APPDATA_WIDTH-1:0]                 app_wdf_data,
   input [(APPDATA_WIDTH/8)-1:0]             app_wdf_mask_data,
   input                                     wdf_rden,
   output                                    app_wdf_afull,
   output [(2*DQ_WIDTH)-1:0]                 wdf_data,
   output [((2*DQ_WIDTH)/8)-1:0]             wdf_mask_data
   );

  wire [(APPDATA_WIDTH/2)-1:0] i_rd_data_fifo_out_fall;
  wire [(APPDATA_WIDTH/2)-1:0] i_rd_data_fifo_out_rise;

  //***************************************************************************

  assign rd_data_fifo_out = {i_rd_data_fifo_out_fall,
                             i_rd_data_fifo_out_rise};

  // read data de-skew and ECC calculation
   ml505_ddr2_usr_rd_0 #
    (
     .DQ_PER_DQS    (DQ_PER_DQS),
     .ECC_ENABLE    (ECC_ENABLE),
     .APPDATA_WIDTH (APPDATA_WIDTH),
     .DQS_WIDTH     (DQS_WIDTH)
     )
     u_usr_rd_0
      (
       .clk0             (clk0),
       .rst0             (rst0),
       .app_clk          (app_clk),
       .rd_data_in_rise  (rd_data_in_rise),
       .rd_data_in_fall  (rd_data_in_fall),
       .rd_ecc_error     (rd_ecc_error),
       .ctrl_rden        (phy_calib_rden),
       .ctrl_rden_sel    (phy_calib_rden_sel),
       .rd_data_valid    (rd_data_valid),
       .rd_data_out_rise (i_rd_data_fifo_out_rise),
       .rd_data_out_fall (i_rd_data_fifo_out_fall)
       );

  // Command/Addres FIFO
   ml505_ddr2_usr_addr_fifo_0 #
    (
     .BANK_WIDTH (BANK_WIDTH),
     .COL_WIDTH  (COL_WIDTH),
     .CS_BITS    (CS_BITS),
     .ROW_WIDTH  (ROW_WIDTH)
     )
     u_usr_addr_fifo_0
      (
       .clk0         (clk0),
       .rst0         (rst0),
       .app_clk      (app_clk),
       .app_af_cmd   (app_af_cmd),
       .app_af_addr  (app_af_addr),
       .app_af_wren  (app_af_wren),
       .ctrl_af_rden (ctrl_af_rden),
       .af_cmd       (af_cmd),
       .af_addr      (af_addr),
       .af_empty     (af_empty),
       .app_af_afull (app_af_afull)
       );

  ml505_ddr2_usr_wr_0 #
    (
     .BANK_WIDTH    (BANK_WIDTH),
     .COL_WIDTH     (COL_WIDTH),
     .CS_BITS       (CS_BITS),
     .DQ_WIDTH      (DQ_WIDTH),
     .APPDATA_WIDTH (APPDATA_WIDTH),
     .ECC_ENABLE    (ECC_ENABLE),
     .ROW_WIDTH     (ROW_WIDTH)
     )
    u_usr_wr
      (
       .clk0              (clk0),
       .clk90             (clk90),
       .rst0              (rst0),
       .app_wdf_wren      (app_wdf_wren),
       .app_wdf_data      (app_wdf_data),
       .app_wdf_mask_data (app_wdf_mask_data),
       .wdf_rden          (wdf_rden),
       .app_wdf_afull     (app_wdf_afull),
       .wdf_data          (wdf_data),
       .wdf_mask_data     (wdf_mask_data)
       );

endmodule
