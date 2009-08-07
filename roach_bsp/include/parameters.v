`ifndef PARAMETERS_V
`define PARAMETERS_V

/************* Clock Speed Definitions *************/

`define EPB_CLOCK_RATE    88_000_000
`define SYS_CLOCK_RATE    100_000_000

/************* Debug Serial UART BAUD **************/

`define SERIAL_UART_BAUD  115200

/*********** Individual Module Enables *************/

`define ENABLE_TEN_GB_ETH_0
`define ENABLE_TEN_GB_ETH_1
`define ENABLE_TEN_GB_ETH_2
`define ENABLE_TEN_GB_ETH_3
`define ENABLE_DRAM
`define ENABLE_QDR_INFRASTRUCTURE
`define ENABLE_QDR0
`define ENABLE_QDR1
//`define ENABLE_APPLICATION

/************** XAUI/TENGBE Defines ***************/

`define MGT_DIFF_BOOST    "FALSE"

`define TGE_0_DEFAULT_FABRIC_MAC     48'hff_ff_ff_ff_ff_ff
`define TGE_0_DEFAULT_FABRIC_IP      32'hff_ff_ff_ff
`define TGE_0_DEFAULT_FABRIC_GATEWAY 8'hff
`define TGE_0_DEFAULT_FABRIC_PORT    16'hff_ff
`define TGE_0_FABRIC_RUN_ON_STARTUP  1

`define TGE_1_DEFAULT_FABRIC_MAC     48'hff_ff_ff_ff_ff_ff
`define TGE_1_DEFAULT_FABRIC_IP      32'hff_ff_ff_ff
`define TGE_1_DEFAULT_FABRIC_GATEWAY 8'hff
`define TGE_1_DEFAULT_FABRIC_PORT    16'hff_ff
`define TGE_1_FABRIC_RUN_ON_STARTUP  1

`define TGE_2_DEFAULT_FABRIC_MAC     48'hff_ff_ff_ff_ff_ff
`define TGE_2_DEFAULT_FABRIC_IP      32'hff_ff_ff_ff
`define TGE_2_DEFAULT_FABRIC_GATEWAY 8'hff
`define TGE_2_DEFAULT_FABRIC_PORT    16'hff_ff
`define TGE_2_FABRIC_RUN_ON_STARTUP  1

`define TGE_3_DEFAULT_FABRIC_MAC     48'hff_ff_ff_ff_ff_ff
`define TGE_3_DEFAULT_FABRIC_IP      32'hff_ff_ff_ff
`define TGE_3_DEFAULT_FABRIC_GATEWAY 8'hff
`define TGE_3_DEFAULT_FABRIC_PORT    16'hff_ff
`define TGE_3_FABRIC_RUN_ON_STARTUP  1

/***************** DRAM Defines ********************/

`define DRAM_CLK_FREQ         266
`define DRAM_WIDTH_MULTIPLIER 1
`define DRAM_HALF_BURST       0
`define DRAM_ARB_BASIC

/***************** QDR Defines ********************/

`define QDR_CLK_FREQ          300
`define QDR0_WIDTH_MULTIPLIER 1
`define QDR1_WIDTH_MULTIPLIER 1

`endif
