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
//  /   /         Filename           : qdrii_phy_dly_cal_sm.v
// /___/   /\     Timestamp          : 15 May 2006
// \   \  /  \    Date Last Modified : $Date: 2008/02/06 16:24:58 $
//  \___\/\___\
//
//Device: Virtex-5
//Design: QDRII
//
//Purpose:
//    This module
//       1. Calibrates the IDELAY tap values for the QDR_Q and QDR_CQ inputs
//          to allow direct capture of the read data into the system clock
//          domain.
//
//Revision History:
//
////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module qdrii_phy_dly_cal_sm #
  (
   // Following parameters are for 72-bit design (for ML561 Reference board
   // design). Actual values may be different. Actual parameters values are
   // passed from design top module qdrii_sram module. Please refer to the
   // qdrii_sram module for actual values.
   parameter BURST_LENGTH = 4,
   parameter CLK_FREQ     = 300,
   parameter CQ_WIDTH     = 2,
   parameter DATA_WIDTH   = 72,
   parameter DEBUG_EN     = 0,
   parameter Q_PER_CQ     = 18,
   parameter Q_PER_CQ_9   = 2
   )
  (
   input                clk0,
   input                user_rst_0,
   input                start_cal,
   input [Q_PER_CQ-1:0] rd_data_rise,
   input [Q_PER_CQ-1:0] rd_data_fall,
   input                q_delay_done,
   input                rd_en,
   input                we_cal_start,
   output reg           q_dly_rst,
   output reg           q_dly_ce,
   output reg           q_dly_inc,
   output reg           cq_dly_rst,
   output reg           cq_dly_ce,
   output reg           cq_dly_inc,
   output               dly_cal_done,
   output reg           q_init_delay_done,
   output               rdfifo_we,
   output reg           we_cal_done,
   output [3:0]         srl_count,

   // Debug Signals
   input                dbg_idel_up_q_cq,
   input                dbg_idel_down_q_cq,
   input                dbg_idel_up_cq,
   input                dbg_idel_down_cq,
   input                dbg_sel_idel_q_cq,
   input                dbg_sel_idel_cq,
   output [5:0]         dbg_q_init_delay_done_tap_count,
   output [5:0]         dbg_cq_cal_tap_count
   );

   localparam CLK_PERIOD = 1000000/CLK_FREQ;

   localparam PATTERN_A = 9'h1FF,
              PATTERN_B = 9'h000,
              PATTERN_C = 9'h155,
              PATTERN_D = 9'h0AA;

   localparam [3:0] Q_ERROR_CHECK = 4'b0001,
                    Q_ERROR_1     = 4'b0010,
                    Q_ERROR_2     = 4'b0100,
                    Q_ERROR_ST    = 4'b1000;

   localparam [8:0] IDLE         = 9'b000000001,
                    CQ_TAP_INC   = 9'b000000010,
                    CQ_TAP_RST   = 9'b000000100,
                    Q_TAP_INC    = 9'b000001000,
                    Q_TAP_RST    = 9'b000010000,
                    CQ_Q_TAP_INC = 9'b000100000,
                    CQ_Q_TAP_DEC = 9'b001000000,
                    TAP_WAIT     = 9'b010000000,
                    DEBUG_ST     = 9'b100000000;

   localparam [2:0] COMP_1      = 3'b001,
                    COMP_2      = 3'b010,
                    CAL_DONE_ST = 3'b100;


   reg [Q_PER_CQ-1:0] rd_data_rise_r;
   reg [Q_PER_CQ-1:0] rd_data_fall_r;
   reg [8:0]          next_state;
   reg                cal_begin;
   reg                first_edge_detect;
   reg                first_edge_detect_r;
   reg                second_edge_detect;
   reg                second_edge_detect_r;
   reg                cq_q_detect_done;
   reg                cq_q_detect_done_r;
   reg                cq_q_detect_done_2r;
   reg                dvw_detect_done;
   reg                dvw_detect_done_r;
   reg                insuff_window_detect;
   reg                insuff_window_detect_r;
   reg [2:0]          tap_wait_cnt;
   reg                cq_cal_done;
   reg                end_of_taps;
   reg                tap_wait_en;
   reg                start_cal_r;
   reg                start_cal_2r;
   reg                start_cal_3r;
   reg                start_cal_4r;
   reg                start_cal_5r;
   reg                start_cal_6r;
   reg                q_error;
   reg                q_initdelay_inc_done;
   reg                q_initdelay_inc_done_r;
   reg                cal1_error;
   reg [5:0]          cq_tap_cnt;
   reg [5:0]          q_tap_cnt;
   reg [5:0]          cq_tap_range;
   reg                q_delay_done_r;
   reg                q_delay_done_2r;
   reg                q_delay_done_3r;
   reg                q_delay_done_4r;
   reg                q_delay_done_5r;
   reg                q_delay_done_6r;
   reg [5:0]          cq_tap_range_center;
   reg [5:0]          insuff_window_taps;
   reg                cal1_chk;
   reg [5:0]          cq_final_tap_cnt;
   reg [5:0]          cq_hold_range;
   reg [5:0]          cq_setup_range;
   reg                cq_initdelay_inc_done;
   reg                cq_initdelay_inc_done_r;
   reg                cq_rst_done;
   reg                q_rst_done;
   reg [5:0]          q_tap_inc_range;
   reg [5:0]          q_tap_range;
   reg                q_init_delay_done_r;
   reg                cal2_chk_1;
   reg                cal2_chk_2;
   reg                q_initdelay_inc_done_2r;
   reg                cq_initdelay_inc_done_2r;
   reg                q_init_delay_done_2r;
   reg [3:0]          rden_cnt_clk0;
   reg [1:0]          rd_stb_cnt;
   reg                rd_cmd;
   reg [2:0]          comp_cs;
   reg [3:0]          q_error_state;
   reg [2:0]          we_cal_cnt;
   reg                write_cal_start;
   reg                we_cal_done_r;
   reg                rd_en_i;

   wire [5:0] q_tap_inc_val;
   wire       cq_initdelay_done_p;
   wire       q_inc_delay_done_p;
   wire       rden_srl_clk0;
   wire [5:0] max_window;
   wire [5:0] cq_tap_range_center_w;
   wire       cnt_rst;
   wire       insuff_window_detect_p;
   wire       q_initdelay_done_p;

   assign dbg_q_init_delay_done_tap_count = q_tap_cnt;
   assign dbg_cq_cal_tap_count            = cq_tap_cnt;

   // used for second stage tap centering
   assign max_window = (CLK_PERIOD > 4000)? 6'h14 : 6'h0f;

   assign srl_count[3:0] =  rden_cnt_clk0[3:0];

   always @ (posedge clk0)
     begin
        if (user_rst_0) begin
           rd_data_rise_r <= 'b0;
           rd_data_fall_r <= 'b0;
        end else begin
           rd_data_rise_r <= rd_data_rise;
           rd_data_fall_r <= rd_data_fall;
        end
     end

   always @ (posedge clk0)
     begin
        if (user_rst_0) begin
           cal1_chk <= 1'b0;
        end else if (rd_data_rise_r == {Q_PER_CQ_9{PATTERN_A}} &&
                     rd_data_fall_r == {Q_PER_CQ_9{PATTERN_B}})begin
           cal1_chk <= 1'b1;
        end else begin
           cal1_chk <= 1'b0;
        end
     end

   always @ (posedge clk0)
     begin
        if (user_rst_0) begin
           cal1_error <= 1'b0;
        end else if (q_initdelay_inc_done) begin
           cal1_error <= 1'b0;
        end else if (tap_wait_cnt == 3'b101) begin
           if (cal1_chk)
             cal1_error <= 1'b0;
           else
             cal1_error <= 1'b1;
        end
     end

   always @ (posedge clk0)
     begin
        if (user_rst_0) begin
           cal2_chk_1 <= 1'b0;
        end else if (rd_data_rise_r == {Q_PER_CQ_9{PATTERN_A}} &&
                     rd_data_fall_r == {Q_PER_CQ_9{PATTERN_B}})begin
           cal2_chk_1 <= 1'b1;
        end else begin
           cal2_chk_1 <= 1'b0;
        end
     end

   always @ (posedge clk0)
     begin
        if (user_rst_0) begin
           cal2_chk_2 <= 1'b0;
        end else if (rd_data_rise_r == {Q_PER_CQ_9{PATTERN_C}} &&
                     rd_data_fall_r == {Q_PER_CQ_9{PATTERN_D}})begin
           cal2_chk_2 <= 1'b1;
        end else begin
           cal2_chk_2 <= 1'b0;
        end
     end

   always @ (posedge clk0)
    begin
       if (user_rst_0) begin
          q_error <= 1'b0;
          q_error_state  <= Q_ERROR_CHECK;
       end else begin
          case (q_error_state)
            Q_ERROR_CHECK : begin
               //q_error <= 1'b0;
               if (q_delay_done_6r && tap_wait_cnt == 3'b101) begin
                  if (cal2_chk_1) begin
                     q_error       <= 1'b0;
                     q_error_state <= Q_ERROR_1;
                  end else if (cal2_chk_2) begin
                     q_error       <= 1'b0;
                     q_error_state <= Q_ERROR_2;
                  end else begin
                     q_error       <= 1'b1;
                     q_error_state <= Q_ERROR_ST;
                  end
               end else begin
                  q_error       <= q_error;
                  q_error_state <= Q_ERROR_CHECK;
               end
            end
            Q_ERROR_1 :   begin
               if (cal2_chk_2) begin
                  q_error       <= 1'b0;
                  q_error_state <= Q_ERROR_CHECK;
               end else begin
                  q_error       <= 1'b1;
                  q_error_state <= Q_ERROR_CHECK;
               end
            end

            Q_ERROR_2 : begin
               if (cal2_chk_1) begin
                  q_error       <= 1'b0;
                  q_error_state <= Q_ERROR_CHECK;
               end else begin
                  q_error       <= 1'b1;
                  q_error_state <= Q_ERROR_CHECK;
               end
            end

            Q_ERROR_ST  : begin
               q_error       <= 1'b1;
               q_error_state <= Q_ERROR_CHECK;
            end
          endcase
       end
    end

   assign dly_cal_done = cq_cal_done;

   always @ (posedge clk0)
     begin
        if (user_rst_0) begin
           start_cal_r  <= 1'b0;
           start_cal_2r <= 1'b0;
           start_cal_3r <= 1'b0;
           start_cal_4r <= 1'b0;
           start_cal_5r <= 1'b0;
           start_cal_6r <= 1'b0;
        end else begin
           start_cal_r  <= start_cal;
           start_cal_2r <= start_cal_r;
           start_cal_3r <= start_cal_2r;
           start_cal_4r <= start_cal_3r;
           start_cal_5r <= start_cal_4r;
           start_cal_6r <= start_cal_5r;
        end
     end

   always @ (posedge clk0)
     begin
        if (user_rst_0) begin
           q_delay_done_r  <= 1'b0;
           q_delay_done_2r <= 1'b0;
           q_delay_done_3r <= 1'b0;
           q_delay_done_4r <= 1'b0;
           q_delay_done_5r <= 1'b0;
           q_delay_done_6r <= 1'b0;
        end else begin
           q_delay_done_r  <= q_delay_done;
           q_delay_done_2r <= q_delay_done_r;
           q_delay_done_3r <= q_delay_done_2r;
           q_delay_done_4r <= q_delay_done_3r;
           q_delay_done_5r <= q_delay_done_4r;
           q_delay_done_6r <= q_delay_done_5r;
        end
     end

   always @ (posedge clk0)
     begin
        if (user_rst_0)
          cal_begin <= 1'b0;
        else if (start_cal_5r && ~start_cal_6r)
          cal_begin <= 1'b1;
        else if (q_dly_inc)
          cal_begin <= 1'b0;

     end

   /////////////////////////////////////////////////////////////////////////////
   // 1. CQ-Q calibration
   //
   // This stage is required since cq is delayed by an amount equal to the bufio
   // delay with respect to the data. This might move CQ towards the end of the
   // data window at higher frequencies. This stage of calibration helps to
   // align data within the CQ window. In this stage, a static data pattern of
   // 1s and 0s are written as rise and fall data respectively. This pattern
   // also helps to eliminate any metastability arising due to the phase
   // alignment of the data output from the ISERDES and the FPGA clock.
   // The stages of this calibration are as follows:
   // 1. Increment the cq taps to determine the hold data window.
   // 2. Reset the CQ taps once the end of window is reached or sufficient
   //    window not detected.
   // 3. Increment Q taps to determine the set up window.
   // 4. Reset the q taps.
   // 5. If the hold window detected is greater than the set up window, then no
   //    tap increments needed. If the hold window is less than the setup window,
   //    data taps are incremented so that CQ is in the center of the
   //    data valid window.
   //
   // 2. CQ-Q to FPGA clk calibration
   //
   // This stage helps to determine the relationship between cq/q with respect to
   // the fpga clk.
   // 1. CQ and Q are incremented and the window detected with respect to the
   //    FPGA clk. If there is insufficient window , CQ/Q are both incremented
   //    so that they can be aligned to the next rising edge of the FPGA clk.
   // 2. Once sufficient window is detected, CQ and Q are decremented such that
   //    they are atleast half the clock period away from the FPGA clock in case
   //    of frequencies lower than or equal to 250 MHz and atleast 20 taps away
   //    from the FPGA clock for frequencies higher than 250 MHz.
   /////////////////////////////////////////////////////////////////////////////

   always @ (posedge clk0)
     begin
       if (user_rst_0 || ~start_cal) begin
          cq_dly_inc  <= 0;
          cq_dly_ce   <= 0;
          cq_dly_rst  <= 1;
          q_dly_inc   <= 0;
          q_dly_ce    <= 0;
          q_dly_rst   <= 1;
          tap_wait_en <= 1'b0;
          next_state  <= IDLE;
       end else begin
          case (next_state)
            IDLE : begin
               cq_dly_inc  <= 0;
               cq_dly_ce   <= 0;
               cq_dly_rst  <= 0;
               q_dly_inc   <= 0;
               q_dly_ce    <= 0;
               q_dly_rst   <= 0;
               tap_wait_en <= 1'b0;

               if (cal_begin && ~cq_initdelay_inc_done ) begin
                  next_state <= CQ_TAP_INC;

               end else if (cq_initdelay_inc_done_r && ~cq_rst_done) begin
                  next_state <= CQ_TAP_RST;

               end else if ((cq_rst_done && ~q_initdelay_inc_done) ||
                            (q_rst_done && ~q_init_delay_done)) begin
                  next_state <= Q_TAP_INC;

               end else if (q_initdelay_inc_done_r && ~q_rst_done) begin
                  next_state <= Q_TAP_RST;

               end else if ( q_delay_done_6r && ~cq_q_detect_done ) begin
                  next_state <= CQ_Q_TAP_INC;

               end else if (cq_q_detect_done_2r && ~cq_cal_done)  begin
                  next_state <=  CQ_Q_TAP_DEC;

               end else if(start_cal_6r && DEBUG_EN == 1) begin
                  if(dbg_sel_idel_q_cq) begin
                    q_dly_inc <= dbg_idel_up_q_cq;
                    q_dly_ce  <= dbg_idel_up_q_cq | dbg_idel_down_q_cq;
                  end else
                    q_dly_ce  <= 0;

                  if(dbg_sel_idel_cq) begin
                    cq_dly_inc <= dbg_idel_up_cq;
                    cq_dly_ce  <= dbg_idel_up_cq | dbg_idel_down_cq;
                  end else
                    cq_dly_ce  <= 0;

                  next_state <= DEBUG_ST;

               end else begin
                  next_state <= IDLE;

               end
            end

            CQ_TAP_INC : begin
               cq_dly_inc  <= 1;
               cq_dly_ce   <= 1;
               cq_dly_rst  <= 0;
               q_dly_inc   <= 0;
               q_dly_ce    <= 0;
               q_dly_rst   <= 0;
               tap_wait_en <= 1'b1;
               next_state  <= TAP_WAIT;
            end

            CQ_TAP_RST : begin
               cq_dly_inc  <= 0;
               cq_dly_ce   <= 0;
               cq_dly_rst  <= 1;
               q_dly_inc   <= 0;
               q_dly_ce    <= 0;
               q_dly_rst   <= 0;
               tap_wait_en <= 1'b1;
               next_state  <= TAP_WAIT;
            end

            Q_TAP_INC : begin
               cq_dly_inc  <= 0;
               cq_dly_ce   <= 0;
               cq_dly_rst  <= 0;
               q_dly_inc   <= 1;
               q_dly_ce    <= 1;
               q_dly_rst   <= 0;
               tap_wait_en <= 1'b1;
               next_state  <= TAP_WAIT;
            end

            Q_TAP_RST : begin
               cq_dly_inc  <= 0;
               cq_dly_ce   <= 0;
               cq_dly_rst  <= 0;
               q_dly_inc   <= 0;
               q_dly_ce    <= 0;
               q_dly_rst   <= 1;
               tap_wait_en <= 1'b1;
               next_state  <= TAP_WAIT;
            end

            CQ_Q_TAP_INC : begin
               cq_dly_inc  <= 1;
               cq_dly_ce   <= 1;
               cq_dly_rst  <= 0;
               q_dly_inc   <= 1;
               q_dly_ce    <= 1;
               q_dly_rst   <= 0;
               tap_wait_en <= 1'b1;
               next_state  <= TAP_WAIT;
            end

            CQ_Q_TAP_DEC : begin
               cq_dly_inc  <= 0;
               cq_dly_ce   <= 1;
               cq_dly_rst  <= 0;
               q_dly_inc   <= 0;
               q_dly_ce    <= 1;
               q_dly_rst   <= 0;
               tap_wait_en <= 1'b1;
               next_state  <= TAP_WAIT;
            end

            TAP_WAIT : begin
               cq_dly_inc  <= 0;
               cq_dly_ce   <= 0;
               cq_dly_rst  <= 0;
               q_dly_inc   <= 0;
               q_dly_ce    <= 0;
               q_dly_rst   <= 0;
               tap_wait_en <= 1'b0;
               if (tap_wait_cnt == 3'b111)
                 next_state <= IDLE;
               else
                 next_state <= TAP_WAIT;
            end

            DEBUG_ST : begin
               cq_dly_inc  <= 0;
               cq_dly_ce   <= 0;
               cq_dly_rst  <= 0;
               q_dly_inc   <= 0;
               q_dly_ce    <= 0;
               q_dly_rst   <= 0;
               tap_wait_en <= 1'b1;

               if(dbg_sel_idel_q_cq) begin
                 q_dly_inc <= dbg_idel_up_q_cq;
                 q_dly_ce  <= dbg_idel_up_q_cq | dbg_idel_down_q_cq;
               end else
                 q_dly_ce  <= 0;

               if(dbg_sel_idel_cq) begin
                 cq_dly_inc <= dbg_idel_up_cq;
                 cq_dly_ce  <= dbg_idel_up_cq | dbg_idel_down_cq;
               end else
                 cq_dly_ce  <= 0;

               if((!dbg_sel_idel_q_cq) & (!dbg_sel_idel_cq))
                 next_state <= IDLE;
               else
                 next_state <= DEBUG_ST;

            end

            default : next_state <= IDLE;

          endcase
       end
     end

   assign cnt_rst = user_rst_0 | insuff_window_detect_p | q_initdelay_done_p |
                    cq_initdelay_done_p | q_inc_delay_done_p;

   always @ (posedge clk0)
     begin
        if (cnt_rst)
          first_edge_detect <= 1'b0;
        else if ((~q_error && ~cal1_error) && (tap_wait_cnt == 3'b111))
          first_edge_detect <= 1'b1;
     end

   always @ (posedge clk0)
     begin
        if (cnt_rst)
          second_edge_detect <= 1'b0;
        else if (first_edge_detect && (q_error|| cal1_error || end_of_taps))
          second_edge_detect <= 1'b1;
     end

   always @ (posedge clk0)
     begin
        if (cnt_rst) begin
           first_edge_detect_r  <= 1'b0;
           second_edge_detect_r <= 1'b0;
        end else begin
           first_edge_detect_r  <= first_edge_detect;
           second_edge_detect_r <= second_edge_detect;
        end
     end

   always @ (posedge clk0)
     begin
        if (cnt_rst)
          dvw_detect_done <= 1'b0;
        else if (second_edge_detect_r && ~insuff_window_detect &&
                 ~(q_rst_done && ~q_delay_done_6r))
          dvw_detect_done <= 1'b1;
     end

   always @ (posedge clk0)
     begin
        if (cnt_rst)
          dvw_detect_done_r <= 1'b0;
        else
          dvw_detect_done_r <= dvw_detect_done;
     end

   always @(posedge clk0)
     begin
        if (user_rst_0 || cq_dly_rst)
          cq_tap_cnt <= 6'b000000;
        else if (cq_dly_ce && cq_dly_inc)
          cq_tap_cnt <= cq_tap_cnt + 1;
        else if (cq_dly_ce && ~cq_dly_inc)
          cq_tap_cnt <= cq_tap_cnt - 1;
     end

   always @(posedge clk0)
     begin
        if (user_rst_0 || q_dly_rst)
          q_tap_cnt <= 6'b000000;
        else if (q_dly_ce && q_dly_inc)
          q_tap_cnt <= q_tap_cnt + 1;
        else if (q_dly_ce && ~q_dly_inc)
          q_tap_cnt <= q_tap_cnt - 1;
     end

   always @(posedge clk0)
     begin
        if (user_rst_0)
          tap_wait_cnt <= 3'b000;
        else if ((tap_wait_cnt != 3'b000) || (tap_wait_en))
          tap_wait_cnt <= tap_wait_cnt + 1;
     end

   always @(posedge clk0)
     begin
        if (cnt_rst)
          cq_tap_range <= 6'b0;
        else if (cq_dly_inc && first_edge_detect)
          cq_tap_range <= cq_tap_range + 1;
     end

   always @(posedge clk0)
     begin
        if (cnt_rst)
          q_tap_range <= 6'b0;
        else if (q_dly_inc && first_edge_detect)
          q_tap_range <= q_tap_range + 1;
     end

  //////////////////////////////////////////////////////////////////////////////
  // 1st stage calibration registers
  //////////////////////////////////////////////////////////////////////////////

  // either end of window reached or no window detected
    always @ (posedge clk0)
      begin
         if (user_rst_0)
           cq_initdelay_inc_done <= 1'b0;
         else if ((~cq_initdelay_inc_done && dvw_detect_done
                   && ~dvw_detect_done_r)|| (cq_tap_cnt == 6'h05 &&
                                             ~first_edge_detect))
           cq_initdelay_inc_done <= 1'b1;
      end

   always @(posedge clk0)
     begin
        if (user_rst_0)
          q_initdelay_inc_done <= 1'b0;
        else if (cq_initdelay_inc_done && ~q_initdelay_inc_done &&
                 dvw_detect_done && ~dvw_detect_done_r&& q_tap_range > 6'h07)
          q_initdelay_inc_done <= 1'b1;
     end

   always @ (posedge clk0)
     begin
        if (user_rst_0)
          cq_rst_done <= 1'b0;
        else if (cq_initdelay_inc_done && cq_dly_rst)
          cq_rst_done <= 1'b1;
     end

   always @ (posedge clk0)
     begin
        if (user_rst_0)
          q_rst_done <= 1'b0;
        else if (q_initdelay_inc_done && q_dly_rst)
          q_rst_done <= 1'b1;
     end

   always @ (posedge clk0)
     begin
        if (user_rst_0)
          cq_hold_range <= 6'h00;
        else if (~cq_initdelay_inc_done &&  cq_dly_inc && first_edge_detect )
          cq_hold_range <= cq_hold_range + 1 ;
     end

   always @ (posedge clk0)
     begin
        if (user_rst_0)
          cq_setup_range <= 6'h00;
        else if (~q_initdelay_inc_done && q_dly_inc && first_edge_detect  )
          cq_setup_range <= cq_setup_range +1;
     end

   always @(posedge clk0)
     begin
        if (user_rst_0) begin
           q_initdelay_inc_done_r   <= 1'b0;
           cq_initdelay_inc_done_r  <= 1'b0;
           q_init_delay_done_r      <= 1'b0;
           q_initdelay_inc_done_2r  <= 1'b0;
           cq_initdelay_inc_done_2r <= 1'b0;
           q_init_delay_done_2r     <= 1'b0;
        end else begin
           q_initdelay_inc_done_r   <= q_initdelay_inc_done;
           cq_initdelay_inc_done_r  <= cq_initdelay_inc_done;
           q_init_delay_done_r      <= q_init_delay_done;
           q_initdelay_inc_done_2r  <= q_initdelay_inc_done_r;
           cq_initdelay_inc_done_2r <= cq_initdelay_inc_done_r;
           q_init_delay_done_2r     <= q_init_delay_done_r;
        end
     end

   assign q_initdelay_done_p  = ( q_initdelay_inc_done_r &&
                                 ~q_initdelay_inc_done_2r )? 1'b1 : 1'b0;
   assign cq_initdelay_done_p = ( cq_initdelay_inc_done_r &&
                                 ~cq_initdelay_inc_done_2r)? 1'b1 : 1'b0;
   assign q_inc_delay_done_p  = ( q_init_delay_done_r && ~q_init_delay_done_2r )
                                ? 1'b1 : 1'b0;

   assign q_tap_inc_val = (q_initdelay_inc_done_r &&
                           cq_setup_range > cq_hold_range) ?
                          (cq_setup_range - cq_hold_range)>>1 : 6'h00;

   always @(posedge clk0)
     begin
        if (user_rst_0)
          q_tap_inc_range <= 6'b0;
        else
          q_tap_inc_range <= q_tap_inc_val;
     end

   always @(posedge clk0)
     begin
        if (user_rst_0)
          q_init_delay_done <= 1'b0;
        else if (q_rst_done && ~q_init_delay_done &&
                 q_tap_cnt == q_tap_inc_range)
          q_init_delay_done <= 1'b1;
     end

   /////////////////////////////////////////////////////////////////////////////
   // 2nd stage calibration registers
   /////////////////////////////////////////////////////////////////////////////

   always @(posedge clk0)
     begin
        if (user_rst_0)
          cq_q_detect_done <= 1'b0;
        else if (q_delay_done_6r && dvw_detect_done && ~dvw_detect_done_r)
          cq_q_detect_done <= 1'b1;
     end

   always @(posedge clk0)
     begin
        if (user_rst_0) begin
           cq_q_detect_done_r  <= 1'b0;
           cq_q_detect_done_2r <= 1'b0;
        end else begin
           cq_q_detect_done_r  <= cq_q_detect_done;
           cq_q_detect_done_2r <= cq_q_detect_done_r;
        end
     end

   always @ (posedge clk0)
     begin
        if (cnt_rst)
          insuff_window_detect <= 1'b0;
        else if (q_delay_done_6r && second_edge_detect &&
                 (cq_tap_range < max_window))
          insuff_window_detect <= 1'b1;
        else if (insuff_window_detect && first_edge_detect_r)
          insuff_window_detect <= 1'b0;
     end

   always @ (posedge clk0)
     begin
        if (user_rst_0)
           insuff_window_detect_r  <= 1'b0;
        else
           insuff_window_detect_r  <= insuff_window_detect;
     end

   assign insuff_window_detect_p = (insuff_window_detect &&
                                    ~insuff_window_detect_r )? 1'b1 : 1'b0;

   always @ (posedge clk0)
     begin
        if (user_rst_0)
          insuff_window_taps <= 6'h0;
        else if (insuff_window_detect && ~insuff_window_detect_r)
          insuff_window_taps <= cq_tap_cnt;
     end

   assign cq_tap_range_center_w = (cq_tap_range < max_window) ? 6'h00 :
                                  (cq_tap_range < 2* max_window)?
                                  cq_tap_range - max_window : cq_tap_range >>1;

   always @(posedge clk0)
     begin
        if (user_rst_0) begin
           cq_tap_range_center <= 6'b0;
           cq_final_tap_cnt    <= 6'b0;
        end else begin
           cq_tap_range_center <= cq_tap_range_center_w ;
           cq_final_tap_cnt    <= insuff_window_taps + cq_tap_range_center ;
        end
     end

   always @ (posedge clk0)
     begin
        if (cnt_rst)
          end_of_taps <= 1'b0;
        else if (cq_tap_cnt == 6'h30)
          end_of_taps <= 1'b1;
     end

   always @ (posedge clk0)
     begin
        if (user_rst_0)
          cq_cal_done <= 1'b0;
        else if ((cq_tap_cnt == cq_final_tap_cnt &&  cq_q_detect_done))
          cq_cal_done <= 1'b1;
     end

   // generate read fifo strobe logic

   generate
     if(BURST_LENGTH == 4)begin : BL4_INST
     // For BL4 design, when a single read command is issued, 4 bursts of data is
     // received. The same read command is expanded for two clock cycles and
     // then the comparision of read data with pattern data is done in this
     // particular two clock command window. Until the read data is matched with
     // the pattern data, the two clock command window is shifted using SRL.
       always @ (posedge clk0)
         begin
            if (user_rst_0) begin
               rd_stb_cnt <= 2'b00;
                end else if (!rd_en) begin
               rd_stb_cnt <= 2'b10;
            end else if (rd_stb_cnt != 2'b00) begin
               rd_stb_cnt <= rd_stb_cnt - 1;
            end else begin
               rd_stb_cnt <= rd_stb_cnt;
            end
         end

       always @ (posedge clk0)
         begin
            if (user_rst_0)
              rd_cmd <= 1'b0;
            else if (rd_stb_cnt != 2'b00)
              rd_cmd <= 1'b1;
            else
              rd_cmd <= 1'b0;
         end
     end
     else begin : BL2_INST
     // For BL2 design, when two consecutive read commands are issued, 4 bursts
     // of data is received. The read data is compared with pattern data in this
     // particular two clock command window. Until the read data is matched with
     // the pattern data, the two clock command window is shifted using SRL.
       always @ (posedge clk0)
         begin
            if (user_rst_0)
              rd_cmd <= 1'b0;
            else if (!rd_en)
              rd_cmd <= 1'b1;
            else
              rd_cmd <= 1'b0;
         end

       always @ (posedge clk0)
         rd_en_i <= ~rd_en;

     end
   endgenerate

   always @ (posedge clk0)
     begin
        if (user_rst_0)
          rden_cnt_clk0 <= 4'b000;
        // Increment count for SRL. This count determines the number of clocks
        // two clock command window is delayed until the Read data is matched
        // with pattern data.
        else if ((rd_stb_cnt == 2'b01) & write_cal_start & ~we_cal_done
                 & (BURST_LENGTH == 4))
          rden_cnt_clk0 <= rden_cnt_clk0 + 1;
        else if ((!rd_en) & rd_en_i & write_cal_start & ~we_cal_done
                 & (BURST_LENGTH == 2))
          rden_cnt_clk0 <= rden_cnt_clk0 + 1;
        else if (we_cal_done && ~we_cal_done_r)
          rden_cnt_clk0 <= rden_cnt_clk0 - 1;
        else
          rden_cnt_clk0 <= rden_cnt_clk0;
     end

   always @ (posedge clk0)
     begin
        if (user_rst_0)
          we_cal_done_r <= 1'b0;
        else
          we_cal_done_r <= we_cal_done;
     end

   SRL16 SRL_RDEN_CLK0
     (
      .Q   ( rden_srl_clk0 ),
      .A0  ( rden_cnt_clk0[0] ),
      .A1  ( rden_cnt_clk0[1] ),
      .A2  ( rden_cnt_clk0[2] ),
      .A3  ( rden_cnt_clk0[3] ),
      .CLK ( clk0 ),
      .D   ( rd_cmd )
      );

   FD WE_CLK0_INST
     (
      .Q ( rdfifo_we ),
      .C ( clk0 ),
      .D ( rden_srl_clk0 )
      );

   // generate read fifo strobe logic

   always @ (posedge clk0)
     begin
        if (user_rst_0)
          we_cal_cnt <= 3'b000;
        else if ((we_cal_start) || (we_cal_cnt != 3'b000) )
          we_cal_cnt <= we_cal_cnt + 1;
        else
          we_cal_cnt <= we_cal_cnt;
     end

   always @ (posedge clk0)
     begin
        if (user_rst_0)
          write_cal_start <= 1'b0;
        else if (we_cal_cnt == 3'b111)
          write_cal_start <= 1'b1;
        else
          write_cal_start <= write_cal_start;
     end

   always @ (posedge clk0)
     begin
        if (user_rst_0) begin
           we_cal_done <= 1'b0;
           comp_cs     <= COMP_1;
        end else begin
           case (comp_cs)

             COMP_1 : begin
                if (rdfifo_we && write_cal_start) begin
                   if (cal2_chk_1) begin
                      we_cal_done <= 1'b0;
                      comp_cs     <= COMP_2;
                   end else begin
                      we_cal_done <= 1'b0;
                      comp_cs     <= COMP_1;
                   end
                end else begin
                   we_cal_done <= 1'b0;
                   comp_cs     <= COMP_1;
                end
             end // case: COMP_1

             COMP_2 : begin
                if (cal2_chk_2) begin
                   we_cal_done <= 1'b1;
                   comp_cs     <= CAL_DONE_ST;
                end else begin
                   we_cal_done <= 1'b0;
                   comp_cs     <= COMP_1;
                end
             end

             CAL_DONE_ST  : begin
                we_cal_done <= 1'b1;
                comp_cs     <= CAL_DONE_ST;
             end

             default:  begin
                we_cal_done <= 1'b0;
                comp_cs     <= COMP_1;
             end
           endcase
        end
     end

endmodule