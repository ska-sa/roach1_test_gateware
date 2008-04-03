//*****************************************************************************
// Copyright (c) 2006-2007 Xilinx, Inc.
// This design is confidential and proprietary of Xilinx, Inc.
// All Rights Reserved
//*****************************************************************************
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor: Xilinx
// \   \   \/     Version: $Name: i+IP+131489 $
//  \   \         Application: MIG
//  /   /         Filename: black_box.v
// /___/   /\     Date Last Modified: $Date: 2007/09/21 15:23:30 $
// \   \  /  \    Date Created: Mon Dec 11 2006
//  \___\/\___\
//
//Device: Virtex-5
//Design Name: DDR2
//Purpose:
//   Black box declarations for primitives Synplify Pro doesn't recognize.
//   Use only for Synplify Pro - don't need for XST or for simulation.
//   Eventually these may not be needed for Synplify Pro as the tool
//   recognizes these primitives in future builds
//Reference:
//   Rev 1.2 - Added LUT6_2. RC. 07/25/07
//Revision History:
//*****************************************************************************

`timescale 1ns/1ps

(* syn_black_box *) module IODELAY
  (DATAOUT,
   C,
   CE,
   DATAIN,
   IDATAIN,
   INC,
   ODATAIN,
   RST,
   T)
  /* synthesis syn_black_box */;
  parameter DELAY_SRC    = "I";
  parameter HIGH_PERFORMANCE_MODE    = "FALSE";
  parameter IDELAY_TYPE  = "DEFAULT";
  parameter IDELAY_VALUE = 0;
  parameter ODELAY_VALUE = 0;
  parameter REFCLK_FREQUENCY = 200.0;
  output    DATAOUT;
  input     C;
  input     CE;
  input     DATAIN;
  input     IDATAIN;
  input     INC;
  input     ODATAIN;
  input     RST;
  input     T ;
endmodule

(* syn_black_box *) module ISERDES_NODELAY
  (Q1,
   Q2,
   Q3,
   Q4,
   Q5,
   Q6,
   SHIFTOUT1,
   SHIFTOUT2,
   BITSLIP,
   CE1,
   CE2,
   CLK,
   CLKB,
   CLKDIV,
   D,
   OCLK,
   RST,
   SHIFTIN1,
   SHIFTIN2)
  /* synthesis syn_black_box */;
  parameter BITSLIP_ENABLE = "FALSE";
  parameter DATA_RATE = "DDR";
  parameter DATA_WIDTH = 4;
  parameter INIT_Q1 = 1'b0;
  parameter INIT_Q2 = 1'b0;
  parameter INIT_Q3 = 1'b0;
  parameter INIT_Q4 = 1'b0;
  parameter INTERFACE_TYPE = "MEMORY";
  parameter NUM_CE = 2;
  parameter SERDES_MODE = "MASTER";
  output    Q1;
  output    Q2;
  output    Q3;
  output    Q4;
  output    Q5;
  output    Q6;
  output    SHIFTOUT1;
  output    SHIFTOUT2;
  input     BITSLIP;
  input     CE1;
  input     CE2;
  input     CLK;
  input     CLKB;
  input     CLKDIV;
  input     D;
  input     OCLK;
  input     RST;
  input     SHIFTIN1;
  input     SHIFTIN2;
endmodule

(* syn_black_box *) module LUT6_2
  (O5,
   O6,
   I0,
   I1,
   I2,
   I3,
   I4,
   I5)
  /* synthesis syn_black_box */;
  parameter INIT = 64'h0000000000000000;
  input I0, I1, I2, I3, I4, I5;
  output O5, O6;
endmodule
