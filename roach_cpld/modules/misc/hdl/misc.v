`define REG_MISC_RESET       3'd0
`define REG_MISC_SYSCONFIG_0 3'd1
`define REG_MISC_SYSCONFIG_1 3'd2
`define REG_MISC_SELECTMAP   3'd3
`define REG_MISC_FLASH       3'd4
`define REG_MISC_REGS        3'd5
module misc(
    lb_clk, lb_rst,
    lb_we_i, lb_stb_i,
    lb_adr_i, lb_dat_i, lb_dat_o,
    
    por_force_n, reset_mon, gig_eth_reset_n,
    sys_config, user_dip, config_dip,
    boot_conf_oen,
    user_led,

    eeprom_0_wp, eeprom_1_wp, flash_wp_n, flash_busy_n,
    serial_busy, serial_abort
  );
  input  lb_clk, lb_rst;
  input  lb_we_i, lb_stb_i;
  input  [2:0] lb_adr_i;
  input  [7:0] lb_dat_i;
  output [7:0] lb_dat_o;
    
  output por_force_n;
  input  reset_mon;
  output gig_eth_reset_n;

  input  [7:0] sys_config;
  input  [3:0] user_dip;
  input  [3:0] config_dip;
  output boot_conf_oen;
  output [1:0] user_led;
  
  input  eeprom_0_wp, eeprom_1_wp;
  input  flash_wp_n;
  input  flash_busy_n;

  input  serial_busy;
  output serial_abort;

  reg [1:0] user_led;
  reg por_force_n, gig_eth_reset_n;
  reg boot_conf_oen;
  reg serial_abort;
  assign lb_dat_o = lb_adr_i == `REG_MISC_RESET       ? {6'b0, !gig_eth_reset_n, !por_force_n} :
                    lb_adr_i == `REG_MISC_SYSCONFIG_0 ? {config_dip, user_dip} :
                    lb_adr_i == `REG_MISC_SYSCONFIG_1 ? sys_config :
                    lb_adr_i == `REG_MISC_SELECTMAP   ? {6'b0, serial_abort, serial_busy} :
                    lb_adr_i == `REG_MISC_FLASH       ? {eeprom_1_wp, eeprom_0_wp, flash_wp_n, flash_busy_n} :
                    lb_adr_i == `REG_MISC_REGS        ? {5'b0, boot_conf_oen, user_led} :
                    8'b0;

  always @(posedge lb_clk) begin
    if (lb_rst) begin
      user_led <= 2'b0;
      por_force_n <= 1'b1;
      gig_eth_reset_n <= 1'b1;
      boot_conf_oen <= 1'b1;
      serial_abort <= 1'b0;
    end else begin
      por_force_n <= ~reset_mon;
      if (lb_stb_i & lb_we_i) begin
        case (lb_adr_i)
          `REG_MISC_RESET: begin
            por_force_n <= ~lb_dat_i[0];
            gig_eth_reset_n <= ~lb_dat_i[1];
          end
          `REG_MISC_SYSCONFIG_0: begin
          end
          `REG_MISC_SYSCONFIG_1: begin
          end
          `REG_MISC_SELECTMAP: begin
            serial_abort <= lb_dat_i[1];
          end
          `REG_MISC_FLASH: begin
          end
          `REG_MISC_REGS: begin
            user_led <= lb_dat_i[1:0];
            boot_conf_oen <= lb_dat_i[2];
          end
        endcase
      end
    end
  end 
endmodule
