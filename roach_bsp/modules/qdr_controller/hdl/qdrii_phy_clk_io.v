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
//  /   /         Filename           : qdrii_phy_clk_io.v
// /___/   /\     Timestamp          : 15 May 2006
// \   \  /  \    Date Last Modified : $Date: 2008/02/06 16:24:58 $
//  \___\/\___\
//
//Device: Virtex-5
//Design: QDRII
//
//Purpose:
//    This module
//  1. Generates the memory C/C# and K/K# clocks and the DLL Disable signal.
//
//Revision History:
//
////////////////////////////////////////////////////////////////////////////////


`timescale 1ns/1ps

module qdrii_phy_clk_io #
  (
   // Following parameters are for 72-bit design (for ML561 Reference board
   // design). Actual values may be different. Actual parameters values are
   // passed from design top module qdrii_sram module. Please refer to the
   // qdrii_sram module for actual values.
   parameter CLK_WIDTH = 2
   )
  (
   input                  clk0,
   input                  user_rst_0,
   input                  init_cnt_done,
   output [CLK_WIDTH-1:0] qdr_c,
   output [CLK_WIDTH-1:0] qdr_c_n,
   output [CLK_WIDTH-1:0] qdr_k,
   output [CLK_WIDTH-1:0] qdr_k_n,
   output                 qdr_dll_off_n
   );

   reg qdr_dll_off_int;

   wire [CLK_WIDTH-1:0] clk_out;
   wire [CLK_WIDTH-1:0] clk_outb;
   wire                 qdr_dll_off_out;

   assign qdr_c   = {CLK_WIDTH{1'b1}};
   assign qdr_c_n = {CLK_WIDTH{1'b1}};

   //QDR_DLL_OFF is asserted high after the 200 us initial count
   always @ (posedge clk0)
     begin
        if (user_rst_0)
          qdr_dll_off_int <= 1'b0;
        else if(init_cnt_done)
          qdr_dll_off_int <= 1'b1;
     end

   (* IOB = "TRUE" *) FDC QDR_DLL_OFF_FF
     (
      .Q   ( qdr_dll_off_out ),
      .D   ( qdr_dll_off_int ),
      .C   ( clk0 ),
      .CLR ( user_rst_0 )
      )/* synthesis syn_useioff = 1 */;

   OBUF obuf_dll_off_n
     (
      .I(qdr_dll_off_out),
      .O(qdr_dll_off_n)
      );

   genvar clk_i;
   generate
      for(clk_i = 0; clk_i < CLK_WIDTH; clk_i = clk_i +1)
        begin : CLK_INST
           ODDR #
             (
              .DDR_CLK_EDGE ( "OPPOSITE_EDGE" )
              )
             ODDR_K_CLK0
               (
                .Q  ( clk_out[clk_i] ),
                .C  ( clk0 ),
                .CE ( 1'b1 ),
                .D1 ( 1'b1 ),
                .D2 ( 1'b0 ),
                .R  ( 1'b0 ),
                .S  ( 1'b0 )
                );

           ODDR #
             (
              .DDR_CLK_EDGE ( "OPPOSITE_EDGE" )
              )
             ODDR_K_CLKB
               (
                .Q  ( clk_outb[clk_i] ),
                .C  ( clk0 ),
                .CE ( 1'b1 ),
                .D1 ( 1'b0 ),
                .D2 ( 1'b1 ),
                .R  ( 1'b0 ),
                .S  ( 1'b0 )
                );

           OBUF OBUF_K_CLK
             (
              .I( clk_out[clk_i] ),
              .O( qdr_k[clk_i] )
              );

           OBUF OBUF_K_CLKB
             (
              .I( clk_outb[clk_i] ),
              .O( qdr_k_n[clk_i] )
              );
        end
   endgenerate

endmodule