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
// done at the user’s sole risk and will be unsupported.
//
// Copyright (c) 2006-2007 Xilinx, Inc. All rights reserved.
//
// This copyright and support notice must be retained as part
// of this text at all times.
////////////////////////////////////////////////////////////////////////////////
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor             : Xilinx
// \   \   \/     Version            : 2.2
//  \   \         Application        : MIG
//  /   /         Filename           : qdrii_top_wrdata_bw_fifo.v
// /___/   /\     Timestamp          : 15 May 2006
// \   \  /  \    Date Last Modified : $Date: 2008/02/06 16:24:58 $
//  \___\/\___\
//
//Device: Virtex-5
//Design: QDRII
//
//Purpose:
//    This module
//       1. Responsible for storing the Byte Write requests made by the
//          user design. Instantiates the FIFOs for Byte Write data storage.
//
//Revision History:
//
///////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module qdrii_top_wrdata_bw_fifo #
  (
   // Following parameters are for 72-bit design (for ML561 Reference board
   // design). Actual values may be different. Actual parameters values are
   // passed from design top module qdrii_sram module. Please refer to the
   // qdrii_sram module for actual values.
   parameter BW_WIDTH = 8
   )
  (
   input                     clk0,
   input                     clk270,
   input                     user_rst_270,
   input [(2*BW_WIDTH)-1:0]  idata,
   input                     rdenb,
   input                     wrenb,
   output [(2*BW_WIDTH)-1:0] odata
   );

   wire [35:0] fifo_data_in;
   wire [35:0] fifo_data_out;

   assign fifo_data_in = {{36-(2*BW_WIDTH){1'b0}}, idata[(2*BW_WIDTH)-1:0]};
   assign odata        = fifo_data_out[(2*BW_WIDTH)-1:0];

   FIFO36 #
     (
      .ALMOST_FULL_OFFSET      ( 13'h0080 ),
      .ALMOST_EMPTY_OFFSET     ( 13'h0080 ),
      .DATA_WIDTH              ( 36 ),
      .FIRST_WORD_FALL_THROUGH ( "FALSE" ),
      .DO_REG                  ( 1 ),
      .EN_SYN                  ( "FALSE" )
      )
     U_FIFO36
       (
        .DI          ( fifo_data_in[31:0] ),
        .DIP         ( fifo_data_in[35:32] ),
        .RDCLK       ( clk270 ),
        .RDEN        ( rdenb ),
        .RST         ( user_rst_270 ),
        .WRCLK       ( clk0 ),
        .WREN        ( wrenb ),
        .ALMOSTEMPTY ( ),
        .ALMOSTFULL  ( ),
        .DO          ( fifo_data_out[31:0] ),
        .DOP         ( fifo_data_out[35:32] ),
        .EMPTY       ( ),
        .FULL        ( ),
        .RDCOUNT     ( ),
        .RDERR       ( ),
        .WRCOUNT     ( ),
        .WRERR       ( )
        );

endmodule