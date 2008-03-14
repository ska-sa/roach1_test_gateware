`define SIMLENGTH 10000
`define CLK_PERIOD 2

`define NUM_MASTERS  4
`define NUM_SLAVES   11

`define TEST_SL_INDEX  1
`define TEST_BASE_ADDR 16'h0100
`define TEST_ADDR      16'h140
`define TEST_DATA      16'h400

`define FAIL_ADDR_RDWR 16'h1000
`define FAIL_ADDR_RD   16'h0
`define FAIL_ADDR_WR   16'h1

`define TIMEOUT_0      20'd1000
`define TIMEOUT_1      20'd10
`define TO_ADDR_0      16'h80
`define TO_ADDR_1      16'h430

`define RESTRICTION0 ({{`NUM_MASTERS{1'b1}}, 16'hffff, 16'h1000, 1'b1, 1'b1})
// no rd or wr to anything from 0x1000 on
`define RESTRICTION1 ({{`NUM_MASTERS{1'b1}},    16'd0,    16'd0, 1'b1, 1'b0})
// no rd to 0x0 
`define RESTRICTION2 ({{`NUM_MASTERS{1'b1}},    16'd1,    16'd1, 1'b0, 1'b1})
// no wr to 0x1 
`define TOCONF0      ({20'd1000, 16'h100, 16'h0  })
// 1000 cycle delay from 0x100 to 0x0
`define TOCONF1      ({20'd100,  16'h300, 16'h200})
// 100 cycle delay from 0x200 to 0x100
`define TODEFAULT    ({20'd10})
// 10  cycle timeout default


`define A0_BASE 16'h0000
`define A0_HIGH 16'h0100
`define A1_BASE 16'h0100
`define A1_HIGH 16'h0200
`define A2_BASE 16'h0200
`define A2_HIGH 16'h0300
`define A3_BASE 16'h0300
`define A3_HIGH 16'h0400
`define A4_BASE 16'h0400
`define A4_HIGH 16'h0500
`define A5_BASE 16'h0500
`define A5_HIGH 16'h0600
`define A6_BASE 16'h0600
`define A6_HIGH 16'h0700
`define A7_BASE 16'h0700
`define A7_HIGH 16'h0800
`define A8_BASE 16'h0800
`define A8_HIGH 16'h0900
`define A9_BASE 16'h0900
`define A9_HIGH 16'h1000
`define A10_BASE 16'h1000
`define A10_HIGH 16'h1100

module TB_wbs_arbiter();

  reg reset;
  wire clk;

  reg   wbm_cyc_i;
  reg   wbm_stb_i;
  reg   wbm_we_i;
  reg   [15:0] wbm_adr_i;
  reg   [15:0] wbm_dat_i;
  wire  [15:0] wbm_dat_o;
  wire  wbm_ack_o;
  wire  wbm_err_o;

  wire [`NUM_SLAVES - 1:0] wbs_cyc_o;
  wire [`NUM_SLAVES - 1:0] wbs_stb_o;
  wire wbs_we_o;
  wire [15:0] wbs_adr_o;
  wire [15:0] wbs_dat_o;
  reg  [16*(`NUM_SLAVES) - 1:0] wbs_dat_i;
  reg  [`NUM_SLAVES - 1:0] wbs_ack_i;

  wire [1:0] wbm_id = 2'b11;
  wire bm_memv;
  wire [1:0] bm_wbm_id;
  wire [15:0] bm_addr;
  wire bm_we;
  wire bm_timeout;

  wbs_arbiter #(
    .NUM_MASTERS(`NUM_MASTERS),
    .RESTRICTION0(`RESTRICTION0),
    .RESTRICTION1(`RESTRICTION1),
    .RESTRICTION2(`RESTRICTION2),
    .TOCONF0(`TOCONF0),
    .TOCONF1(`TOCONF1),
    .TODEFAULT(`TODEFAULT),
    .A0_BASE(`A0_BASE),
    .A0_HIGH(`A0_HIGH),
    .A1_BASE(`A1_BASE),
    .A1_HIGH(`A1_HIGH),
    .A2_BASE(`A2_BASE),
    .A2_HIGH(`A2_HIGH),
    .A3_BASE(`A3_BASE),
    .A3_HIGH(`A3_HIGH),
    .A4_BASE(`A4_BASE),
    .A4_HIGH(`A4_HIGH),
    .A5_BASE(`A5_BASE),
    .A5_HIGH(`A5_HIGH),
    .A6_BASE(`A6_BASE),
    .A6_HIGH(`A6_HIGH),
    .A7_BASE(`A7_BASE),
    .A7_HIGH(`A7_HIGH),
    .A8_BASE(`A8_BASE),
    .A8_HIGH(`A8_HIGH),
    .A9_BASE(`A9_BASE),
    .A9_HIGH(`A9_HIGH)
  ) wbs_arbiter_inst(
    .wb_clk_i(clk), .wb_rst_i(reset),
    .wbm_cyc_i(wbm_cyc_i), .wbm_stb_i(wbm_stb_i), .wbm_we_i(wbm_we_i),
    .wbm_adr_i(wbm_adr_i), .wbm_dat_i(wbm_dat_i), .wbm_dat_o(wbm_dat_o),
    .wbm_ack_o(wbm_ack_o), .wbm_err_o(wbm_err_o),
    .wbs_cyc_o(wbs_cyc_o), .wbs_stb_o(wbs_stb_o), .wbs_we_o(wbs_we_o),
    .wbs_adr_o(wbs_adr_o), .wbs_dat_o(wbs_dat_o), .wbs_dat_i(wbs_dat_i),
    .wbs_ack_i(wbs_ack_i),
    .wbm_id(wbm_id),
    .bm_memv(bm_memv),
    .bm_wbm_id(bm_wbm_id),
    .bm_addr(bm_addr),
    .bm_we(bm_we),
    .bm_timeout(bm_timeout)
  );


  reg [31:0] clk_counter;

  initial begin
    reset<=1'b1;
    clk_counter<=32'b0;
    #50
    reset<=1'b0;
`ifdef DEBUG
    $display("sys: reset cleared");
`endif
    #`SIMLENGTH
    $display("FAILED: simulation timed out");
    $finish;
  end

  assign clk = clk_counter < ((`CLK_PERIOD) / 2);

  always begin
    #1 clk_counter <= (clk_counter == `CLK_PERIOD - 1 ? 32'b0 : clk_counter + 1);
  end

  /********** Mode Control ***********/
`define MODE_PASS_WR   3'd0
`define MODE_PASS_RD   3'd1
`define MODE_FAIL_WR   3'd2
`define MODE_FAIL_RD   3'd3
`define MODE_FAIL_RDWR 3'd4
`define MODE_TO_0      3'd5
`define MODE_TO_1      3'd6

  reg [2:0] mode;
  reg mode_done_strb;

  reg [31:0] timer;

  reg [15:0] slave_mem;
  reg [15:0] master_mem;

  reg bus_err;

  always @(posedge clk) begin
    if (reset) begin
      mode <= `MODE_PASS_WR;
    end else begin
      case (mode)
        `MODE_PASS_WR:begin
          if (mode_done_strb) begin
            if (bus_err) begin
              $display("FAILED: got error when expected ack on wr");
              $finish;
            end else if (slave_mem !== `TEST_DATA) begin
              $display("FAILED: write failed");
              $finish;
            end else begin
              mode<=`MODE_PASS_RD;
            end
          end
        end
        `MODE_PASS_RD:begin
          if (mode_done_strb) begin
            if (bus_err) begin
              $display("FAILED: got error when expected ack on rd");
              $finish;
            end else if (master_mem !== `TEST_DATA) begin
              $display("FAILED: read failed");
              $finish;
            end else begin
              mode<=`MODE_FAIL_WR;
            end
          end
        end
        `MODE_FAIL_WR:begin
          if (mode_done_strb) begin
            if (~bus_err) begin
              $display("FAILED: write memory protection error");
              $finish;
            end else begin
              mode<=`MODE_FAIL_RD;
            end
          end
        end
        `MODE_FAIL_RD:begin
          if (mode_done_strb) begin
            if (~bus_err) begin
              $display("FAILED: read memory protection error");
              $finish;
            end else begin
              mode<=`MODE_FAIL_RDWR;
            end
          end
        end
        `MODE_FAIL_RDWR:begin
          if (mode_done_strb) begin
            if (~bus_err) begin
              $display("FAILED: RDWR memory protection error");
              $finish;
            end else begin
              $display("mode: mode MODE_FAIL_RDWR passed");
              mode<=`MODE_TO_0;
              timer<=32'b0;
            end
          end
        end
        `MODE_TO_0:begin
          if (mode_done_strb) begin
            if (~bus_err) begin
              $display("FAILED: no error on TO_0 error");
              $finish;
            end else if (timer - 5 < `TIMEOUT_0 || timer - 5 > `TIMEOUT_0) begin
              $display("FAILED: timeout invalid - TO_0 %d, got %d",`TIMEOUT_0,timer);
              $finish;
            end else begin
              mode<=`MODE_TO_1;
              timer<=32'b0;
            end
          end else begin
            timer<=timer+1;
          end
        end
        `MODE_TO_1:begin
          if (mode_done_strb) begin
            if (~bus_err) begin
              $display("FAILED: no error on TO_1 error");
              $finish;
            end else if (timer - 5 < `TIMEOUT_1 || timer - 5 > `TIMEOUT_1) begin
              $display("FAILED: timeout invalid - TO_1 %d, got %d",`TIMEOUT_1,timer);
              $finish;
            end else begin
              $display("PASSED");
              $finish;
            end
          end else begin
            timer<=timer+1;
          end
        end
      endcase
    end
  end
  /******************* Wishbone Slaves ******************/

  always @(posedge clk) begin
    //strobes
    wbs_ack_i <= {`NUM_SLAVES{1'b0}};
    if (reset) begin
      wbs_dat_i <= {16*(`NUM_SLAVES){1'b0}};
    end else begin
      if (wbs_cyc_o[`TEST_SL_INDEX] && wbs_stb_o[`TEST_SL_INDEX]) begin
        wbs_ack_i<=wbs_cyc_o & wbs_stb_o;
        if (wbs_adr_o == (`TEST_ADDR) - (`TEST_BASE_ADDR)) begin
          if (wbs_we_o) begin
            slave_mem <= wbs_dat_o;
          end else begin
            wbs_dat_i[((`TEST_SL_INDEX) + 1)*16 - 1: (`TEST_SL_INDEX)*16] <= slave_mem;
          end
        end
        `ifdef DEBUG
        if (wbs_we_o) begin
          $display("wbs: write - adr = %x, dat =%x", wbs_adr_o, wbs_dat_o);
        end else begin
          $display("wbs: read  - adr = %x, dat =%x", wbs_adr_o, wbs_dat_i[((`TEST_SL_INDEX) + 1)*16 - 1: (`TEST_SL_INDEX)*16]);
        end
        `endif
      end else begin
        if (mode != `MODE_TO_1 && mode != `MODE_TO_0) begin
          wbs_ack_i<=wbs_cyc_o & wbs_stb_o;
        end
      end
    end
  end
  /******************* Wishbone Master ******************/
  reg [1:0] mstate;
`define MSTATE_COMMAND 2'd0
`define MSTATE_COLLECT 2'd1
`define MSTATE_WAIT    2'd2

  always @(posedge clk) begin
    //strobes
    wbm_cyc_i <= 1'b0;
    wbm_stb_i <= 1'b0;
    mode_done_strb <= 1'b0;
    if (reset) begin
      mstate <= `MSTATE_COMMAND;
    end else begin
      case (mstate)
        `MSTATE_COMMAND: begin
          wbm_cyc_i <= 1'b1;
          wbm_stb_i <= 1'b1;
          mstate <= `MSTATE_COLLECT;
          case (mode)
            `MODE_PASS_WR: begin
              wbm_adr_i <= `TEST_ADDR;
              wbm_dat_i <= `TEST_DATA;
              wbm_we_i  <= 1'b1;
            end
            `MODE_PASS_RD: begin
              wbm_adr_i <= `TEST_ADDR;
              wbm_we_i  <= 1'b0;
            end
            `MODE_FAIL_WR: begin
              wbm_adr_i <= `FAIL_ADDR_WR;
              wbm_dat_i <= `TEST_DATA;
              wbm_we_i  <= 1'b1;
            end
            `MODE_FAIL_RD: begin
              wbm_adr_i <= `FAIL_ADDR_RD;
              wbm_we_i  <= 1'b0;
            end
            `MODE_FAIL_RDWR: begin
              wbm_adr_i <= `FAIL_ADDR_RDWR;
              wbm_we_i  <= 1'b0;
            end
            `MODE_TO_0: begin
              wbm_adr_i <= `TO_ADDR_0;
              wbm_we_i  <= 1'b0;
            end
            `MODE_TO_1: begin
              wbm_adr_i <= `TO_ADDR_1;
              wbm_we_i  <= 1'b0;
            end
          endcase
        end
        `MSTATE_COLLECT: begin
          if (wbm_ack_o) begin
            if (~wbm_we_i) begin
              if (wbm_adr_i == `TEST_ADDR) begin
                master_mem <= wbm_dat_o;
              end
            end
            mode_done_strb <= 1'b1;
            bus_err <= 1'b0;
            mstate <= `MSTATE_WAIT;
`ifdef DEBUG
            if (wbm_we_i) begin
              $display("wbm: write response, adr = %x", wbm_adr_i);
            end else begin
              $display("wbm: read response, adr = %x", wbm_adr_i);
            end
`endif
          end else if (wbm_err_o) begin
            mode_done_strb <= 1'b1;
            bus_err <= 1'b1;
            mstate <= `MSTATE_WAIT;
`ifdef DEBUG
            if (wbm_we_i) begin
              $display("wbm: write err, adr = %x", wbm_adr_i);
            end else begin
              $display("wbm: read err, adr = %x", wbm_adr_i);
            end
`endif
          end
        end
        `MSTATE_WAIT: begin
          mstate <= `MSTATE_COMMAND;
        end
      endcase
    end
  end 





  
endmodule
