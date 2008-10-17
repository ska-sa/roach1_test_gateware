`include "dram_cpu_interface.vh"

module dram_reg_wb_attach(
    //memory wb slave IF
    wb_clk_i, wb_rst_i,
    wb_we_i, wb_cyc_i, wb_stb_i, wb_sel_i,
    wb_adr_i, wb_dat_i, wb_dat_o,
    wb_ack_o,
    phy_ready,
    cal_fail,
    dram_reset,
    arb_grant
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
  output dram_reset;
  output arb_grant;

  reg dram_reset;
  reg arb_grant;

  reg wb_ack_o;
  reg [2:0] wb_dat_o_src;
  //assign wb_dat_o = wb_dat_o_src == `REG_DRAM_PHY_READY ? {15'b0, phy_ready} :
  assign wb_dat_o = wb_dat_o_src == `REG_DRAM_PHY_READY ? {8'h0, 3'b0, cal_fail, 3'b0, phy_ready} :
                    wb_dat_o_src == `REG_DRAM_RESET     ? 16'b0              :
                    wb_dat_o_src == `REG_DRAM_FREQ      ? CLK_FREQ :
                    wb_dat_o_src == `REG_DRAM_GRANT     ? {15'b0, arb_grant} :
                    16'd0;

  always @(posedge wb_clk_i) begin
    // strobes
    wb_ack_o   <= 1'b0;
    dram_reset <= 1'b0;

    if (wb_rst_i) begin
      arb_grant <= 1'b0;
    end else begin
      if (wb_cyc_i & wb_stb_i & ~wb_ack_o) begin
        wb_ack_o <= 1'b1;
        wb_dat_o_src <= wb_adr_i[3:1];
`ifdef DEBUG
        $display("dram_wb_regs: got wb transaction - we = %x adr = %x dat = %x, %x", wb_we_i, wb_adr_i, wb_dat_i, wb_dat_o);
`endif
        case (wb_adr_i[3:1])
          `REG_DRAM_PHY_READY: begin
          end
          `REG_DRAM_RESET: begin
            if (wb_we_i & wb_sel_i[0]) begin
              dram_reset <= wb_dat_i[0];
            end
          end
          `REG_DRAM_FREQ: begin
          end
          `REG_DRAM_GRANT: begin
            if (wb_we_i & wb_sel_i[0]) begin
              arb_grant <= wb_dat_i[0];
            end
          end
        endcase
      end
    end
  end

endmodule

