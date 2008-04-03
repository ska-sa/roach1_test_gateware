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
//  /   /         Filename: ml505_ddr2_usr_addr_fifo_0.v
// /___/   /\     Date Last Modified: $Date: 2007/09/21 15:23:30 $
// \   \  /  \    Date Created: Mon Aug 28 2006
//  \___\/\___\
//
//Device: Virtex-5
//Design Name: DDR2
//Purpose:
//   This module instantiates the block RAM based FIFO to store the user
//   address and the command information. Also calculates potential bank/row
//   conflicts by comparing the new address with last address issued.
//Reference:
//Revision History:
//*****************************************************************************

`timescale 1ns/1ps

module ml505_ddr2_usr_addr_fifo_0 #
  (
   parameter BANK_WIDTH    = 2,
   parameter COL_WIDTH     = 10,
   parameter CS_BITS       = 0,
   parameter ROW_WIDTH     = 13
   )
  (
   input          clk0,
   input          rst0,
   input [2:0]    app_af_cmd,
   input [30:0]   app_af_addr,
   input          app_af_wren,
   input          ctrl_af_rden,
   output [2:0]   af_cmd,
   output [30:0]  af_addr,
   output         af_empty,
   output         app_af_afull
   );

  wire [35:0]     fifo_data_out;
   reg            rst_r;


  always @(posedge clk0)
     rst_r <= rst0;


  //***************************************************************************

  assign af_cmd      = fifo_data_out[33:31];
  assign af_addr     = fifo_data_out[30:0];

  //***************************************************************************

  FIFO36 #
    (
     .ALMOST_EMPTY_OFFSET     (13'h0007),
     .ALMOST_FULL_OFFSET      (13'h000F),
     .DATA_WIDTH              (36),
     .DO_REG                  (1),
     .EN_SYN                  ("TRUE"),
     .FIRST_WORD_FALL_THROUGH ("FALSE")
     )
    u_af
      (
       .ALMOSTEMPTY (),
       .ALMOSTFULL  (app_af_afull),
       .DO          (fifo_data_out[31:0]),
       .DOP         (fifo_data_out[35:32]),
       .EMPTY       (af_empty),
       .FULL        (),
       .RDCOUNT     (),
       .RDERR       (),
       .WRCOUNT     (),
       .WRERR       (),
       .DI          ({app_af_cmd[0],app_af_addr}),
       .DIP         ({2'b00,app_af_cmd[2:1]}),
       .RDCLK       (clk0),
       .RDEN        (ctrl_af_rden),
       .RST         (rst_r),
       .WRCLK       (clk0),
       .WREN        (app_af_wren)
       );

endmodule
