`include "sys_block.vh"
module sys_block(
    //wb slave
    wb_clk_i, wb_rst_i,
    wb_we_i, wb_cyc_i, wb_stb_i, wb_sel_i,
    wb_adr_i, wb_dat_i, wb_dat_o,
    wb_ack_o,
    soft_reset,
    user_irq
  );
  parameter BOARD_ID     = 16'hdead;
  parameter REV_MAJOR    = 16'haaaa;
  parameter REV_MINOR    = 16'hbbbb;
  parameter REV_RCS      = 16'hcccc;
  parameter RCS_UPTODATE = 1'b1;

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

  output soft_reset;
  output user_irq;

  reg soft_reset, user_irq;

  reg wb_ack_o;
  reg  [3:0] wb_dat_o_sel;
  reg [15:0] scratch_pad;

  assign wb_dat_o = wb_dat_o_sel == `REG_BOARD_ID     ? BOARD_ID              :
                    wb_dat_o_sel == `REG_REV_MAJOR    ? REV_MAJOR             :
                    wb_dat_o_sel == `REG_REV_MINOR    ? REV_MINOR             :
                    wb_dat_o_sel == `REG_REV_RCS      ? REV_RCS               :
                    wb_dat_o_sel == `REG_RCS_UPTODATE ? {15'b0, RCS_UPTODATE} :
                    wb_dat_o_sel == `REG_SCRATCHPAD   ? scratch_pad           :
                    wb_dat_o_sel == `REG_SOFT_RESET   ? {15'b0, soft_reset}   :
                    wb_dat_o_sel == `REG_USER_IRQ     ? {15'b0, user_irq}     :
                    16'b0;

  always @(posedge wb_clk_i) begin
    wb_ack_o <= 1'b0;
    if (wb_rst_i) begin
      soft_reset <= 1'b0;
      user_irq   <= 1'b0;
    end else begin
      if (wb_cyc_i & wb_stb_i & ~wb_ack_o) begin
        wb_ack_o     <= 1'b1;
        wb_dat_o_sel <= wb_adr_i[4:1];

        case (wb_adr_i[4:1])
          `REG_BOARD_ID: begin
          end
          `REG_REV_MAJOR: begin
          end
          `REG_REV_MINOR: begin
          end
          `REG_REV_RCS: begin
          end
          `REG_RCS_UPTODATE: begin
          end
          `REG_SCRATCHPAD: begin
            if (wb_we_i) begin
              if (wb_sel_i[0])
                scratch_pad[7:0] <= wb_dat_i[7:0];
              if (wb_sel_i[1])
                scratch_pad[15:8] <= wb_dat_i[15:8];
            end
          end
          `REG_SOFT_RESET: begin
            if (wb_we_i && wb_sel_i[0]) begin
              soft_reset <= wb_dat_i[0];
            end
          end
          `REG_USER_IRQ: begin
            if (wb_we_i && wb_sel_i[0]) begin
              user_irq <= wb_dat_i[0];
            end
          end
        endcase
      end
    end
  end

endmodule
