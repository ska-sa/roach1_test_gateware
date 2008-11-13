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
///////////////////////////////////////////////////////////////////////////////
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor             : Xilinx
// \   \   \/     Version            : 2.2
//  \   \         Application        : MIG
//  /   /         Filename           : qdrii_top_wr_data_interface.v
// /___/   /\     Timestamp          : 15 May 2006
// \   \  /  \    Date Last Modified : $Date: 2008/02/06 16:24:58 $
//  \___\/\___\
//
//Device: Virtex-5
//Design: QDRII
//
//Purpose:
//    This module
//       1. Responsible for storing the Write data written by the user design.
//          Instantiates the FIFOs for storing the write data.
//
//Revision History:
//
///////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module qdrii_top_wr_data_interface #
  (
   // Following parameters are for 72-bit design (for ML561 Reference board
   // design). Actual values may be different. Actual parameters values are
   // passed from design top module qdrii_sram module. Please refer to the
   // qdrii_sram module for actual values.
   parameter BURST_LENGTH = 4,
   parameter BW_WIDTH     = 8,
   parameter DATA_WIDTH   = 72
   )
  (
   input                   clk0,
   input                   clk270,
   input                   user_rst_0,
   input                   user_rst_270,
   input [DATA_WIDTH-1:0]  dummy_wrl,
   input [DATA_WIDTH-1:0]  dummy_wrh,
   input                   dummy_wren,
   input                   user_w_n,
   input [BW_WIDTH-1:0]    user_bw_h,
   input [BW_WIDTH-1:0]    user_bw_l,
   input [DATA_WIDTH-1:0]  user_dwl,
   input [DATA_WIDTH-1:0]  user_dwh,
   input                   wr_init2_n,
   output [DATA_WIDTH-1:0] fifo_dwl,
   output [DATA_WIDTH-1:0] fifo_dwh,
   output [BW_WIDTH-1:0]   fifo_bw_h,
   output [BW_WIDTH-1:0]   fifo_bw_l
   );

   wire                    user_w_n_delay;
   wire                    user_w_n_stretch;
   wire [(2*BW_WIDTH)-1:0] user_fifo_bw_out;
   wire [(2*BW_WIDTH)-1:0] user_fifo_bw_in;
   wire                    wrfifo_wren;
   wire [DATA_WIDTH-1:0]   wrfifo_wrdata_l;
   wire [DATA_WIDTH-1:0]   wrfifo_wrdata_h;

   assign wrfifo_wren =  user_w_n && ~dummy_wren;
   assign wrfifo_wrdata_l =  user_dwl | dummy_wrl ;
   assign wrfifo_wrdata_h =  user_dwh | dummy_wrh ;

   FDP USER_W_N_FF
     (
      .Q   (user_w_n_delay),
      .D   (wrfifo_wren),
      .C   (clk0),
      .PRE (user_rst_0)
      );

   assign user_w_n_stretch = (BURST_LENGTH == 4) ? (wrfifo_wren  & user_w_n_delay) :
                                                    wrfifo_wren;

   qdrii_top_wrdata_fifo #
      (
       .DATA_WIDTH (DATA_WIDTH)
       )
      U_QDRII_TOP_WRDATA_FIFO
        (
         .clk0         ( clk0 ),
         .clk270       ( clk270 ),
         .user_rst_270 ( user_rst_270 ),
         .idata_lsb    ( wrfifo_wrdata_l ),
         .idata_msb    ( wrfifo_wrdata_h ),
         .rdenb        ( ~wr_init2_n ),
         .wrenb        ( ~user_w_n_stretch ),
         .odata_lsb    ( fifo_dwl ),
         .odata_msb    ( fifo_dwh )
         );

   qdrii_top_wrdata_bw_fifo #
      (
       .BW_WIDTH (BW_WIDTH)
       )
      U_QDRII_TOP_WRDATA_BW_FIFO
         (
          .clk0         ( clk0 ),
          .clk270       ( clk270 ),
          .user_rst_270 ( user_rst_270 ),
          .idata        ( user_fifo_bw_in ),
          .rdenb        ( ~wr_init2_n ),
          .wrenb        ( ~user_w_n_stretch ),
          .odata        ( user_fifo_bw_out )
          );

   assign user_fifo_bw_in = {user_bw_h[BW_WIDTH-1:0], user_bw_l[BW_WIDTH-1:0]};
   assign fifo_bw_l       = user_fifo_bw_out[BW_WIDTH-1:0];
   assign fifo_bw_h       = user_fifo_bw_out[(2*BW_WIDTH)-1:BW_WIDTH];

endmodule