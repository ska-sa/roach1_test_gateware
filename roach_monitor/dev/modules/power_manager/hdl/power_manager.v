`timescale 1ns/10ps
`include "power_manager.vh"

module power_manager(
    /* Wishbone Interface */
    wb_clk_i, wb_rst_i,
    wb_cyc_i, wb_stb_i, wb_we_i,
    wb_adr_i, wb_dat_i, wb_dat_o,
    wb_ack_o,
    /* System Health */
    sys_health, unsafe_sys_health,
    /* Informational Signals */
    power_ok,
    /* Control Signals */
    cold_start, dma_done, chs_power_button,
    soft_reset, crash, chs_powerdown_pending,
    no_power_cause,
    /* ATX Power Supply Control */
    ATX_PS_ON_N, ATX_PWR_OK,
    ATX_LOAD_RES_OFF,
    /* Power Supply Control */
    TRACK_2V5,
    INHIBIT_2V5, INHIBIT_1V8, INHIBIT_1V5, INHIBIT_1V2, INHIBIT_1V0,
    MGT_AVCC_EN, MGT_AVTTX_EN, MGT_AVCCPLL_EN,
    MGT_AVCC_PG, MGT_AVTTX_PG, MGT_AVCCPLL_PG,
    AUX_3V3_PG,
    /* FET gate drivers */
    G12V_EN, G5V_EN, G3V3_EN
  );
  parameter WATCHDOG_OVERFLOW_DEFAULT = 5'b00000; //no watchdog overflows
  parameter MAX_UNACKED_CRASHES = 3'b011; // 3 crashes
  parameter MAX_UNACKED_WD_OVERFLOWS = 3'b111; //  7 overflows
  parameter SYS_HEALTH_POWERUP_MASK = 32'hffff_ffff; //all inputs must be valid
  parameter POWER_DOWN_WAIT = 32'h003f_ffff; //100ms
  parameter POST_POWERUP_WAIT = 32'h003f_ffff; //100ms

  input  wb_clk_i, wb_rst_i;
  input  wb_cyc_i, wb_stb_i, wb_we_i;
  input  [15:0] wb_adr_i;
  input  [15:0] wb_dat_i;
  output [15:0] wb_dat_o;
  output wb_ack_o;
  input  [31:0] sys_health;
  input  unsafe_sys_health;
  output power_ok;
  output [1:0] no_power_cause;
  input  cold_start, dma_done, chs_power_button;
  output soft_reset, crash, chs_powerdown_pending;
  output ATX_PS_ON_N;
  input  ATX_PWR_OK;
  output ATX_LOAD_RES_OFF;
  output TRACK_2V5;
  output INHIBIT_2V5, INHIBIT_1V8, INHIBIT_1V5, INHIBIT_1V2, INHIBIT_1V0;
  output MGT_AVCC_EN, MGT_AVTTX_EN, MGT_AVCCPLL_EN;
  input  MGT_AVCC_PG, MGT_AVTTX_PG, MGT_AVCCPLL_PG;
  input  AUX_3V3_PG;
  output G12V_EN, G5V_EN, G3V3_EN;

  /************* Common Signals *************/
  wire chs_powerdown_force; //the chs_powerdown signal was asserted for longer than 3 seconds
  wire chs_powerdown_strb; //the chs_powerdown signal was asserted briefly
  reg  power_down_strb; //tell the power-sequencer to startup
  reg  power_up_strb;   //tell the power-sequencer to shutdown

  wire power_up_done;   //the power-sequencer has finished powering up

  reg  pre_check_pass; //pre power-up checks passed
  reg  post_check_pass; //post power-up checks passed
  reg  post_check_fail; //post power-up checks failed

  reg  watchdog_overflow; //the watchdog timer was not reset and overflowed
  reg  chs_powerdown; //the chs powerdown was acknowledged

  reg  wb_powerdown_strb; //wishbone master issues a shutdown command
  reg  wb_powerup_strb; //wishbone master issues a shutdown command
  reg  wb_reset_strb;    //wishbone master issues a reset command

  reg [2:0] unacked_crashes;
  reg [2:0] unacked_wd_overflows;

  sequencer sequencer_inst(
    .reset(wb_rst_i), .clk(wb_clk_i),
    .power_up(power_up_strb), .power_down(power_down_strb),
    .power_up_done(power_up_done), .power_down_done(),
    /* Power Control Signals */
    .ATX_PS_ON_N(ATX_PS_ON_N),
    .TRACK_2V5(TRACK_2V5),
    .INHIBIT_2V5(INHIBIT_2V5), .INHIBIT_1V8(INHIBIT_1V8), .INHIBIT_1V5(INHIBIT_1V5), .INHIBIT_1V2(INHIBIT_1V2), .INHIBIT_1V0(INHIBIT_1V0),
    .MGT_AVCC_EN(MGT_AVCC_EN), .MGT_AVTTX_EN(MGT_AVTTX_EN), .MGT_AVCCPLL_EN(MGT_AVCCPLL_EN),
    .G12V_EN(G12V_EN), .G5V_EN(G5V_EN), .G3V3_EN(G3V3_EN)
  );

  /********** Power State Machine ************/

  reg [2:0] power_state;
  localparam STATE_POWERED_DOWN = 3'd0;
  localparam STATE_POWERING_UP  = 3'd1;
  localparam STATE_CHECK        = 3'd2;
  localparam STATE_POWERED_UP   = 3'd3;
  localparam STATE_NO_POWER     = 3'd4;

  assign power_ok = power_state == STATE_POWERED_UP;
  assign soft_reset = power_down_strb;

  reg [31:0] powered_down_wait;
  reg crash;

  reg [1:0] no_power_cause;

  always @(posedge wb_clk_i) begin
    //strobes
    crash <= 1'b0;
    power_up_strb <= 1'b0;
    power_down_strb <= 1'b0;

    if (wb_rst_i) begin
      powered_down_wait <= POWER_DOWN_WAIT;
      if (cold_start) begin
        power_state <= STATE_NO_POWER;
        no_power_cause <= 2'b00;
      end else begin
        power_state <= STATE_POWERED_DOWN;
      end
    end else begin
      case (power_state)
        STATE_POWERED_DOWN: begin
          if (powered_down_wait != 32'b0) begin
            powered_down_wait <= powered_down_wait - 1;
          end else if (pre_check_pass) begin
            power_state <= STATE_POWERING_UP;
            power_up_strb <= 1'b1;
          end
        end
        STATE_POWERING_UP: begin
          if (power_up_done) begin
            power_state <= STATE_CHECK;
          end
        end
        STATE_CHECK: begin
          if (post_check_fail) begin
            power_down_strb <= 1'b1;
            crash <= 1'b1;
            if (unacked_crashes == MAX_UNACKED_CRASHES) begin
              power_state <= STATE_NO_POWER;
              no_power_cause <= 2'b01;
            end else begin
              power_state <= STATE_POWERED_DOWN;
            end
          end else if (post_check_pass) begin
            power_state <= STATE_POWERED_UP;
          end
        end
        STATE_POWERED_UP: begin
          if (wb_reset_strb) begin //lowest priority
            power_down_strb <= 1'b1;
            power_state <= STATE_POWERED_DOWN;
            powered_down_wait <= POWER_DOWN_WAIT;
          end
          if (watchdog_overflow) begin
            power_down_strb <= 1'b1;
            if (unacked_wd_overflows == MAX_UNACKED_WD_OVERFLOWS) begin
              power_state <= STATE_NO_POWER;
              no_power_cause <= 2'b10;
            end else begin
              power_state <= STATE_POWERED_DOWN;
              powered_down_wait <= POWER_DOWN_WAIT;
            end
          end 
          if (unsafe_sys_health) begin
            power_down_strb <= 1'b1;
            crash <= 1'b1;
            if (unacked_crashes == MAX_UNACKED_CRASHES) begin
              power_state <= STATE_NO_POWER;
              no_power_cause <= 2'b01;
            end else begin
              power_state <= STATE_POWERED_DOWN;
              powered_down_wait <= POWER_DOWN_WAIT;
            end
          end
          if (chs_powerdown_force | chs_powerdown | wb_powerdown_strb) begin //highest priority
            power_down_strb <= 1'b1;
            power_state <= STATE_NO_POWER;
            no_power_cause <= 2'b11;
          end
        end
        STATE_NO_POWER: begin
          if (chs_powerdown_strb | wb_powerup_strb) begin
            power_state <= STATE_POWERED_DOWN;
            powered_down_wait <= POWER_DOWN_WAIT;
          end
        end
      endcase
    end
  end

  /************** Pre power-up checking ************************/
  always @(posedge wb_clk_i) begin
    if (wb_rst_i) begin
      pre_check_pass <= 1'b0;
    end else begin
      if (power_state != STATE_POWERED_DOWN) begin
        pre_check_pass <= 1'b0;
      end else begin
        if ((!(sys_health & ~SYS_HEALTH_POWERUP_MASK)) && dma_done) begin
          pre_check_pass <= 1'b1;
        end
      end
    end
  end

  /************** Post power-up checking ************************/
  reg [31:0] post_power_up_wait;
  always @(posedge wb_clk_i) begin
    if (wb_rst_i | power_state != STATE_CHECK) begin
      post_check_pass <= 1'b0;
      post_check_fail <= 1'b0;
      post_power_up_wait <= POST_POWERUP_WAIT;
    end else begin
      if (post_power_up_wait) begin
        post_power_up_wait <= post_power_up_wait - 1;
      end else begin
        if (unsafe_sys_health) begin
          post_check_fail <= 1'b1;
        end else begin
          post_check_pass <= 1'b1;
        end
      end
    end
  end

  /************** Power Button Ctrl ***************/
  reg [26:0] power_button_timer;

  assign chs_powerdown_force = power_button_timer == {27{1'b1}};
  assign chs_powerdown_strb = power_button_timer == 27'b1;
  
  always @(posedge wb_clk_i) begin
    if (wb_rst_i | soft_reset) begin
      power_button_timer <= 27'b0;
    end else begin
      if (chs_power_button) begin
        power_button_timer <= ~chs_powerdown_force ? power_button_timer + 1 : power_button_timer;
      end else begin
        power_button_timer <= 27'b0;
      end
    end
  end

  /************* Chassis Powerdown Control *********/
  reg chs_powerdown_pending;
  reg chs_powerdown_ack;

  always @(posedge wb_clk_i) begin
    chs_powerdown <= 1'b0;
    if (wb_rst_i) begin
      chs_powerdown_pending <= 1'b0;
    end else begin
      if (chs_powerdown_strb)
        chs_powerdown_pending <= 1'b1;

      if (chs_powerdown_pending && chs_powerdown_ack && power_state == STATE_POWERED_UP) begin
        chs_powerdown <= 1'b1;
        chs_powerdown_pending <= 1'b0;
      end
    end
  end
  /************* Watchdog Timer Control *********/

  reg [35:0] watchdog_timer;

  reg  [4:0] watchdog_overflow_conf;
  reg wd_overflow_ack;

  always @(posedge wb_clk_i) begin
    watchdog_overflow <= 1'b0;

    if (wd_overflow_ack)
      unacked_wd_overflows <= 3'b0;


    if (wb_rst_i || power_state == STATE_NO_POWER) begin
      watchdog_timer <= 32'b0;
      unacked_wd_overflows <= 3'b0;
    end else if (power_state != STATE_POWERED_UP) begin
      watchdog_timer <= 32'b0;
    end else begin
      if (watchdog_overflow_conf != 5'b0) begin
        if (watchdog_timer[35:31] == watchdog_overflow_conf) begin
          watchdog_timer <= 32'b0;
          watchdog_overflow <= 1'b1;
          unacked_wd_overflows <= unacked_wd_overflows + 1;
        end else begin
          watchdog_timer <= watchdog_timer + 1;
        end
      end
    end
  end
 
  /************ Crash Control *************/
  reg crash_ack;

  always @(posedge wb_clk_i) begin
    if (crash_ack)
      unacked_crashes <= 3'b0;

    if (wb_rst_i) begin
      unacked_crashes <= 3'b0;
    end else begin
      if (crash && power_state == STATE_POWERED_UP) begin
        unacked_crashes <= unacked_crashes + 1;
      end
    end
  end

  /************ WishBone Attachment **************/

  reg wb_ack_o;
  reg [3:0] wb_dat_o_sel;
  reg atx_load_res_off_reg;
  assign ATX_LOAD_RES_OFF = atx_load_res_off_reg;

  assign wb_dat_o = wb_dat_o_sel == 4'd0 ? {13'b0, power_state} :
                    wb_dat_o_sel == 4'd3 ? {13'b0, unacked_crashes} :
                    wb_dat_o_sel == 4'd4 ? {13'b0, unacked_wd_overflows} :
                    wb_dat_o_sel == 4'd5 ? {15'b0, chs_powerdown_pending} :
                    wb_dat_o_sel == 4'd6 ? {15'b0, atx_load_res_off_reg} :
                    wb_dat_o_sel == 4'd7 ? {11'b0, ATX_PWR_OK, MGT_AVCC_PG, MGT_AVTTX_PG, MGT_AVCCPLL_PG, AUX_3V3_PG} :
                    wb_dat_o_sel == 4'd8 ? {watchdog_overflow_conf} :
                    16'b0;

  always @(posedge wb_clk_i) begin
    wb_ack_o <= 1'b0;
    wb_powerdown_strb <= 1'b0;
    wb_powerup_strb <= 1'b0;
    wb_reset_strb <= 1'b0;
    crash_ack <= 1'b0;
    wd_overflow_ack <= 1'b0;
    chs_powerdown_ack <= 1'b0;

    if (soft_reset) begin
      atx_load_res_off_reg <= 1'b0;
    end

    if (wb_rst_i) begin
      atx_load_res_off_reg <= 1'b0;
      watchdog_overflow_conf <= WATCHDOG_OVERFLOW_DEFAULT;
    end else begin
      if (wb_cyc_i & wb_stb_i & ~wb_ack_o) begin
        wb_ack_o <= 1'b1;
        case (wb_adr_i)
          `REG_POWERSTATE: begin
            wb_dat_o_sel <= 4'd0;
          end
          `REG_POWERUP: begin
            wb_dat_o_sel <= 4'd1;
            if (wb_we_i) begin
              if (wb_dat_i != 16'd0) begin
                wb_powerup_strb <= 1'b1;
              end
            end
          end
          `REG_POWERDOWN: begin
            wb_dat_o_sel <= 4'd2;
            if (wb_we_i) begin
              if (wb_dat_i != 16'd0) begin
                wb_powerdown_strb <= 1'b1;
              end else begin
                wb_reset_strb <= 1'b1;
              end
            end
          end
          `REG_CRASH_CTRL: begin
            wb_dat_o_sel <= 4'd3;
            if (wb_we_i) begin
              crash_ack <= 1'b1;
            end
          end
          `REG_WATCHDOG_CTRL: begin
            wb_dat_o_sel <= 4'd4;
            if (wb_we_i) begin
              wd_overflow_ack <= 1'b1;
            end
          end
          `REG_CHS_SHUTDOWN_CTRL: begin
            wb_dat_o_sel <= 4'd5;
            if (wb_we_i) begin
              chs_powerdown_ack <= 1'b1;
            end
          end
          `REG_ATXLOADRES_CTRL: begin
            wb_dat_o_sel <= 4'd6;
            if (wb_we_i) begin
              atx_load_res_off_reg <= wb_dat_i[0];
            end
          end
          `REG_PS_POWERGDS: begin
            wb_dat_o_sel <= 4'd7;
          end
          `REG_WATCHDOG_CONF: begin
            wb_dat_o_sel <= 4'd8;
            if (wb_we_i) begin
              watchdog_overflow_conf <= wb_dat_i[4:0];
            end
          end
        endcase
      end
    end
  end

endmodule
