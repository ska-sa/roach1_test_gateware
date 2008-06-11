`define TEST_START 20
`define RESET_WAIT 20
`define HALF_CLKPERIOD 5 
`define SIM_LENGTH 2000

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
	reg [79:0] harness_control_test;

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
  reset = 1;
  ddr_af_afull_i = 0;                   //address fifo almost full
  ddr_df_afull_i = 0;                   //data fifo almost full
  ddr_data_i = {128'h0008_0007_0006_0005_0004_0003_0002_0001};  //read data       -- latch on ddr_dvalid_i( and cycle afterwards
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

  harness_control_test[79:48]  = 32'h0000_0008;
  harness_control_test[47:16]  = 32'h0000_0004;
  harness_control_test[15:00]  = 16'h0000;


end

always
  #`HALF_CLKPERIOD clk = !clk;

always @(posedge clk) begin
  if (!ddr_df_we_o && ddr_af_we_o) begin
    #50 ddr_dvalid_i = 1;
    #101 ddr_dvalid_i = 0;
  end
end

always begin
  #`RESET_WAIT reset = 0;
  #5 ddr_phy_rdy_i = 1;
  #`TEST_START harness_control_test[0] = 1;
end

integer i;

always begin
  #1000;
  for (i = 0; i < 80; i = i + 1) begin 
    harness_control_test[79:64]  = i;
    #20;
  end  
end

initial  begin
  $dumpfile ("ddr2_test_harness.vcd"); 
  $dumpvars; 
end
	  
initial 
 #`SIM_LENGTH  $finish; 


//initial begin
// $display("PASSED");
// $finish;
//end
	
endmodule
