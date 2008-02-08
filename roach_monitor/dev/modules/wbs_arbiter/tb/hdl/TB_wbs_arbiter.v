`define SIMLENGTH 6400
`define CLK_PERIOD 10

`define NUM_MASTERS  4
`define NUM_SLAVES   9

`define RESTRICTION0 ({16'hffff, 16'h1000, 1'b1, 1'b1, 1'b1})
// no rd or wr to anything from 0x1000 on
`define RESTRICTION1 ({16'h0, 16'h0, 1'b0, 1'b1, 1'b0})
// no rd to 0x0 
`define RESTRICTION2 ({16'd0, 16'd1, 1'b0, 1'b0, 1'b1})
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

  wire [`NUM_MASTERS - 1:0] wbm_id = 1;
  wire bm_memv;
  wire [`NUM_MASTERS - 1:0] bm_wbm_id;
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

  
endmodule
