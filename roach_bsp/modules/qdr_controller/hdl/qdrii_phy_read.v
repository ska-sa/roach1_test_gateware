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
//  /   /         Filename           : qdrii_phy_read.v
// /___/   /\     Timestamp          : 15 May 2006
// \   \  /  \    Date Last Modified : $Date: 2008/02/06 16:24:58 $
//  \___\/\___\
//
//Device: Virtex-5
//Design: QDRII
//
//Purpose:
//    This module
//  1. Is the top level module for read capture.
//  2. Instantiates the I/O modules for the memory clock and data, the
//     initialization state machine, the delay calibration state machine,
//         the write enable state machine as well as generating the read
//     commands to the memory.
//
//Revision History:
//
////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module qdrii_phy_read #
  (
   // Following parameters are for 72-bit design (for ML561 Reference board
   // design). Actual values may be different. Actual parameters values are
   // passed from design top module qdrii_sram module. Please refer to the
   // qdrii_sram module for actual values.
   parameter BURST_LENGTH  = 4,
   parameter CLK_FREQ      = 300,
   parameter CQ_WIDTH      = 2,
   parameter DATA_WIDTH    = 72,
   parameter DEBUG_EN      = 0,
   parameter MEMORY_WIDTH  = 36,
   parameter Q_PER_CQ      = 18,
   parameter Q_PER_CQ_9    = 2,
   parameter SIM_ONLY      = 0
   )
  (
   input                   clk0,
   input                   clk180,
   input                   clk270,
   input                   user_rst_0,
   input                   user_rst_180,
   input                   user_rst_270,
   input                   idly_ctrl_rdy,
   input                   rd_init_n,
   input  [DATA_WIDTH-1:0] qdr_q,
   input  [CQ_WIDTH-1:0]   qdr_cq,
   /*synthesis syn_keep = 1 */(* S = "TRUE" *)
   input [CQ_WIDTH-1:0]    qdr_cq_n,
   output [DATA_WIDTH-1:0] read_data_rise,
   output [DATA_WIDTH-1:0] read_data_fall,
   output                  data_valid,
   output [1:0]            dummy_write,
   output [1:0]            dummy_read,
   output                  cal_done,
   output                  init_cnt_done,
   output                  qdr_r_n,
   output                  rd_init_delay_n,

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

   localparam STROBE_WIDTH = ((CQ_WIDTH*(MEMORY_WIDTH/36))+CQ_WIDTH);
   // For a 36 bit component design the value is 2*CQ_WIDTH, for 18 bit
   // component designs the value is CQ_WIDTH. For x36 bit component designs,
   // both CQ and CQ# are used in calibration. For x18 bit component designs,
   // only CQ is used in calibration.

   wire                        qdr_r_n_int;
   wire [CQ_WIDTH-1:0]         q_cq_dly_ce;
   wire [CQ_WIDTH-1:0]         q_cq_dly_inc;
   wire [CQ_WIDTH-1:0]         q_cq_dly_rst;
   wire [CQ_WIDTH-1:0]         q_cq_n_dly_ce;
   wire [CQ_WIDTH-1:0]         q_cq_n_dly_inc;
   wire [CQ_WIDTH-1:0]         q_cq_n_dly_rst;
   wire [CQ_WIDTH-1:0]         cq_dly_ce;
   wire [CQ_WIDTH-1:0]         cq_n_dly_ce;
   wire [CQ_WIDTH-1:0]         cq_dly_inc;
   wire [CQ_WIDTH-1:0]         cq_n_dly_inc;
   wire [CQ_WIDTH-1:0]         cq_dly_rst;
   wire [CQ_WIDTH-1:0]         cq_n_dly_rst;
   wire [DATA_WIDTH-1:0]       rd_data_rise;
   wire [DATA_WIDTH-1:0]       rd_data_fall;
   wire [DATA_WIDTH-1:0]       rd_data_rise_out;
   wire [DATA_WIDTH-1:0]       rd_data_fall_out;
   wire                        rd_cmd_in;
   wire                        dly_cal_start;
   wire [CQ_WIDTH-1:0]         dly_cal_done_cq_inst;
   wire [CQ_WIDTH-1:0]         dly_cal_done_cq_n_inst;
   wire                        dly_cal_done;
   wire                        data_valid_out;
   wire [STROBE_WIDTH-1:0]     data_valid_inst;
   wire [CQ_WIDTH-1:0]         data_valid_cq_inst;
   wire [CQ_WIDTH-1:0]         data_valid_cq_n_inst;
   wire [CQ_WIDTH-1:0]         we_cal_done_cq_inst;
   wire [CQ_WIDTH-1:0]         we_cal_done_cq_n_inst;
   wire [CQ_WIDTH-1:0]         qdr_cq_bufio;
   wire [CQ_WIDTH-1:0]         qdr_cq_n_bufio;
   wire                        we_cal_start;
   wire                        we_cal_done;
   wire                        q_init_delay_done;
   wire [CQ_WIDTH-1:0]         q_init_delay_done_cq_inst;
   wire [CQ_WIDTH-1:0]         q_init_delay_done_cq_n_inst;
   wire [(STROBE_WIDTH*4)-1:0] srl_count;
   wire                        rd_init_delay2_n;
   wire                        rd_init_delay3_n;

   (* KEEP = "TRUE" *) wire [CQ_WIDTH-1:0]   unused_qdr_cq_n/*synthesis syn_keep = 1 */;

   wire [CQ_WIDTH-1:0]         dbg_sel_idel_q_cq_i;
   wire [CQ_WIDTH-1:0]         dbg_sel_idel_q_cq_n_i;
   wire [CQ_WIDTH-1:0]         dbg_sel_idel_cq_i;
   wire [CQ_WIDTH-1:0]         dbg_sel_idel_cq_n_i;
   wire                        dbg_idel_up_q_cq_i;
   wire                        dbg_idel_down_q_cq_i;
   wire                        dbg_idel_up_q_cq_n_i;
   wire                        dbg_idel_down_q_cq_n_i;
   wire                        dbg_idel_up_cq_i;
   wire                        dbg_idel_down_cq_i;
   wire                        dbg_idel_up_cq_n_i;
   wire                        dbg_idel_down_cq_n_i;

   /////////////////////////////////////////////////////////////////////////////
   // This logic is added to increment/decrement the tap delay count of CQ, CQ#
   // and the respective Data(Q) bits associated with CQ/CQ# manually. You can
   // increment/decrement the tap delay values for CQ/CQ# and the corresponding
   // Data(Q) bits individually or all-together based on the input selection.
   // You can increment/decrement the tap delay values through VIO (Virtual I/O)
   // module of Chipscope. Refer to the MIG user guide for more information on
   // debug port signals.
   //
   // Note: For QDRII, idelay tap count values are applied on all the Data(Q)
   // bits which are associated with the correspondng CQ/CQ#. You cannot change
   // the tap value for each individual Data(Q) bit.
   /////////////////////////////////////////////////////////////////////////////

   assign dbg_sel_idel_q_cq_i = (dbg_idel_up_all | dbg_idel_down_all |
                                dbg_sel_all_idel_q_cq)? {CQ_WIDTH{1'b1}} :
                                                        dbg_sel_idel_q_cq;

   assign dbg_sel_idel_q_cq_n_i = (dbg_idel_up_all | dbg_idel_down_all |
                                  dbg_sel_all_idel_q_cq_n)? {CQ_WIDTH{1'b1}} :
                                                            dbg_sel_idel_q_cq_n;

   assign dbg_sel_idel_cq_i = (dbg_idel_up_all | dbg_idel_down_all |
                               dbg_sel_all_idel_cq)? {CQ_WIDTH{1'b1}} :
                                                     dbg_sel_idel_cq;

   assign dbg_sel_idel_cq_n_i = (dbg_idel_up_all | dbg_idel_down_all |
                                 dbg_sel_all_idel_cq_n)? {CQ_WIDTH{1'b1}} :
                                                         dbg_sel_idel_cq_n;

   assign dbg_idel_up_q_cq_i     = dbg_idel_up_all | dbg_idel_up_q_cq;
   assign dbg_idel_down_q_cq_i   = dbg_idel_down_all | dbg_idel_down_q_cq;
   assign dbg_idel_up_q_cq_n_i   = dbg_idel_up_all | dbg_idel_up_q_cq_n;
   assign dbg_idel_down_q_cq_n_i = dbg_idel_down_all | dbg_idel_down_q_cq_n;
   assign dbg_idel_up_cq_i       = dbg_idel_up_all | dbg_idel_up_cq;
   assign dbg_idel_down_cq_i     = dbg_idel_down_all | dbg_idel_down_cq;
   assign dbg_idel_up_cq_n_i     = dbg_idel_up_all | dbg_idel_up_cq_n;
   assign dbg_idel_down_cq_n_i   = dbg_idel_down_all | dbg_idel_down_cq_n;



   assign dbg_q_cq_init_delay_done   = q_init_delay_done_cq_inst;
   assign dbg_q_cq_n_init_delay_done = q_init_delay_done_cq_n_inst;

   assign dbg_cq_cal_done   = dly_cal_done_cq_inst;
   assign dbg_cq_n_cal_done = dly_cal_done_cq_n_inst;

   assign dbg_we_cal_done_cq   = we_cal_done_cq_inst;
   assign dbg_we_cal_done_cq_n = we_cal_done_cq_n_inst;

   assign dbg_cq_q_data_valid   = data_valid_cq_inst;
   assign dbg_cq_n_q_data_valid = data_valid_cq_n_inst;

   assign dbg_cal_done = cal_done;

   assign read_data_rise = rd_data_rise_out;
   assign read_data_fall = rd_data_fall_out;

   genvar we_i;
   generate
     if(MEMORY_WIDTH == 36) begin : D_V_36
       for(we_i=0; we_i < CQ_WIDTH; we_i=we_i+1) begin : D_V_SIG
         assign data_valid_inst[((2*we_i)+1):(2*we_i)] = {data_valid_cq_n_inst[we_i],
                                                     data_valid_cq_inst[we_i]};
       end
     end
     else begin : D_V_18_9
       assign data_valid_inst = data_valid_cq_inst;
     end
   endgenerate

   assign data_valid = data_valid_out;

   generate
     if(MEMORY_WIDTH == 36) begin : FLAG_36
       assign dly_cal_done       = ((&dly_cal_done_cq_inst) &
                                    (&dly_cal_done_cq_n_inst));
       assign we_cal_done        = ((&we_cal_done_cq_inst) &
                                    (&we_cal_done_cq_n_inst));
       assign q_init_delay_done  = ((&q_init_delay_done_cq_inst) &
                                    (&q_init_delay_done_cq_n_inst));
     end
     else begin : FLAG_18_9
       assign dly_cal_done       = &dly_cal_done_cq_inst;
       assign we_cal_done        = &we_cal_done_cq_inst;
       assign q_init_delay_done  = &q_init_delay_done_cq_inst;
     end
   endgenerate

   genvar cq_i, cq_n_i;
   generate
     if(MEMORY_WIDTH == 36) begin : CQ_INST_36
       for(cq_i=0; cq_i < CQ_WIDTH; cq_i=cq_i+1) begin : CQ_INST
         qdrii_phy_cq_io U_QDRII_PHY_CQ_IO
           (
            .qdr_cq       ( qdr_cq[cq_i] ),
            .cal_clk      ( clk0 ),
            .cq_dly_ce    ( cq_dly_ce[cq_i] ),
            .cq_dly_inc   ( cq_dly_inc[cq_i] ),
            .cq_dly_rst   ( cq_dly_rst[cq_i] ),
            .qdr_cq_bufio ( qdr_cq_bufio[cq_i] )
            );
       end

       for(cq_n_i=0; cq_n_i < CQ_WIDTH; cq_n_i=cq_n_i+1) begin : CQ_N_INST
         qdrii_phy_cq_io U_QDRII_PHY_CQ_N_IO
           (
            .qdr_cq       ( qdr_cq_n[cq_n_i] ),
            .cal_clk      ( clk0 ),
            .cq_dly_ce    ( cq_n_dly_ce[cq_n_i] ),
            .cq_dly_inc   ( cq_n_dly_inc[cq_n_i] ),
            .cq_dly_rst   ( cq_n_dly_rst[cq_n_i] ),
            .qdr_cq_bufio ( qdr_cq_n_bufio[cq_n_i] )
            );
       end
     end
     else begin : CQ_INST_18_9
       for(cq_i=0; cq_i < CQ_WIDTH; cq_i=cq_i+1) begin : CQ_INST
         qdrii_phy_cq_io U_QDRII_PHY_CQ_IO
           (
            .qdr_cq       ( qdr_cq[cq_i] ),
            .cal_clk      ( clk0 ),
            .cq_dly_ce    ( cq_dly_ce[cq_i] ),
            .cq_dly_inc   ( cq_dly_inc[cq_i] ),
            .cq_dly_rst   ( cq_dly_rst[cq_i] ),
            .qdr_cq_bufio ( qdr_cq_bufio[cq_i] )
            );

         MUXCY UNUSED_CQ_N_INST
           (
            .O  (unused_qdr_cq_n[cq_i]),
            .CI (qdr_cq_n[cq_i]),
            .DI (1'b0),
            .S  (1'b1)
            )/* synthesis syn_noprune = 1 */;
       end
     end
   endgenerate

   /////////////////////////////////////////////////////////////////////////////
   // QDR Q IO instantiations
   /////////////////////////////////////////////////////////////////////////////
   //clocked by CQ_0_P(BYTES 0,2)

   genvar cq_width;
   generate
     if(MEMORY_WIDTH == 36) begin : COMP_36_INST
       for(cq_width=0; cq_width < CQ_WIDTH; cq_width=cq_width+1) begin : Q_INST_CQ
         qdrii_phy_q_io #
           (
            .DATA_WIDTH ( DATA_WIDTH ),
            .CQ_WIDTH   ( CQ_WIDTH ),
            .Q_PER_CQ   ( Q_PER_CQ )
            )
           U_QDRII_PHY_Q_IO_CQ
             (
              .qdr_q      ( qdr_q[(2*cq_width*Q_PER_CQ)+:Q_PER_CQ] ),
              .bufio_clk  ( ~qdr_cq_bufio[cq_width] ),
              .q_dly_ce   ( q_cq_dly_ce[cq_width] ),
              .q_dly_inc  ( q_cq_dly_inc[cq_width] ),
              .q_dly_rst  ( q_cq_dly_rst[cq_width] ),
              .cal_clk    ( clk0 ),
              .qdr_q_rise ( rd_data_rise[(2*cq_width*Q_PER_CQ)+:Q_PER_CQ] ),
              .qdr_q_fall ( rd_data_fall[(2*cq_width*Q_PER_CQ)+:Q_PER_CQ] )
              );

         qdrii_phy_q_io #
           (
            .DATA_WIDTH ( DATA_WIDTH ),
            .CQ_WIDTH   ( CQ_WIDTH ),
            .Q_PER_CQ   ( Q_PER_CQ )
            )
           U_QDRII_PHY_Q_IO_CQ_N
             (
              .qdr_q      ( qdr_q[(((2*cq_width)+1)*Q_PER_CQ)+:Q_PER_CQ] ),
              .bufio_clk  ( qdr_cq_n_bufio[cq_width] ),
              .q_dly_ce   ( q_cq_n_dly_ce[cq_width] ),
              .q_dly_inc  ( q_cq_n_dly_inc[cq_width] ),
              .q_dly_rst  ( q_cq_n_dly_rst[cq_width] ),
              .cal_clk    ( clk0 ),
              .qdr_q_rise ( rd_data_rise[(((2*cq_width)+1)*Q_PER_CQ)+:Q_PER_CQ] ),
              .qdr_q_fall ( rd_data_fall[(((2*cq_width)+1)*Q_PER_CQ)+:Q_PER_CQ] )
              );
       end
     end
     else begin : COMP_18_9_INST
       for(cq_width=0; cq_width < CQ_WIDTH; cq_width=cq_width+1) begin : Q_INST_CQ
         qdrii_phy_q_io #
           (
            .DATA_WIDTH ( DATA_WIDTH ),
            .CQ_WIDTH   ( CQ_WIDTH ),
            .Q_PER_CQ   ( Q_PER_CQ )
            )
           U_QDRII_PHY_Q_IO_CQ
             (
              .qdr_q      ( qdr_q[(cq_width*Q_PER_CQ)+:Q_PER_CQ] ),
              .bufio_clk  ( ~qdr_cq_bufio[cq_width] ),
              .q_dly_ce   ( q_cq_dly_ce[cq_width] ),
              .q_dly_inc  ( q_cq_dly_inc[cq_width] ),
              .q_dly_rst  ( q_cq_dly_rst[cq_width] ),
              .cal_clk    ( clk0 ),
              .qdr_q_rise ( rd_data_rise[(cq_width*Q_PER_CQ)+:Q_PER_CQ] ),
              .qdr_q_fall ( rd_data_fall[(cq_width*Q_PER_CQ)+:Q_PER_CQ] )
              );
       end
     end
   endgenerate

   /////////////////////////////////////////////////////////////////////////////
   // Memory initialization state machine
   /////////////////////////////////////////////////////////////////////////////

   qdrii_phy_init_sm #
     (
      .BURST_LENGTH ( BURST_LENGTH ),
      .SIM_ONLY     ( SIM_ONLY ),
      .CLK_FREQ     ( CLK_FREQ )
      )
     U_QDRII_PHY_INIT_SM
       (
        .clk0              ( clk0 ),
        .user_rst_0        ( user_rst_0 ),
        .dly_cal_done      ( dly_cal_done ),
        .q_init_delay_done ( q_init_delay_done ),
        .en_cal_done       ( we_cal_done ),
        .dly_ready         ( idly_ctrl_rdy ),
        .dly_cal_start     ( dly_cal_start ),
        .we_cal_start      ( we_cal_start ),
        .dummy_write       ( dummy_write ),
        .dummy_read        ( dummy_read ),
        .cal_done          ( cal_done ),
        .init_cnt_done     ( init_cnt_done )
        );

   genvar cqi, cq_ni;
   generate
     if(MEMORY_WIDTH == 36) begin : CAL_INST_36
       for(cqi=0; cqi < CQ_WIDTH; cqi=cqi+1) begin : CAL_INST_CQ
         ///////////////////////////////////////////////////////////////////////
         // Delay calibration module CQ instantiation for 36 bit component
         ///////////////////////////////////////////////////////////////////////
         qdrii_phy_dly_cal_sm #
            (
             .BURST_LENGTH ( BURST_LENGTH ),
             .CLK_FREQ     ( CLK_FREQ ),
             .DATA_WIDTH   ( DATA_WIDTH ),
             .DEBUG_EN     ( DEBUG_EN ),
             .CQ_WIDTH     ( CQ_WIDTH ),
             .Q_PER_CQ     ( Q_PER_CQ ),
             .Q_PER_CQ_9   ( Q_PER_CQ_9 )
             )
           U_QDRII_PHY_DLY_CAL_SM_CQ
            (
             .clk0              ( clk0 ),
             .user_rst_0        ( user_rst_0 ),
             .start_cal         ( dly_cal_start ),
             .rd_en             ( rd_cmd_in ),
             .we_cal_start      ( we_cal_start ),
             .rd_data_rise      ( rd_data_rise[(2*cqi*Q_PER_CQ)+:Q_PER_CQ] ),
             .rd_data_fall      ( rd_data_fall[(2*cqi*Q_PER_CQ)+:Q_PER_CQ] ),
             .q_dly_rst         ( q_cq_dly_rst[cqi] ),
             .q_dly_ce          ( q_cq_dly_ce[cqi] ),
             .q_dly_inc         ( q_cq_dly_inc[cqi] ),
             .cq_dly_rst        ( cq_dly_rst[cqi] ),
             .cq_dly_ce         ( cq_dly_ce[cqi] ),
             .cq_dly_inc        ( cq_dly_inc[cqi] ),
             .dly_cal_done      ( dly_cal_done_cq_inst[cqi] ),
             .q_delay_done      ( q_init_delay_done ),
             .q_init_delay_done ( q_init_delay_done_cq_inst[cqi] ),
             .rdfifo_we         ( data_valid_cq_inst[cqi] ),
             .we_cal_done       ( we_cal_done_cq_inst[cqi] ),
             .srl_count         ( srl_count[(2*cqi*4)+:4] ),

             // Debug Signals
             .dbg_idel_up_q_cq                ( dbg_idel_up_q_cq_i ),
             .dbg_idel_down_q_cq              ( dbg_idel_down_q_cq_i ),
             .dbg_idel_up_cq                  ( dbg_idel_up_cq_i ),
             .dbg_idel_down_cq                ( dbg_idel_down_cq_i ),
             .dbg_sel_idel_q_cq               ( dbg_sel_idel_q_cq_i[cqi] ),
             .dbg_sel_idel_cq                 ( dbg_sel_idel_cq_i[cqi] ),
             .dbg_q_init_delay_done_tap_count ( dbg_q_cq_init_delay_done_tap_count[(cqi*6)+:6] ),
             .dbg_cq_cal_tap_count            ( dbg_cq_cal_tap_count[(cqi*6)+:6] )
             );
       end

       for(cq_ni=0; cq_ni < CQ_WIDTH; cq_ni=cq_ni+1) begin : CAL_INST_CQ_N
         ///////////////////////////////////////////////////////////////////////
         // Delay calibration module CQ# instantiation for 36 bit component
         ///////////////////////////////////////////////////////////////////////
         qdrii_phy_dly_cal_sm #
            (
             .BURST_LENGTH ( BURST_LENGTH ),
             .CLK_FREQ     ( CLK_FREQ ),
             .DATA_WIDTH   ( DATA_WIDTH ),
             .DEBUG_EN     ( DEBUG_EN ),
             .CQ_WIDTH     ( CQ_WIDTH ),
             .Q_PER_CQ     ( Q_PER_CQ ),
             .Q_PER_CQ_9   ( Q_PER_CQ_9 )
             )
           U_QDRII_PHY_DLY_CAL_SM_CQ_N
            (
             .clk0              ( clk0 ),
             .user_rst_0        ( user_rst_0 ),
             .start_cal         ( dly_cal_start ),
             .rd_en             ( rd_cmd_in ),
             .we_cal_start      ( we_cal_start ),
             .rd_data_rise      ( rd_data_rise[(((2*cq_ni)+1)*Q_PER_CQ)+:Q_PER_CQ] ),
             .rd_data_fall      ( rd_data_fall[(((2*cq_ni)+1)*Q_PER_CQ)+:Q_PER_CQ] ),
             .q_dly_rst         ( q_cq_n_dly_rst[cq_ni] ),
             .q_dly_ce          ( q_cq_n_dly_ce[cq_ni] ),
             .q_dly_inc         ( q_cq_n_dly_inc[cq_ni] ),
             .cq_dly_rst        ( cq_n_dly_rst[cq_ni] ),
             .cq_dly_ce         ( cq_n_dly_ce[cq_ni] ),
             .cq_dly_inc        ( cq_n_dly_inc[cq_ni] ),
             .dly_cal_done      ( dly_cal_done_cq_n_inst[cq_ni] ),
             .q_delay_done      ( q_init_delay_done ),
             .q_init_delay_done ( q_init_delay_done_cq_n_inst[cq_ni] ),
             .rdfifo_we         ( data_valid_cq_n_inst[cq_ni] ),
             .we_cal_done       ( we_cal_done_cq_n_inst[cq_ni] ),
             .srl_count         ( srl_count[(((2*cq_ni)+1)*4)+:4] ),

             // Debug Signals
             .dbg_idel_up_q_cq                ( dbg_idel_up_q_cq_n_i ),
             .dbg_idel_down_q_cq              ( dbg_idel_down_q_cq_n_i ),
             .dbg_idel_up_cq                  ( dbg_idel_up_cq_n_i ),
             .dbg_idel_down_cq                ( dbg_idel_down_cq_n_i ),
             .dbg_sel_idel_q_cq               ( dbg_sel_idel_q_cq_n_i[cq_ni] ),
             .dbg_sel_idel_cq                 ( dbg_sel_idel_cq_n_i[cq_ni] ),
             .dbg_q_init_delay_done_tap_count ( dbg_q_cq_n_init_delay_done_tap_count[(cq_ni*6)+:6] ),
             .dbg_cq_cal_tap_count            ( dbg_cq_n_cal_tap_count[(cq_ni*6)+:6] )
             );
       end
     end
     else begin : CAL_INST_18_9
       for(cqi=0; cqi < CQ_WIDTH; cqi=cqi+1) begin : CAL_INST_CQ
         ///////////////////////////////////////////////////////////////////////
         // Delay calibration module CQ instantiation for 18bit & 9bit component
         ///////////////////////////////////////////////////////////////////////
         qdrii_phy_dly_cal_sm #
           (
            .BURST_LENGTH ( BURST_LENGTH ),
            .CLK_FREQ     ( CLK_FREQ ),
            .DATA_WIDTH   ( DATA_WIDTH ),
            .DEBUG_EN     ( DEBUG_EN ),
            .CQ_WIDTH     ( CQ_WIDTH ),
            .Q_PER_CQ     ( Q_PER_CQ ),
            .Q_PER_CQ_9   ( Q_PER_CQ_9 )
            )
           U_QDRII_PHY_DLY_CAL_SM_CQ
            (
             .clk0              ( clk0 ),
             .user_rst_0        ( user_rst_0 ),
             .start_cal         ( dly_cal_start ),
             .rd_en             ( rd_cmd_in ),
             .we_cal_start      ( we_cal_start ),
             .rd_data_rise      ( rd_data_rise[(cqi*Q_PER_CQ)+:Q_PER_CQ] ),
             .rd_data_fall      ( rd_data_fall[(cqi*Q_PER_CQ)+:Q_PER_CQ] ),
             .q_dly_rst         ( q_cq_dly_rst[cqi] ),
             .q_dly_ce          ( q_cq_dly_ce[cqi] ),
             .q_dly_inc         ( q_cq_dly_inc[cqi] ),
             .cq_dly_rst        ( cq_dly_rst[cqi] ),
             .cq_dly_ce         ( cq_dly_ce[cqi] ),
             .cq_dly_inc        ( cq_dly_inc[cqi] ),
             .dly_cal_done      ( dly_cal_done_cq_inst[cqi] ),
             .q_delay_done      ( q_init_delay_done ),
             .q_init_delay_done ( q_init_delay_done_cq_inst[cqi] ),
             .rdfifo_we         ( data_valid_cq_inst[cqi] ),
             .we_cal_done       ( we_cal_done_cq_inst[cqi] ),
             .srl_count         ( srl_count[(cqi*4)+:4] ),

             // Debug Signals
             .dbg_idel_up_q_cq                ( dbg_idel_up_q_cq_i ),
             .dbg_idel_down_q_cq              ( dbg_idel_down_q_cq_i ),
             .dbg_idel_up_cq                  ( dbg_idel_up_cq_i ),
             .dbg_idel_down_cq                ( dbg_idel_down_cq_i ),
             .dbg_sel_idel_q_cq               ( dbg_sel_idel_q_cq_i[cqi] ),
             .dbg_sel_idel_cq                 ( dbg_sel_idel_cq_i[cqi] ),
             .dbg_q_init_delay_done_tap_count ( dbg_q_cq_init_delay_done_tap_count[(cqi*6)+:6] ),
             .dbg_cq_cal_tap_count            ( dbg_cq_cal_tap_count[(cqi*6)+:6] )
             );
       end
     end
   endgenerate

   qdrii_phy_en #
      (
       .CQ_WIDTH     ( CQ_WIDTH ),
       .DATA_WIDTH   ( DATA_WIDTH ),
       .Q_PER_CQ     ( Q_PER_CQ ),
       .STROBE_WIDTH ( STROBE_WIDTH )
       )
      U_QDRII_PHY_EN
        (
         .clk0             ( clk0 ),
         .user_rst_0       ( user_rst_0 ),
         .we_cal_done      ( we_cal_done ),
         .rd_data_rise     ( rd_data_rise ),
         .rd_data_fall     ( rd_data_fall ),
         .we_in            ( data_valid_inst ),
         .srl_count        ( srl_count ),
         .rd_data_rise_out ( rd_data_rise_out ),
         .rd_data_fall_out ( rd_data_fall_out ),
         .data_valid_out   ( data_valid_out )
         );


  //synthesis translate_off
  always@(posedge init_cnt_done)begin
    if(!user_rst_0)
      $display("INITIALIZATION PERIOD OF 200uSec IS COMPLETE at time %t", $time);
  end

  always@(posedge q_init_delay_done)begin
    if(!user_rst_0)
      $display("FIRST STAGE CALIBRATION COMPLETE at time %t", $time);
  end

  always@(posedge dly_cal_done)begin
    if(!user_rst_0)
      $display("SECOND STAGE CALIBRATION COMPLETE at time %t", $time);
  end

  always@(posedge we_cal_done)begin
    if(!user_rst_0)
      $display("READ ENABLE CALIBRATION COMPLETE at time %t", $time);
  end
  //synthesis translate_on


   // Generate QDR_R_n logic

   assign rd_cmd_in = (rd_init_n == 1'b0 || (|dummy_read))? 1'b0 : 1'b1 ;

   FDP RD_INIT_FF1
     (
      .Q   ( rd_init_delay_n ),
      .D   ( rd_cmd_in ),
      .C   ( clk270 ),
      .PRE ( user_rst_270 )
      );

   FDP RD_INIT_FF2
     (
      .Q   ( rd_init_delay2_n ),
      .D   ( rd_init_delay_n ),
      .C   ( clk180 ),
      .PRE ( user_rst_180 )
      );

   generate
     if(BURST_LENGTH == 4) begin : BL4_INST
       (* IOB = "TRUE" *) FDP RD_INIT_FF3
         (
          .Q   ( qdr_r_n_int ),
          .D   ( rd_init_delay2_n ),
          .C   ( clk180 ),
          .PRE ( user_rst_180 )
          )/* synthesis syn_useioff = 1 */;
     end
     else begin : BL2_INST
       FDP RD_INIT_FF3
         (
          .Q   ( rd_init_delay3_n ),
          .D   ( rd_init_delay2_n ),
          .C   ( clk180 ),
          .PRE ( user_rst_180 )
          );

       (* IOB = "TRUE" *) FDP RD_INIT_FF4
         (
          .Q   ( qdr_r_n_int ),
          .D   ( rd_init_delay3_n ),
          .C   ( clk180 ),
          .PRE ( user_rst_180 )
          )/* synthesis syn_useioff = 1 */;
     end
   endgenerate

   OBUF QDR_R_N_OBUF
     (
      .I ( qdr_r_n_int ),
      .O ( qdr_r_n )
      );

endmodule