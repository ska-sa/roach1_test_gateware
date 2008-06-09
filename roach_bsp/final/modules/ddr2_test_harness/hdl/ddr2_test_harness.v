module ddr2_test_harness(
    clk,
    reset,

    ddr_rd_wr_n_o,
    ddr_addr_o,
    ddr_data_o,
    ddr_mask_n_o,
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
    wb_ack_o,

    harness_control_test
  );

  // Module Definitions
  parameter  DATA_WIDTH         = 64;
  parameter  DATA_BITS_PER_MASK = 8;
  localparam MASK_WIDTH         = DATA_WIDTH/8;
  
  parameter  STATUS_START_ADDR  = 5;
  parameter  FAULT_VAL_ADDR     = STATUS_START_ADDR + 1;  // Status register size = 1
  parameter  FIFO_AFULL_ADDR    = FAULT_VAL_ADDR + 8;     // Fault register size = 8
  parameter  RDBLK_START_ADDR   = FIFO_AFULL_ADDR + 2;    // Fifo almost full register size = 2
  parameter  RDBLK_SIZE_BITS    = 3;                      // Read block addressing bits
  parameter  RDBLK_SIZE         = 1 << RDBLK_SIZE_BITS;   // 128 bit word locations
  parameter  STATUS_MEM_DEPTH   = RDBLK_START_ADDR + (RDBLK_SIZE * 8);
    // parameter  STATUS_ADDR_WIDTH  = 4;
    //

  // Inputs & Outputs
  input  clk, reset;
  output ddr_rd_wr_n_o;                    //read/not-write  -- latched on ddr_af_we_o 
  output [30:0] ddr_addr_o;                //address         -- latched on ddr_af_we_o
  output [DATA_WIDTH*2 - 1:0] ddr_data_o;  //write data      -- latched on ddr_df_we_o
  output [MASK_WIDTH*2 - 1:0] ddr_mask_n_o;  //write data mask -- latched on ddr_df_we_o
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
  
  input [79:0] harness_control_test;

  assign ddr_request_o = 1'b1;

  // Internal variables
   
    // State machine registers
      reg [2:0] test_state;
    // Test state machine states
      localparam TEST_IDLE      = 3'b000;
      localparam WR_TEST_PATT_0 = 3'b001;
      localparam WR_TEST_PATT_1 = 3'b010;
      localparam TEST_WAIT      = 3'b011;
      localparam RD_TEST_PATT   = 3'b100;
      localparam WAIT_FOR_DATA  = 3'b101;
      localparam RD_BACKOFF     = 3'b110;
      localparam WR_BACKOFF     = 3'b111;
    // Address Counter
      reg [30:2] ddr_addr;
      reg [63:0] ddr_data_cnt;
    // General
      wire test_start_re;
      reg test_start_re0;
      wire ddr_dvalid_fe; 
      reg ddr_dvalid_fe0; 
      wire module_rst;
      reg module_rst_re;
      wire af_df_afull;
      wire burst_edge;
      reg [31:0] data_rdblk_cnt;
      reg assign_rdblk;
      reg [RDBLK_SIZE_BITS - 1:0] addr_rdblk_cnt;
      reg [15:0] rdblk_mem [0 : RDBLK_SIZE - 1];

    // Test harness communications

      wire [20:0] status_addr;
      wire [15:0] harness_status;  //test harness control and status
      wire [79:0] harness_control;
      wire [29:0] ctrl_ddr_size;
      wire [31:0] ctrl_rdblk_addr;
      reg  [29:0] afull_addr;
      reg  ctrl_reset;
      reg  ctrl_start;
      reg test_done;
      reg test_fault;
      reg afull_event;
      reg [DATA_WIDTH*2 - 1:0] data_fault_read;
      wire [15:0] status_mem [STATUS_START_ADDR:STATUS_MEM_DEPTH];

  //Wishbone map:
  //  Control:
  //    400000: bit 0 = start; bit 1 = reset
  //    400002: lower byte of ddr test size (
  //    400004: upper byte of ddr test size
  //  Status:
  //    400006: bit 0 = test done; bit 1 = test fault
  
  dram_test_h_wb dram_test_h_wb_inst(
    //memory wb slave IF
    .wb_clk_i(wb_clk_i), .wb_rst_i(wb_rst_i),
    .wb_cyc_i(wb_cyc_i), .wb_stb_i(wb_stb_i), .wb_we_i(wb_we_i),
    .wb_sel_i(wb_sel_i),
    .wb_adr_i(wb_adr_i), .wb_dat_i(wb_dat_i), .wb_dat_o(wb_dat_o),
    .wb_ack_o(wb_ack_o),
    .status_addr(status_addr),
    .harness_status(harness_status),
    .harness_control(harness_control)
  );


  // Code starts here
  
  // General assignments and control assignments
   
  assign af_df_afull = ddr_af_afull_i || ddr_df_afull_i;
  always @(posedge clk) begin
    ctrl_start <= harness_control_test[0];
    ctrl_reset <= harness_control_test[1];
  end
  assign ctrl_ddr_size = harness_control_test[45:16];
  assign ctrl_rdblk_addr = harness_control_test[79:48];
 
  always @(posedge clk) begin
    if (module_rst) begin
      afull_event <= 0;
      afull_addr <= {30'b0};
    end else if (af_df_afull && !afull_event) begin
      afull_event <= 1;
      afull_addr <= ddr_addr;
    end
  end



  genvar i;
  generate
    for (i = 0; i < 8; i = i + 1) begin : fucknuckle
      assign status_mem[i + FAULT_VAL_ADDR] = data_fault_read[((i*16) + 15):(i*16)];
    end
  endgenerate
  
  assign status_mem[FIFO_AFULL_ADDR] = afull_addr[15:0];
  assign status_mem[FIFO_AFULL_ADDR + 1] = {2'b00,afull_addr[29:16]};

  assign status_mem[STATUS_START_ADDR][0] = test_done;
  assign status_mem[STATUS_START_ADDR][1] = test_fault;
  assign status_mem[STATUS_START_ADDR][2] = afull_event;
  assign harness_status = status_mem[status_addr];

  // Detect rising edge on harness_control bit 1. This is a module reset
  always @(posedge clk) begin
    if (reset) begin
      module_rst_re <= 1;
    end else begin
      module_rst_re <= ctrl_reset;
    end
  end
  assign module_rst = (ctrl_reset && !module_rst_re) || reset || !ddr_phy_rdy_i;

  // Detect rising edge on harness_control bit 0. This indicates start of test
  // run
  always @(posedge clk) begin
    if (module_rst) begin
      test_start_re0 <= 1;
    end else begin
      test_start_re0 <= ctrl_start;
    end
  end
 assign test_start_re = ctrl_start && !test_start_re0;
  
  // Detect negative edge on ddr_dvalid_i
  always @(posedge clk) begin
    if (module_rst) begin
      ddr_dvalid_fe0 <= 0;
    end else begin
      ddr_dvalid_fe0 <= ddr_dvalid_i;
    end
  end
  assign ddr_dvalid_fe = !ddr_dvalid_i && ddr_dvalid_fe0;
  
  // Main state machine
  always @(posedge clk) begin
    if (module_rst) begin
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
          if (ddr_addr == ctrl_ddr_size) begin
            test_state <= TEST_WAIT;
          end else if (burst_edge && af_df_afull) begin  //Check almost full flag at end of 4 burst write
            test_state <= WR_BACKOFF;
          end else begin
            test_state <= WR_TEST_PATT_0; 
          end
        end
        WR_BACKOFF : begin
          if (!af_df_afull) begin
            test_state <= WR_TEST_PATT_0;
          end else begin
            test_state <= WR_BACKOFF;
          end
        end
        TEST_WAIT : begin
          test_state <= RD_TEST_PATT;
        end 
        RD_TEST_PATT : begin
          if (ddr_addr == ctrl_ddr_size) begin
            test_state <= WAIT_FOR_DATA;
          end else if (burst_edge && af_df_afull) begin  //Check almost full flag at end of 4 burst write
            test_state <= RD_BACKOFF;
          end else begin
            test_state <= RD_TEST_PATT;
          end
        end
        RD_BACKOFF : begin
          if (!af_df_afull) begin
            test_state <= RD_TEST_PATT;
          end else begin
            test_state <= RD_BACKOFF;
          end
        end
        WAIT_FOR_DATA : begin
          if (ddr_dvalid_fe) begin                       //ToDo: add code to ensure full memory have been read
            test_state <= TEST_IDLE;
          end else begin
            test_state <= WAIT_FOR_DATA;
          end
        end
      endcase
    end
  end

  assign ddr_rd_wr_n_o = (test_state == WR_TEST_PATT_0) ? 1'b0 : 1'b1;
  assign ddr_mask_n_o  = {MASK_WIDTH*2{1'b0}};

  assign ddr_af_we_o   = ((test_state == WR_TEST_PATT_0) || (test_state == RD_TEST_PATT)) ? 1'b1 : 1'b0;
  assign ddr_df_we_o   = ((test_state == WR_TEST_PATT_0) || (test_state == WR_TEST_PATT_1)) ? 1'b1 : 1'b0;

  // Check when test is done
  always @(ddr_dvalid_fe or test_state or test_start_re or module_rst) begin
    if (ddr_dvalid_fe && (test_state == WAIT_FOR_DATA)) begin
      test_done <= 1;
    end else if (test_start_re || module_rst ) begin
      test_done <= 0;
    end
  end

  // Adress Generator
  
  always @(posedge clk) begin
    if ((test_state == TEST_IDLE) || (test_state == TEST_WAIT)) begin
      ddr_addr <= 29'b0;
    end else if ((test_state == WR_TEST_PATT_1) || (test_state == RD_TEST_PATT)) begin
      ddr_addr <= ddr_addr + 1;
    end
  end  
  assign ddr_addr_o = {ddr_addr,2'b0};
  assign burst_edge = ddr_addr % 4;
  
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
    if ((test_state == WR_TEST_PATT_0) || module_rst) begin
      test_fault <= 0;
      data_fault_read <= {128'b0};
    end else if(ddr_dvalid_i) begin
      if (ddr_data_i != {ddr_data_cnt,ddr_data_cnt}) begin
        test_fault <= 1; 
        data_fault_read <= ddr_data_i;
      end
    end
  end

  // Data Read Block
  always @(posedge clk) begin
    if ((test_state == WR_TEST_PATT_0) || module_rst) begin
      data_rdblk_cnt <= 0;
      assign_rdblk   <= 0;
      addr_rdblk_cnt <= 0;
    end else if(ddr_dvalid_i) begin
      data_rdblk_cnt <= data_rdblk_cnt + 2;
      if ((data_rdblk_cnt >= ctrl_rdblk_addr) && (data_rdblk_cnt <= ctrl_rdblk_addr + RDBLK_SIZE)) begin
        rdblk_mem[addr_rdblk_cnt] <= ddr_data_i;
        addr_rdblk_cnt            <= addr_rdblk_cnt + 1;
      end
    end
  end

  generate 
    for (i = 0; i < RDBLK_SIZE; i = i + 1) begin : readblock_generate
      assign status_mem[RDBLK_START_ADDR + i] = rdblk_mem[i];
    end
  endgenerate

endmodule

