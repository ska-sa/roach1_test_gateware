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
// done at the user�s sole risk and will be unsupported.
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
//  /   /         Filename           : qdrii_phy_init_sm.v
// /___/   /\     Timestamp          : 15 May 2006
// \   \  /  \    Date Last Modified : $Date: 2008/02/06 16:24:58 $
//  \___\/\___\
//
//Device: Virtex-5
//Design: QDRII
//
//Purpose:
//    This module
//  1. Is the initialization statemachine generating the dummy write and
//     dummy read commands for delay calibration before regular memory
//     transactions begin.
//
//Revision History:
//
////////////////////////////////////////////////////////////////////////////////


`timescale 1ns/1ps

module qdrii_phy_init_sm #
  (
   // Following parameters are for 72-bit design (for ML561 Reference board
   // design). Actual values may be different. Actual parameters values are
   // passed from design top module qdrii_sram module. Please refer to the
   // qdrii_sram module for actual values.
   parameter BURST_LENGTH = 4,
   parameter CLK_FREQ     = 300,
   parameter SIM_ONLY     = 0
   )
  (
   input            clk0,
   input            user_rst_0,
   input            dly_cal_done,
   input            q_init_delay_done,
   input            en_cal_done,
   input            dly_ready,
   output reg       dly_cal_start,
   output reg       we_cal_start,
   output reg [1:0] dummy_write,
   output reg [1:0] dummy_read,
   output reg       cal_done,
   output reg       init_cnt_done
   );

   localparam [13:0] //14 states - one-hot encoded
       CQ_WAIT          =  14'b00_0000_0000_0001,
       CAL_WR1          =  14'b00_0000_0000_0010,
       CAL_CQ_RD1       =  14'b00_0000_0000_0100,
       CAL_CQ_RD_WAIT1  =  14'b00_0000_0000_1000,
       CAL_WR2_A        =  14'b00_0000_0001_0000,
       CAL_WR2_B        =  14'b00_0000_0010_0000,
       CAL_CQ_RD2_A     =  14'b00_0000_0100_0000,
       CAL_CQ_RD2_B     =  14'b00_0000_1000_0000,
       CAL_CQ_RD_WAIT2  =  14'b00_0001_0000_0000,
       CAL_EN_RD_START  =  14'b00_0010_0000_0000,
       CAL_EN_RD_A      =  14'b00_0100_0000_0000,
       CAL_EN_RD_B      =  14'b00_1000_0000_0000,
       CAL_EN_RD_WAIT   =  14'b01_0000_0000_0000,
       CAL_DONE_ST      =  14'b10_0000_0000_0000;

   reg [3:0]  dummy_rd_cnt;
   reg        dummy_cnt_en;
   reg [13:0] phy_init_ns;
   reg [13:0] phy_init_cs;
   reg [10:0] cq_cnt;
   reg        cq_active;
   reg        cal_done_r;
   reg        cal_done_2r;
   reg        cal_done_3r;
   reg        cal_done_4r;
   reg        cal_done_5r;
   reg        dly_ready_r;
   reg        dly_ready_2r;
   reg [7:0]  init_count;
   reg        q_init_delay_done_i;

   integer init_max_count;

   always @(posedge clk0)
     begin
       if(user_rst_0)
         q_init_delay_done_i <= 'b0;
       else
         q_init_delay_done_i <= q_init_delay_done;
     end

   always @ (posedge clk0)
     begin
        if (user_rst_0)
          init_count <= 8'b0;
        else if (init_count == 8'hC8)
          init_count <= 8'b0;
        else if(init_cnt_done == 1'b0)
          init_count <= init_count + 1;
        else
          init_count <= init_count;
     end

   //init_max_count generates a 200 us counter based on init_count
   // an init_max_count of 8'hC8 refers to a 200 us count

   always @ (posedge clk0)
     begin
        if (user_rst_0)
          if (SIM_ONLY == 1)
            init_max_count <= CLK_FREQ;
          else
            init_max_count <= 0;
        else if ((init_count == 8'hC8) && (init_cnt_done == 1'b0))
          init_max_count <= init_max_count + 1;
        else
          init_max_count <= init_max_count;
     end

   always @ (posedge clk0)
     begin
        if (user_rst_0)
          init_cnt_done <= 1'b0;
        else if (init_max_count == CLK_FREQ)
          init_cnt_done <= 1'b1;
        else
          init_cnt_done <= init_cnt_done;
     end

   always @(posedge clk0)
     begin
        if (user_rst_0) begin
           we_cal_start <= 1'b0;
        end else if (dummy_cnt_en) begin
           we_cal_start <= 1'b1;
        end else
          we_cal_start <= we_cal_start;
     end


   always @(posedge clk0)
     begin
        if (user_rst_0)
          cq_cnt <= 10'b0;
        else if ((init_cnt_done) && (cq_cnt != 11'b11111111111))
          cq_cnt <= cq_cnt + 1;
        else
          cq_cnt <= cq_cnt;
     end

   always @(posedge clk0)
   //Make sure CQ clock is established (1024 clocks) before starting calibration
     begin
        if (user_rst_0)
          cq_active <= 1'b0;
        else if (cq_cnt == 11'b11111111111)
          cq_active <= 1'b1;
        else
          cq_active <= cq_active;
     end

   always @ (posedge clk0)
     begin
        if (user_rst_0) begin
           dly_ready_r  <= 1'b0;
           dly_ready_2r <= 1'b0;
        end else begin
           dly_ready_r  <= dly_ready;
           dly_ready_2r <= dly_ready_r;
        end
     end

   always @(posedge clk0)
     begin
        if (user_rst_0) begin
           dly_cal_start <= 1'b0;
        end else if (cq_active && dly_ready_2r ) begin
           dly_cal_start <= 1'b1;
        end
     end

   always @(posedge clk0)
     begin
        if (user_rst_0) begin
           dummy_rd_cnt <= 4'b0000;
        end else if (dummy_cnt_en) begin
           dummy_rd_cnt <= 4'b1111;
        end else if (dummy_rd_cnt != 4'b0000) begin
           dummy_rd_cnt <= dummy_rd_cnt - 1;
        end else begin
           dummy_rd_cnt <= dummy_rd_cnt;
        end
     end

   always @ (posedge clk0)
     begin
        if (user_rst_0)
          cal_done_r <= 1'b0;
        else if  (en_cal_done && dummy_rd_cnt == 4'b0000)
          cal_done_r <= 1'b1;
        else
          cal_done_r <= cal_done_r;
     end

   always @ (posedge clk0)
     begin
        if (user_rst_0) begin
           cal_done_2r <= 1'b0;
           cal_done_3r <= 1'b0;
           cal_done_4r <= 1'b0;
           cal_done_5r <= 1'b0;
           cal_done    <= 1'b0;
        end else begin
           cal_done_2r <= cal_done_r;
           cal_done_3r <= cal_done_2r;
           cal_done_4r <= cal_done_3r;
           cal_done_5r <= cal_done_4r;
           cal_done    <= cal_done_5r;
        end
     end

   // synthesis translate_off
   always @(posedge cal_done) begin
     if(!user_rst_0)
        $display("Calibration completed at time %t", $time );
   end
   // synthesis translate_on

   always @(posedge clk0)
     begin
        if (user_rst_0)
          phy_init_cs <= CQ_WAIT;
        else
          phy_init_cs <= phy_init_ns;
     end

   always @ *
     begin
        dummy_write[1:0]  = 2'b00;
        dummy_read        = 2'b00;
        dummy_cnt_en      = 1'b0;

        case (phy_init_cs)
          CQ_WAIT : begin
             dummy_write = 2'b00;
             dummy_read  = 2'b00;
             if (cq_active && dly_ready_2r)
               phy_init_ns = CAL_WR1;
             else
               phy_init_ns = CQ_WAIT;
          end

          // First Stage Calibration-Single Write command
          CAL_WR1  :  begin
             dummy_write = 2'b01;
             dummy_read  = 2'b00;
             phy_init_ns = CAL_CQ_RD1;
          end

          // First Stage Calibration- Continous Read commands until first stage
          // calibration is complete.
          // For BL4 read commands are issued on alternate clock.
          // For BL2 read commands are issued on every clock.
          CAL_CQ_RD1   : begin
             dummy_write = 2'b00;
             dummy_read  = 2'b01;
             if(BURST_LENGTH == 2)
               if(q_init_delay_done_i)
                 phy_init_ns = CAL_WR2_A;
               else
                 phy_init_ns = CAL_CQ_RD1;
             else if(BURST_LENGTH == 4)
               phy_init_ns = CAL_CQ_RD_WAIT1;
          end

          CAL_CQ_RD_WAIT1 : begin
             dummy_write = 2'b00;
             dummy_read  = 2'b00;
             if (q_init_delay_done)
               phy_init_ns = CAL_WR2_A;
             else
               phy_init_ns = CAL_CQ_RD1;
          end

          // Second Stage Calibration-Write command
          // For BL4 a single Write command is issued.
          // For BL2 two Write commands are issued.
          CAL_WR2_A  :  begin
             dummy_write = 2'b10;
             dummy_read  = 2'b00;
             if(BURST_LENGTH == 2)
               phy_init_ns = CAL_WR2_B;
             else if(BURST_LENGTH == 4)
               phy_init_ns = CAL_CQ_RD2_A;
          end

          CAL_WR2_B  :  begin
             dummy_write = 2'b11;
             dummy_read  = 2'b00;
             phy_init_ns = CAL_CQ_RD2_A;
          end

          // Second Stage Calibration-Continous Read Commands until Second stage
          // calibration is complete.
          // For BL4 read commands are issued on alternate clocks.
          // For BL2 read commands are issued on every clock.
          CAL_CQ_RD2_A   : begin
             dummy_write = 2'b00;
             dummy_read  = 2'b01;
             if(BURST_LENGTH == 2)
               phy_init_ns = CAL_CQ_RD2_B;
             else if(BURST_LENGTH == 4)
               phy_init_ns = CAL_CQ_RD_WAIT2;
          end

          CAL_CQ_RD2_B : begin
             dummy_write = 2'b00;
             dummy_read  = 2'b10;
             if(dly_cal_done)
               phy_init_ns = CAL_EN_RD_START;
             else
               phy_init_ns = CAL_CQ_RD2_A;
          end

          CAL_CQ_RD_WAIT2 : begin
             dummy_write = 2'b00;
             dummy_read  = 2'b00;
             if (dly_cal_done)
               phy_init_ns = CAL_EN_RD_START;
             else
               phy_init_ns = CAL_CQ_RD2_A;
          end

          // Third Stage Calibration-Read Enable Calibration start
          CAL_EN_RD_START : begin
             dummy_write  = 2'b00;
             dummy_read   = 2'b00;
             dummy_cnt_en = 1'b1;
             phy_init_ns  = CAL_EN_RD_WAIT;
          end

          // Third Stage Calibration-Read commands until Third Stage Calibration
          // is complete (en_cal_done = '1');
          // For BL4 a single Read command for every dummy_rd_cnt=4'd0.
          // For BL2, two consecutive Read commands for every dummy_rd_cnt=4'd0.
          CAL_EN_RD_A   : begin
             dummy_write  = 2'b00;
             dummy_read   = 2'b01;
             dummy_cnt_en = 1'b1;
             if(BURST_LENGTH == 2)
               phy_init_ns  = CAL_EN_RD_B;
             else if(BURST_LENGTH == 4)
               phy_init_ns  = CAL_EN_RD_WAIT;
          end

          CAL_EN_RD_B : begin
             dummy_write  = 2'b00;
             dummy_read   = 2'b10;
             dummy_cnt_en = 1'b1;
             phy_init_ns  = CAL_EN_RD_WAIT;
          end

          CAL_EN_RD_WAIT : begin
             dummy_write = 2'b00;
             dummy_read  = 2'b00;
             if (cal_done)
               phy_init_ns = CAL_DONE_ST;
             else if (~en_cal_done && dummy_rd_cnt == 4'b0000)
               phy_init_ns = CAL_EN_RD_A;
             else
               phy_init_ns = CAL_EN_RD_WAIT;
          end

          CAL_DONE_ST:   begin
             dummy_write = 2'b00;
             dummy_read  = 2'b00;
             phy_init_ns = CAL_DONE_ST;
          end

          default:   begin
             dummy_write = 2'b00;
             dummy_read  = 2'b00;
             phy_init_ns = CQ_WAIT;
          end
        endcase
     end

endmodule