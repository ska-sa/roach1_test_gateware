module roach_app #(
    parameter DRAM_WIDTH_MULTIPLIER = 1,
    parameter QDR0_WIDTH_MULTIPLIER = 1,
    parameter QDR1_WIDTH_MULTIPLIER = 1
  ) (
    /* global reset */
    input  sys_reset,

    /* input clocks */
    input  sys_clk,
    input  dram_clk,
    input  qdr0_clk,
    input  qdr1_clk,
    input  adc0_clk,
    input  adc1_clk,
    input  tge_clk,
    input  [1:0] aux_clk,
    input  [1:0] aux_sync,

    /* Wishbone Interface */
    input  wb_clk_i,
    input  wb_rst_i,
    input  wb_cyc_i,
    input  wb_stb_i,
    input  wb_we_i,
    input   [1:0] wb_sel_i,
    input  [31:0] wb_adr_i,
    input  [15:0] wb_dat_i,
    output [15:0] wb_dat_o,
    output wb_ack_o,

    /* 4 x TGE interfaces */
    output  [1*4 - 1:0] tge_usr_clk,
    output  [1*4 - 1:0] tge_usr_rst,
    output  [1*4 - 1:0] tge_tx_valid,
    input   [1*4 - 1:0] tge_tx_ack,
    output  [1*4 - 1:0] tge_tx_end_of_frame,
    output  [1*4 - 1:0] tge_tx_discard,
    output [64*4 - 1:0] tge_tx_data,
    output [32*4 - 1:0] tge_tx_dest_ip,
    output [16*4 - 1:0] tge_tx_dest_port,
    input   [1*4 - 1:0] tge_rx_valid,
    output  [1*4 - 1:0] tge_rx_ack,
    input  [64*4 - 1:0] tge_rx_data,
    input   [1*4 - 1:0] tge_rx_end_of_frame,
    input  [16*4 - 1:0] tge_rx_size,
    input  [32*4 - 1:0] tge_rx_source_ip,
    input  [16*4 - 1:0] tge_rx_source_port,
    input   [1*4 - 1:0] tge_led_up,
    input   [1*4 - 1:0] tge_led_rx,
    input   [1*4 - 1:0] tge_led_tx,

    /* DRAM Interfaces */
    output dram_usrclk,
    input  dram_rdy,

    output dram_cmd_valid,
    input  dram_cmd_ack,
    output dram_cmd_rnw,
    output [31:0] dram_cmd_addr,
    output [144*DRAM_WIDTH_MULTIPLIER - 1:0] dram_wr_data,
    output  [18*DRAM_WIDTH_MULTIPLIER - 1:0] dram_wr_be,

    input  dram_rd_valid,
    output dram_rd_ack,
    input  [144*DRAM_WIDTH_MULTIPLIER - 1:0] dram_rd_data,

    /* QDR0 Interfaces */
    output qdr0_usrclk,
    input  qdr0_rdy,

    output qdr0_cmd_valid,
    input  qdr0_cmd_ack,
    output qdr0_cmd_rnw,
    output [31:0] qdr0_cmd_addr,
    output [36*QDR0_WIDTH_MULTIPLIER - 1:0] qdr0_wr_data,
    output  [4*QDR0_WIDTH_MULTIPLIER - 1:0] qdr0_wr_be,

    input  qdr0_rd_valid,
    output qdr0_rd_ack,
    input  [36*QDR0_WIDTH_MULTIPLIER - 1:0] qdr0_rd_data,

    /* QDR1 Interfaces */
    output qdr1_usrclk,
    input  qdr1_rdy,

    output qdr1_cmd_valid,
    input  qdr1_cmd_ack,
    output qdr1_cmd_rnw,
    output [31:0] qdr1_cmd_addr,
    output [36*QDR1_WIDTH_MULTIPLIER - 1:0] qdr1_wr_data,
    output  [4*QDR1_WIDTH_MULTIPLIER - 1:0] qdr1_wr_be,

    input  qdr1_rd_valid,
    output qdr1_rd_ack,
    input  [36*QDR1_WIDTH_MULTIPLIER - 1:0] qdr1_rd_data,

    /* ADC0 */
    input [63:0] adc0_data,
    input  [3:0] adc0_sync,
    input  [3:0] adc0_outofrange,
    
    /* ADC1 */
    input [63:0] adc1_data,
    input  [3:0] adc1_sync,
    input  [3:0] adc1_outofrange,

    /* GPIO */
    inout  [7:0] gpio_a,
    output gpio_a_oe,
    inout  [7:0] gpio_b,
    output gpio_b_oe,

    /* Diff GPIO */
    inout  [19:0] diff_gpio_a_n,
    inout  [19:0] diff_gpio_a_p,
    inout  diff_gpio_a_clk_n, 
    inout  diff_gpio_a_clk_p, 
    inout  [19:0] diff_gpio_b_n,
    inout  [19:0] diff_gpio_b_p,
    inout  diff_gpio_b_clk_n, 
    inout  diff_gpio_b_clk_p, 

    /* Misc */
    output  [3:0] led,
    output [15:0] irq
  );
endmodule
