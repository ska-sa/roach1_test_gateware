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
//  /   /         Filename           : qdrii_top_ctrl_sm.v
// /___/   /\     Timestamp          : 15 May 2006
// \   \  /  \    Date Last Modified : $Date: 2008/02/06 16:24:58 $
//  \___\/\___\
//
//Device: Virtex-5
//Design: QDRII
//
//Purpose:
//    This module
//       1. Monitors Read / Write queue status from User Interface FIFOs and
//      generates strobe signals to launch Read / Write requests to
//      QDR II device.
//
//Revision History:
//
////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module qdrii_top_ctrl_sm #
  (
   // Following parameters are for 72-bit design (for ML561 Reference board
   // design). Actual values may be different. Actual parameters values are
   // passed from design top module qdrii_sram module. Please refer to the
   // qdrii_sram module for actual values.
   parameter BURST_LENGTH = 4
   )
  (
   input      clk0,
   input      user_rst_0,
   input      wr_empty,
   input      rd_empty,
   input      cal_done,
   output reg wr_init_n,
   output reg rd_init_n
   );

   reg [2:0] Current_State;
   reg [2:0] Next_State;

   localparam [2:0]
                   INIT       = 3'b000,
                   READ       = 3'b001,
                   WRITE      = 3'b010,
                   WRITE_READ = 3'b011,
                   IDLE       = 3'b100;

   always @(posedge clk0)
     begin
        if (user_rst_0)
          Current_State <= INIT;
        else
          Current_State <= Next_State;
     end


     always @ (Current_State or wr_empty or rd_empty or cal_done)
     begin
        wr_init_n = 1;
        rd_init_n = 1;
          case (Current_State)

          INIT: begin
             wr_init_n = 1;
             rd_init_n = 1;
             if (cal_done)
               Next_State = IDLE;
             else
               Next_State = INIT;
          end

          IDLE:   begin
             wr_init_n = 1;
             rd_init_n = 1;
             if ((!wr_empty) & (BURST_LENGTH == 4))
               Next_State = WRITE;
             else if ((!rd_empty) & (BURST_LENGTH == 4))
               Next_State = READ;
             else if (((!wr_empty) | (!rd_empty)) & (BURST_LENGTH == 2))
               Next_State = WRITE_READ;
             else
               Next_State = IDLE;
          end

          WRITE:   begin
             wr_init_n = 0;  // Initiate a write cycle
             rd_init_n = 1;
             if (!rd_empty)
               Next_State = READ;
             else
               Next_State = IDLE;
          end

          READ:   begin
             rd_init_n  = 0;  // Initiate a read cycle
             wr_init_n  = 1;
             if (!wr_empty)
               Next_State = WRITE;
             else
               Next_State = IDLE;
          end

          // BL2 design Write-Read state. For BL2 Write and Read command can be
          // issued in the same clock(K-Clock).
          WRITE_READ : begin
            if(!wr_empty)
              wr_init_n = 0;
            if(!rd_empty)
              rd_init_n = 0;
            if(wr_empty & rd_empty)
              Next_State = IDLE;
            else
              Next_State = WRITE_READ;
          end

          default:   begin
             wr_init_n  = 1;
             rd_init_n  = 1;
             Next_State = IDLE;
          end
        endcase
     end

endmodule