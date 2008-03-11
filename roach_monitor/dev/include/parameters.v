`ifndef PARAMETERS_V
`define PARAMETERS_V

`include "memlayout.v"

/************* GENERIC Parameters ***************/
`define BOARD_ID 16'h00_00
`define MASTER_CLOCK_RATE 40_000_000

/********** WishbBone Masters' Interface Parameters *********/
`define ENABLE_DEBUG_INTERFACE
//`define ENABLE_XPORT_INTERFACE
//`define ENABLE_CONTROLLER_INTERFACE
//`define ENABLE_DMA_ENGINE

`define XPORT_SERIAL_BAUD 115200
`define DEBUG_SERIAL_BAUD 115200

`define I2C_CLOCK_RATE    100_000
`define I2C_SLAVE_ADDRESS 7'b0001111

/********** WB Timeout Values ***********/

/*
  timeout format :
  timeout in cycles [20 bits],
  high address [16 bits],
  low address  [16 bits]
*/

`define TO_CONF_0 {20'h7_ff_ff, 16'hff_ff, 16'h0400}
`define TO_CONF_1 {20'h7_ff_ff, 16'hff_ff, 16'h0400}
`define TO_DEFAULT 20'd20

/********* Memory Protection ************/

/*
  memory restriction format :
  wbm mask       [3 bits] (which wb masters do the restriction apply to {controller, xport, debug}),
  high address   [16 bits],
  low address    [16 bits],
  read disallow  [1  bit],
  write disallow [1  bit]
*/

`define MEM_RESTRICTION_0 {4'b0110, `MEM_ACM_H, `MEM_ACM_A, 1'b0, 1'b1}
`define MEM_RESTRICTION_1 {4'b0110, `MEM_ACM_H, `MEM_ACM_A, 1'b0, 1'b1}
`define MEM_RESTRICTION_2 {4'b0110, `MEM_ACM_H, `MEM_ACM_A, 1'b0, 1'b1}


`endif
