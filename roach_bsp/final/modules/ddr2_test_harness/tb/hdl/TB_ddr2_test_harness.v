
`define HALF_CLKPERIOD = 5 

module TB_ddr2_test_harness();



reg  clk( reset;
wire ddr_rd_we_n_o;                    //read/not-write  -- latched on ddr_af_we_o
wire [30:0] ddr_addr_o;                //address         -- latched on ddr_af_we_o
wire [127:0] ddr_data_o;  //write data      -- latched on ddr_df_we_o
wire [16:0] ddr_mask_o;  //write data mask -- latched on ddr_df_we_o
wire ddr_af_we_o;                      //address fifo write enable
wire ddr_df_we_o;                      //data fifo write enable
reg  ddr_af_afull_i;                   //address fifo almost full
reg  ddr_df_afull_i;                   //data fifo almost full
reg  [127:0] ddr_data_i;  //read data       -- latch on ddr_dvalid_i( and cycle afterwards
reg  ddr_dvalid_i;                     //read data valid
reg  ddr_phy_rdy_i;                    //pysical interface to mem ready and calibrated

wire [31:0] harness_status;  //test harness control and status
reg  [31:0] harness_control;
// harness_control fuctions (activ
  
  
  ddr2_test_harness ddr2_test_harness_inst (
    .clk (clk),
    .reset (reset),
    .ddr_rd_we_n_o (ddr_rd_we_n_o),
    .ddr_addr_o (ddr_addr_o),
    .ddr_data_o (ddr_data_o),
    .ddr_mask_o (ddr_mask_o),
    .ddr_af_we_o (ddr_af_we_o),
    .ddr_df_we_o (ddr_df_we_o),
    .ddr_af_afull_i (ddr_af_afull_i),
    .ddr_df_afull_i (ddr_df_afull_i),
    .ddr_data_i (ddr_data_i),
    .ddr_dvalid_i (ddr_dvalid_i),
    .ddr_phy_rdy_i (ddr_phy_rdy_i),
    .harness_status (harness_status),
    .harness_control (harness_control)
);


initial
begin

  clk = 0;
  reset = 0;
  ddr_af_afull_i = 0;                   //address fifo almost full
  ddr_df_afull_i = 0;                   //data fifo almost full
  ddr_data_i = {128{1'b1}};  //read data       -- latch on ddr_dvalid_i( and cycle afterwards
  ddr_dvalid_i = 0;                     //read data valid
  ddr_phy_rdy_i = 0;                    //pysical interface to mem ready and calibrated

  harness_control = {32{1'b1}};

end

always
  #'HALF_CLKPERIOD clk = !clk





//  initial begin
//    $display("PASSED");
//    $finish;
//  end
endmodule
