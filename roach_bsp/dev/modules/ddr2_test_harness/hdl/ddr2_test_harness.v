module ddr2_test_harness(
    clk,
    reset,

    ddr_addr_o,
    ddr_data_o,
    ddr_mask_o,
    ddr_af_we_o,
    ddr_df_we_o,
    ddr_af_afull,
    ddr_df_afull,
    ddr_data_i,
    ddr_dvalid_i,

    harness_status,
    harness_control
  );
  parameter  DATA_WIDTH         = 64;
  parameter  DATA_BITS_PER_MASK = 8;
  localparam MASK_WIDTH         = DATA_WIDTH/8;

  input  clk, reset;
  output ddr_rd_we_n;                      //read/not-write  -- latched on ddr_af_we_o 
  output [30:0] ddr_addr_o;                //address         -- latched on ddr_af_we_o
  output [DATA_WIDTH*2 - 1:0] ddr_data_o;  //write data      -- latched on ddr_df_we_o
  output [MASK_WIDTH*2 - 1:0] ddr_mask_o;  //write data mask -- latched on ddr_df_we_o
  output ddr_af_we_o;                      //address fifo write enable
  output ddr_df_we_o;                      //data fifo write enable
  input  ddr_af_afull_i;                   //address fifo almost full
  output ddr_df_afull_i;                   //data fifo almost full
  input  [DATA_WIDTH*2 - 1:0] ddr_data_i;  //read data       -- latch on ddr_dvalid_i, and cycle afterwards
  input  ddr_dvalid_i;                     //read data valid

  output [31:0] harness_status;  //test harness control and status
  input  [31:0] harness_control;

endmodule

