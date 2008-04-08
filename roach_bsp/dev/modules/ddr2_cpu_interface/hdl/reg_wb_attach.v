`include "ddr2_cpu_interface.vh"

module reg_wb_attach(
    //memory wb slave IF
    wb_clk_i, wb_rst_i,
    wb_we_i, wb_cyc_i, wb_stb_i, wb_sel_i,
    wb_adr_i, wb_dat_i, wb_dat_o,
    wb_ack_o,
    soft_addr,
    phy_ready,
    ddr2_reset,
    ddr2_bus_rqst,
    ddr2_bus_grntd
  );
  parameter SOFT_ADDR_BITS = 4;
  
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

  output [SOFT_ADDR_BITS - 1:0] soft_addr;
  input  phy_ready;
  output ddr2_reset;
  output ddr2_bus_rqst;
  input  ddr2_bus_grntd;

  reg ddr2_reset;
  reg ddr2_bus_rqst;

  reg wb_ack_o;
  reg [2:0] wb_dat_o_src;
  assign wb_dat_o = wb_dat_o_src == `REG_DDR2_PHY_READY ? {15'b0, phy_ready}                        :
                    wb_dat_o_src == `REG_DDR2_SOFT_ADDR ? {{16 - SOFT_ADDR_BITS{1'b0}} , soft_addr} :
                    wb_dat_o_src == `REG_DDR2_RESET     ? 16'b0                                     :
                    wb_dat_o_src == `REG_DDR2_BUS_RQST  ? {15'b0, ddr2_bus_rqst}                    :
                    wb_dat_o_src == `REG_DDR2_BUS_GRNTD ? {15'b0, ddr2_bus_grntd}                   :
                    16'd0;

  reg [SOFT_ADDR_BITS - 1:0] soft_addr;

  always @(posedge wb_clk_i) begin
    // strobes
    wb_ack_o <= 1'b0;
    ddr2_reset <= 1'b0;
    if (wb_rst_i) begin
      soft_addr <= {SOFT_ADDR_BITS{1'b0}};
      ddr2_bus_rqst <= 1'b0;
    end else begin
      if (wb_cyc_i & wb_stb_i & ~wb_ack_o) begin
        wb_ack_o <= 1'b1;
        wb_dat_o_src <= wb_adr_i[3:1];
`ifdef DEBUG
        $display("ddr2_wb_regs: got wb transaction - we = %x adr = %x dat = %x, %x", wb_we_i, wb_adr_i, wb_dat_i, wb_dat_o);
`endif
        case (wb_adr_i[3:1])
          `REG_DDR2_PHY_READY: begin
          end
          `REG_DDR2_SOFT_ADDR: begin
            if (SOFT_ADDR_BITS > 8) begin
              if (wb_we_i) begin
                if (wb_sel_i[0])
                  soft_addr[7:0] <= wb_dat_i[7:0];
                if (wb_sel_i[1])
                  soft_addr[SOFT_ADDR_BITS-1:8] <= wb_dat_i[SOFT_ADDR_BITS-1:8];
              end
            end else begin
              if (wb_we_i) begin
                if (wb_sel_i[0])
                  soft_addr[SOFT_ADDR_BITS-1:0] <= wb_dat_i[SOFT_ADDR_BITS-1:0];
              end
            end
          end
          `REG_DDR2_RESET: begin
            if (wb_we_i & wb_sel_i[0]) begin
              ddr2_reset <= wb_dat_i[0];
            end
          end
          `REG_DDR2_BUS_RQST: begin
            if (wb_we_i & wb_sel_i[0]) begin
              ddr2_bus_rqst <= wb_dat_i[0];
            end
          end
          `REG_DDR2_BUS_GRNTD: begin
          end
        endcase
      end
    end
  end

endmodule
