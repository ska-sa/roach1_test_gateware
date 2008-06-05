`include "ddr2_test_harness.vh"

module dram_test_h_wb(
    //memory wb slave IF
    wb_clk_i, wb_rst_i,
    wb_we_i, wb_cyc_i, wb_stb_i, wb_sel_i,
    wb_adr_i, wb_dat_i, wb_dat_o,
    wb_ack_o,
    harness_status,
    harness_control
  );
  
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

  input  [31:0] harness_status;  //test harness control and status
  output [31:0] harness_control;

  reg [31:0] harness_control;

`define REG_DDR2_TH_STATUS_0 4'd0
`define REG_DDR2_TH_STATUS_1 4'd1
`define REG_DDR2_TH_CTRL_0   4'd2
`define REG_DDR2_TH_CTRL_1   4'd3

  reg wb_ack_o;
  reg [3:0] wb_dat_o_src;
  assign wb_dat_o = wb_dat_o_src == `REG_DDR2_TH_STATUS_0 ? harness_status [15:0 ] :
                    wb_dat_o_src == `REG_DDR2_TH_STATUS_1 ? harness_status [31:16] :
                    wb_dat_o_src == `REG_DDR2_TH_CTRL_0   ? harness_control[15:0 ] :
                    wb_dat_o_src == `REG_DDR2_TH_CTRL_1   ? harness_control[31:16] :
                    16'd0;


  always @(posedge wb_clk_i) begin
    // strobes
    wb_ack_o <= 1'b0;
    if (wb_rst_i) begin
    end else begin
      if (wb_cyc_i & wb_stb_i & ~wb_ack_o) begin
        wb_ack_o <= 1'b1;
        wb_dat_o_src <= wb_adr_i[4:1];
        case (wb_adr_i[4:1])
          `REG_DDR2_TH_STATUS_0: begin
          end
          `REG_DDR2_TH_STATUS_1: begin
          end
          `REG_DDR2_TH_CTRL_0: begin
            if (wb_we_i) begin
              if (wb_sel_i[0])
                harness_control[7:0]  <= wb_dat_i[7:0];
              if (wb_sel_i[1])
                harness_control[15:8] <= wb_dat_i[15:8];
            end
          end
          `REG_DDR2_TH_CTRL_1: begin
            if (wb_we_i) begin
              if (wb_sel_i[0])
                harness_control[23:16] <= wb_dat_i[7:0];
              if (wb_sel_i[1])
                harness_control[31:24] <= wb_dat_i[15:8];
            end
          end
        endcase
      end
    end
  end

endmodule
