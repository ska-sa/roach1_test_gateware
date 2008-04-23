`ifndef PARAMETERS_V
`define PARAMETERS_V
`define SERIAL_UART_BAUD  115200
`define MASTER_CLOCK_RATE 100_000_000
`define MGT_DIFF_BOOST    "FALSE"


/************** XAUI/TENGBE Defines ***************/
`define TGE_0_DEFAULT_FABRIC_MAC     48'hff_ff_ff_ff_ff_ff
`define TGE_0_DEFAULT_FABRIC_IP      32'hff_ff_ff_ff
`define TGE_0_DEFAULT_FABRIC_GATEWAY 8'hff
`define TGE_0_DEFAULT_FABRIC_PORT    16'hff_ff
`define TGE_0_FABRIC_RUN_ON_STARTUP  1


//`define ENABLE_TEN_GB_ETH_0
//`define ENABLE_XAUI_0
//`define ENABLE_TEN_GB_ETH_1
//`define ENABLE_XAUI_1
//`define ENABLE_TEN_GB_ETH_2
//`define ENABLE_XAUI_2
//`define ENABLE_TEN_GB_ETH_3
//`define ENABLE_XAUI_3
//

//`define ENABLE_DDR2


`define DDR2_CLK_FREQ "266"






`endif
