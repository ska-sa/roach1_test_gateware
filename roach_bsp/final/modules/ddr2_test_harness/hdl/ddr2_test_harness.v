module ddr2_test_harness(
    clk,
    reset,

    ddr_rd_wr_n_o,
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
  parameter  DDR2_SIZE          = 8;//(256 * 1024 * 1024)/4;

  // Inputs & Outputs
  input  clk, reset;
  output ddr_rd_wr_n_o;                    //read/not-write  -- latched on ddr_af_we_o 
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
  input  ddr_granted_i;

  input  wb_clk_i, wb_rst_i;
  input  wb_cyc_i, wb_stb_i, wb_we_i;
  input   [1:0] wb_sel_i;
  input  [31:0] wb_adr_i;
  input  [15:0] wb_dat_i;
  output [15:0] wb_dat_o;
  output wb_ack_o;

  assign ddr_request_o = 1'b1;

  // Internal variables
   
    // State machine registers
      reg [2:0] test_state;
    // Test state machine states
      localparam TEST_IDLE      = 3'd000;
      localparam WR_TEST_PATT_0 = 3'd001;
      localparam WR_TEST_PATT_1 = 3'd010;
      localparam TEST_WAIT      = 3'd011;
      localparam RD_TEST_PATT   = 3'd100;
      localparam WAIT_FOR_DATA  = 3'd101;
    // Address Counter
      reg [30:2] ddr_addr;
      reg [63:0] ddr_data_cnt;
    // General
      wire test_start_re;
      reg test_start_re0;
      wire ddr_dvalid_fe; 
      reg ddr_dvalid_fe0; 
      reg test_done;
      reg test_fault;

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


  // Code starts here
  
  // Detect rising edge on harness_control bit 0. This indicates start of test
  // run
  always @(posedge clk) begin
    if (reset) begin
      test_start_re0 <= 1;
    end else begin
      test_start_re0 <= harness_control[0];
    end
  end
 assign test_start_re = harness_control[0] && !test_start_re0;
  
  // Detect negative edge on ddr_dvalid_i
  always @(posedge clk) begin
    if (reset) begin
      ddr_dvalid_fe0 <= 0;
    end else begin
      ddr_dvalid_fe0 <= ddr_dvalid_i;
    end
  end
  assign ddr_dvalid_fe = !ddr_dvalid_i && ddr_dvalid_fe0;
  
  // Main state machine
  always @(posedge clk) begin
    if (reset) begin
      test_state <= TEST_IDLE;
    end else begin
      case (test_state)
        TEST_IDLE: begin
          if (test_start_re == 1) begin
            test_state <= WR_TEST_PATT_0;
          end else begin
            test_state <= TEST_IDLE;
          end
        end
        WR_TEST_PATT_0 : begin
          test_state <= WR_TEST_PATT_1; 
        end
        WR_TEST_PATT_1 : begin
          if (ddr_addr == DDR2_SIZE) begin
            test_state <= TEST_WAIT;
          end else begin
            test_state <= WR_TEST_PATT_0; 
          end
        end
        TEST_WAIT : begin
          test_state <= RD_TEST_PATT;
        end 
        RD_TEST_PATT : begin
          if (ddr_addr == DDR2_SIZE) begin
            test_state <= WAIT_FOR_DATA;
          end else begin
            test_state <= RD_TEST_PATT;
          end
        end
        WAIT_FOR_DATA : begin
          if (ddr_dvalid_fe) begin
            test_state <= TEST_IDLE;
          end else begin
            test_state <= WAIT_FOR_DATA;
          end
        end
      endcase
    end
  end

  assign ddr_rd_wr_n_o = (test_state == WR_TEST_PATT_0) ? 1'b0 : 1'b1;
  assign ddr_mask_o    = {MASK_WIDTH*2{1'b1}};

  assign ddr_af_we_o   = ((test_state == WR_TEST_PATT_0) || (test_state == RD_TEST_PATT)) ? 1'b1 : 1'b0;
  assign ddr_df_we_o   = ((test_state == WR_TEST_PATT_0) || (test_state == WR_TEST_PATT_1)) ? 1'b1 : 1'b0;

  always @(ddr_dvalid_fe or test_start_re or reset) begin
    if (ddr_dvalid_fe) begin
      test_done <= 1;
    end else if (test_start_re || reset ) begin
      test_done <= 0;
    end
  end
  assign harness_status[0] = test_done;

  // Adress Generator
  
  always @(posedge clk) begin
    if ((test_state == TEST_IDLE) || (test_state == TEST_WAIT)) begin
      ddr_addr <= 29'b0;
    end else if ((test_state == WR_TEST_PATT_1) || (test_state == RD_TEST_PATT)) begin
      ddr_addr <= ddr_addr + 1;
    end
  end  
  assign ddr_addr_o = {ddr_addr,2'b0};
  
  // Data Generator
  always @(posedge clk) begin
    if ((test_state == TEST_IDLE) || (test_state == TEST_WAIT)) begin
      ddr_data_cnt <= 64'b0;
    end else if ((test_state == WR_TEST_PATT_1) || (test_state == WR_TEST_PATT_0) || (ddr_dvalid_i)) begin
      ddr_data_cnt <= ddr_data_cnt + 1;
    end
  end  
  
  assign ddr_data_o = {ddr_data_cnt,ddr_data_cnt}; 

  // Data Comparator
  always @(posedge clk) begin
    if (test_state == WR_TEST_PATT_0) begin
      test_fault <= 0;
    end else if(ddr_dvalid_i) begin
      if (ddr_data_i != {ddr_data_cnt,ddr_data_cnt}) begin
        test_fault <= 1; 
      end
    end
  end
  assign harness_status[1] = test_fault;

endmodule

