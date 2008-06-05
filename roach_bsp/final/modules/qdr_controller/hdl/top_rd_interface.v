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
///////////////////////////////////////////////////////////////////////////////
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor             : Xilinx
// \   \   \/     Version            : 2.1
//  \   \         Application        : MIG
//  /   /         Filename           : top_rd_interface.v
// /___/   /\     Timestamp          : 15 May 2006
// \   \  /  \    Date Last Modified : $Date: 2007/11/28 13:20:58 $
//  \___\/\___\
//
//Device: Virtex-5
//Design: QDRII
//
//Purpose:
//    This module
//       1. Responsible for storing the Read requests made by the user design.
//       2. Instantiates the FIFOs for Read address, data, and control storage.
//
//Revision History:
//
///////////////////////////////////////////////////////////////////////////////


`timescale 1ns/1ps

module top_rd_interface #
  (
   // Following parameters are for 72-bit design (for ML561 Reference board
   // design). Actual values may be different. Actual parameters values are
   // passed from design top module qdrii_sram module. Please refer to the
   // qdrii_sram module for actual values.
   parameter ADDR_WIDTH = 19
   )
  (
   input                   clk0,
   input                   user_rst_0,
   input                   user_r_n,
   input [ADDR_WIDTH-1:0]  user_ad_rd,
   input                   rd_init_n,
   output                  user_rd_full,
   output [ADDR_WIDTH-1:0] fifo_ad_rd,
   output                  fifo_rd_empty
     );

   top_rd_addr_interface #
      (
       .ADDR_WIDTH (ADDR_WIDTH)
       )
      RD_ADDR_INTERFACE0
        (
         .clk0          ( clk0 ),
         .user_rst_0    ( user_rst_0 ),
         .user_r_n      ( user_r_n ),
         .user_ad_rd    ( user_ad_rd ),
         .rd_init_n     ( rd_init_n ),
         .usr_rd_full   ( user_rd_full ),
         .fifo_ad_rd    ( fifo_ad_rd ),
         .fifo_rd_empty ( fifo_rd_empty )
         );

endmodule