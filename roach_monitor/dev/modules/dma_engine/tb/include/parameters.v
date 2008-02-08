`ifndef PARAMETERS_V
`define PARAMETERS_V

/************* GENERIC Parameters ***************/
`define ACTEL_DEV_BOARD
`define LBUS_CLOCK_PERIOD 10000000
//`define XCC_BOARD
//10MHz
/*`define ADDRESS_PROTECTION_ENABLE*/
/*`define TEST_MODULE_ENABLE*/
/********** Serial Interface Parameters *********/
`define SERIAL_UART_BAUDRATE 115200
`define I2C_ADDRESS 7'b1111000
`define I2C_EXTERNAL_OC
//`define I2C_ENABLE 
//1ms
`define SERIAL_INTERFACE_TIMEOUT 32'd1_0000

`define SERIAL_LOOPBACK 


/************ MemBlock Parameters ************/
`define MB_RING_BUFFER_SIZE 8192

/************* Clock Parameters **************/

/* Clock parameters, INPUT and FEEDBACK divide
 * must maintain a range of 1.5 to 5.5MHz  PLL input clock
 * and a range of 24 to 350 MHz on PLL output clock.
 * The value VCO_FREQ is used by DESIGNER to perform checking*/
/* 100*38/19 === 200MHz*/
`define PLL_INPUT_DIVIDE    (7'd19)
`define PLL_FEEDBACK_DIVIDE (7'd38) 

/*CLKA == 100, CLKB == 40, CLKC == 10*/
`define PLL_AOUT_DIVIDE     (5'd2 )
`define PLL_BOUT_DIVIDE     (5'd5 )
`define PLL_COUT_DIVIDE     (5'd20)

`define PLL_VCO_FREQ	    200.00

/************* ALC Parameters ***************/
`define ALC_IRQ_ENABLE
`define ALC_POWER_DOWN_ENABLE
/*********Flash Memory Parameters************/
`define FLASH_CRASH_OFFSET (16'd0)
/*********Power Manager Parameters***********/

// How long should the fpga wait before powering up again after a crash or shutdown?
// Measured in number of cycles, 1 cycle = 100ns
// 1 Second ===32'd10'000'000 
`define PM_USER_POWERUP_WAIT 32'd10_000_000

// The GA base delay must equal GA * X, where X is the delay per GA increment
// However, * is a costly operation - thus X is restricted to powers of two.
// (1 << PM_GLOBAL_ADDRESS_WAIT_SHIFT) === X [cycles]
// 0 == 1 cycle, 1 == 2 cycles, ..., 23 == 2^23 cycles === 838 ms
`define PM_GLOBAL_ADDRESS_WAIT_SHIFT 23

// Defines the maximum number of unanswered crashes after which the board will enter
// a permanent unpowered state

`define PM_MAX_CRASHES 5'd5

// Period of led flash in cycles
`define PM_BEAT_PERIOD 32'd10_000_000

//Period before power_down
`define PM_WATCHDOG_ENABLE
 //Five Minutes
`define PM_WATCHDOG_TIMEOUT 32'd300_0000000
`define PM_WATCHDOG_RESETS_MAX 5'd5

//Timeout before shutdown command is forced
`define PM_SHUTDOWN_WAIT 32'd300_0000000

`endif
