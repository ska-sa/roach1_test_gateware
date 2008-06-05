module ddr2_test_harness(
    clk,
    reset,

    ddr_rd_we_n_o,
    ddr_addr_o,
    ddr_data_o,
    ddr_mask_o,
    ddr_af_we_o,
    ddr_df_we_o,
    ddr_af_afull_i,
    ddr_df_afull_i,
    ddr_data_i,
    ddr_dvalid_i,
    ddr_phy_rdy_i,

    ddr_request_o, ddr_granted_i,

    wb_clk_i, wb_rst_i,
    wb_cyc_i, wb_stb_i, wb_we_i , wb_sel_i,
    wb_adr_i, wb_dat_i, wb_dat_o,
    wb_ack_o
  );

  // Module Definitions
  parameter  DATA_WIDTH         = 64;
  parameter  DATA_BITS_PER_MASK = 8;
  localparam MASK_WIDTH         = DATA_WIDTH/8;
  parameter  DDR2_Size          = 256 * 1024 * 1024;

  // Inputs & Outputs
  input  clk, reset;
  output ddr_rd_we_n_o;                    //read/not-write  -- latched on ddr_af_we_o 
  output [30:0] ddr_addr_o;                //address         -- latched on ddr_af_we_o
  output [DATA_WIDTH*2 - 1:0] ddr_data_o;  //write data      -- latched on ddr_df_we_o
  output [MASK_WIDTH*2 - 1:0] ddr_mask_o;  //write data mask -- latched on ddr_df_we_o
  output ddr_af_we_o;                      //address fifo write enable
  output ddr_df_we_o;                      //data fifo write enable
  input  ddr_af_afull_i;                   //address fifo almost full
  input  ddr_df_afull_i;                   //data fifo almost full
  input  [DATA_WIDTH*2 - 1:0] ddr_data_i;  //read data       -- latch on ddr_dvalid_i, and cycle afterwards
  input  ddr_dvalid_i;                     //read data valid
  input  ddr_phy_rdy_i;                    //pysical interface to mem ready and calibrated

  output ddr_request_o;
  input  ddr_granted_i,

  input  wb_clk_i, wb_rst_i;
  input  wb_cyc_i, wb_stb_i, wb_we_i;
  input   [1:0] wb_sel_i;
  input  [31:0] wb_adr_i;
  input  [15:0] wb_dat_i;
  output [15:0] wb_dat_o;
  output wb_ack_o;

  assign ddr_request_o = 1'b1;

  wire [31:0] harness_status;  //test harness control and status
  wire [31:0] harness_control;

  dram_test_h_wb dram_test_h_wb_inst(
    //memory wb slave IF
    .wb_clk_i(wb_clk_i), .wb_rst_i(wb_rst_i),
    .wb_cyc_i(wb_cyc_i), .wb_stb_i(wb_stb_i), .wb_we_i(wb_we_i),
    .wb_sel_i(wb_sel_i),
    .wb_adr_i(wb_adr_i), .wb_dat_i(wb_dat_i), .wb_dat_o(wb_dat_o),
    .wb_ack_o(wb_ack_o),
    .harness_status(harness_status),
    .harness_control(harness_control)
  );

  // harness_control fuctions (active high):
  // 0 - Start test

  // Internal variables
   
  // State machine registers
  reg [2:0] test_state;
  // Test state machine states
  localparam TEST_IDLE      = 3'd000;
  localparam WR_TEST_PATT_0 = 3'd001;
  localparam WR_TEST_PATT_1 = 3'd010;
  localparam TEST_WAIT      = 3'd011;
  // localparam TEST_RD_PATT = 2'd11;
  
  // Address Counter
  reg [30:2] ddr_addr;
  
  // Code starts here
  
  always @(posedge clk) begin
    if (reset || !harness_control[0]) begin
      test_state <= TEST_IDLE;
    end else begin
      case (test_state)
        TEST_IDLE: begin
          test_state <= WR_TEST_PATT_0;
        end
        WR_TEST_PATT_0 : begin
          if (1'b1) begin
            test_state <= TEST_WAIT;
          end else begin
            test_state <= WR_TEST_PATT_1; 
          end
        end
        WR_TEST_PATT_1 : begin
          test_state <= WR_TEST_PATT_0; 
        end
      endcase
    end   
  end


  assign ddr_rd_we_n_o = (test_state == WR_TEST_PATT_0) ? 1'b0 : 1'b1;
  assign ddr_mask_o    = {MASK_WIDTH*2{1'b1}};

  assign ddr_af_we_o   = (test_state == WR_TEST_PATT_0) ? 1'b0 : 1'b1;
  assign ddr_df_we_o   = (test_state == (WR_TEST_PATT_0 || WR_TEST_PATT_1)) ? 1'b0 : 1'b1;
  
  // Adress Generator
  
  always @(posedge clk)
  if (test_state == TEST_IDLE) begin
    ddr_addr <= 29'b0;
  end else if (test_state == WR_TEST_PATT_1) begin
    ddr_addr <= ddr_addr + 1;
  end
  assign ddr_addr_o = {ddr_addr,2'b0};
  
  // Data Generator
  assign ddr_data_o = {DATA_WIDTH*2{1'b1}};  //write data      -- latched on ddr_df_we_o
  
 
endmodule

