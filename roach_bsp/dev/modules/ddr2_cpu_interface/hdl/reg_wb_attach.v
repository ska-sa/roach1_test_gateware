`include "ddr2_cpu_interface.vh"

module reg_wb_attach(
    //memory wb slave IF
    wb_clk_i, wb_rst_i,
    wb_we_i, wb_cyc_i, wb_stb_i, wb_sel_i,
    wb_adr_i, wb_dat_i, wb_dat_o,
    wb_ack_o,
    soft_addr,
    phy_ready
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

  reg wb_ack_o;
  reg wb_dat_o_src;
  assign wb_dat_o = wb_dat_o_src == `REG_DDR2_PHY_READY ? {15'b0, phy_ready} :
                    wb_dat_o_src == `REG_DDR2_SOFT_ADDR ? {{16 - SOFT_ADDR_BITS{1'b0}} , soft_addr} :

  reg [SOFT_ADDR_BITS - 1:0] soft_addr;

  always @(posedge wb_clk_i) begin
    wb_ack_o <= 1'b0;
    if (wb_rst_i) begin
      soft_addr <= {SOFT_ADDR_BITS{1'b0}};
    end else begin
      if (wb_cyc_i & wb_stb_i & ~wb_ack_o) begin
        wb_ack_o <= 1'b1;
        wb_dat_o_src <= wb_adr_i[1];
        case (wb_adr_i[1])
          `REG_DDR2_PHY_READY: begin
          end
          `REG_DDR2_SOFT_ADDR: begin
            if (SOFT_ADDR_BITS > 8) begin
              if (wb_we_i) begin
                if (wb_sel_i[0])
                  soft_addr[7:0] <= wb_dat_i[7:0]
                if (wb_sel_i[1])
                  soft_addr[SOFT_ADDR_BITS-1:8] <= wb_dat_i[SOFT_ADDR_BITS-1:8]
              end
            end else begin
              if (wb_we_i) begin
                if (wb_sel_i[0])
                  soft_addr[SOFT_ADDR_BITS-1:0] <= wb_dat_i[SOFT_ADDR_BITS-1:0]
              end
            end
          end
        endcase
      end
    end
  end

endmodule
