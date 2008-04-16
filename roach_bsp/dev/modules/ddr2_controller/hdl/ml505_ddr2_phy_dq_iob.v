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
//  /   /         Filename: ml505_ddr2_phy_dq_iob.v
// /___/   /\     Date Last Modified: $Date: 2007/09/21 15:23:30 $
// \   \  /  \    Date Created: Wed Aug 16 2006
//  \___\/\___\
//
//Device: Virtex-5
//Design Name: DDR2
//Purpose:
//   This module places the data in the IOBs.
//Reference:
//Revision History:
//*****************************************************************************

`timescale 1ns/1ps

module ml505_ddr2_phy_dq_iob #
  (
   parameter DQ_COL = 0,
   parameter DQ_MS  = 0
   )
  (
   input        clk0,
   input        clk90,
   input        clkdiv0,
   input        rst90,
   input        dlyinc,
   input        dlyce,
   input        dlyrst,
   input  [1:0] dq_oe_n,
   input        dqs,
   input        ce,
   input        rd_data_sel,
   input        wr_data_rise,
   input        wr_data_fall,
   output       rd_data_rise,
   output       rd_data_fall,
   inout        ddr_dq
   );

  wire       dq_iddr_clk;
  wire       dq_idelay;
  wire       dq_in;
  wire       dq_oe_n_r;
  wire       dq_out;
  // prevent MAP from optimizing dummy carry-chain and LUT logic in RPM slices
  (* S = "TRUE", syn_keep = 1 *) wire [3:0] dummy_carry4_co_a;
  (* S = "TRUE", syn_keep = 1 *) wire [3:0] dummy_carry4_co_b;
  (* S = "TRUE", syn_keep = 1 *) wire [3:0] dummy_lut_o5_a;
  (* S = "TRUE", syn_keep = 1 *) wire [3:0] dummy_lut_o5_b;
  (* S = "TRUE", syn_keep = 1 *) wire [3:0] dummy_lut_o6_a;
  (* S = "TRUE", syn_keep = 1 *) wire [3:0] dummy_lut_o6_b;
  wire       stg2a_out_fall;
  wire       stg2a_out_rise;
  wire       stg2b_out_fall;
  wire       stg2b_out_rise;
  wire       stg3a_out_fall;
  wire       stg3a_out_rise;
  wire       stg3b_out_fall;
  wire       stg3b_out_rise;

  //***************************************************************************
  // Directed routing constraints for route between IDDR and stage 2 capture
  // in fabric.
  // Only 2 out of the 12 wire declarations will be used for any given
  // instantiation of this module.
  // Varies according:
  //  (1) I/O column (left, center, right) used
  //  (2) Which I/O in I/O pair (master, slave) used
  // Nomenclature: _Xy, X = column (0 = left, 1 = center, 2 = right),
  //  y = master or slave
  //***************************************************************************

  // master, left
  (* syn_keep = "1", keep = "TRUE",
     ROUTE = "{3;1;5vlx50tff1136;93a1e3bb!-1;-78112;-4200;S!0;-143;-1248!1;-452;0!2;2747;1575!3;2461;81!4;2732;-960!4;2732;-984!5;404;8!6;404;8!7;683;-568;L!8;843;24;L!}" *)
  wire stg1_out_rise_0m;
  (* syn_keep = "1", keep = "TRUE",
     ROUTE = "{3;1;5vlx50tff1136;907923a!-1;-78112;-4192;S!0;-143;-1192!0;-143;-1272!1;-452;0!2;-452;0!3;2723;-385!4;2731;-311!5;3823;-1983!6;5209;1271!7;1394;3072!8;0;-8!9;404;8!10;0;-144!11;683;-536;L!12;404;8!14;843;8;L!}" *)
  wire stg1_out_fall_0m;
  // slave, left
  (* syn_keep = "1", keep = "TRUE",
     ROUTE = "{3;1;5vlx50tff1136;53bb9d6f!-1;-78112;-4600;S!0;-143;-712!1;-452;0!2;1008;-552!3;2780;1360!4;0;-8!5;0;-240!5;0;-264!6;404;8!7;404;8!8;683;-568;L!9;843;24;L!}" *)
  wire stg1_out_rise_0s;
  (* syn_keep = "1", keep = "TRUE",
     ROUTE = "{3;1;5vlx50tff1136;46bf60d8!-1;-78112;-4592;S!0;-143;-800!1;-452;0!2;1040;1592!3;5875;-85!4;-3127;-843!4;-3127;-939!5;404;8!6;404;8!7;683;-696;L!8;843;-136;L!}" *)
  wire stg1_out_fall_0s;
  // master, center
  (* syn_keep = "1", keep = "TRUE",
     ROUTE = "{3;1;5vlx50tff1136;9ee47800!-1;-6504;-50024;S!0;-175;-1136!1;-484;0!2;-3208;1552!3;-4160;-2092!4;-1428;1172!4;-1428;1076!5;404;8!6;404;8!7;843;-152;L!8;683;-728;L!}" *)
  wire stg1_out_rise_1m;
  (* syn_keep = "1", keep = "TRUE",
     ROUTE = "{3;1;5vlx50tff1136;e7df31c2!-1;-6504;-50016;S!0;-175;-1192!1;-484;0!2;-5701;1523!3;-3095;-715!3;-4423;2421!4;0;-8!5;1328;-3288!6;0;-240!7;404;8!8;404;8!9;683;-696;L!10;843;-136;L!}" *)
  wire stg1_out_fall_1m;
  // slave, center
  (* syn_keep = "1", keep = "TRUE",
     ROUTE = "{3;1;5vlx50tff1136;a8c11eb3!-1;-6504;-50424;S!0;-175;-856!1;-484;0!2;-5677;-337!3;1033;1217!3;-295;4353!4;0;-8!5;1328;-3288!6;0;-120!7;404;8!8;404;8!9;683;-696;L!10;843;-152;L!}" *)
  wire stg1_out_rise_1s;
  (* syn_keep = "1", keep = "TRUE",
     ROUTE = "{3;1;5vlx50tff1136;ed30cce!-1;-6504;-50416;S!0;-175;-848!1;-484;0!2;-3192;-432!3;-1452;1368!3;-6645;85!4;0;-8!5;5193;1035!6;0;-264!7;404;8!8;404;8!9;683;-568;L!10;843;24;L!}" *)
  wire stg1_out_fall_1s;
  // master, right
  (* syn_keep = "1", keep = "TRUE",
     ROUTE = "{3;1;5vlx50tff1136;4d035a44!-1;54728;-108896;S!0;-175;-1248!1;-484;0!2;-3192;-424!3;-4208;2092!4;-1396;-972!4;-1396;-996!5;404;8!6;404;8!7;683;-568;L!8;843;24;L!}" *)
  wire stg1_out_rise_2m;
  (* syn_keep = "1", keep = "TRUE",
     ROUTE = "{3;1;5vlx50tff1136;92ae8739!-1;54728;-108888;S!0;-175;-1272!1;-484;0!2;-5677;-329!3;-1691;-83!4;-1428;1076!4;-1428;1052!5;404;8!6;404;8!7;683;-728;L!8;843;-136;L!}" *)
  wire stg1_out_fall_2m;
  // slave, right
  (* syn_keep = "1", keep = "TRUE",
     ROUTE = "{3;1;5vlx50tff1136;9de34bf1!-1;54728;-109296;S!0;-175;-712!1;-484;0!2;-5685;-475!3;1041;1107!3;1041;1011!4;404;8!5;404;8!6;683;-536;L!7;843;24;L!}" *)
  wire stg1_out_rise_2s;
  (* syn_keep = "1", keep = "TRUE",
     ROUTE = "{3;1;5vlx50tff1136;1df9e65d!-1;54728;-109288;S!0;-175;-800!1;-484;0!2;-3208;1608!3;-1436;-792!4;0;-8!5;0;-240!5;0;-144!6;404;8!7;404;8!8;843;-136;L!9;683;-696;L!}" *)
  wire stg1_out_fall_2s;

  //***************************************************************************
  // Bidirectional I/O
  //***************************************************************************

  IOBUF #(
    .IOSTANDARD("SSTL18_II_DCI")
  ) u_iobuf_dq
    (
     .I  (dq_out),
     .T  (dq_oe_n_r),
     .IO (ddr_dq),
     .O  (dq_in)
     );

  //***************************************************************************
  // Write (output) path
  //***************************************************************************

  // on a write, rising edge of DQS corresponds to rising edge of CLK180
  // (aka falling edge of CLK0 -> rising edge DQS). We also know:
  //  1. data must be driven 1/4 clk cycle before corresponding DQS edge
  //  2. first rising DQS edge driven on falling edge of CLK0
  //  3. rising data must be driven 1/4 cycle before falling edge of CLK0
  //  4. therefore, rising data driven on rising edge of CLK
  ODDR #
    (
     .SRTYPE("SYNC"),
     .DDR_CLK_EDGE("SAME_EDGE")
     )
    u_oddr_dq
      (
       .Q  (dq_out),
       .C  (clk90),
       .CE (1'b1),
       .D1 (wr_data_rise),
       .D2 (wr_data_fall),
       .R  (1'b0),
       .S  (1'b0)
       );

  // make sure output is tri-state during reset (DQ_OE_N_R = 1)
  ODDR #
    (
     .SRTYPE("ASYNC"),
     .DDR_CLK_EDGE("SAME_EDGE")
     )
    u_tri_state_dq
      (
       .Q  (dq_oe_n_r),
       .C  (clk90),
       .CE (1'b1),
       .D1 (dq_oe_n[0]),
       .D2 (dq_oe_n[1]),
       .R  (rst90),
       .S  (1'b0)
       );

  //***************************************************************************
  // Read data capture scheme description:
  // Data capture consists of 3 ranks of flops, and a MUX
  //  1. Rank 1 ("Stage 1"): IDDR captures delayed DDR DQ from memory using
  //     delayed DQS.
  //     - Data is split into 2 SDR streams, one each for rise and fall data.
  //     - BUFIO (DQS) input inverted to IDDR. IDDR configured in SAME_EDGE
  //       mode. This means that: (1) Q1 = fall data, Q2 = rise data,
  //       (2) Both rise and fall data are output on falling edge of DQS -
  //       rather than rise output being output on one edge of DQS, and fall
  //       data on the other edge if the IDDR were configured in OPPOSITE_EDGE
  //       mode. This simplifies Stage 2 capture (only one core clock edge
  //       used, removing effects of duty-cycle-distortion), and saves one
  //       fabric flop in Rank 3.
  //  2. Rank 2 ("Stage 2"): Fabric flops are used to capture output of first
  //     rank into FPGA clock (CLK) domain. Each rising/falling SDR stream
  //     from IDDR is feed into two flops, one clocked off rising and one off
  //     falling edge of CLK. One of these flops is chosen, with the choice
  //     being the one that reduces # of DQ/DQS taps necessary to align Stage
  //     1 and Stage 2. Same edge is used to capture both rise and fall SDR
  //     streams.
  //  3. Rank 3 ("Stage 3"): Removes half-cycle paths in CLK domain from
  //     output of Rank 2. This stage, like Stage 2, is clocked by CLK. Note
  //     that Stage 3 can be expanded to also support SERDES functionality
  //  4. Output MUX: Selects whether Stage 1 output is aligned to rising or
  //     falling edge of CLK (i.e. specifically this selects whether IDDR
  //     rise/fall output is transfered to rising or falling edge of CLK).
  // Implementation:
  //  1. Rank 1 is implemented using an IDDR primitive
  //  2. Rank 2 is implemented using:
  //     - An RPM to fix the location of the capture flops near the DQ I/O.
  //       The exact RPM used depends on which I/O column (left, center,
  //       right) the DQ I/O is placed at - this affects the optimal location
  //       of the slice flops (or does it - can we always choose the two
  //       columns to slices to the immediate right of the I/O to use, no
  //       matter what the column?). The origin of the RPM must be set in the
  //       UCF file using the RLOC_ORIGIN constraint (where the original is
  //       based on the DQ I/O location).
  //     - Directed Routing Constraints ("DIRT strings") to fix the routing
  //       to the rank 2 fabric flops. This is done to minimize: (1) total
  //       route delay (and therefore minimize voltage/temperature-related
  //       variations), and (2) minimize skew both within each rising and
  //       falling data net, as well as between the rising and falling nets.
  //       The exact DIRT string used depends on: (1) which I/O column the
  //       DQ I/O is placed, and (2) whether the DQ I/O is placed on the
  //       "Master" or "Slave" I/O of a diff pair (DQ is not differential, but
  //       the routing will be affected by which of each I/O pair is used)
  // 3. Rank 3 is implemented using fabric flops. No LOC or DIRT contraints
  //    are used, tools are expected to place these and meet PERIOD timing
  //    without constraints (constraints may be necessary for "full" designs,
  //    in this case, user may need to add LOC constraints - if this is the
  //    case, there are no constraints - other than meeting PERIOD timing -
  //    for rank 3 flops.
  //***************************************************************************

  // IDELAY to delay incoming data for synchronization purposes
  IODELAY #
    (
     .DELAY_SRC             ("I"),
     .IDELAY_TYPE           ("VARIABLE"),
     .HIGH_PERFORMANCE_MODE ("TRUE"),
     .IDELAY_VALUE          (0),
     .ODELAY_VALUE          (0)
     )
    u_idelay_dq
      (
       .DATAOUT (dq_idelay),
       .C       (clkdiv0),
       .CE      (dlyce),
       .DATAIN  (),
       .IDATAIN (dq_in),
       .INC     (dlyinc),
       .ODATAIN (),
       .RST     (dlyrst),
       .T       ()
       );

  //***************************************************************************
  // Rank 1 capture: Use IDDR to generate two SDR outputs
  //***************************************************************************

  // invert clock to IDDR in order to use SAME_EDGE mode (otherwise, we "run
  // out of clocks" because DQS is not continuous
  assign dq_iddr_clk = ~dqs;

  //***************************************************************************
  // Rank 2 capture: Use fabric flops to capture Rank 1 output. Use RPM and
  // DIRT strings here.
  // BEL ("Basic Element of Logic") and relative location constraints for
  // second stage capture. C
  // Varies according:
  //  (1) I/O column (left, center, right) used
  //  (2) Which I/O in I/O pair (master, slave) used
  // NOTES:
  //  1. Placing unrelated logic can cause routing conflicts later during
  //     PAR (e.g. if MAP uses carry chain in one of these slices, the
  //     AX/BX/CX/DX input may be used instead for the carry-chain, which
  //     then results in a routing conflict (with the directed routing
  //     constraints for the IDDR -> fabric flop paths). Additional unused
  //     LUT's and carry-chains are instantiated to prevent MAP from using
  //     these resources.
  //***************************************************************************

  // Six different cases for the different I/O column, master/slave
  // combinations (can't seem to do this using a localparam, which
  // would be easier, XST doesn't allow it)
  generate
    if ((DQ_MS == 1) && (DQ_COL == 0)) begin: gen_stg2_0m

      //*****************************************************************
      // master, left
      //*****************************************************************

      IDDR #
        (
         .DDR_CLK_EDGE ("SAME_EDGE")
         )
        u_iddr_dq
          (
           .Q1 (stg1_out_fall_0m),
           .Q2 (stg1_out_rise_0m),
           .C  (dq_iddr_clk),
           .CE (ce),
           .D  (dq_idelay),
           .R  (1'b0),
           .S  (1'b0)
           );

      //*********************************************************
      // Slice #1 (posedge CLK): Used for:
      //  1. IDDR transfer to CLK0 rising edge domain ("stg2a")
      //  2. stg2 falling edge -> stg3 rising edge transfer
      //*********************************************************

      // Stage 2 capture
      (* HU_SET = "stg2_capture", RLOC = "X2Y0", BEL = "DFF" *)
      FDC u_ff_stg2a_fall
        (
         .D   (stg1_out_fall_0m),
         .Q   (stg2a_out_fall),
         .C   (clk0),
         .CLR (1'b0)
         )/* synthesis syn_preserve = 1 */
          /* synthesis syn_replicate = 0 */;
      (* HU_SET = "stg2_capture", RLOC = "X2Y0", BEL = "CFF" *)
      FDC u_ff_stg2a_rise
        (
         .D   (stg1_out_rise_0m),
         .Q   (stg2a_out_rise),
         .C   (clk0),
         .CLR (1'b0)
         )/* synthesis syn_preserve = 1 */
          /* synthesis syn_replicate = 0 */;
      // Stage 3 falling -> rising edge translation
      (* HU_SET = "stg2_capture", RLOC = "X2Y0", BEL = "BFF" *)
      FDC u_ff_stg3b_fall
        (
         .D   (stg2b_out_fall),
         .Q   (stg3b_out_fall),
         .C   (clk0),
         .CLR (1'b0)
         )/* synthesis syn_preserve = 1 */
          /* synthesis syn_replicate = 0 */;
      (* HU_SET = "stg2_capture", RLOC = "X2Y0", BEL = "AFF" *)
      FDC u_ff_stg3b_rise
        (
         .D   (stg2b_out_rise),
         .Q   (stg3b_out_rise),
         .C   (clk0),
         .CLR (1'b0)
         )/* synthesis syn_preserve = 1 */
          /* synthesis syn_replicate = 0 */;

      //*********************************************************
      // Slice #2 (posedge CLK): Used for:
      //  1. IDDR transfer to CLK0 falling edge domain ("stg2b")
      //*********************************************************

      (* HU_SET = "stg2_capture", RLOC = "X3Y0", BEL = "DFF" *)
      FDC_1 u_ff_stg2b_fall
        (
         .D   (stg1_out_fall_0m),
         .Q   (stg2b_out_fall),
         .C   (clk0),
         .CLR (1'b0)
         )/* synthesis syn_preserve = 1 */
          /* synthesis syn_replicate = 0 */;

      (* HU_SET = "stg2_capture", RLOC = "X3Y0", BEL = "CFF" *)
      FDC_1 u_ff_stg2b_rise
        (
         .D   (stg1_out_rise_0m),
         .Q   (stg2b_out_rise),
         .C   (clk0),
         .CLR (1'b0)
         )/* synthesis syn_preserve = 1 */
          /* synthesis syn_replicate = 0 */;

      //*********************************************************
      // Dummy logic. See comments at beginning of generate statement
      //*********************************************************

      (* HU_SET = "stg2_capture", RLOC = "X2Y0", syn_noprune = 1 *)
      CARRY4 u_dummy_carry_stg2a
        (
         .CO     (dummy_carry4_co_a),
         .O      (),
         .CI     (1'b0),
         .CYINIT (1'b0),
         .DI     (dummy_lut_o5_a),
         .S      (dummy_lut_o6_a)
         );
      (* HU_SET = "stg2_capture", RLOC = "X2Y0", BEL = "A6LUT",
         syn_noprune = 1 *)
      LUT6_2 #
        (
         .INIT (64'h0000000000000000)
         )
        u_dummy_lut_stg2a_a
          (
           .O5 (dummy_lut_o5_a[0]),
           .O6 (dummy_lut_o6_a[0]),
           .I0 (),
           .I1 (),
           .I2 (),
           .I3 (),
           .I4 (),
           .I5 ()
           );
      (* HU_SET = "stg2_capture", RLOC = "X2Y0", BEL = "B6LUT",
         syn_noprune = 1 *)
      LUT6_2 #
        (
         .INIT (64'h0000000000000000)
         )
        u_dummy_lut_stg2a_b
          (
           .O5 (dummy_lut_o5_a[1]),
           .O6 (dummy_lut_o6_a[1]),
           .I0 (),
           .I1 (),
           .I2 (),
           .I3 (),
           .I4 (),
           .I5 ()
           );
      (* HU_SET = "stg2_capture", RLOC = "X2Y0", BEL = "C6LUT",
         syn_noprune = 1 *)
      LUT6_2 #
        (
         .INIT (64'h0000000000000000)
         )
        u_dummy_lut_stg2a_c
          (
           .O5 (dummy_lut_o5_a[2]),
           .O6 (dummy_lut_o6_a[2]),
           .I0 (),
           .I1 (),
           .I2 (),
           .I3 (),
           .I4 (),
           .I5 ()
           );
      (* HU_SET = "stg2_capture", RLOC = "X2Y0", BEL = "D6LUT",
         syn_noprune = 1 *)
      LUT6_2 #
        (
         .INIT (64'h0000000000000000)
         )
        u_dummy_lut_stg2a_d
          (
           .O5 (dummy_lut_o5_a[3]),
           .O6 (dummy_lut_o6_a[3]),
           .I0 (),
           .I1 (),
           .I2 (),
           .I3 (),
           .I4 (),
           .I5 ()
           );

      (* HU_SET = "stg2_capture", RLOC = "X3Y0", syn_noprune = 1 *)
      CARRY4 u_dummy_carry_stg2b
        (
         .CO     (dummy_carry4_co_b),
         .O      (),
         .CI     (1'b0),
         .CYINIT (1'b0),
         .DI     (dummy_lut_o5_b),
         .S      (dummy_lut_o6_b)
         );
      (* HU_SET = "stg2_capture", RLOC = "X3Y0", BEL = "A6LUT",
         syn_noprune = 1 *)
      LUT6_2 #
        (
         .INIT (64'h0000000000000000)
         )
        u_dummy_lut_stg2b_a
          (
           .O5 (dummy_lut_o5_b[0]),
           .O6 (dummy_lut_o6_b[0]),
           .I0 (),
           .I1 (),
           .I2 (),
           .I3 (),
           .I4 (),
           .I5 ()
           );
      (* HU_SET = "stg2_capture", RLOC = "X3Y0", BEL = "B6LUT",
         syn_noprune = 1 *)
      LUT6_2 #
        (
         .INIT (64'h0000000000000000)
         )
        u_dummy_lut_stg2b_b
          (
           .O5 (dummy_lut_o5_b[1]),
           .O6 (dummy_lut_o6_b[1]),
           .I0 (),
           .I1 (),
           .I2 (),
           .I3 (),
           .I4 (),
           .I5 ()
           );
      (* HU_SET = "stg2_capture", RLOC = "X3Y0", BEL = "C6LUT",
         syn_noprune = 1 *)
      LUT6_2 #
        (
         .INIT (64'h0000000000000000)
         )
        u_dummy_lut_stg2b_c
          (
           .O5 (dummy_lut_o5_b[2]),
           .O6 (dummy_lut_o6_b[2]),
           .I0 (),
           .I1 (),
           .I2 (),
           .I3 (),
           .I4 (),
           .I5 ()
           );
      (* HU_SET = "stg2_capture", RLOC = "X3Y0", BEL = "D6LUT",
         syn_noprune = 1 *)
      LUT6_2 #
        (
         .INIT (64'h0000000000000000)
         )
        u_dummy_lut_stg2b_d
          (
           .O5 (dummy_lut_o5_b[3]),
           .O6 (dummy_lut_o6_b[3]),
           .I0 (),
           .I1 (),
           .I2 (),
           .I3 (),
           .I4 (),
           .I5 ()
           );

    end else if ((DQ_MS == 0) && (DQ_COL == 0)) begin: gen_stg2_0s

      //*****************************************************************
      // slave, left
      //*****************************************************************

      IDDR #
        (
         .DDR_CLK_EDGE ("SAME_EDGE")
         )
        u_iddr_dq
          (
           .Q1 (stg1_out_fall_0s),
           .Q2 (stg1_out_rise_0s),
           .C  (dq_iddr_clk),
           .CE (ce),
           .D  (dq_idelay),
           .R  (1'b0),
           .S  (1'b0)
           );

      (* HU_SET = "stg2_capture", RLOC = "X0Y0", BEL = "BFF" *)
      FDC u_ff_stg2a_fall
        (
         .D   (stg1_out_fall_0s),
         .Q   (stg2a_out_fall),
         .C   (clk0),
         .CLR (1'b0)
         )/* synthesis syn_preserve = 1 */
          /* synthesis syn_replicate = 0 */;
      (* HU_SET = "stg2_capture", RLOC = "X0Y0", BEL = "CFF" *)
      FDC u_ff_stg2a_rise
        (
         .D   (stg1_out_rise_0s),
         .Q   (stg2a_out_rise),
         .C   (clk0),
         .CLR (1'b0)
         )/* synthesis syn_preserve = 1 */
          /* synthesis syn_replicate = 0 */;

      (* HU_SET = "stg2_capture", RLOC = "X0Y0", BEL = "DFF" *)
      FDC u_ff_stg3b_fall
        (
         .D   (stg2b_out_fall),
         .Q   (stg3b_out_fall),
         .C   (clk0),
         .CLR (1'b0)
         )/* synthesis syn_preserve = 1 */
          /* synthesis syn_replicate = 0 */;
      (* HU_SET = "stg2_capture", RLOC = "X0Y0", BEL = "AFF" *)
      FDC u_ff_stg3b_rise
        (
         .D   (stg2b_out_rise),
         .Q   (stg3b_out_rise),
         .C   (clk0),
         .CLR (1'b0)
         )/* synthesis syn_preserve = 1 */
          /* synthesis syn_replicate = 0 */;

      (* HU_SET = "stg2_capture", RLOC = "X1Y0", BEL = "AFF" *)
      FDC_1 u_ff_stg2b_fall
        (
         .D   (stg1_out_fall_0s),
         .Q   (stg2b_out_fall),
         .C   (clk0),
         .CLR (1'b0)
         )/* synthesis syn_preserve = 1 */
          /* synthesis syn_replicate = 0 */;
      (* HU_SET = "stg2_capture", RLOC = "X1Y0", BEL = "CFF" *)
      FDC_1 u_ff_stg2b_rise
        (
         .D   (stg1_out_rise_0s),
         .Q   (stg2b_out_rise),
         .C   (clk0),
         .CLR (1'b0)
         )/* synthesis syn_preserve = 1 */
          /* synthesis syn_replicate = 0 */;

      (* HU_SET = "stg2_capture", RLOC = "X0Y0", syn_noprune = 1 *)
      CARRY4 u_dummy_carry_stg2a
        (
         .CO     (dummy_carry4_co_a),
         .O      (),
         .CI     (1'b0),
         .CYINIT (1'b0),
         .DI     (dummy_lut_o5_a),
         .S      (dummy_lut_o6_a)
         );
      (* HU_SET = "stg2_capture", RLOC = "X0Y0", BEL = "A6LUT",
         syn_noprune = 1 *)
      LUT6_2 #
        (
         .INIT (64'h0000000000000000)
         )
        u_dummy_lut_stg2a_a
          (
           .O5 (dummy_lut_o5_a[0]),
           .O6 (dummy_lut_o6_a[0]),
           .I0 (),
           .I1 (),
           .I2 (),
           .I3 (),
           .I4 (),
           .I5 ()
           );
      (* HU_SET = "stg2_capture", RLOC = "X0Y0", BEL = "B6LUT",
         syn_noprune = 1 *)
      LUT6_2 #
        (
         .INIT (64'h0000000000000000)
         )
        u_dummy_lut_stg2a_b
          (
           .O5 (dummy_lut_o5_a[1]),
           .O6 (dummy_lut_o6_a[1]),
           .I0 (),
           .I1 (),
           .I2 (),
           .I3 (),
           .I4 (),
           .I5 ()
           );
      (* HU_SET = "stg2_capture", RLOC = "X0Y0", BEL = "C6LUT",
         syn_noprune = 1 *)
      LUT6_2 #
        (
         .INIT (64'h0000000000000000)
         )
        u_dummy_lut_stg2a_c
          (
           .O5 (dummy_lut_o5_a[2]),
           .O6 (dummy_lut_o6_a[2]),
           .I0 (),
           .I1 (),
           .I2 (),
           .I3 (),
           .I4 (),
           .I5 ()
           );
      (* HU_SET = "stg2_capture", RLOC = "X0Y0", BEL = "D6LUT",
         syn_noprune = 1 *)
      LUT6_2 #
        (
         .INIT (64'h0000000000000000)
         )
        u_dummy_lut_stg2a_d
          (
           .O5 (dummy_lut_o5_a[3]),
           .O6 (dummy_lut_o6_a[3]),
           .I0 (),
           .I1 (),
           .I2 (),
           .I3 (),
           .I4 (),
           .I5 ()
           );

      (* HU_SET = "stg2_capture", RLOC = "X1Y0", syn_noprune = 1 *)
      CARRY4 u_dummy_carry_stg2b
        (
         .CO     (dummy_carry4_co_b),
         .O      (),
         .CI     (1'b0),
         .CYINIT (1'b0),
         .DI     (dummy_lut_o5_b),
         .S      (dummy_lut_o6_b)
         );
      (* HU_SET = "stg2_capture", RLOC = "X1Y0", BEL = "A6LUT",
         syn_noprune = 1 *)
      LUT6_2 #
        (
         .INIT (64'h0000000000000000)
         )
        u_dummy_lut_stg2b_a
          (
           .O5 (dummy_lut_o5_b[0]),
           .O6 (dummy_lut_o6_b[0]),
           .I0 (),
           .I1 (),
           .I2 (),
           .I3 (),
           .I4 (),
           .I5 ()
           );
      (* HU_SET = "stg2_capture", RLOC = "X1Y0", BEL = "B6LUT",
         syn_noprune = 1 *)
      LUT6_2 #
        (
         .INIT (64'h0000000000000000)
         )
        u_dummy_lut_stg2b_b
          (
           .O5 (dummy_lut_o5_b[1]),
           .O6 (dummy_lut_o6_b[1]),
           .I0 (),
           .I1 (),
           .I2 (),
           .I3 (),
           .I4 (),
           .I5 ()
           );
      (* HU_SET = "stg2_capture", RLOC = "X1Y0", BEL = "C6LUT",
         syn_noprune = 1 *)
      LUT6_2 #
        (
         .INIT (64'h0000000000000000)
         )
        u_dummy_lut_stg2b_c
          (
           .O5 (dummy_lut_o5_b[2]),
           .O6 (dummy_lut_o6_b[2]),
           .I0 (),
           .I1 (),
           .I2 (),
           .I3 (),
           .I4 (),
           .I5 ()
           );
      (* HU_SET = "stg2_capture", RLOC = "X1Y0", BEL = "D6LUT",
         syn_noprune = 1 *)
      LUT6_2 #
        (
         .INIT (64'h0000000000000000)
         )
        u_dummy_lut_stg2b_d
          (
           .O5 (dummy_lut_o5_b[3]),
           .O6 (dummy_lut_o6_b[3]),
           .I0 (),
           .I1 (),
           .I2 (),
           .I3 (),
           .I4 (),
           .I5 ()
           );

    end else if ((DQ_MS == 1) && (DQ_COL == 1))  begin: gen_stg2_1m

      //*****************************************************************
      // master, center
      //*****************************************************************

      IDDR #
        (
         .DDR_CLK_EDGE ("SAME_EDGE")
         )
        u_iddr_dq
          (
           .Q1 (stg1_out_fall_1m),
           .Q2 (stg1_out_rise_1m),
           .C  (dq_iddr_clk),
           .CE (ce),
           .D  (dq_idelay),
           .R  (1'b0),
           .S  (1'b0)
           );

      (* HU_SET = "stg2_capture", RLOC = "X0Y0", BEL = "BFF" *)
      FDC u_ff_stg2a_fall
        (
         .D   (stg1_out_fall_1m),
         .Q   (stg2a_out_fall),
         .C   (clk0),
         .CLR (1'b0)
         )/* synthesis syn_preserve = 1 */
          /* synthesis syn_replicate = 0 */;
      (* HU_SET = "stg2_capture", RLOC = "X0Y0", BEL = "AFF" *)
      FDC u_ff_stg2a_rise
        (
         .D   (stg1_out_rise_1m),
         .Q   (stg2a_out_rise),
         .C   (clk0),
         .CLR (1'b0)
         )/* synthesis syn_preserve = 1 */
          /* synthesis syn_replicate = 0 */;

      (* HU_SET = "stg2_capture", RLOC = "X0Y0", BEL = "DFF" *)
      FDC u_ff_stg3b_fall
        (
         .D   (stg2b_out_fall),
         .Q   (stg3b_out_fall),
         .C   (clk0),
         .CLR (1'b0)
         )/* synthesis syn_preserve = 1 */
          /* synthesis syn_replicate = 0 */;
      (* HU_SET = "stg2_capture", RLOC = "X0Y0", BEL = "CFF" *)
      FDC u_ff_stg3b_rise
        (
         .D   (stg2b_out_rise),
         .Q   (stg3b_out_rise),
         .C   (clk0),
         .CLR (1'b0)
         )/* synthesis syn_preserve = 1 */
          /* synthesis syn_replicate = 0 */;

      (* HU_SET = "stg2_capture", RLOC = "X1Y0", BEL = "AFF" *)
      FDC_1 u_ff_stg2b_fall
        (
         .D   (stg1_out_fall_1m),
         .Q   (stg2b_out_fall),
         .C   (clk0),
         .CLR (1'b0)
         )/* synthesis syn_preserve = 1 */
          /* synthesis syn_replicate = 0 */;
      (* HU_SET = "stg2_capture", RLOC = "X1Y0", BEL = "BFF" *)
      FDC_1 u_ff_stg2b_rise
        (
         .D   (stg1_out_rise_1m),
         .Q   (stg2b_out_rise),
         .C   (clk0),
         .CLR (1'b0)
         )/* synthesis syn_preserve = 1 */
          /* synthesis syn_replicate = 0 */;

      (* HU_SET = "stg2_capture", RLOC = "X0Y0", syn_noprune = 1 *)
      CARRY4 u_dummy_carry_stg2a
        (
         .CO     (dummy_carry4_co_a),
         .O      (),
         .CI     (1'b0),
         .CYINIT (1'b0),
         .DI     (dummy_lut_o5_a),
         .S      (dummy_lut_o6_a)
         );
      (* HU_SET = "stg2_capture", RLOC = "X0Y0", BEL = "A6LUT",
         syn_noprune = 1 *)
      LUT6_2 #
        (
         .INIT (64'h0000000000000000)
         )
        u_dummy_lut_stg2a_a
          (
           .O5 (dummy_lut_o5_a[0]),
           .O6 (dummy_lut_o6_a[0]),
           .I0 (),
           .I1 (),
           .I2 (),
           .I3 (),
           .I4 (),
           .I5 ()
           );
      (* HU_SET = "stg2_capture", RLOC = "X0Y0", BEL = "B6LUT",
         syn_noprune = 1 *)
      LUT6_2 #
        (
         .INIT (64'h0000000000000000)
         )
        u_dummy_lut_stg2a_b
          (
           .O5 (dummy_lut_o5_a[1]),
           .O6 (dummy_lut_o6_a[1]),
           .I0 (),
           .I1 (),
           .I2 (),
           .I3 (),
           .I4 (),
           .I5 ()
           );
      (* HU_SET = "stg2_capture", RLOC = "X0Y0", BEL = "C6LUT",
         syn_noprune = 1 *)
      LUT6_2 #
        (
         .INIT (64'h0000000000000000)
         )
        u_dummy_lut_stg2a_c
          (
           .O5 (dummy_lut_o5_a[2]),
           .O6 (dummy_lut_o6_a[2]),
           .I0 (),
           .I1 (),
           .I2 (),
           .I3 (),
           .I4 (),
           .I5 ()
           );
      (* HU_SET = "stg2_capture", RLOC = "X0Y0", BEL = "D6LUT",
         syn_noprune = 1 *)
      LUT6_2 #
        (
         .INIT (64'h0000000000000000)
         )
        u_dummy_lut_stg2a_d
          (
           .O5 (dummy_lut_o5_a[3]),
           .O6 (dummy_lut_o6_a[3]),
           .I0 (),
           .I1 (),
           .I2 (),
           .I3 (),
           .I4 (),
           .I5 ()
           );

      (* HU_SET = "stg2_capture", RLOC = "X1Y0", syn_noprune = 1 *)
      CARRY4 u_dummy_carry_stg2b
        (
         .CO     (dummy_carry4_co_b),
         .O      (),
         .CI     (1'b0),
         .CYINIT (1'b0),
         .DI     (dummy_lut_o5_b),
         .S      (dummy_lut_o6_b)
         );
      (* HU_SET = "stg2_capture", RLOC = "X1Y0", BEL = "A6LUT",
         syn_noprune = 1 *)
      LUT6_2 #
        (
         .INIT (64'h0000000000000000)
         )
        u_dummy_lut_stg2b_a
          (
           .O5 (dummy_lut_o5_b[0]),
           .O6 (dummy_lut_o6_b[0]),
           .I0 (),
           .I1 (),
           .I2 (),
           .I3 (),
           .I4 (),
           .I5 ()
           );
      (* HU_SET = "stg2_capture", RLOC = "X1Y0", BEL = "B6LUT",
         syn_noprune = 1 *)
      LUT6_2 #
        (
         .INIT (64'h0000000000000000)
         )
        u_dummy_lut_stg2b_b
          (
           .O5 (dummy_lut_o5_b[1]),
           .O6 (dummy_lut_o6_b[1]),
           .I0 (),
           .I1 (),
           .I2 (),
           .I3 (),
           .I4 (),
           .I5 ()
           );
      (* HU_SET = "stg2_capture", RLOC = "X1Y0", BEL = "C6LUT",
         syn_noprune = 1 *)
      LUT6_2 #
        (
         .INIT (64'h0000000000000000)
         )
        u_dummy_lut_stg2b_c
          (
           .O5 (dummy_lut_o5_b[2]),
           .O6 (dummy_lut_o6_b[2]),
           .I0 (),
           .I1 (),
           .I2 (),
           .I3 (),
           .I4 (),
           .I5 ()
           );
      (* HU_SET = "stg2_capture", RLOC = "X1Y0", BEL = "D6LUT",
         syn_noprune = 1 *)
      LUT6_2 #
        (
         .INIT (64'h0000000000000000)
         )
        u_dummy_lut_stg2b_d
          (
           .O5 (dummy_lut_o5_b[3]),
           .O6 (dummy_lut_o6_b[3]),
           .I0 (),
           .I1 (),
           .I2 (),
           .I3 (),
           .I4 (),
           .I5 ()
           );

    end else if ((DQ_MS == 0) && (DQ_COL == 1)) begin: gen_stg2_1s

      //*****************************************************************
      // slave, center
      //*****************************************************************

      IDDR #
        (
         .DDR_CLK_EDGE ("SAME_EDGE")
         )
        u_iddr_dq
          (
           .Q1 (stg1_out_fall_1s),
           .Q2 (stg1_out_rise_1s),
           .C  (dq_iddr_clk),
           .CE (ce),
           .D  (dq_idelay),
           .R  (1'b0),
           .S  (1'b0)
           );

      (* HU_SET = "stg2_capture", RLOC = "X2Y0", BEL = "CFF" *)
      FDC u_ff_stg2a_fall
        (
         .D   (stg1_out_fall_1s),
         .Q   (stg2a_out_fall),
         .C   (clk0),
         .CLR (1'b0)
         )/* synthesis syn_preserve = 1 */
          /* synthesis syn_replicate = 0 */;
      (* HU_SET = "stg2_capture", RLOC = "X2Y0", BEL = "BFF" *)
      FDC u_ff_stg2a_rise
        (
         .D   (stg1_out_rise_1s),
         .Q   (stg2a_out_rise),
         .C   (clk0),
         .CLR (1'b0)
         )/* synthesis syn_preserve = 1 */
          /* synthesis syn_replicate = 0 */;

      (* HU_SET = "stg2_capture", RLOC = "X2Y0", BEL = "DFF" *)
      FDC u_ff_stg3b_fall
        (
         .D   (stg2b_out_fall),
         .Q   (stg3b_out_fall),
         .C   (clk0),
         .CLR (1'b0)
         )/* synthesis syn_preserve = 1 */
          /* synthesis syn_replicate = 0 */;
      (* HU_SET = "stg2_capture", RLOC = "X2Y0", BEL = "AFF" *)
      FDC u_ff_stg3b_rise
        (
         .D   (stg2b_out_rise),
         .Q   (stg3b_out_rise),
         .C   (clk0),
         .CLR (1'b0)
         )/* synthesis syn_preserve = 1 */
          /* synthesis syn_replicate = 0 */;

      (* HU_SET = "stg2_capture", RLOC = "X3Y0", BEL = "CFF" *)
      FDC_1 u_ff_stg2b_fall
        (
         .D   (stg1_out_fall_1s),
         .Q   (stg2b_out_fall),
         .C   (clk0),
         .CLR (1'b0)
         )/* synthesis syn_preserve = 1 */
          /* synthesis syn_replicate = 0 */;
      (* HU_SET = "stg2_capture", RLOC = "X3Y0", BEL = "BFF" *)
      FDC_1 u_ff_stg2b_rise
        (
         .D   (stg1_out_rise_1s),
         .Q   (stg2b_out_rise),
         .C   (clk0),
         .CLR (1'b0)
         )/* synthesis syn_preserve = 1 */
          /* synthesis syn_replicate = 0 */;

      (* HU_SET = "stg2_capture", RLOC = "X2Y0", syn_noprune = 1 *)
      CARRY4 u_dummy_carry_stg2a
        (
         .CO     (dummy_carry4_co_a),
         .O      (),
         .CI     (1'b0),
         .CYINIT (1'b0),
         .DI     (dummy_lut_o5_a),
         .S      (dummy_lut_o6_a)
         );
      (* HU_SET = "stg2_capture", RLOC = "X2Y0", BEL = "A6LUT",
         syn_noprune = 1 *)
      LUT6_2 #
        (
         .INIT (64'h0000000000000000)
         )
        u_dummy_lut_stg2a_a
          (
           .O5 (dummy_lut_o5_a[0]),
           .O6 (dummy_lut_o6_a[0]),
           .I0 (),
           .I1 (),
           .I2 (),
           .I3 (),
           .I4 (),
           .I5 ()
           );
      (* HU_SET = "stg2_capture", RLOC = "X2Y0", BEL = "B6LUT",
         syn_noprune = 1 *)
      LUT6_2 #
        (
         .INIT (64'h0000000000000000)
         )
        u_dummy_lut_stg2a_b
          (
           .O5 (dummy_lut_o5_a[1]),
           .O6 (dummy_lut_o6_a[1]),
           .I0 (),
           .I1 (),
           .I2 (),
           .I3 (),
           .I4 (),
           .I5 ()
           );
      (* HU_SET = "stg2_capture", RLOC = "X2Y0", BEL = "C6LUT",
         syn_noprune = 1 *)
      LUT6_2 #
        (
         .INIT (64'h0000000000000000)
         )
        u_dummy_lut_stg2a_c
          (
           .O5 (dummy_lut_o5_a[2]),
           .O6 (dummy_lut_o6_a[2]),
           .I0 (),
           .I1 (),
           .I2 (),
           .I3 (),
           .I4 (),
           .I5 ()
           );
      (* HU_SET = "stg2_capture", RLOC = "X2Y0", BEL = "D6LUT",
         syn_noprune = 1 *)
      LUT6_2 #
        (
         .INIT (64'h0000000000000000)
         )
        u_dummy_lut_stg2a_d
          (
           .O5 (dummy_lut_o5_a[3]),
           .O6 (dummy_lut_o6_a[3]),
           .I0 (),
           .I1 (),
           .I2 (),
           .I3 (),
           .I4 (),
           .I5 ()
           );

      (* HU_SET = "stg2_capture", RLOC = "X3Y0", syn_noprune = 1 *)
      CARRY4 u_dummy_carry_stg2b
        (
         .CO     (dummy_carry4_co_b),
         .O      (),
         .CI     (1'b0),
         .CYINIT (1'b0),
         .DI     (dummy_lut_o5_b),
         .S      (dummy_lut_o6_b)
         );
      (* HU_SET = "stg2_capture", RLOC = "X3Y0", BEL = "A6LUT",
         syn_noprune = 1 *)
      LUT6_2 #
        (
         .INIT (64'h0000000000000000)
         )
        u_dummy_lut_stg2b_a
          (
           .O5 (dummy_lut_o5_b[0]),
           .O6 (dummy_lut_o6_b[0]),
           .I0 (),
           .I1 (),
           .I2 (),
           .I3 (),
           .I4 (),
           .I5 ()
           );
      (* HU_SET = "stg2_capture", RLOC = "X3Y0", BEL = "B6LUT",
         syn_noprune = 1 *)
      LUT6_2 #
        (
         .INIT (64'h0000000000000000)
         )
        u_dummy_lut_stg2b_b
          (
           .O5 (dummy_lut_o5_b[1]),
           .O6 (dummy_lut_o6_b[1]),
           .I0 (),
           .I1 (),
           .I2 (),
           .I3 (),
           .I4 (),
           .I5 ()
           );
      (* HU_SET = "stg2_capture", RLOC = "X3Y0", BEL = "C6LUT",
         syn_noprune = 1 *)
      LUT6_2 #
        (
         .INIT (64'h0000000000000000)
         )
        u_dummy_lut_stg2b_c
          (
           .O5 (dummy_lut_o5_b[2]),
           .O6 (dummy_lut_o6_b[2]),
           .I0 (),
           .I1 (),
           .I2 (),
           .I3 (),
           .I4 (),
           .I5 ()
           );
      (* HU_SET = "stg2_capture", RLOC = "X3Y0", BEL = "D6LUT",
         syn_noprune = 1 *)
      LUT6_2 #
        (
         .INIT (64'h0000000000000000)
         )
        u_dummy_lut_stg2b_d
          (
           .O5 (dummy_lut_o5_b[3]),
           .O6 (dummy_lut_o6_b[3]),
           .I0 (),
           .I1 (),
           .I2 (),
           .I3 (),
           .I4 (),
           .I5 ()
           );

    end else if ((DQ_MS == 1) && (DQ_COL == 2)) begin: gen_stg2_2m

      //*****************************************************************
      // master, right
      //*****************************************************************

      IDDR #
        (
         .DDR_CLK_EDGE ("SAME_EDGE")
         )
        u_iddr_dq
          (
           .Q1 (stg1_out_fall_2m),
           .Q2 (stg1_out_rise_2m),
           .C  (dq_iddr_clk),
           .CE (ce),
           .D  (dq_idelay),
           .R  (1'b0),
           .S  (1'b0)
           );

      (* HU_SET = "stg2_capture", RLOC = "X0Y0", BEL = "AFF" *)
      FDC u_ff_stg2a_fall
        (
         .D   (stg1_out_fall_2m),
         .Q   (stg2a_out_fall),
         .C   (clk0),
         .CLR (1'b0)
         )/* synthesis syn_preserve = 1 */
          /* synthesis syn_replicate = 0 */;
      (* HU_SET = "stg2_capture", RLOC = "X0Y0", BEL = "CFF" *)
      FDC u_ff_stg2a_rise
        (
         .D   (stg1_out_rise_2m),
         .Q   (stg2a_out_rise),
         .C   (clk0),
         .CLR (1'b0)
         )/* synthesis syn_preserve = 1 */
          /* synthesis syn_replicate = 0 */;

      (* HU_SET = "stg2_capture", RLOC = "X0Y0", BEL = "DFF" *)
      FDC u_ff_stg3b_fall
        (
         .D   (stg2b_out_fall),
         .Q   (stg3b_out_fall),
         .C   (clk0),
         .CLR (1'b0)
         )/* synthesis syn_preserve = 1 */
          /* synthesis syn_replicate = 0 */;
      (* HU_SET = "stg2_capture", RLOC = "X0Y0", BEL = "BFF" *)
      FDC u_ff_stg3b_rise
        (
         .D   (stg2b_out_rise),
         .Q   (stg3b_out_rise),
         .C   (clk0),
         .CLR (1'b0)
         )/* synthesis syn_preserve = 1 */
          /* synthesis syn_replicate = 0 */;

      (* HU_SET = "stg2_capture", RLOC = "X1Y0", BEL = "AFF" *)
      FDC_1 u_ff_stg2b_fall
        (
         .D   (stg1_out_fall_2m),
         .Q   (stg2b_out_fall),
         .C   (clk0),
         .CLR (1'b0)
         )/* synthesis syn_preserve = 1 */
          /* synthesis syn_replicate = 0 */;
      (* HU_SET = "stg2_capture", RLOC = "X1Y0", BEL = "CFF" *)
      FDC_1 u_ff_stg2b_rise
        (
         .D   (stg1_out_rise_2m),
         .Q   (stg2b_out_rise),
         .C   (clk0),
         .CLR (1'b0)
         )/* synthesis syn_preserve = 1 */
          /* synthesis syn_replicate = 0 */;

      (* HU_SET = "stg2_capture", RLOC = "X0Y0", syn_noprune = 1 *)
      CARRY4 u_dummy_carry_stg2a
        (
         .CO     (dummy_carry4_co_a),
         .O      (),
         .CI     (1'b0),
         .CYINIT (1'b0),
         .DI     (dummy_lut_o5_a),
         .S      (dummy_lut_o6_a)
         );
      (* HU_SET = "stg2_capture", RLOC = "X0Y0", BEL = "A6LUT",
         syn_noprune = 1 *)
      LUT6_2 #
        (
         .INIT (64'h0000000000000000)
         )
        u_dummy_lut_stg2a_a
          (
           .O5 (dummy_lut_o5_a[0]),
           .O6 (dummy_lut_o6_a[0]),
           .I0 (),
           .I1 (),
           .I2 (),
           .I3 (),
           .I4 (),
           .I5 ()
           );
      (* HU_SET = "stg2_capture", RLOC = "X0Y0", BEL = "B6LUT",
         syn_noprune = 1 *)
      LUT6_2 #
        (
         .INIT (64'h0000000000000000)
         )
        u_dummy_lut_stg2a_b
          (
           .O5 (dummy_lut_o5_a[1]),
           .O6 (dummy_lut_o6_a[1]),
           .I0 (),
           .I1 (),
           .I2 (),
           .I3 (),
           .I4 (),
           .I5 ()
           );
      (* HU_SET = "stg2_capture", RLOC = "X0Y0", BEL = "C6LUT",
         syn_noprune = 1 *)
      LUT6_2 #
        (
         .INIT (64'h0000000000000000)
         )
        u_dummy_lut_stg2a_c
          (
           .O5 (dummy_lut_o5_a[2]),
           .O6 (dummy_lut_o6_a[2]),
           .I0 (),
           .I1 (),
           .I2 (),
           .I3 (),
           .I4 (),
           .I5 ()
           );
      (* HU_SET = "stg2_capture", RLOC = "X0Y0", BEL = "D6LUT",
         syn_noprune = 1 *)
      LUT6_2 #
        (
         .INIT (64'h0000000000000000)
         )
        u_dummy_lut_stg2a_d
          (
           .O5 (dummy_lut_o5_a[3]),
           .O6 (dummy_lut_o6_a[3]),
           .I0 (),
           .I1 (),
           .I2 (),
           .I3 (),
           .I4 (),
           .I5 ()
           );

      (* HU_SET = "stg2_capture", RLOC = "X1Y0", syn_noprune = 1 *)
      CARRY4 u_dummy_carry_stg2b
        (
         .CO     (dummy_carry4_co_b),
         .O      (),
         .CI     (1'b0),
         .CYINIT (1'b0),
         .DI     (dummy_lut_o5_b),
         .S      (dummy_lut_o6_b)
         );
      (* HU_SET = "stg2_capture", RLOC = "X1Y0", BEL = "A6LUT",
         syn_noprune = 1 *)
      LUT6_2 #
        (
         .INIT (64'h0000000000000000)
         )
        u_dummy_lut_stg2b_a
          (
           .O5 (dummy_lut_o5_b[0]),
           .O6 (dummy_lut_o6_b[0]),
           .I0 (),
           .I1 (),
           .I2 (),
           .I3 (),
           .I4 (),
           .I5 ()
           );
      (* HU_SET = "stg2_capture", RLOC = "X1Y0", BEL = "B6LUT",
         syn_noprune = 1 *)
      LUT6_2 #
        (
         .INIT (64'h0000000000000000)
         )
        u_dummy_lut_stg2b_b
          (
           .O5 (dummy_lut_o5_b[1]),
           .O6 (dummy_lut_o6_b[1]),
           .I0 (),
           .I1 (),
           .I2 (),
           .I3 (),
           .I4 (),
           .I5 ()
           );
      (* HU_SET = "stg2_capture", RLOC = "X1Y0", BEL = "C6LUT",
         syn_noprune = 1 *)
      LUT6_2 #
        (
         .INIT (64'h0000000000000000)
         )
        u_dummy_lut_stg2b_c
          (
           .O5 (dummy_lut_o5_b[2]),
           .O6 (dummy_lut_o6_b[2]),
           .I0 (),
           .I1 (),
           .I2 (),
           .I3 (),
           .I4 (),
           .I5 ()
           );
      (* HU_SET = "stg2_capture", RLOC = "X1Y0", BEL = "D6LUT",
         syn_noprune = 1 *)
      LUT6_2 #
        (
         .INIT (64'h0000000000000000)
         )
        u_dummy_lut_stg2b_d
          (
           .O5 (dummy_lut_o5_b[3]),
           .O6 (dummy_lut_o6_b[3]),
           .I0 (),
           .I1 (),
           .I2 (),
           .I3 (),
           .I4 (),
           .I5 ()
           );

    end else if ((DQ_MS == 0) && (DQ_COL == 2)) begin: gen_stg2_2s

      //*****************************************************************
      // slave, right
      //*****************************************************************

      IDDR #
        (
         .DDR_CLK_EDGE ("SAME_EDGE")
         )
        u_iddr_dq
          (
           .Q1 (stg1_out_fall_2s),
           .Q2 (stg1_out_rise_2s),
           .C  (dq_iddr_clk),
           .CE (ce),
           .D  (dq_idelay),
           .R  (1'b0),
           .S  (1'b0)
           );

      (* HU_SET = "stg2_capture", RLOC = "X2Y0", BEL = "BFF" *)
      FDC u_ff_stg2a_fall
        (
         .D   (stg1_out_fall_2s),
         .Q   (stg2a_out_fall),
         .C   (clk0),
         .CLR (1'b0)
         )/* synthesis syn_preserve = 1 */
          /* synthesis syn_replicate = 0 */;
      (* HU_SET = "stg2_capture", RLOC = "X2Y0", BEL = "DFF" *)
      FDC u_ff_stg2a_rise
        (
         .D   (stg1_out_rise_2s),
         .Q   (stg2a_out_rise),
         .C   (clk0),
         .CLR (1'b0)
         )/* synthesis syn_preserve = 1 */
          /* synthesis syn_replicate = 0 */;
      (* HU_SET = "stg2_capture", RLOC = "X2Y0", BEL = "CFF" *)
      FDC u_ff_stg3b_fall
        (
         .D   (stg2b_out_fall),
         .Q   (stg3b_out_fall),
         .C   (clk0),
         .CLR (1'b0)
         )/* synthesis syn_preserve = 1 */
          /* synthesis syn_replicate = 0 */;
      (* HU_SET = "stg2_capture", RLOC = "X2Y0", BEL = "AFF" *)
      FDC u_ff_stg3b_rise
        (
         .D   (stg2b_out_rise),
         .Q   (stg3b_out_rise),
         .C   (clk0),
         .CLR (1'b0)
         )/* synthesis syn_preserve = 1 */
          /* synthesis syn_replicate = 0 */;

      (* HU_SET = "stg2_capture", RLOC = "X3Y0", BEL = "AFF" *)
      FDC_1 u_ff_stg2b_fall
        (
         .D   (stg1_out_fall_2s),
         .Q   (stg2b_out_fall),
         .C   (clk0),
         .CLR (1'b0)
         )/* synthesis syn_preserve = 1 */
          /* synthesis syn_replicate = 0 */;
      (* HU_SET = "stg2_capture", RLOC = "X3Y0", BEL = "CFF" *)
      FDC_1 u_ff_stg2b_rise
        (
         .D   (stg1_out_rise_2s),
         .Q   (stg2b_out_rise),
         .C   (clk0),
         .CLR (1'b0)
         )/* synthesis syn_preserve = 1 */
          /* synthesis syn_replicate = 0 */;

      (* HU_SET = "stg2_capture", RLOC = "X2Y0", syn_noprune = 1 *)
      CARRY4 u_dummy_carry_stg2a
        (
         .CO     (dummy_carry4_co_a),
         .O      (),
         .CI     (1'b0),
         .CYINIT (1'b0),
         .DI     (dummy_lut_o5_a),
         .S      (dummy_lut_o6_a)
         );
      (* HU_SET = "stg2_capture", RLOC = "X2Y0", BEL = "A6LUT",
         syn_noprune = 1 *)
      LUT6_2 #
        (
         .INIT (64'h0000000000000000)
         )
        u_dummy_lut_stg2a_a
          (
           .O5 (dummy_lut_o5_a[0]),
           .O6 (dummy_lut_o6_a[0]),
           .I0 (),
           .I1 (),
           .I2 (),
           .I3 (),
           .I4 (),
           .I5 ()
           );
      (* HU_SET = "stg2_capture", RLOC = "X2Y0", BEL = "B6LUT",
         syn_noprune = 1 *)
      LUT6_2 #
        (
         .INIT (64'h0000000000000000)
         )
        u_dummy_lut_stg2a_b
          (
           .O5 (dummy_lut_o5_a[1]),
           .O6 (dummy_lut_o6_a[1]),
           .I0 (),
           .I1 (),
           .I2 (),
           .I3 (),
           .I4 (),
           .I5 ()
           );
      (* HU_SET = "stg2_capture", RLOC = "X2Y0", BEL = "C6LUT",
         syn_noprune = 1 *)
      LUT6_2 #
        (
         .INIT (64'h0000000000000000)
         )
        u_dummy_lut_stg2a_c
          (
           .O5 (dummy_lut_o5_a[2]),
           .O6 (dummy_lut_o6_a[2]),
           .I0 (),
           .I1 (),
           .I2 (),
           .I3 (),
           .I4 (),
           .I5 ()
           );
      (* HU_SET = "stg2_capture", RLOC = "X2Y0", BEL = "D6LUT",
         syn_noprune = 1 *)
      LUT6_2 #
        (
         .INIT (64'h0000000000000000)
         )
        u_dummy_lut_stg2a_d
          (
           .O5 (dummy_lut_o5_a[3]),
           .O6 (dummy_lut_o6_a[3]),
           .I0 (),
           .I1 (),
           .I2 (),
           .I3 (),
           .I4 (),
           .I5 ()
           );

      (* HU_SET = "stg2_capture", RLOC = "X3Y0", syn_noprune = 1 *)
      CARRY4 u_dummy_carry_stg2b
        (
         .CO     (dummy_carry4_co_b),
         .O      (),
         .CI     (1'b0),
         .CYINIT (1'b0),
         .DI     (dummy_lut_o5_b),
         .S      (dummy_lut_o6_b)
         );
      (* HU_SET = "stg2_capture", RLOC = "X3Y0", BEL = "A6LUT",
         syn_noprune = 1 *)
      LUT6_2 #
        (
         .INIT (64'h0000000000000000)
         )
        u_dummy_lut_stg2b_a
          (
           .O5 (dummy_lut_o5_b[0]),
           .O6 (dummy_lut_o6_b[0]),
           .I0 (),
           .I1 (),
           .I2 (),
           .I3 (),
           .I4 (),
           .I5 ()
           );
      (* HU_SET = "stg2_capture", RLOC = "X3Y0", BEL = "B6LUT",
         syn_noprune = 1 *)
      LUT6_2 #
        (
         .INIT (64'h0000000000000000)
         )
        u_dummy_lut_stg2b_b
          (
           .O5 (dummy_lut_o5_b[1]),
           .O6 (dummy_lut_o6_b[1]),
           .I0 (),
           .I1 (),
           .I2 (),
           .I3 (),
           .I4 (),
           .I5 ()
           );
      (* HU_SET = "stg2_capture", RLOC = "X3Y0", BEL = "C6LUT",
         syn_noprune = 1 *)
      LUT6_2 #
        (
         .INIT (64'h0000000000000000)
         )
        u_dummy_lut_stg2b_c
          (
           .O5 (dummy_lut_o5_b[2]),
           .O6 (dummy_lut_o6_b[2]),
           .I0 (),
           .I1 (),
           .I2 (),
           .I3 (),
           .I4 (),
           .I5 ()
           );
      (* HU_SET = "stg2_capture", RLOC = "X3Y0", BEL = "D6LUT",
         syn_noprune = 1 *)
      LUT6_2 #
        (
         .INIT (64'h0000000000000000)
         )
        u_dummy_lut_stg2b_d
          (
           .O5 (dummy_lut_o5_b[3]),
           .O6 (dummy_lut_o6_b[3]),
           .I0 (),
           .I1 (),
           .I2 (),
           .I3 (),
           .I4 (),
           .I5 ()
           );

    end
  endgenerate

  //***************************************************************************
  // Second stage flops clocked by posedge CLK0 don't need another layer of
  // registering
  //***************************************************************************

  assign stg3a_out_rise = stg2a_out_rise;
  assign stg3a_out_fall = stg2a_out_fall;

  //*******************************************************************

  assign rd_data_rise = (rd_data_sel) ? stg3a_out_rise : stg3b_out_rise;
  assign rd_data_fall = (rd_data_sel) ? stg3a_out_fall : stg3b_out_fall;

endmodule