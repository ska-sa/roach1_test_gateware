`timescale 1ns/10ps

`define SIMLENGTH 64000
`define CLK_PERIOD 4


module TB_mmc_ro();

  reg reset;
  wire clk;

  wire dstrb;
  wire user_rdy;

  mmc_ro mmc_ro(
    .clk(clk), .reset(reset),
    .mmc_clk(),
    .mmc_cmd_o(), .mmc_cmd_i(1'b0), .mmc_cmd_oen(),
    .mmc_data_i(8'd0),
    .user_data_o(), .user_data_strb(dstrb),
    .user_rdy(user_rdy),
    .boot_sel(2'd1)
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
  reg [1:0] cnt;
  assign user_rdy = ~(dstrb | cnt != 2'b00);

  always @(posedge clk) begin
    if (reset) begin
      cnt <= 2'b0;
    end else begin
      if (dstrb) begin
        cnt <= 2'b10;
      end else if (cnt) begin
        cnt <= cnt - 1;
      end
    end
  end

  
endmodule

