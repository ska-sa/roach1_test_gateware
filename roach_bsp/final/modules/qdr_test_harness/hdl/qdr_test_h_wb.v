`include "ddr2_test_harness.vh"

module qdr_test_h_wb(
    //memory wb slave IF
    wb_clk_i, wb_rst_i,
    wb_we_i, wb_cyc_i, wb_stb_i, wb_sel_i,
    wb_adr_i, wb_dat_i, wb_dat_o,
    wb_ack_o,
    status_addr,
    harness_status,
    harness_control
  );
  
  parameter STATUS_DEPTH = 1;
  
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

  output [20:0] status_addr;
  input  [15:0] harness_status;  //test harness control and status
  output [79:0] harness_control;

  reg [79:0] harness_control;
  reg wb_ack_o;
  reg [20:0] wb_dat_o_src;
  
  assign wb_dat_o = wb_dat_o_src == `REG_DDR2_TH_CTRL_0   ? harness_control[15:0 ] :
                    wb_dat_o_src == `REG_DDR2_TH_CTRL_1   ? harness_control[31:16] :
                    wb_dat_o_src == `REG_DDR2_TH_CTRL_2   ? harness_control[47:32] :
                    wb_dat_o_src == `REG_DDR2_TH_CTRL_3   ? harness_control[63:48] :
                    wb_dat_o_src == `REG_DDR2_TH_CTRL_4   ? harness_control[79:64] :
                    harness_status;
                  
  assign status_addr = wb_dat_o_src[20:0]; 

  always @(posedge wb_clk_i) begin
    // strobes
    wb_ack_o <= 1'b0;
    if (wb_rst_i) begin
    end else begin
      if (wb_cyc_i & wb_stb_i & ~wb_ack_o) begin
        wb_ack_o <= 1'b1;
        wb_dat_o_src <= wb_adr_i[21:1];
        case (wb_adr_i[21:1])
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
          `REG_DDR2_TH_CTRL_2: begin
            if (wb_we_i) begin
              if (wb_sel_i[0])
                harness_control[39:32] <= wb_dat_i[7:0];
              if (wb_sel_i[1])
                harness_control[47:40] <= wb_dat_i[15:8];
            end
          end
          `REG_DDR2_TH_CTRL_3: begin
            if (wb_we_i) begin
              if (wb_sel_i[0])
                harness_control[55:48] <= wb_dat_i[7:0];
              if (wb_sel_i[1])
                harness_control[63:56] <= wb_dat_i[15:8];
            end
          end
          `REG_DDR2_TH_CTRL_4: begin
            if (wb_we_i) begin
              if (wb_sel_i[0])
                harness_control[71:64] <= wb_dat_i[7:0];
              if (wb_sel_i[1])
                harness_control[79:72] <= wb_dat_i[15:8];
            end
          end
        endcase
      end
    end
  end

endmodule
