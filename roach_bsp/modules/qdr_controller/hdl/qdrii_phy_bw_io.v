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
//  /   /         Filename           : qdrii_phy_bw_io.v
// /___/   /\     Timestamp          : 15 May 2006
// \   \  /  \    Date Last Modified : $Date: 2008/02/06 16:24:58 $
//  \___\/\___\
//
//Device: Virtex-5
//Design: QDRII
//
//Purpose:
//    This module
//      1. Is the I/O module of the QDR Byte Write control data, using ODDR
//         Flip flops.
//
//Revision History:
//
///////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module qdrii_phy_bw_io
  (
   input clk270,
   input bwl,
   input bwh,
   output qdr_bw_n
   );

   wire qdr_bw_int;

   ODDR #
     (
      .DDR_CLK_EDGE ( "SAME_EDGE" )
      )
     ODDR_QDR_BW
       (
        .Q  ( qdr_bw_int ),
        .C  ( clk270 ),
        .CE ( 1'b1 ),
        .D1 ( bwh ),
        .D2 ( bwl ),
        .R  ( 1'b0 ),
        .S  ( 1'b0 )
        );

   OBUFT QDR_BW_OBUF
     (
      .I ( qdr_bw_int ),
      .O ( qdr_bw_n ),
      .T ( 1'b0 )
      );

endmodule