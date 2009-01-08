`include "sys_config.vh"
module sys_config(
    wb_clk_i, wb_rst_i,
    wb_stb_i, wb_cyc_i, wb_we_i,
    wb_adr_i, wb_dat_i, wb_dat_o,
    wb_ack_o,
    sys_config_vector
  );
  parameter BOARD_ID  = 0;
  parameter REV_MAJOR = 0;
  parameter REV_MINOR = 0;
  parameter REV_RCS   = 0;
  parameter DEFAULT_SYS_CONFIG = 0;

  input  wb_clk_i, wb_rst_i;
  input  wb_stb_i, wb_cyc_i, wb_we_i;
  input  [15:0] wb_adr_i;
  input  [15:0] wb_dat_i;
  output [15:0] wb_dat_o;
  output wb_ack_o;

  output  [7:0] sys_config_vector;

  reg wb_ack_o;
  reg [7:0] sys_config_vector;

  reg [2:0] wb_dat_src;

  assign wb_dat_o = wb_dat_src == 3'd0 ? BOARD_ID :
                    wb_dat_src == 3'd1 ? REV_MAJOR :
                    wb_dat_src == 3'd2 ? REV_MINOR :
                    wb_dat_src == 3'd3 ? REV_RCS :
                    wb_dat_src == 3'd4 ? sys_config_vector :
                    16'b0;

  always @(posedge wb_clk_i) begin
    //strobes
    wb_ack_o <=1'b0;

    if (wb_rst_i) begin
      sys_config_vector <= DEFAULT_SYS_CONFIG;
    end else begin
      if (wb_cyc_i & wb_stb_i & ~wb_ack_o) begin
        wb_ack_o <=1'b1;
        case (wb_adr_i)
          `REG_BOARD_ID: begin
            wb_dat_src <= 3'd0;
          end
          `REG_REV_MAJOR: begin
            wb_dat_src <= 3'd1;
          end
          `REG_REV_MINOR: begin
            wb_dat_src <= 3'd2;
          end
          `REG_REV_RCS: begin
            wb_dat_src <= 3'd3;
          end
          `REG_SYS_CONFIG: begin
            wb_dat_src <= 3'd4;
          end
        endcase

        if (wb_we_i) begin
          if (wb_adr_i == `REG_SYS_CONFIG) begin
            sys_config_vector <= wb_dat_i[7:0];
          end
        end
      end
    end
  end

endmodule
