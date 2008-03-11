`include "sys_config.vh"
module sys_config(
    wb_clk_i, wb_rst_i,
    wb_stb_i, wb_cyc_i, wb_we_i,
    wb_adr_i, wb_dat_i, wb_dat_o,
    wb_ack_o,
    sys_config_vector
    ,test_in
  );
  input [15:0] test_in;
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

  assign wb_dat_o = wb_adr_i == `REG_BOARD_ID   ? BOARD_ID :
                    wb_adr_i == `REG_REV_MAJOR  ? REV_MAJOR :
                    wb_adr_i == `REG_REV_MINOR  ? REV_MINOR :
                    wb_adr_i == `REG_REV_RCS    ? REV_RCS :
                    wb_adr_i == `REG_SYS_CONFIG ? sys_config_vector :
                    test_in;
                    //16'b0;

  always @(posedge wb_clk_i) begin
    //strobes
    wb_ack_o <=1'b0;

    if (wb_rst_i) begin
      sys_config_vector <= DEFAULT_SYS_CONFIG;
    end else begin
      if (wb_cyc_i & wb_stb_i & ~wb_ack_o) begin
        wb_ack_o <=1'b1;
        if (wb_we_i) begin
          if (wb_adr_i == `REG_SYS_CONFIG) begin
            sys_config_vector <= wb_dat_i[7:0];
          end
        end
      end
    end
  end

endmodule
