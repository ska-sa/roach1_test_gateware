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
//  /   /         Filename: ml505_ddr2_phy_dm_iob.v
// /___/   /\     Date Last Modified: $Date: 2007/09/21 15:23:30 $
// \   \  /  \    Date Created: Wed Aug 16 2006
//  \___\/\___\
//
//Device: Virtex-5
//Design Name: DDR2
//Purpose:
//   This module places the data mask signals into the IOBs.
//Reference:
//Revision History:
//*****************************************************************************

`timescale 1ns/1ps

module ml505_ddr2_phy_dm_iob
  (
   input  clk90,
   input  dm_ce,
   input  mask_data_rise,
   input  mask_data_fall,
   output ddr_dm
   );

  wire    dm_out;
  wire    dm_ce_r;

  FDPE_1 u_dm_ce
    (
     .D    (dm_ce),
     .PRE  (1'b0),
     .C    (clk90),
     .Q    (dm_ce_r),
     .CE   (1'b1)
     );

  ODDR #
    (
     .SRTYPE("SYNC"),
     .DDR_CLK_EDGE("SAME_EDGE")
     )
    u_oddr_dm
      (
       .Q  (dm_out),
       .C  (clk90),
       .CE (dm_ce_r),
       .D1 (mask_data_rise),
       .D2 (mask_data_fall),
       .R  (1'b0),
       .S  (1'b0)
       );

  OBUF #(
    .IOSTANDARD("SSTL18_I")
  ) u_obuf_dm
    (
     .I (dm_out),
     .O (ddr_dm)
     );

endmodule
