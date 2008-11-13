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
//  /   /         Filename           : qdrii_phy_write.v
// /___/   /\     Timestamp          : 15 May 2006
// \   \  /  \    Date Last Modified : $Date: 2008/02/20 16:41:44 $
//  \___\/\___\
//
//Device: Virtex-5
//Design: QDRII
//
//Purpose:
//    This module
//  1. Is the top level module for write data and commands
//  2. Instantiates the I/O modules for the memory write data, as well as
//     for the write command.
//
//Revision History:
//
////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module qdrii_phy_write #
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
   input                       clk0,
   input                       clk180,
   input                       clk270,
   input                       user_rst_0,
   input                       user_rst_180,
   input                       user_rst_270,
   input [BW_WIDTH-1:0]        fifo_bw_h,
   input [BW_WIDTH-1:0]        fifo_bw_l,
   input [DATA_WIDTH-1:0]      fifo_dwh,
   input [DATA_WIDTH-1:0]      fifo_dwl,
   input [1:0]                 dummy_wr,
   input                       wr_init_n,
   output                      wr_init2_n,
   output [BW_WIDTH-1:0]       qdr_bw_n,
   output [DATA_WIDTH-1:0]     qdr_d,
   output                      qdr_w_n,
   output reg [DATA_WIDTH-1:0] dummy_wrl,
   output reg [DATA_WIDTH-1:0] dummy_wrh,
   output reg                  dummy_wren
   );

   localparam [5:0] IDLE    = 6'b000001,
                    WR_1    = 6'b000010,
                    WR_2    = 6'b000100,
                    WR_3    = 6'b001000,
                    WR_4    = 6'b010000,
                    WR_DONE = 6'b100000;

   localparam [8:0] PATTERN_A = 9'h1FF,
                    PATTERN_B = 9'h000,
                    PATTERN_C = 9'h155,
                    PATTERN_D = 9'h0AA;

   reg                  d_wr_en;
   reg [5:0]            Next_datagen_st;
   reg [BW_WIDTH-1:0]   bwl_int;
   reg [BW_WIDTH-1:0]   bwh_int;
   reg [DATA_WIDTH-1:0] dwl_int;
   reg [DATA_WIDTH-1:0] dwh_int;
   reg [DATA_WIDTH-1:0] dummy_write_l/* synthesis syn_preserve=1 */;
   reg [DATA_WIDTH-1:0] dummy_write_h/* synthesis syn_preserve=1 */;

   wire wr_init_delay_n;
   wire wr_init_delay2_n;
   wire wr_init_delay3_n;
   wire qdr_w_n_int;
   wire wr_cmd_in;
   wire wr_fifo_rden_1;
   wire wr_fifo_rden_2;
   wire wr_init2_n_1;

   // For Calibration purpose, a sequence of pattern datas are written in to
   // Write Data FIFOs.
   // For BL4, a pattern of F-0, F-0, F-0, A-5 are written into Write Data FIFOs.
   // For BL2, a pattern of F-0, F-0, A-5 are written into Write Data FIFOs.
   always @ (posedge clk0)
     begin
        if (user_rst_0) begin
           dummy_write_h   <= {DATA_WIDTH{1'b0}};
           dummy_write_l   <= {DATA_WIDTH{1'b0}};
           d_wr_en         <= 1'b0;
           Next_datagen_st <= IDLE;
        end else begin
           case (Next_datagen_st)
             IDLE : begin
                dummy_write_h   <= {DATA_WIDTH{1'b0}};
                dummy_write_l   <= {DATA_WIDTH{1'b0}};
                d_wr_en         <= 1'b0;
                Next_datagen_st <= WR_1;
             end

             WR_1 : begin
                dummy_write_h   <= {BW_WIDTH{PATTERN_A}};
                dummy_write_l   <= {BW_WIDTH{PATTERN_B}};
                d_wr_en         <= 1'b1;
                if(BURST_LENGTH == 2)
                  Next_datagen_st <= WR_3;
                else if(BURST_LENGTH == 4)
                  Next_datagen_st <= WR_2;
             end

             WR_2 : begin
                dummy_write_h   <= {BW_WIDTH{PATTERN_A}};
                dummy_write_l   <= {BW_WIDTH{PATTERN_B}};
                d_wr_en         <= 1'b0;
                Next_datagen_st <= WR_3;
             end

             WR_3 : begin
                dummy_write_h   <= {BW_WIDTH{PATTERN_A}};
                dummy_write_l   <= {BW_WIDTH{PATTERN_B}};
                d_wr_en         <= 1'b1;
                Next_datagen_st <= WR_4;
             end

             WR_4 : begin
                dummy_write_h   <= {BW_WIDTH{PATTERN_C}};
                dummy_write_l   <= {BW_WIDTH{PATTERN_D}};
                if(BURST_LENGTH == 2)
                  d_wr_en       <= 1'b1;
                else if(BURST_LENGTH == 4)
                  d_wr_en       <= 1'b0;
                Next_datagen_st <= WR_DONE;
             end

             WR_DONE : begin
                dummy_write_h   <= {DATA_WIDTH{1'b0}};
                dummy_write_l   <= {DATA_WIDTH{1'b0}};
                d_wr_en         <= 1'b0;
                Next_datagen_st <= WR_DONE;
             end
           endcase
        end
     end

    always @ (posedge clk0)
     begin
        if(user_rst_0) begin
           dummy_wrl  <= {DATA_WIDTH{1'b0}};
           dummy_wrh  <= {DATA_WIDTH{1'b0}};
           dummy_wren <= 1'b0;
        end else  begin
           dummy_wrl  <= dummy_write_l;
           dummy_wrh  <= dummy_write_h;
           dummy_wren <= d_wr_en;
        end

     end

   // Generate Byte Write Logic
   always @ (posedge clk270)
     begin
        if (user_rst_270) begin
           bwh_int <= 'b0;
           bwl_int <= 'b0;
        end else if(!wr_init2_n_1)begin
           bwh_int <= fifo_bw_h;
           bwl_int <= fifo_bw_l;
        end else begin
           bwh_int <= 'b0;
           bwl_int <= 'b0;
        end
     end

   genvar bw_i;
   generate
      for(bw_i= 0; bw_i < BW_WIDTH ; bw_i = bw_i+1)
        begin:BW_INST
           qdrii_phy_bw_io U_QDRII_PHY_BW_IO
             (
              .clk270   ( clk270 ),
              .bwl      ( bwl_int[bw_i] ),
              .bwh      ( bwh_int[bw_i] ),
              .qdr_bw_n ( qdr_bw_n[bw_i] )
              );
        end
   endgenerate

   assign wr_cmd_in = ~(~wr_init_n || dummy_wr[1] || dummy_wr[0] ) ;

   // Generate Write Burst Logic

   always @(posedge clk270 )
     begin
        if (user_rst_270 ) begin
           dwl_int <= 'b0;
           dwh_int <= 'b0;
        end else if(!wr_init2_n_1) begin
           dwh_int <= fifo_dwh;
           dwl_int <= fifo_dwl;
        end else begin
           dwl_int <= 'b0;
           dwh_int <= 'b0;
        end
     end


   /////////////////////////////////////////////////////////////////////////////
   // QDR D IO instantiations
   /////////////////////////////////////////////////////////////////////////////

   genvar d_i;
   generate
      for(d_i= 0; d_i < DATA_WIDTH ; d_i = d_i+1)
        begin:D_INST
           qdrii_phy_d_io U_QDRII_PHY_D_IO
             (
              .clk270 ( clk270 ),
              .dwl    ( dwl_int[d_i] ),
              .dwh    ( dwh_int[d_i] ),
              .qdr_d  ( qdr_d[d_i] )
              );
        end
   endgenerate


   // Generate write data fifo rden
   FDP wr_fifo_rden_ff1
     (
      .Q   ( wr_fifo_rden_1 ),
      .D   ( wr_cmd_in ),
      .C   ( clk270 ),
      .PRE ( user_rst_270 )
      );

   FDP wr_fifo_rden_ff2
     (
      .Q   ( wr_fifo_rden_2 ),
      .D   ( wr_fifo_rden_1 ),
      .C   ( clk270 ),
      .PRE ( user_rst_270 )
      );

   // A single Write Command is expanded for two clock cycles for BL4, so that
   // two sets of Write Datas can be read from Write Data FIFOs. For BL2 only
   // one set of Write Datas can be read form Write Data FIFOs.
   assign wr_init2_n = (BURST_LENGTH == 4) ? (wr_fifo_rden_1 & wr_fifo_rden_2 ) :
                                              wr_fifo_rden_1;

   FDP wr_init2_n_ff
     (
      .Q   ( wr_init2_n_1 ),
      .D   ( wr_init2_n ),
      .C   ( clk270 ),
      .PRE ( user_rst_270 )
      );

   // Generate QDR_W_n logic
   FDP wr_init_ff1
     (
      .Q   ( wr_init_delay_n ),
      .D   ( wr_cmd_in ),
      .C   ( clk270 ),
      .PRE ( user_rst_270 )
      );

   FDP wr_init_ff2
     (
      .Q   ( wr_init_delay2_n ),
      .D   ( wr_init_delay_n ),
      .C   ( clk180 ),
      .PRE ( user_rst_180 )
      );

   generate
     if(BURST_LENGTH == 4) begin : BL4_INST
       (* IOB = "TRUE" *) FDP wr_init_ff3
         (
          .Q   ( qdr_w_n_int ),
          .D   ( wr_init_delay2_n ),
          .C   ( clk180 ),
          .PRE ( user_rst_180 )
          )/* synthesis syn_useioff = 1 */;
     end
     else begin : BL2_INST
       FDP wr_init_ff3
         (
          .Q   ( wr_init_delay3_n ),
          .D   ( wr_init_delay2_n ),
          .C   ( clk180 ),
          .PRE ( user_rst_180 )
          );

       (* IOB = "TRUE" *) FDP wr_init_ff4
         (
          .Q   ( qdr_w_n_int ),
          .D   ( wr_init_delay3_n ),
          .C   ( clk180 ),
          .PRE ( user_rst_180 )
          )/* synthesis syn_useioff = 1 */;
     end
   endgenerate

   OBUF qdr_w_n_obuf
     (
      .I ( qdr_w_n_int ),
      .O ( qdr_w_n )
      );

endmodule
