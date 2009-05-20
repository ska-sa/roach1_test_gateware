module misc(
    wb_clk_i, wb_rst_i,
    wb_stb_i, wb_cyc_i, wb_we_i,
    wb_adr_i, wb_dat_i, wb_dat_o,
    wb_ack_o,
    
    por_force,
    geth_reset,

    sys_config,
    user_dip,
    config_dip,

    user_led,

    flash_busy_n,
    mmc_wp,
    mmc_cdetect
  );

  input  wb_clk_i, wb_rst_i;
  input  wb_cyc_i, wb_stb_i, wb_we_i;
  input  [2:0] wb_adr_i;
  input  [7:0] wb_dat_i;
  output [7:0] wb_dat_o;
  output wb_ack_o;
    
  output por_force;
  output geth_reset;

  input  [7:0] sys_config;
  input  [3:0] user_dip;
  input  [3:0] config_dip;
  output [1:0] user_led;
  
  input  flash_busy_n;
  input  mmc_wp;
  input  mmc_cdetect;

  localparam REG_MISC_RESET       = 3'd0;
  localparam REG_MISC_SYSCONFIG_0 = 3'd1;
  localparam REG_MISC_SYSCONFIG_1 = 3'd2;
  localparam REG_MISC_SELECTMAP   = 3'd3;
  localparam REG_MISC_FLASH       = 3'd4;
  localparam REG_MISC_REGS        = 3'd5;

  /* Registers */
  reg por_force, geth_reset;
  reg [1:0] user_led;

  assign wb_dat_o = wb_adr_i == REG_MISC_RESET       ? {6'b0, geth_reset, por_force} :
                    wb_adr_i == REG_MISC_SYSCONFIG_0 ? {config_dip, user_dip} :
                    wb_adr_i == REG_MISC_SYSCONFIG_1 ? sys_config :
                    wb_adr_i == REG_MISC_FLASH       ? {2'b0, mmc_wp, mmc_cdetect, 3'b0, flash_busy_n} :
                    wb_adr_i == REG_MISC_REGS        ? {6'b0, user_led} :
                    8'b0;

  reg wb_ack_o;
  wire wb_trans = wb_cyc_i && wb_stb_i;
  always @(posedge wb_clk_i) begin
    //strobes
    wb_ack_o <= 1'b0;

    if (wb_rst_i) begin
      user_led            <= 2'b0;
      por_force           <= 1'b0;
      geth_reset          <= 1'b0;
    end else begin
      if (wb_trans)
        wb_ack_o <= 1'b1;

      if (wb_trans & wb_we_i) begin
        case (wb_adr_i)
          REG_MISC_RESET: begin
            por_force  <= wb_dat_i[0];
            geth_reset <= wb_dat_i[1];
          end
          REG_MISC_SYSCONFIG_0: begin
          end
          REG_MISC_SYSCONFIG_1: begin
          end
          REG_MISC_SELECTMAP: begin
          end
          REG_MISC_REGS: begin
            user_led <= wb_dat_i[1:0];
          end
        endcase
      end
    end
  end 
endmodule
