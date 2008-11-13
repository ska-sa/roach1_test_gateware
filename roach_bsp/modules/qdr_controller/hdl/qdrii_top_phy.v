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
//  /   /         Filename           : qdrii_top_phy.v
// /___/   /\     Timestamp          : 15 May 2006
// \   \  /  \    Date Last Modified : $Date: 2008/02/13 16:19:30 $
//  \___\/\___\
//
//Device: Virtex-5
//Design: QDRII
//
//Purpose:
//    This module
//       1. serves as the top level phy layer. The phy layer serves as the main
//          interface section between the FPGA and the memory.
//       2. Instantiates all the interface modules to the memory, including the
//          clocks, address, commands, write interface and read data interface.

//Revision History:
//
///////////////////////////////////////////////////////////////////////////////

`timescale 1ps/1ps

(* X_CORE_INFO = "mig_v2_1_qdrii_sram_v5, Coregen 10.1i_ip0" , CORE_GENERATION_INFO = "qdrii_sram_v5,mig_v2_1,{component_name=qdrii_top_phy, addr_width = 19, burst_length = 4, bw_width = 2, clk_freq = 250, clk_width = 1, cq_width = 1, data_width = 18, memory_width = 18, rst_act_low = 1}" *)
module qdrii_top_phy #
  (
   // Following parameters are for 72-bit design (for ML561 Reference board
   // design). Actual values may be different. Actual parameters values are
   // passed from design top module qdrii_sram module. Please refer to the
   // qdrii_sram module for actual values.
   parameter ADDR_WIDTH   = 19,
   parameter BURST_LENGTH = 4,
   parameter BW_WIDTH     = 8,
   parameter CLK_WIDTH    = 2,
   parameter CLK_FREQ     = 300,
   parameter CQ_WIDTH     = 2,
   parameter DATA_WIDTH   = 72,
   parameter DEBUG_EN     = 0,
   parameter MEMORY_WIDTH = 36,
   parameter Q_PER_CQ     = 18,
   parameter SIM_ONLY     = 0
   )
  (
   input                   clk0,
   input                   clk180,
   input                   clk270,
   input                   user_rst_0,
   input                   user_rst_180,
   input                   user_rst_270,
   input                   wr_init_n,
   input                   rd_init_n,
   input [ADDR_WIDTH-1:0]  fifo_ad_wr,
   input [BW_WIDTH-1:0]    fifo_bw_h,
   input [BW_WIDTH-1:0]    fifo_bw_l,
   input [DATA_WIDTH-1:0]  fifo_dwl,
   input [DATA_WIDTH-1:0]  fifo_dwh,
   input [ADDR_WIDTH-1:0]  fifo_ad_rd,
   input                   idelay_ctrl_rdy,
   output [DATA_WIDTH-1:0] rd_qrl,
   output [DATA_WIDTH-1:0] rd_qrh,
   output                  data_valid,
   output                  cal_done,  //Indicates that the calibration of Input delay tap is done
   output                  wr_init2_n,
   output [CLK_WIDTH-1:0]  qdr_c,
   output [CLK_WIDTH-1:0]  qdr_c_n,
   output                  qdr_dll_off_n,
   output [CLK_WIDTH-1:0]  qdr_k,         //Memory-side Outputs
   output [CLK_WIDTH-1:0]  qdr_k_n,
   output [ADDR_WIDTH-1:0] qdr_sa,
   output [BW_WIDTH-1:0]   qdr_bw_n,
   output                  qdr_w_n,
   output [DATA_WIDTH-1:0] qdr_d,
   output                  qdr_r_n,
   input [DATA_WIDTH-1:0]  qdr_q,
   input [CQ_WIDTH-1:0]    qdr_cq,
   input [CQ_WIDTH-1:0]    qdr_cq_n,
   output [DATA_WIDTH-1:0] dummy_wrl,
   output [DATA_WIDTH-1:0] dummy_wrh,
   output                  dummy_wren,

   // Debug Signals
   input                     dbg_idel_up_all,
   input                     dbg_idel_down_all,
   input                     dbg_idel_up_q_cq,
   input                     dbg_idel_down_q_cq,
   input                     dbg_idel_up_q_cq_n,
   input                     dbg_idel_down_q_cq_n,
   input                     dbg_idel_up_cq,
   input                     dbg_idel_down_cq,
   input                     dbg_idel_up_cq_n,
   input                     dbg_idel_down_cq_n,
   input [CQ_WIDTH-1:0]      dbg_sel_idel_q_cq,
   input                     dbg_sel_all_idel_q_cq,
   input [CQ_WIDTH-1:0]      dbg_sel_idel_q_cq_n,
   input                     dbg_sel_all_idel_q_cq_n,
   input [CQ_WIDTH-1:0]      dbg_sel_idel_cq,
   input                     dbg_sel_all_idel_cq,
   input [CQ_WIDTH-1:0]      dbg_sel_idel_cq_n,
   input                     dbg_sel_all_idel_cq_n,
   output                    dbg_init_count_done,
   output [CQ_WIDTH-1:0]     dbg_q_cq_init_delay_done,
   output [CQ_WIDTH-1:0]     dbg_q_cq_n_init_delay_done,
   output [(6*CQ_WIDTH)-1:0] dbg_q_cq_init_delay_done_tap_count,
   output [(6*CQ_WIDTH)-1:0] dbg_q_cq_n_init_delay_done_tap_count,
   output [CQ_WIDTH-1:0]     dbg_cq_cal_done,
   output [CQ_WIDTH-1:0]     dbg_cq_n_cal_done,
   output [(6*CQ_WIDTH)-1:0] dbg_cq_cal_tap_count,
   output [(6*CQ_WIDTH)-1:0] dbg_cq_n_cal_tap_count,
   output [CQ_WIDTH-1:0]     dbg_we_cal_done_cq,
   output [CQ_WIDTH-1:0]     dbg_we_cal_done_cq_n,
   output [CQ_WIDTH-1:0]     dbg_cq_q_data_valid,
   output [CQ_WIDTH-1:0]     dbg_cq_n_q_data_valid,
   output                    dbg_cal_done
   );


   localparam Q_PER_CQ_9 = Q_PER_CQ/9; // Number of sets of 9 bits in every
                                       // read data bits associated with the
                                       // corresponding read strobe (CQ) bit.

   wire [1:0] dummy_write;
   wire [1:0] dummy_read;
   wire       init_cnt_done;

   assign dbg_init_count_done = init_cnt_done;

   qdrii_phy_addr_io #
      (
       .ADDR_WIDTH   ( ADDR_WIDTH ),
       .BURST_LENGTH ( BURST_LENGTH )
       )
      U_QDRII_PHY_ADDR_IO
        (
         .clk180          ( clk180 ),
         .clk270          ( clk270 ),
         .user_rst_180    ( user_rst_180 ),
         .user_rst_270    ( user_rst_270 ),
         .wr_init_n       ( wr_init_n ),
         .rd_init_n       ( rd_init_n ),
         .fifo_ad_wr      ( fifo_ad_wr ),
         .fifo_ad_rd      ( fifo_ad_rd ),
         .dummy_write     ( dummy_write ),
         .dummy_read      ( dummy_read ),
         .cal_done        ( cal_done ),
         .rd_init_delay_n ( rd_init_delay_n ),
         .qdr_sa          ( qdr_sa )
         );

   qdrii_phy_clk_io #
      (
       .CLK_WIDTH ( CLK_WIDTH )
       )
      U_QDRII_PHY_CLK_IO
        (
         .clk0          ( clk0 ),
         .user_rst_0    ( user_rst_0 ),
         .init_cnt_done ( init_cnt_done ),
         .qdr_c         ( qdr_c ),
         .qdr_c_n       ( qdr_c_n ),
         .qdr_k         ( qdr_k ),
         .qdr_k_n       ( qdr_k_n ),
         .qdr_dll_off_n ( qdr_dll_off_n )
         );

   qdrii_phy_write #
      (
       .BURST_LENGTH ( BURST_LENGTH ),
       .BW_WIDTH     ( BW_WIDTH ),
       .DATA_WIDTH   ( DATA_WIDTH )
       )
      U_QDRII_PHY_WRITE
        (
         .clk0             ( clk0 ),
         .clk180           ( clk180 ),
         .clk270           ( clk270 ),
         .user_rst_0       ( user_rst_0 ),
         .user_rst_180     ( user_rst_180 ),
         .user_rst_270     ( user_rst_270 ),
         .fifo_bw_h        ( fifo_bw_h ),
         .fifo_bw_l        ( fifo_bw_l ),
         .fifo_dwh         ( fifo_dwh ),
         .fifo_dwl         ( fifo_dwl ),
         .dummy_wr         ( dummy_write ),
         .wr_init_n        ( wr_init_n ),
         .wr_init2_n       ( wr_init2_n ),
         .qdr_bw_n         ( qdr_bw_n ),
         .qdr_d            ( qdr_d ),
         .qdr_w_n          ( qdr_w_n ),
         .dummy_wrl        ( dummy_wrl ),
         .dummy_wrh        ( dummy_wrh ),
         .dummy_wren       ( dummy_wren )
         );

   qdrii_phy_read #
      (
       .BURST_LENGTH ( BURST_LENGTH ),
       .DATA_WIDTH   ( DATA_WIDTH ),
       .DEBUG_EN     ( DEBUG_EN ),
       .CQ_WIDTH     ( CQ_WIDTH ),
       .MEMORY_WIDTH ( MEMORY_WIDTH ),
       .Q_PER_CQ     ( Q_PER_CQ ),
       .Q_PER_CQ_9   ( Q_PER_CQ_9 ),
       .SIM_ONLY     ( SIM_ONLY ),
       .CLK_FREQ     ( CLK_FREQ )
       )
      U_QDRII_PHY_READ
        (
         .clk0             ( clk0 ),
         .clk180           ( clk180 ),
         .clk270           ( clk270 ),
         .user_rst_0       ( user_rst_0 ),
         .user_rst_180     ( user_rst_180 ),
         .user_rst_270     ( user_rst_270 ),
         .idly_ctrl_rdy    ( idelay_ctrl_rdy ),
         .rd_init_n        ( rd_init_n ),
         .qdr_q            ( qdr_q ),
         .qdr_cq           ( qdr_cq ),
         .qdr_cq_n         ( qdr_cq_n ),
         .read_data_rise   ( rd_qrh ) ,
         .read_data_fall   ( rd_qrl ),
         .data_valid       ( data_valid ),
         .dummy_write      ( dummy_write ),
         .dummy_read       ( dummy_read ),
         .cal_done         ( cal_done ),
         .init_cnt_done    ( init_cnt_done ),
         .qdr_r_n          ( qdr_r_n ),
         .rd_init_delay_n  ( rd_init_delay_n ),

         // Debug Signals
         .dbg_idel_up_all                      ( dbg_idel_up_all ),
         .dbg_idel_down_all                    ( dbg_idel_down_all ),
         .dbg_idel_up_q_cq                     ( dbg_idel_up_q_cq ),
         .dbg_idel_down_q_cq                   ( dbg_idel_down_q_cq ),
         .dbg_idel_up_q_cq_n                   ( dbg_idel_up_q_cq_n ),
         .dbg_idel_down_q_cq_n                 ( dbg_idel_down_q_cq_n ),
         .dbg_idel_up_cq                       ( dbg_idel_up_cq ),
         .dbg_idel_down_cq                     ( dbg_idel_down_cq ),
         .dbg_idel_up_cq_n                     ( dbg_idel_up_cq_n ),
         .dbg_idel_down_cq_n                   ( dbg_idel_down_cq_n ),
         .dbg_sel_idel_q_cq                    ( dbg_sel_idel_q_cq ),
         .dbg_sel_all_idel_q_cq                ( dbg_sel_all_idel_q_cq ),
         .dbg_sel_idel_q_cq_n                  ( dbg_sel_idel_q_cq_n ),
         .dbg_sel_all_idel_q_cq_n              ( dbg_sel_all_idel_q_cq_n ),
         .dbg_sel_idel_cq                      ( dbg_sel_idel_cq ),
         .dbg_sel_all_idel_cq                  ( dbg_sel_all_idel_cq ),
         .dbg_sel_idel_cq_n                    ( dbg_sel_idel_cq_n ),
         .dbg_sel_all_idel_cq_n                ( dbg_sel_all_idel_cq_n ),
         .dbg_q_cq_init_delay_done             ( dbg_q_cq_init_delay_done ),
         .dbg_q_cq_n_init_delay_done           ( dbg_q_cq_n_init_delay_done ),
         .dbg_q_cq_init_delay_done_tap_count   ( dbg_q_cq_init_delay_done_tap_count ),
         .dbg_q_cq_n_init_delay_done_tap_count ( dbg_q_cq_n_init_delay_done_tap_count ),
         .dbg_cq_cal_done                      ( dbg_cq_cal_done ),
         .dbg_cq_n_cal_done                    ( dbg_cq_n_cal_done ),
         .dbg_cq_cal_tap_count                 ( dbg_cq_cal_tap_count ),
         .dbg_cq_n_cal_tap_count               ( dbg_cq_n_cal_tap_count ),
         .dbg_we_cal_done_cq                   ( dbg_we_cal_done_cq ),
         .dbg_we_cal_done_cq_n                 ( dbg_we_cal_done_cq_n ),
         .dbg_cq_q_data_valid                  ( dbg_cq_q_data_valid ),
         .dbg_cq_n_q_data_valid                ( dbg_cq_n_q_data_valid ),
         .dbg_cal_done                         ( dbg_cal_done)
         );

endmodule