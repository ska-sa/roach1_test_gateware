`ifndef PARAMETERS_V
`define PARAMETERS_V

/************* GENERIC Parameters ***************/
`define LBUS_CLOCK_FREQ 40_000_000

/********** Serial Interface Parameters *********/
`define I2C_FREQUENCY 100_000
`define SERIAL_UART_BAUDRATE 115200
`define I2C_ADDRESS 7'b0001111
`define I2C_EXTERNAL_OC
//`define I2C_ENABLE 
//1ms
`define SERIAL_INTERFACE_TIMEOUT 32'd1_0000

//`define SERIAL_LOOPBACK 

/************** Module Enables ****************/
//`define TEST_MODULE_ENABLE
`define FROM_CONTROLLER_ENABLE
`define ABCONF_CONTROLLER_ENABLE
`define ALC_ENABLE
`define POWER_MANAGER_ENABLE
`define IRQ_CONTROLLER_ENABLE
`define BUS_MONITOR_ENABLE
`define FLASHMEM_CONTROLLER_ENABLE
//`define ADDRESS_PROTECTOR_ENABLE
//`define DMA_ENGINE_ENABLE


/************* ALC Parameters ***************/
`define ALC_IRQ_ENABLE
`define ALC_POWER_DOWN_ENABLE
/*********Flash Memory Parameters************/
`define FLASH_CRASH_OFFSET (16'd0)
/*********Power Manager Parameters***********/
/*start in no power state*/
`define PM_COLD_START

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
