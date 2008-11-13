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
//  /   /         Filename           : qdrii_phy_addr_io.v
// /___/   /\     Timestamp          : 15 May 2006
// \   \  /  \    Date Last Modified : $Date: 2008/02/06 16:24:58 $
//  \___\/\___\
//
//Device: Virtex-5
//Design: QDRII
//
//Purpose:
//    This module
//  1. Instantiates the I/O module for generating the addresses to the memory
//
//Revision History:
//
////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module qdrii_phy_addr_io #
  (
   // Following parameters are for 72-bit design (for ML561 Reference board
   // design). Actual values may be different. Actual parameters values are
   // passed from design top module qdrii_sram module. Please refer to the
   // qdrii_sram module for actual values.
   parameter ADDR_WIDTH   = 19,
   parameter BURST_LENGTH = 4
   )
  (
   input                   clk180,
   input                   clk270,
   input                   user_rst_180,
   input                   user_rst_270,
   input                   wr_init_n,
   input                   rd_init_n,
   input [ADDR_WIDTH-1:0]  fifo_ad_wr,
   input [ADDR_WIDTH-1:0]  fifo_ad_rd,
   input [1:0]             dummy_write,
   input [1:0]             dummy_read,
   input                   cal_done,
   input                   rd_init_delay_n,
   output [ADDR_WIDTH-1:0] qdr_sa
   );

   reg [ADDR_WIDTH-1:0] address_int_ff;
   reg [ADDR_WIDTH-1:0] fifo_ad_wr_r;
   reg [ADDR_WIDTH-1:0] fifo_ad_rd_r;
   reg [ADDR_WIDTH-1:0] fifo_ad_wr_2r;
   reg [ADDR_WIDTH-1:0] fifo_ad_rd_2r;
   reg [ADDR_WIDTH-1:0] fifo_ad_wr_3r;
   reg [ADDR_WIDTH-1:0] fifo_ad_rd_3r;
   reg                  wr_init_n_r;
   reg                  rd_init_n_r;
   reg [1:0]            dummy_write_r;
   reg [1:0]            dummy_read_r;

   wire [ADDR_WIDTH-1:0] qdr_sa_int;

   always @ (posedge clk270)
   begin
     fifo_ad_wr_r <= fifo_ad_wr;
     fifo_ad_rd_r <= fifo_ad_rd;
   end

   generate
     // For BL4 address is SDR
     if(BURST_LENGTH == 4) begin : BL4_INST
       always @ (posedge clk270)
         begin
            if (user_rst_270 ||~cal_done )
              address_int_ff <= 'b0;
            else if (rd_init_delay_n)
              address_int_ff <= fifo_ad_wr_r;
            else
              address_int_ff <= fifo_ad_rd_r;
         end
     end else begin : BL2_INST
     // For BL2 address is DDR. A read command by the controller is associated
     // with read address bits and write command by the controller is associated
     // with write address bits on to the IO bus. Absence of any commands is
     // associated with address bits on IO bus tied to logic 0.
       always @ (posedge clk270)
       begin
         if(user_rst_270)begin
           wr_init_n_r <= 'b0;
           rd_init_n_r <= 'b0;
         end else begin
           wr_init_n_r <= wr_init_n;
           rd_init_n_r <= rd_init_n;
         end
       end

       always @ (posedge clk270)
       begin
         dummy_write_r <= dummy_write;
         dummy_read_r  <= dummy_read;
       end

       always @ (posedge clk270)
       begin
         if((BURST_LENGTH == 2) && (dummy_write_r == 2'b11))
           fifo_ad_wr_2r <= {{ADDR_WIDTH-1{1'b0}}, 1'b1};
         else if((BURST_LENGTH == 2) && (dummy_read_r == 2'b10))
           fifo_ad_rd_2r <= {{ADDR_WIDTH-1{1'b0}}, 1'b1};
         else if (!wr_init_n_r | !rd_init_n_r)begin
           fifo_ad_wr_2r <= fifo_ad_wr_r;
           fifo_ad_rd_2r <= fifo_ad_rd_r;
         end else begin
           fifo_ad_wr_2r <= 'b0;
           fifo_ad_rd_2r <= 'b0;
         end
       end

       always @ (posedge clk270)
       begin
         fifo_ad_rd_3r  <= fifo_ad_rd_2r;
         fifo_ad_wr_3r  <= fifo_ad_wr_2r;
       end
     end
   endgenerate

   genvar aw_i;
   generate
      // For BL2 address is DDR. write address is associated with falling edge
      // of K clock. Read address is associated with rising edge of K clock.
      if(BURST_LENGTH == 2) begin : BL2_IOB_INST
        for(aw_i=0; aw_i < ADDR_WIDTH; aw_i=aw_i+1) begin : ADDR_INST
          ODDR #
            (
             .DDR_CLK_EDGE ( "SAME_EDGE" )
             )
            ODDR_QDR_SA
              (
               .Q  (qdr_sa_int[aw_i]),
               .C  (clk270),
               .CE (1'b1),
               .D1 (fifo_ad_rd_3r[aw_i]),
               .D2 (fifo_ad_wr_3r[aw_i]),
               .R  (1'b0),
               .S  (1'b0)
               );
        end
      end else begin : BL4_IOB_INST
        // For BL4 address is SDR. Read or Write address is always associated
        // with rising edge of K clock.
        for(aw_i=0; aw_i < ADDR_WIDTH; aw_i=aw_i+1) begin : ADDR_INST
          (* IOB = "TRUE" *) FDC ADDRESS_FF
              (
               .Q   ( qdr_sa_int[aw_i] ),
               .D   ( address_int_ff[aw_i] ),
               .C   ( clk180 ),
               .CLR ( user_rst_180 )
               )/* synthesis syn_useioff = 1 */;
        end
      end
   endgenerate

   genvar aw_ii;
   generate
      for(aw_ii=0; aw_ii < ADDR_WIDTH; aw_ii=aw_ii+1) begin : OBUF_INST
        // output buffers for SA bus
        OBUF IO_FF
          (
           .I ( qdr_sa_int[aw_ii] ),
           .O ( qdr_sa[aw_ii] )
           );
      end
   endgenerate

endmodule