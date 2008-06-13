// `define TEST_BENCH

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
    wb_ack_o
`ifdef TEST_BENCH ,harness_control_test `endif
  );

  // Module Definitions
  parameter  DATA_WIDTH         = 64;
  parameter  DATA_BYTES         = (DATA_WIDTH*2)/8;
  parameter  DATA_BITS_PER_MASK = 8;
  parameter  ADDR_WIDTH         = 31;
  localparam MASK_WIDTH         = DATA_WIDTH/8;
  
  parameter  FAULTMEM_SIZE_BITS   = 2;
  parameter  FAULTMEM_SIZE        = 1 << FAULTMEM_SIZE_BITS;
  parameter  RDBLK_SIZE_BITS      = 2;                      // Read block addressing bits
  parameter  RDBLK_SIZE           = 1 << RDBLK_SIZE_BITS;   // 128 bit word locations

  parameter  STATUS_START_ADDR    = 5;
  parameter  FIFO_AFULL_ADDR      = STATUS_START_ADDR + 1;  // Status register size = 1
  parameter  DATAFAULT_START_ADDR = FIFO_AFULL_ADDR + 2;    // Fifo almost full register size = 2
  parameter  ADDRFAULT_START_ADDR = DATAFAULT_START_ADDR + (FAULTMEM_SIZE*DATA_BYTES); // x 16 bit words per data fault
  parameter  RDBLK_START_ADDR     = ADDRFAULT_START_ADDR + (FAULTMEM_SIZE*2); // x 16 bit words per address fault  
  parameter  RDBLKADDR_START_ADDR = RDBLK_START_ADDR + (RDBLK_SIZE*DATA_BYTES);
  parameter  STATUS_MEM_DEPTH     = RDBLKADDR_START_ADDR + (RDBLK_SIZE*2); // x 16 bit words per read

  // Inputs & Outputs
  input  clk, reset;
  output ddr_rd_wr_n_o;                    //read/not-write  -- latched on ddr_af_we_o 
  output [ADDR_WIDTH - 1:0] ddr_addr_o;    //address         -- latched on ddr_af_we_o
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

`ifdef TEST_BENCH  
  input [79:0] harness_control_test;
  wire [15:0] status_addr_temp;
`endif

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
    // Address & Data Counters / Generators
      reg  [ADDR_WIDTH - 1:2] ddr_addr;
      reg  [DATA_WIDTH - 1:0] ddr_data_0;
      reg  [DATA_WIDTH - 1:0] ddr_data_1;
      reg  data_index;
      reg  [DATA_WIDTH*4 - 1:0] data_pipe_0;
      reg  [DATA_WIDTH*4 - 1:0] data_pipe;
      reg  ddr_dvalid_0;
      reg  ddr_dvalid_1;
      reg  ddr_dvalid_2;
      reg  compare_data;
      wire gen_data;
      wire cmp_data;
      reg  [DATA_WIDTH - 1:0] check_data_0;
      reg  [DATA_WIDTH - 1:0] check_data_1;
      reg  [DATA_WIDTH - 1:0] check_data_2 ;
      reg  [DATA_WIDTH - 1:0] check_data_3;
      reg  [ADDR_WIDTH - 1:0] check_addr;
    // General
      wire test_start_re;
      reg test_start_re0;
      wire ddr_dvalid_fe; 
      reg ddr_dvalid_fe0; 
      wire module_rst;
      reg module_rst_re;
      wire af_df_afull;
      reg [FAULTMEM_SIZE_BITS:0] fault_cnt;
      reg [DATA_WIDTH*4 - 1:0] datafault_mem [0:FAULTMEM_SIZE - 1];
      reg [ADDR_WIDTH - 1:0] addrfault_mem [0:FAULTMEM_SIZE - 1];
      reg [RDBLK_SIZE_BITS - 1:0] rdblk_cnt;
      reg [DATA_WIDTH*4 - 1:0] rdblk_mem [0:RDBLK_SIZE - 1];
      reg [ADDR_WIDTH - 1:0] rdblk_addr_mem [0:FAULTMEM_SIZE - 1];

    // Test harness communications

      wire [20:0] status_addr;
      wire [15:0] harness_status;  //test harness control and status
      wire [79:0] harness_control;
      wire [ADDR_WIDTH - 3:0] ctrl_ddr_size;
      wire [ADDR_WIDTH - 1:0] ctrl_rdblk_addr;
      reg  [ADDR_WIDTH - 3:0] afull_addr;
      reg  ctrl_reset;
      reg  ctrl_start;
      reg  test_done;
      reg  test_fault;
      reg  afull_event;
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
 
`ifdef TEST_BENCH
  always @(posedge clk) begin
    ctrl_start <= harness_control_test[0];
    ctrl_reset <= harness_control_test[1];
  end
  assign ctrl_ddr_size = {harness_control_test[44:16] - 1;
  assign ctrl_rdblk_addr = {15'h0000,harness_control_test[63:48]};
`else
  always @(posedge clk) begin
    ctrl_start <= harness_control[0];
    ctrl_reset <= harness_control[1];
  end
  assign ctrl_ddr_size = harness_control[44:16] - 1;
  assign ctrl_rdblk_addr = {15'h0000,harness_control[63:48]};
`endif

  always @(posedge clk) begin
    if (module_rst) begin
      afull_event <= 0;
      afull_addr  <= {(ADDR_WIDTH - 2){1'b0}};
    end else if (af_df_afull && !afull_event) begin
      afull_event <= 1;
      afull_addr  <= ddr_addr;
    end
  end

  assign status_mem[FIFO_AFULL_ADDR] = afull_addr[15:0];
  assign status_mem[FIFO_AFULL_ADDR + 1] = {3'b000,afull_addr[28:16]};

  assign status_mem[STATUS_START_ADDR][0] = test_done;
  assign status_mem[STATUS_START_ADDR][1] = test_fault;
  assign status_mem[STATUS_START_ADDR][2] = afull_event;
  assign status_mem[STATUS_START_ADDR][15:3] = {13'b0};

`ifdef TEST_BENCH
  assign status_addr_temp = harness_control_test[79:64]; 
  assign harness_status = status_mem[status_addr_temp];
`else
  assign harness_status = status_mem[status_addr];
`endif

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
      ddr_dvalid_fe0 <= ddr_dvalid_2;
    end
  end
  assign ddr_dvalid_fe = !ddr_dvalid_2 && ddr_dvalid_fe0;
  
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
          end else if (af_df_afull) begin  //Check almost full flag at end of 4 burst write
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
          end else if (af_df_afull) begin  //Check almost full flag at end of 4 burst write
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
      ddr_addr <= {(ADDR_WIDTH - 2){1'b0}};
    end else if ((test_state == WR_TEST_PATT_1) || (test_state == RD_TEST_PATT)) begin
      ddr_addr <= ddr_addr + 1;
    end
  end  
  assign ddr_addr_o = {ddr_addr,2'b0};
  
  // Write Data Generator
  always @(posedge clk) begin
    if (test_state == TEST_IDLE) begin
      ddr_data_0 <= 0;
      ddr_data_1 <= 1;
    end else if ((test_state == WR_TEST_PATT_1) || (test_state == WR_TEST_PATT_0)) begin
      ddr_data_0 <= ddr_data_0 + 2;
      ddr_data_1 <= ddr_data_1 + 2;
    end
  end  
  
  assign ddr_data_o = {ddr_data_1,ddr_data_0}; 

  // Incomming data pipeline
  always @(posedge clk) begin
    if (!ddr_dvalid_i) begin
      data_index <= 0;
    end else begin
      data_index <= !data_index;
    end
  end
  
  always @(posedge clk) begin
    if (ddr_dvalid_i) begin
      if (!data_index) begin
        data_pipe_0[DATA_WIDTH*2 - 1:0] <= ddr_data_i;
      end else begin
        data_pipe_0[DATA_WIDTH*4 - 1:DATA_WIDTH*2] <= ddr_data_i;
      end
    end
  end

  always @(posedge clk) begin
    if (!data_index) begin
      data_pipe <= data_pipe_0;
    end
  end

  always @(posedge clk) begin
    ddr_dvalid_0 <= ddr_dvalid_i;
    ddr_dvalid_1 <= ddr_dvalid_0;
    ddr_dvalid_2 <= ddr_dvalid_1;
  end

  // compare_data and ddr_dvalid_2 is used to control the data comparator and data generator

  always @(posedge clk) begin
    if (!ddr_dvalid_2) begin
      compare_data <= 0;
    end else begin
      compare_data <= !compare_data;
    end
  end 
  assign gen_data = compare_data && ddr_dvalid_2;
  assign cmp_data = !compare_data && ddr_dvalid_2;

  // Check data generator
  always @(posedge clk) begin
    if (test_state == TEST_WAIT) begin
      check_data_0 <= 0;
      check_data_1 <= 1;
      check_data_2 <= 2; 
      check_data_3 <= 3;
    end else if (gen_data) begin
      check_data_0 <= check_data_0 + 4;
      check_data_1 <= check_data_1 + 4;
      check_data_2 <= check_data_2 + 4;
      check_data_3 <= check_data_3 + 4;
    end
  end

  // Check address generator
  always @(posedge clk) begin
    if (test_state == TEST_WAIT) begin
      check_addr <= 0;
    end else if (gen_data) begin
      check_addr <= check_addr + 4;
    end
  end

  // Data Comparator
  always @(posedge clk) begin
    if ((test_state == WR_TEST_PATT_0) || module_rst) begin
      test_fault       <= 0;
      fault_cnt        <= 0;
      //datafault_mem    <= 0;
      //addrfault_mem    <= 0;
    end else if (cmp_data) begin
      if (data_pipe != {check_data_3,check_data_2,check_data_1,check_data_0}) begin
        test_fault <= 1; 
        if (fault_cnt == FAULTMEM_SIZE) begin
          fault_cnt <= FAULTMEM_SIZE;
        end else begin
          fault_cnt <= fault_cnt + 1;
          datafault_mem[fault_cnt] <= data_pipe;
          addrfault_mem[fault_cnt] <= check_addr;
        end  
      end
    end
  end

  // Data Read Block
  always @(posedge clk) begin
    if ((test_state == WR_TEST_PATT_0) || module_rst) begin
      rdblk_cnt <= 0;
      //rdblk_mem <= 0;
      //rdblk_addr_mem <= 0;
    end else if(cmp_data) begin
      if (rdblk_cnt == RDBLK_SIZE) begin
        rdblk_cnt <= RDBLK_SIZE;
      end else if ((check_addr == ctrl_rdblk_addr) || (rdblk_cnt != 0)) begin
        rdblk_cnt <= rdblk_cnt + 1;
        rdblk_mem[rdblk_cnt] <= data_pipe;
        rdblk_addr_mem[rdblk_cnt] <= check_addr;
      end
    end
  end

  genvar j;
  genvar i;

  generate 
    for (i = 0; i < FAULTMEM_SIZE; i = i + 1) begin : faultdata_generate
      for (j = 0; j < DATA_BYTES; j = j + 1) begin : assign_faultdata_generate
        assign status_mem[DATAFAULT_START_ADDR + (i*DATA_BYTES) + j ] = datafault_mem[i][15 + (j*16):(j*16)];
      end
    end
  endgenerate

  generate 
    for (i = 0; i < FAULTMEM_SIZE; i = i + 1) begin : faultaddr_generate
      assign status_mem[ADDRFAULT_START_ADDR + (i*2)] = addrfault_mem[i][15:0];
      assign status_mem[ADDRFAULT_START_ADDR + (i*2) + 1] = {1'b0,addrfault_mem[i][ADDR_WIDTH - 1:16]};
    end
  endgenerate

  generate 
    for (i = 0; i < RDBLK_SIZE; i = i + 1) begin : readblock_generate
      for (j = 0; j < DATA_BYTES; j = j + 1) begin : assign_status_mem_generat
        assign status_mem[RDBLK_START_ADDR + (i*DATA_BYTES) + j ] = rdblk_mem[i][15 + (j*16):(j*16)];
      end
    end
  endgenerate

  generate 
    for (i = 0; i < RDBLK_SIZE; i = i + 1) begin : readblock_addr_generayte
      assign status_mem[RDBLKADDR_START_ADDR + (i*2)] = rdblk_addr_mem[i][15:0];
      assign status_mem[RDBLKADDR_START_ADDR + (i*2) + 1] = {1'b0,rdblk_addr_mem[i][ADDR_WIDTH - 1:16]};
    end
  endgenerate

endmodule

