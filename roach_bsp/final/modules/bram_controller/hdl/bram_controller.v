`include "log2.v"
module bram_controller( 
    wb_clk_i, wb_rst_i,
    wb_we_i, wb_cyc_i, wb_stb_i, wb_sel_i,
    wb_adr_i, wb_dat_i, wb_dat_o,
    wb_ack_o
  );
  parameter RAM_SIZE_K = 4;
  input  wb_clk_i;
  input  wb_rst_i;
  input  wb_we_i;
  input  wb_cyc_i;
  input  wb_stb_i;
  input   [1:0] wb_sel_i;
  input  [31:0] wb_adr_i;
  input  [15:0] wb_dat_i;
  output [15:0] wb_dat_o;
  output wb_ack_o;

  wire [15:0] wb_dat_o_int;
  wire [15:0] wb_dat_i_int;

  function [15:0] swap_endianness;
    input  [15:0] d_in;
    integer i;
    begin
      for (i=0; i < 16; i=i+1) begin
        swap_endianness[i] = d_in[15 - i];
      end
    end
  endfunction

  assign wb_dat_o = swap_endianness(wb_dat_o_int);
  assign wb_dat_i_int = swap_endianness(wb_dat_i);

  /************ WishBone attach ************/

  reg wb_ack_o;
  wire wb_trans = wb_cyc_i & wb_stb_i & ~wb_ack_o;

  always @(posedge wb_clk_i) begin
    wb_ack_o <= 1'b0;
    if (wb_rst_i) begin
    end else begin
      if (wb_trans) begin
        wb_ack_o <= 1'b1;
      end
    end
  end

  /************ Block RAMs *************/
  //number of half blockrams [RAM_SIZE_K/4 rounded up]
  localparam NUM_BLOCKRAMS = ((RAM_SIZE_K + 3) >> 2);

  wire [31:0] bram_data_i;
  wire [32*NUM_BLOCKRAMS - 1:0] bram_data_o;

  wire [10:0] bram_addr_i;
  wire [4*NUM_BLOCKRAMS - 1:0] bram_wen_i;

  /* Simple Assignments */
  assign bram_addr_i = wb_adr_i[11:1];
  assign bram_data_i = {16'b0, wb_dat_i_int};

  localparam NUM_BLOCKRAMS_LOG2 = `LOG2(NUM_BLOCKRAMS);
  wire  [NUM_BLOCKRAMS_LOG2:0] ram_sel;
  assign ram_sel = wb_adr_i[12 + NUM_BLOCKRAMS_LOG2:12];

  /*
  initial begin
    $display("FUCK YOU! #=%d log2=%d", NUM_BLOCKRAMS, NUM_BLOCKRAMS_LOG2); 
  end
  */


  function [15:0] d_o_sel;
    input [NUM_BLOCKRAMS - 1:0]    sel;
    input [32*NUM_BLOCKRAMS - 1:0] bram_data_o;
    integer i;
    begin
      d_o_sel = 16'b0;
      for (i=0; i < NUM_BLOCKRAMS; i=i+1) begin
        if (i == ram_sel) begin
          //stupid iverilog work-around
          d_o_sel[ 0] = bram_data_o[32*i + 0];  d_o_sel[ 1] = bram_data_o[32*i + 1];
          d_o_sel[ 2] = bram_data_o[32*i + 2];  d_o_sel[ 3] = bram_data_o[32*i + 3];
          d_o_sel[ 4] = bram_data_o[32*i + 4];  d_o_sel[ 5] = bram_data_o[32*i + 5];
          d_o_sel[ 6] = bram_data_o[32*i + 6];  d_o_sel[ 7] = bram_data_o[32*i + 7];
          d_o_sel[ 8] = bram_data_o[32*i + 8];  d_o_sel[ 9] = bram_data_o[32*i + 9];
          d_o_sel[10] = bram_data_o[32*i + 10]; d_o_sel[11] = bram_data_o[32*i + 11];
          d_o_sel[12] = bram_data_o[32*i + 12]; d_o_sel[13] = bram_data_o[32*i + 13];
          d_o_sel[14] = bram_data_o[32*i + 14]; d_o_sel[15] = bram_data_o[32*i + 15];
        end
      end
    end
  endfunction


  assign wb_dat_o_int = d_o_sel(ram_sel, bram_data_o);

  genvar gen_j;
  generate
    for (gen_j = 0; gen_j < NUM_BLOCKRAMS; gen_j = gen_j + 1) begin: G1
      assign bram_wen_i[4*(gen_j + 1) - 1: 4*gen_j] = ram_sel == gen_j ? {2{wb_we_i & wb_trans}} & wb_sel_i : 4'b0;
    end
  endgenerate

  RAMB36 #(
    .DOA_REG(0),
    .DOB_REG(0),
    .INIT_A(18'h00000),
    .INIT_B(18'h00000),
    .READ_WIDTH_A(18),
    .READ_WIDTH_B(18),
    .SRVAL_A(18'h00000),
    .SRVAL_B(18'h00000),
    .WRITE_MODE_A("WRITE_FIRST"),
    .WRITE_MODE_B("WRITE_FIRST"),
    .WRITE_WIDTH_A(18),
    .WRITE_WIDTH_B(18),
    .INIT_00(256'h01234567_01234567_01234567_01234567_01234567_01234567_01234567_01234567)
  ) RAMB36_inst [NUM_BLOCKRAMS-1:0] (
    .DOA(bram_data_o), .DOB(), .DOPA(), .DOPB(),
    .ADDRA({1'b0, bram_addr_i, 4'b0}), .ADDRB(16'b0),
    .CLKA(wb_clk_i), .CLKB(1'b0),
    .DIA(bram_data_i), .DIB(32'b0), .DIPA(4'b0), .DIPB(4'b0),
    .ENA(1'b1), .ENB(1'b0),
    .REGCEA(1'b0), .REGCEB(1'b0),
    .SSRA(wb_rst_i), .SSRB(1'b0),
    .WEA({bram_wen_i}), .WEB(4'b0),
    .CASCADEOUTLATA(),
    .CASCADEOUTLATB(),
    .CASCADEOUTREGA(),
    .CASCADEOUTREGB(),
    .CASCADEINLATA(1'b0),
    .CASCADEINLATB(1'b0),
    .CASCADEINREGA(1'b0),
    .CASCADEINREGB(1'b0)
  );
  
endmodule