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
//  /   /         Filename           : qdrii_top_wrdata_fifo.v
// /___/   /\     Timestamp          : 15 May 2006
// \   \  /  \    Date Last Modified : $Date: 2008/02/06 16:24:58 $
//  \___\/\___\
//
//Device: Virtex-5
//Design: QDRII
//
//Purpose:
//    This module
//       1. Responsible for storing the Write/Read requests made by the user
//          design. Instantiates the FIFOs for Write/Read data storage.
//
//Revision History:
//
///////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module qdrii_top_wrdata_fifo #
  (
   // Following parameters are for 72-bit design (for ML561 Reference board
   // design). Actual values may be different. Actual parameters values are
   // passed from design top module qdrii_sram module. Please refer to the
   // qdrii_sram module for actual values.
   parameter DATA_WIDTH = 72
   )
  (
   input                   clk0,
   input                   clk270,
   input                   user_rst_270,
   input [DATA_WIDTH-1:0]  idata_lsb,
   input [DATA_WIDTH-1:0]  idata_msb,
   input                   rdenb,
   input                   wrenb,
   output [DATA_WIDTH-1:0] odata_lsb,
   output [DATA_WIDTH-1:0] odata_msb
   );

   wire [71:0] fifo_data_lsb_input;
   wire [71:0] fifo_data_msb_input;
   wire [71:0] fifo_data_lsb_output;
   wire [71:0] fifo_data_msb_output;

   assign fifo_data_lsb_input =(DATA_WIDTH == 72) ?
                                idata_lsb : {{72-DATA_WIDTH{1'b0}},idata_lsb};
   assign fifo_data_msb_input =(DATA_WIDTH == 72) ?
                                idata_msb : {{72-DATA_WIDTH{1'b0}},idata_msb};

   assign odata_lsb = fifo_data_lsb_output[DATA_WIDTH-1:0];
   assign odata_msb = fifo_data_msb_output[DATA_WIDTH-1:0];

   // Write Data FIFO - Low Word

   FIFO36_72 #
     (
      .ALMOST_FULL_OFFSET      ( 13'h0080 ),
      .ALMOST_EMPTY_OFFSET     ( 13'h0080 ),
      .FIRST_WORD_FALL_THROUGH ( "FALSE" ),
      .DO_REG                  ( 1 ),
      .EN_SYN                  ( "FALSE" )
      )
     U_FIFO36_72_LSB
       (
        .DI          ( fifo_data_lsb_input[63:0] ),
        .DIP         ( fifo_data_lsb_input[71:64] ),
        .RDCLK       ( clk270 ),
        .RDEN        ( rdenb ),
        .RST         ( user_rst_270 ),
        .WRCLK       ( clk0 ),
        .WREN        ( wrenb ),
        .DBITERR     ( ),
        .ECCPARITY   ( ),
        .SBITERR     ( ),
        .ALMOSTEMPTY ( ),
        .ALMOSTFULL  ( ),
        .DO          ( fifo_data_lsb_output[63:0] ),
        .DOP         ( fifo_data_lsb_output[71:64] ),
        .EMPTY       ( ),
        .FULL        ( ),
        .RDCOUNT     ( ),
        .RDERR       ( ),
        .WRCOUNT     ( ),
        .WRERR       ( )
        );


   // Write Data FIFO - High Word

   FIFO36_72 #
     (
      .ALMOST_FULL_OFFSET      ( 13'h0080 ),
      .ALMOST_EMPTY_OFFSET     ( 13'h0080 ),
      .FIRST_WORD_FALL_THROUGH ( "FALSE" ),
      .DO_REG                  ( 1 ),
      .EN_SYN                  ( "FALSE" )
      )
     U_FIFO36_72_MSB
       (
        .DI          ( fifo_data_msb_input[63:0] ),
        .DIP         ( fifo_data_msb_input[71:64] ),
        .RDCLK       ( clk270 ),
        .RDEN        ( rdenb ),
        .RST         ( user_rst_270 ),
        .WRCLK       ( clk0 ),
        .WREN        ( wrenb ),
        .DBITERR     ( ),
        .ECCPARITY   ( ),
        .SBITERR     ( ),
        .ALMOSTEMPTY ( ),
        .ALMOSTFULL  ( ),
        .DO          ( fifo_data_msb_output[63:0] ),
        .DOP         ( fifo_data_msb_output[71:64] ),
        .EMPTY       ( ),
        .FULL        ( ),
        .RDCOUNT     ( ),
        .RDERR       ( ),
        .WRCOUNT     ( ),
        .WRERR       ( )
        );

endmodule