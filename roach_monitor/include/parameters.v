`ifndef PARAMETERS_V
`define PARAMETERS_V

`include "memlayout.v"


/************* GENERIC Parameters ***************/
`define BOARD_ID           16'hbe_ef
`define MASTER_CLOCK_RATE  33_333_333

/********** WishbBone Masters' Interface Parameters *********/
//`define ENABLE_DEBUG_INTERFACE
`define ENABLE_XPORT_INTERFACE
`define ENABLE_CONTROLLER_INTERFACE
`define ENABLE_DMA_ENGINE

`define XPORT_SERIAL_BAUD 921600
`define DEBUG_SERIAL_BAUD 115200

`define I2C_CLOCK_RATE    300_000
`define I2C_SLAVE_ADDRESS 7'b0001111

/************ Power Manager Parameters ************/
// 5'b0 -> no overflows, otherwise overflow time = WATCHDOG_OVERFLOW_DEFAULT * 53.7s
// min = 53.7s, max = 1664.29s [27min]
`define WATCHDOG_OVERFLOW_DEFAULT 5'd0
`define MAX_UNACKED_CRASHES       3'd3
`define MAX_UNACKED_WD_OVERFLOWS  3'd7
//Which analogue values must be checked and be valid -- 1 check, 0 dont check
`define SYS_HEALTH_POWERUP_MASK   32'h0000_0000
//how long the power manager waits before entering the powered_up state
`define POWER_DOWN_WAIT           32'h01ff_ffff
//how long the power manager waits before starting post power-up checks
`define POST_POWERUP_WAIT         32'h00ff_ffff

/************ ADC Controller Defaults ************/
`define DEFAULT_SAMPLE_AVERAGING 3'b111
//2 ^ X

/********** WB Timeout Values ***********/

/*
  timeout format :
  timeout in cycles [20 bits],
  high address [16 bits],
  low address  [16 bits]
*/

`define TO_CONF_0 {20'h7_ff_ff, 16'hff_ff, 16'h03C0}
`define TO_CONF_1 {20'h7_ff_ff, 16'hff_ff, 16'h03C0}
`define TO_DEFAULT 20'd20

/********* Memory Protection ************/

/*
  memory restriction format :
  wbm mask       [3 bits] (which wb masters do the restriction apply to
                           {controller, xport, debug}),
  high address   [16 bits],
  low address    [16 bits],
  read disallow  [1  bit],
  write disallow [1  bit]
*/

`define MEM_RESTRICTION_0 {4'b0110, `MEM_ACM_H, `MEM_ACM_A, 1'b0, 1'b0}
`define MEM_RESTRICTION_1 {4'b0110, `MEM_ACM_H, `MEM_ACM_A, 1'b0, 1'b0}
`define MEM_RESTRICTION_2 {4'b0110, `MEM_ACM_H, `MEM_ACM_A, 1'b0, 1'b0}


`endif
