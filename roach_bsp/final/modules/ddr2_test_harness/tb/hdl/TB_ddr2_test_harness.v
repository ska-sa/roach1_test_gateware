
`define HALF_CLKPERIOD 5 

module TB_ddr2_test_harness;

	// Inputs
	reg clk;
	reg reset;
	reg ddr_af_afull_i;
	reg ddr_df_afull_i;
	reg [127:0] ddr_data_i;
	reg ddr_dvalid_i;
	reg ddr_phy_rdy_i;
	reg ddr_granted_i;
	reg wb_clk_i;
	reg wb_rst_i;
	reg wb_cyc_i;
	reg wb_stb_i;
	reg wb_we_i;
	reg [1:0] wb_sel_i;
	reg [31:0] wb_adr_i;
	reg [15:0] wb_dat_i;
	reg [45:0] harness_control_test;

	// Outputs
	wire ddr_rd_wr_n_o;
	wire [30:0] ddr_addr_o;
	wire [127:0] ddr_data_o;
	wire [15:0] ddr_mask_n_o;
	wire ddr_af_we_o;
	wire ddr_df_we_o;
	wire ddr_request_o;
	wire [15:0] wb_dat_o;
	wire wb_ack_o;

	// Instantiate the Unit Under Test (UUT)
	ddr2_test_harness uut (
		.clk(clk), 
		.reset(reset), 
		.ddr_rd_wr_n_o(ddr_rd_wr_n_o), 
		.ddr_addr_o(ddr_addr_o), 
		.ddr_data_o(ddr_data_o), 
		.ddr_mask_n_o(ddr_mask_n_o), 
		.ddr_af_we_o(ddr_af_we_o), 
		.ddr_df_we_o(ddr_df_we_o), 
		.ddr_af_afull_i(ddr_af_afull_i), 
		.ddr_df_afull_i(ddr_df_afull_i), 
		.ddr_data_i(ddr_data_i), 
		.ddr_dvalid_i(ddr_dvalid_i), 
		.ddr_phy_rdy_i(ddr_phy_rdy_i), 
		.ddr_request_o(ddr_request_o), 
		.ddr_granted_i(ddr_granted_i), 
		.wb_clk_i(wb_clk_i), 
		.wb_rst_i(wb_rst_i), 
		.wb_cyc_i(wb_cyc_i), 
		.wb_stb_i(wb_stb_i), 
		.wb_we_i(wb_we_i), 
		.wb_sel_i(wb_sel_i), 
		.wb_adr_i(wb_adr_i), 
		.wb_dat_i(wb_dat_i), 
		.wb_dat_o(wb_dat_o), 
		.wb_ack_o(wb_ack_o), 
		.harness_control_test(harness_control_test)
	);



initial begin

  clk = 0;
  reset = 0;
  ddr_af_afull_i = 0;                   //address fifo almost full
  ddr_df_afull_i = 0;                   //data fifo almost full
  ddr_data_i = {128{1'b1}};  //read data       -- latch on ddr_dvalid_i( and cycle afterwards
  ddr_dvalid_i = 0;                     //read data valid
  ddr_phy_rdy_i = 0;                    //pysical interface to mem ready and calibrated
  
  ddr_granted_i = 0;
  wb_clk_i = 0;
  wb_rst_i = 0;
  wb_cyc_i = 0;
  wb_stb_i = 0;
  wb_we_i  = 0;
  wb_sel_i = {2{1'b1}};
  wb_adr_i = {32{1'b1}};
  wb_dat_i = {16{1'b1}};

  harness_control_test  = {46{1'b1}};

end

always
  #`HALF_CLKPERIOD clk = !clk;

initial  begin
  $dumpfile ("ddr2_test_harness.vcd"); 
  $dumpvars; 
end
	  
initial 
 #5000  $finish; 


//initial begin
// $display("PASSED");
// $finish;
//end
	
endmodule
