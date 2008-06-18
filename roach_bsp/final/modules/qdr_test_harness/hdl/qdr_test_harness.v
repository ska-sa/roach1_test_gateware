// `define TEST_BENCH

module qdr_test_harness(

    reset_i,
    clk0,
    
    qdr_rst_o,

    cal_done_i,

    user_wr_full_i,
    user_rd_full_i,
    user_qr_valid_i,
    user_qrl_i,
    user_qrh_i,

    user_dwl_o,
    user_dwh_o,
    user_bwl_n_o,
    user_bwh_n_o,
    user_ad_wr_o,
    user_ad_rd_o,
    user_ad_w_n_o,
    user_d_w_n_o,
    user_r_n_o,
    
    qdr_request_o, qdr_granted_i,

    wb_clk_i, wb_rst_i,
    wb_cyc_i, wb_stb_i, wb_we_i , wb_sel_i,
    wb_adr_i, wb_dat_i, wb_dat_o,
    wb_ack_o
`ifdef TEST_BENCH ,harness_control_test `endif
  );

  // Module Definitions
  parameter  DATA_WIDTH         = 18;
  parameter  STATUS_WORDS       = 5; //(DATA_WIDTH*4)/16; Number 16 bit words in a status memory location
  parameter  ADDR_WIDTH         = 22;
  parameter  BW_WIDTH           = 2;
  
  parameter  FAULTMEM_SIZE_BITS   = 2;
  parameter  FAULTMEM_SIZE        = 1 << FAULTMEM_SIZE_BITS;
  parameter  RDBLK_SIZE_BITS      = 2;                      // Read block addressing bits
  parameter  RDBLK_SIZE           = 1 << RDBLK_SIZE_BITS;   // 128 bit word locations

  parameter  STATUS_START_ADDR    = 5;
  parameter  FIFO_AFULL_ADDR      = STATUS_START_ADDR + 1;  // Status register size = 1
  parameter  DATAFAULT_START_ADDR = FIFO_AFULL_ADDR + 2;    // Fifo almost full register size = 2
  parameter  ADDRFAULT_START_ADDR = DATAFAULT_START_ADDR + (FAULTMEM_SIZE*STATUS_WORDS); // x 16 bit words per data fault
  parameter  RDBLK_START_ADDR     = ADDRFAULT_START_ADDR + (FAULTMEM_SIZE*2); // x 16 bit words per address fault  
  parameter  RDBLKADDR_START_ADDR = RDBLK_START_ADDR + (RDBLK_SIZE*STATUS_WORDS);
  parameter  STATUS_MEM_DEPTH     = RDBLKADDR_START_ADDR + (RDBLK_SIZE*2); // x 16 bit words per read

  // Inputs & Outputs
  input  clk0, reset_i;

  output  qdr_rst_o;

  input  cal_done_i;

  input  user_wr_full_i;
  input  user_rd_full_i;
  input  user_qr_valid_i;
  input  [DATA_WIDTH - 1:0] user_qrl_i;
  input  [DATA_WIDTH - 1:0] user_qrh_i;

  output [DATA_WIDTH - 1:0] user_dwl_o;
  output [DATA_WIDTH - 1:0] user_dwh_o;
  output [BW_WIDTH - 1:0] user_bwl_n_o;
  output [BW_WIDTH - 1:0] user_bwh_n_o;
  output [ADDR_WIDTH - 1:0] user_ad_wr_o;
  output [ADDR_WIDTH - 1:0] user_ad_rd_o;
  output user_ad_w_n_o;
  output user_d_w_n_o;
  output user_r_n_o;
    
  output qdr_request_o;
  input  qdr_granted_i;

  input  wb_clk_i, wb_rst_i;
  input  wb_cyc_i, wb_stb_i, wb_we_i;
  input  [1:0] wb_sel_i;
  input  [31:0] wb_adr_i;
  input  [15:0] wb_dat_i;
  output [15:0] wb_dat_o;
  output wb_ack_o;

`ifdef TEST_BENCH  
  input [79:0] harness_control_test;
  wire [15:0] status_addr_temp;
`endif

  // Internal variables
   
    // State machine registers
      reg [2:0] test_state;
    // Test state machine states
      localparam TEST_IDLE      = 4'b0000;
      localparam WR_TEST_PATT_0 = 4'b0001;
      localparam WR_TEST_PATT_1 = 4'b0010;
      localparam TEST_WAIT      = 4'b0011;
      localparam RD_TEST_PATT_0 = 4'b0100;
      localparam RD_TEST_PATT_1 = 4'b0101;
      localparam WAIT_FOR_DATA  = 4'b0110;
      localparam RD_BACKOFF     = 4'b0111;
      localparam WR_BACKOFF     = 4'b1000;
    // Address & Data Counters / Generators
      reg  [ADDR_WIDTH - 1:0] mem_addr;
      reg  [DATA_WIDTH - 1:0] qdr_data_0;
      reg  [DATA_WIDTH - 1:0] qdr_data_1;
      reg  data_index;
      reg  [DATA_WIDTH*4 - 1:0] data_pipe_0;
      reg  [DATA_WIDTH*4 - 1:0] data_pipe;
      reg  [DATA_WIDTH - 1:0] user_dwl;
      reg  [DATA_WIDTH - 1:0] user_dwh;
      reg  [BW_WIDTH - 1:0] user_bwl_n;
      reg  [BW_WIDTH - 1:0] user_bwh_n;
      reg  qdr_dvalid_0;
      reg  qdr_dvalid_1;
      reg  qdr_dvalid_2;
      reg  compare_data;
      wire gen_data;
      wire cmp_data;
      reg  [DATA_WIDTH - 1:0] check_data_0;
      reg  [DATA_WIDTH - 1:0] check_data_1;
      reg  [DATA_WIDTH - 1:0] check_data_2 ;
      reg  [DATA_WIDTH - 1:0] check_data_3;
      reg  [ADDR_WIDTH - 1:0] check_addr;
    // General
      reg qdr_request;
      reg qdr_rst; 
      wire test_start_re;
      reg test_start_re0;
      wire qdr_dvalid_fe; 
      reg qdr_dvalid_fe0; 
      wire module_rst;
      reg module_rst_re;
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
      wire [ADDR_WIDTH - 1:0] ctrl_mem_size;
      wire [ADDR_WIDTH - 1:0] ctrl_rdblk_addr;
      reg  [ADDR_WIDTH - 1:0] afull_addr;
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
  
  qdr_test_h_wb qdr_test_h_wb_inst(
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
   
`ifdef TEST_BENCH
  always @(posedge clk0) begin
    ctrl_start    <= harness_control_test[0];
    ctrl_reset    <= harness_control_test[1];
    qdr_request   <= harness_control_test[2];
    qdr_rst       <= harness_control_test[3];
  end
  assign user_bwl_n_o  = harness_control_test[5:4];
  assign user_bwh_n_o  = harness_control_test[7:6];
  assign qdr_request_o = qdr_request;
  assign qdr_rst_o     = qdr_rst; 
  assign ctrl_mem_size = {harness_control_test[ADDR_WIDTH + 15:16] - 1;
  assign ctrl_rdblk_addr = {15'h0000,harness_control_test[63:48]};
`else
  always @(posedge clk0) begin
    ctrl_start    <= harness_control[0];
    ctrl_reset    <= harness_control[1];
    qdr_request   <= harness_control[2];
    qdr_rst       <= harness_control[3];
    user_bwl_n    <= harness_control[5:4];
    user_bwh_n    <= harness_control[7:6];
  end
  assign user_bwl_n_o  = user_bwl_n;
  assign user_bwh_n_o  = user_bwh_n;
  assign qdr_request_o = qdr_request;
  assign qdr_rst_o     = qdr_rst; 
  assign ctrl_mem_size = harness_control[ADDR_WIDTH + 15:16] - 1;
  assign ctrl_rdblk_addr = {harness_control[ADDR_WIDTH + 47:48]};
`endif

  always @(posedge clk0) begin
    if (module_rst) begin
      afull_event <= 0;
      afull_addr  <= 0; 
    end else if (user_wr_full_i && !afull_event) begin
      afull_event <= 1;
      afull_addr  <= mem_addr;
    end
  end

  assign status_mem[FIFO_AFULL_ADDR] = afull_addr[15:0];
  assign status_mem[FIFO_AFULL_ADDR + 1] = {10'b0000000000,afull_addr[21:16]};

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
  always @(posedge clk0) begin
    if (reset_i) begin
      module_rst_re <= 1;
    end else begin
      module_rst_re <= ctrl_reset;
    end
  end
  assign module_rst = (ctrl_reset && !module_rst_re) || reset_i || !cal_done_i;

  // Detect rising edge on harness_control bit 0. This indicates start of test
  // run
  always @(posedge clk0) begin
    if (module_rst) begin
      test_start_re0 <= 1;
    end else begin
      test_start_re0 <= ctrl_start;
    end
  end
 assign test_start_re = ctrl_start && !test_start_re0;
  
  // Detect negative edge on qdr_dvalid_2
  always @(posedge clk0) begin
    if (module_rst) begin
      qdr_dvalid_fe0 <= 0;
    end else begin
      qdr_dvalid_fe0 <= qdr_dvalid_2;
    end
  end
  assign qdr_dvalid_fe = !qdr_dvalid_2 && qdr_dvalid_fe0;
  
  // Main state machine
  always @(posedge clk0) begin
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
          if (mem_addr == ctrl_mem_size) begin
            test_state <= TEST_WAIT;
          end else if (user_wr_full_i) begin  //Check almost full flag at end of 4 burst write
            test_state <= WR_BACKOFF;
          end else begin
            test_state <= WR_TEST_PATT_0; 
          end
        end
        WR_BACKOFF : begin
          if (!user_wr_full_i) begin
            test_state <= WR_TEST_PATT_0;
          end else begin
            test_state <= WR_BACKOFF;
          end
        end
        TEST_WAIT : begin
          test_state <= RD_TEST_PATT_0;
        end 
        RD_TEST_PATT_0 : begin
          test_state <= RD_TEST_PATT_1;
        end  
        RD_TEST_PATT_1 : begin
          if (mem_addr == ctrl_mem_size) begin
            test_state <= WAIT_FOR_DATA;
          end else if (user_rd_full_i) begin  //Check almost full flag at end of 4 burst write
            test_state <= RD_BACKOFF;
          end else begin
            test_state <= RD_TEST_PATT_0;
          end
        end
        RD_BACKOFF : begin
          if (!user_rd_full_i) begin
            test_state <= RD_TEST_PATT_0;
          end else begin
            test_state <= RD_BACKOFF;
          end
        end
        WAIT_FOR_DATA : begin
          if (qdr_dvalid_fe) begin                       //ToDo: add code to ensure full memory have been read
            test_state <= TEST_IDLE;
          end else begin
            test_state <= WAIT_FOR_DATA;
          end
        end
      endcase
    end
  end

  assign user_ad_w_n_o = (test_state == WR_TEST_PATT_0) ? 1'b0 : 1'b1;
  assign user_d_w_n_o  = (test_state == WR_TEST_PATT_0) ? 1'b0 : 1'b1;

  assign user_r_n_o    = (test_state == RD_TEST_PATT_1) ? 1'b0 : 1'b1; 

  // Check when test is done
  always @(qdr_dvalid_fe or test_state or test_start_re or module_rst) begin
    if (qdr_dvalid_fe && (test_state == WAIT_FOR_DATA)) begin
      test_done <= 1;
    end else if (test_start_re || module_rst ) begin
      test_done <= 0;
    end
  end

  // Adress Generator
  
  always @(posedge clk0) begin
    if ((test_state == TEST_IDLE) || (test_state == TEST_WAIT)) begin
      mem_addr <= 0;
    end else if ((test_state == WR_TEST_PATT_1) || (test_state == RD_TEST_PATT_1)) begin
      mem_addr <= mem_addr + 1;
    end
  end  
  assign user_ad_wr_o = mem_addr;
  assign user_ad_rd_o = mem_addr;

  // Write Data Generator
  always @(posedge clk0) begin
    if (test_state == TEST_IDLE) begin
      user_dwl <= 0;
      user_dwh <= 1;
    end else if ((test_state == WR_TEST_PATT_1) || (test_state == WR_TEST_PATT_0)) begin
      user_dwl <= user_dwl + 2;
      user_dwh <= user_dwh + 2;
    end
  end  
  assign user_dwl_o = user_dwl;
  assign user_dwh_o = user_dwh;

  // Incomming data pipeline
  always @(posedge clk0) begin
    if (!user_qr_valid_i) begin
      data_index <= 0;
    end else begin
      data_index <= !data_index;
    end
  end
  
  always @(posedge clk0) begin
    if (user_qr_valid_i) begin
      if (!data_index) begin
        data_pipe_0[DATA_WIDTH*2 - 1:0] <= {user_qrh_i,user_qrl_i};
      end else begin
        data_pipe_0[DATA_WIDTH*4 - 1:DATA_WIDTH*2] <= {user_qrh_i,user_qrl_i};
      end
    end
  end

  always @(posedge clk0) begin
    if (!data_index) begin
      data_pipe <= data_pipe_0;
    end
  end

  always @(posedge clk0) begin
    qdr_dvalid_0 <= user_qr_valid_i;
    qdr_dvalid_1 <= qdr_dvalid_0;
    qdr_dvalid_2 <= qdr_dvalid_1;
  end

  // compare_data and qdr_dvalid_2 is used to control the data comparator and data generator

  always @(posedge clk0) begin
    if (!qdr_dvalid_2) begin
      compare_data <= 0;
    end else begin
      compare_data <= !compare_data;
    end
  end 
  assign gen_data = compare_data && qdr_dvalid_2;
  assign cmp_data = !compare_data && qdr_dvalid_2;

  // Check data generator
  always @(posedge clk0) begin
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
  always @(posedge clk0) begin
    if (test_state == TEST_WAIT) begin
      check_addr <= 0;
    end else if (gen_data) begin
      check_addr <= check_addr + 1;
    end
  end

  // Data Comparator
  always @(posedge clk0) begin
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
  always @(posedge clk0) begin
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
      for (j = 0; j < STATUS_WORDS; j = j + 1) begin : assign_faultdata_generate
        if (j == STATUS_WORDS - 1) begin
          assign status_mem[DATAFAULT_START_ADDR + (i*STATUS_WORDS) + j ] = datafault_mem[i][((DATA_WIDTH*4) - (j*16) - 1) + (j*16):(j*16)];
        end else begin
          assign status_mem[DATAFAULT_START_ADDR + (i*STATUS_WORDS) + j ] = datafault_mem[i][15 + (j*16):(j*16)];
        end 
      end
    end
  endgenerate

  generate 
    for (i = 0; i < FAULTMEM_SIZE; i = i + 1) begin : faultaddr_generate
      assign status_mem[ADDRFAULT_START_ADDR + (i*2)] = addrfault_mem[i][15:0];
      assign status_mem[ADDRFAULT_START_ADDR + (i*2) + 1] = {{(16*2 - ADDR_WIDTH){1'b0}},addrfault_mem[i][ADDR_WIDTH - 1:16]};
    end
  endgenerate

  generate 
    for (i = 0; i < RDBLK_SIZE; i = i + 1) begin : readblock_generate
      for (j = 0; j < STATUS_WORDS; j = j + 1) begin : assign_status_mem_generat
        if (j == STATUS_WORDS - 1) begin
          assign status_mem[RDBLK_START_ADDR + (i*STATUS_WORDS) + j ] = datafault_mem[i][((DATA_WIDTH*4) - (j*16) - 1) + (j*16):(j*16)];
        end else begin
          assign status_mem[RDBLK_START_ADDR + (i*STATUS_WORDS) + j ] = datafault_mem[i][15 + (j*16):(j*16)];
        end 
      end
    end
  endgenerate

  generate 
    for (i = 0; i < RDBLK_SIZE; i = i + 1) begin : readblock_addr_generayte
      assign status_mem[RDBLKADDR_START_ADDR + (i*2)] = rdblk_addr_mem[i][15:0];
      assign status_mem[RDBLKADDR_START_ADDR + (i*2) + 1] = {{(16*2 - ADDR_WIDTH){1'b0}},rdblk_addr_mem[i][ADDR_WIDTH - 1:16]};
    end
  endgenerate

endmodule

