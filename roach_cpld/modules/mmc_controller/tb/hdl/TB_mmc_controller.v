`timescale 1ns/10ps

`define CLK_PERIOD 10
`define SIMLENGTH 10000

module TB_mmc_controller();

  wire       wb_clk_i;
  wire       wb_rst_i;
  reg        wb_stb_i;
  reg        wb_we_i;
  reg  [2:0] wb_adr_i;
  reg  [7:0] wb_dat_i;
  wire [7:0] wb_dat_o;
  wire       wb_ack_o;

  wire       mmc_clk;
  wire       mmc_cmd_o;
  wire       mmc_cmd_i;
  wire       mmc_cmd_oe;
  wire [7:0] mmc_dat_i;
  wire [7:0] mmc_dat_o;
  wire       mmc_dat_oe;
  wire       mmc_cdetect;

  wire       irq_cdetect;
  wire       irq_got_cmd;
  wire       irq_got_dat;
  wire       irq_got_busy;

  mmc_controller mmc_controller(
    .wb_clk_i(wb_clk_i),
    .wb_rst_i(wb_rst_i),
    .wb_cyc_i(wb_stb_i),
    .wb_stb_i(wb_stb_i),
    .wb_we_i(wb_we_i),
    .wb_adr_i(wb_adr_i),
    .wb_dat_i(wb_dat_i),
    .wb_dat_o(wb_dat_o),
    .wb_ack_o(wb_ack_o),

    .mmc_clk(mmc_clk),
    .mmc_cmd_o(mmc_cmd_o),
    .mmc_cmd_i(mmc_cmd_i),
    .mmc_cmd_oe(mmc_cmd_oe),
    .mmc_dat_i(mmc_dat_i),
    .mmc_dat_o(mmc_dat_o),
    .mmc_dat_oe(mmc_dat_oe),
    .mmc_cdetect(mmc_cdetect),

    .irq_cdetect(irq_cdetect),
    .irq_got_cmd(irq_got_cmd),
    .irq_got_dat(irq_got_dat),
    .irq_got_busy(irq_got_busy)
  );


  reg reset;
  reg [31:0] clk_counter;

  initial begin
    reset<=1'b1;
    clk_counter<=32'b0;
    $dumpvars();
    #50
    reset<=1'b0;
`ifdef DEBUG
    $display("sys: reset cleared");
`endif
    #`SIMLENGTH
    $display("FAILED: simulation timed out");
    $finish;
  end

  wire clk = clk_counter < ((`CLK_PERIOD) / 2);

  always begin
    #1 clk_counter <= (clk_counter == `CLK_PERIOD - 1 ? 32'b0 : clk_counter + 1);
  end


  assign wb_clk_i = clk;
  assign wb_rst_i = reset;

  reg [31:0] progress;
  always @(posedge wb_clk_i) begin
    wb_stb_i <= 1'b0;
    if (wb_rst_i) begin
      progress <= 0;
    end else begin
      case (progress)
        0: begin
          wb_stb_i <= 1'b1;
          wb_we_i  <= 1'b1;
          wb_adr_i <= 3'd2;
          wb_dat_i <= 8'b0101_0000;
          progress <= progress + 1;
        end
        1: begin
          if (wb_ack_o) begin
            wb_stb_i <= 1'b1;
            wb_we_i  <= 1'b1;
            wb_adr_i <= 3'd4;
            wb_dat_i <= 8'b0011_0001;
            progress <= progress + 1;
          end
        end
        2: begin
          if (wb_ack_o) begin
            /* reset crcs */
            wb_stb_i <= 1'b1;
            wb_we_i  <= 1'b1;
            wb_adr_i <= 3'd5;
            wb_dat_i <= 8'b0;
            progress <= progress + 1;
          end
        end
        3: begin
          if (wb_ack_o) begin
            /* write cmd byte 0 */
            wb_stb_i <= 1'b1;
            wb_we_i  <= 1'b1;
            wb_adr_i <= 3'd0;
            wb_dat_i <= 8'b0100_0000;
            progress <= progress + 1;
          end
        end
        4: begin
          if (wb_ack_o) begin
            /* write cmd byte 1 */
            wb_stb_i <= 1'b1;
            wb_we_i  <= 1'b1;
            wb_adr_i <= 3'd0;
            wb_dat_i <= 8'b0000_0000;
            progress <= progress + 1;
          end
        end
        5: begin
          if (wb_ack_o) begin
            /* write cmd byte 2 */
            wb_stb_i <= 1'b1;
            wb_we_i  <= 1'b1;
            wb_adr_i <= 3'd0;
            wb_dat_i <= 8'b0000_0000;
            progress <= progress + 1;
          end
        end
        6: begin
          if (wb_ack_o) begin
            /* write cmd byte 3 */
            wb_stb_i <= 1'b1;
            wb_we_i  <= 1'b1;
            wb_adr_i <= 3'd0;
            wb_dat_i <= 8'b0000_0000;
            progress <= progress + 1;
          end
        end
        7: begin
          if (wb_ack_o) begin
            /* write cmd byte 4 */
            wb_stb_i <= 1'b1;
            wb_we_i  <= 1'b1;
            wb_adr_i <= 3'd0;
            wb_dat_i <= 8'b0;
            progress <= progress + 1;
          end
        end
        8: begin
          if (wb_ack_o) begin
            /* Read CRC */
            wb_stb_i <= 1'b1;
            wb_we_i  <= 1'b0;
            wb_adr_i <= 3'd5;
            progress <= progress + 1;
          end
        end
        9: begin
          if (wb_ack_o) begin
            $display("PASSED: crc = %x", wb_dat_o);
            $finish;
          end
        end
      endcase
    end
  end

  
endmodule
