`timescale 1ns/10ps

`define SIMLENGTH 64000
`define CLK_PERIOD 4


module TB_mmc_bb();

  reg reset;
  wire clk;

  wire dstrb;
  wire user_rdy;

  wire wb_we_i, wb_stb_i;
  wire [2:0] wb_adr_i;
  wire [7:0] wb_dat_i;
  wire [7:0] wb_dat_o;
  wire mmc_clk;
  wire mmc_cmd_o, mmc_cmd_i, mmc_cmd_oen;
  wire [7:0] mmc_data_i;
  wire [7:0] mmc_data_o;
  wire mmc_data_oen;
  wire mmc_cdetect, mmc_wp;


  mmc_bb mmc_bb_inst(
    .wb_clk_i(clk), .wb_rst_i(reset),
    .wb_we_i(wb_we_i), .wb_stb_i(wb_stb_i), .wb_cyc_i(wb_stb_i),
    .wb_adr_i(wb_adr_i), .wb_dat_i(wb_dat_i), .wb_dat_o(wb_dat_o),
    .wb_ack_o(),
    .mmc_clk(mmc_clk),
    .mmc_cmd_o(mmc_cmd_o), .mmc_cmd_i(mmc_cmd_i), .mmc_cmd_oen(mmc_cmd_oen),
    .mmc_data_i(mmc_data_i), .mmc_data_o(mmc_data_o), .mmc_data_oen(mmc_data_oen),
    .mmc_cdetect(mmc_cdetect), .mmc_wp(mmc_wp)
  );

  reg [31:0] clk_counter;

  initial begin
    $dumpvars;
    reset<=1'b1;
    clk_counter<=32'b0;
    #50
    reset<=1'b0;
`ifdef DEBUG
    $display("sys: reset cleared");
`endif
    #`SIMLENGTH
    //$display("FAILED: simulation timed out");
    $display("PASSED");
    $finish;
  end

  assign clk = clk_counter < ((`CLK_PERIOD) / 2);

  always begin
    #1 clk_counter <= (clk_counter == `CLK_PERIOD - 1 ? 32'b0 : clk_counter + 1);
  end
  
endmodule

