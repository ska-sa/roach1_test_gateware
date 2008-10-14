`include "qdr_cpu_interface.vh"

module qdr_wb_attach(
    //memory wb slave IF
    wb_clk_i, wb_rst_i,
    wb_we_i, wb_cyc_i, wb_stb_i, wb_sel_i,
    wb_adr_i, wb_dat_i, wb_dat_o,
    wb_ack_o,
    phy_ready,
    cal_fail,
    qdr_reset
  );
  parameter CLK_FREQ = 0;
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

  input  phy_ready;
  input  cal_fail;
  output qdr_reset;

  reg qdr_reset;

  reg wb_ack_o;
  reg [2:0] wb_dat_o_src;
  //assign wb_dat_o = wb_dat_o_src == `REG_QDR_PHY_READY ? {15'b0, phy_ready} :
  assign wb_dat_o = wb_dat_o_src == `REG_QDR_PHY_READY ? {8'h0, 3'b0, cal_fail, 3'b0, phy_ready} :
                    wb_dat_o_src == `REG_QDR_RESET     ? 16'b0              :
                    wb_dat_o_src == `REG_QDR_FREQ      ? CLK_FREQ :
                    16'd0;

  always @(posedge wb_clk_i) begin
    // strobes
    wb_ack_o <= 1'b0;
    qdr_reset <= 1'b0;
    if (wb_rst_i) begin
    end else begin
      if (wb_cyc_i & wb_stb_i & ~wb_ack_o) begin
        wb_ack_o <= 1'b1;
        wb_dat_o_src <= wb_adr_i[3:1];
`ifdef DEBUG
        $display("qdr_wb_regs: got wb transaction - we = %x adr = %x dat = %x, %x", wb_we_i, wb_adr_i, wb_dat_i, wb_dat_o);
`endif
        case (wb_adr_i[3:1])
          `REG_QDR_PHY_READY: begin
          end
          `REG_QDR_RESET: begin
            if (wb_we_i & wb_sel_i[0]) begin
              qdr_reset <= wb_dat_i[0];
            end
          end
          `REG_QDR_FREQ: begin
          end
        endcase
      end
    end
  end

endmodule

