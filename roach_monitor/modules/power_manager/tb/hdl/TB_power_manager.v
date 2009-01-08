`timescale 10ns/1ps
`define SIM_LENGTH 100000
`define CLK_PERIOD 2


module TB_power_manager();
  wire clk;
  reg  reset;
  reg  wb_stb_i, wb_cyc_i, wb_we_i;
  reg  [15:0] wb_adr_i;
  reg  [15:0] wb_dat_i;
  wire [15:0] wb_dat_o;
  wire wb_ack_o;

  reg  [31:0] sys_health;
  reg  unsafe_sys_health;
  wire power_ok;
  reg  cold_start, dma_done, chs_power_button;
  wire soft_reset, crash;
  wire ATX_PS_ON_N;
  wire ATX_LOAD_RES_OFF;
  wire TRACK_2V5;
  wire INHIBIT_2V5, INHIBIT_1V8, INHIBIT_1V5, INHIBIT_1V2, INHIBIT_1V0;
  wire MGT_AVCC_EN, MGT_AVTTX_EN, MGT_AVCCPLL_EN;
  wire G12V_EN, G5V_EN, G3V3_EN;

  power_manager #(
    .POWER_DOWN_WAIT(32'd100),
    .POST_POWERUP_WAIT(32'd100),
    .WATCHDOG_OVERFLOW_DEFAULT(5'd1)
  ) power_manager_inst (
    .wb_clk_i(clk), .wb_rst_i(reset),
    .wb_cyc_i(wb_cyc_i), .wb_stb_i(wb_stb_i), .wb_we_i(wb_we_i),
    .wb_adr_i(wb_adr_i), .wb_dat_i(wb_dat_i), .wb_dat_o(wb_dat_o),
    .wb_ack_o(wb_ack_o),
    .sys_health(sys_health), .unsafe_sys_health(unsafe_sys_health),
    .power_ok(power_ok),
    .cold_start(cold_start), .dma_done(dma_done), .chs_power_button(1'b0),
    .soft_reset(soft_reset), .crash(crash),
    .ATX_PS_ON_N(ATX_PS_ON_N), .ATX_PWR_OK(~ATX_PS_ON_N),
    .ATX_LOAD_RES_OFF(ATX_LOAD_RES_OFF),
    .TRACK_2V5(TRACK_2V5),
    .INHIBIT_2V5(INHIBIT_2V5), .INHIBIT_1V8(INHIBIT_1V8), .INHIBIT_1V5(INHIBIT_1V5), .INHIBIT_1V2(INHIBIT_1V2), .INHIBIT_1V0(INHIBIT_1V0),
    .MGT_AVCC_EN(MGT_AVCC_EN), .MGT_AVTTX_EN(MGT_AVTTX_EN), .MGT_AVCCPLL_EN(MGT_AVCCPLL_EN),
    .MGT_AVCC_PG(MGT_AVCC_EN), .MGT_AVTTX_PG(MGT_AVTTX_EN), .MGT_AVCCPLL_PG(MGT_AVCCPLL_EN),
    .AUX_3V3_PG(1'b1),
    .G12V_EN(G12V_EN), .G5V_EN(G5V_EN), .G3V3_EN(G3V3_EN)
  );

  reg [7:0] clk_counter;

  initial begin
    clk_counter<=8'b0;
    reset<=1'b1;
`ifdef DEBUG
    $dumpvars;
    $display("sim: starting sim");
`endif
    #5
    reset<=1'b0;
`ifdef DEBUG
    $display("sim: clearing reset");
`endif
    #`SIM_LENGTH 
    $display("FAILED: simulation timed out");
    $finish;
  end

  assign clk = clk_counter < ((`CLK_PERIOD) / 2);

  always begin
    #1 clk_counter <= (clk_counter == `CLK_PERIOD - 1 ? 32'b0 : clk_counter + 1);
  end

  /************ MODE  ***************/
  reg [3:0] mode;
`define MODE_START_CHECK      4'd0
`define MODE_WB_RESTART       4'd1
`define MODE_WB_SHUTDOWN      4'd2
`define MODE_WB_POWERUP       4'd3
`define MODE_CRASH            4'd4
  reg [3:0] mode_progress;
  reg [31:0] mode_timer;

  reg [3:0] mode_done;

  always @(posedge clk) begin
    if (reset || soft_reset) begin
      dma_done <= 1'b0;
    end else begin
      dma_done <= 1'b1;
    end
  end

  reg got_a_n_pwrok;
  always @(posedge clk) begin
    unsafe_sys_health <= 1'b0;
    if (reset) begin
      mode <= `MODE_START_CHECK;
      mode_progress <= 4'b0;
      mode_timer <= 32'b0;

      sys_health <= {32{1'b0}};
      cold_start <= 1'b0;
    end else begin
      case (mode)
        `MODE_START_CHECK: begin
          mode_timer <= mode_timer + 1;
          case (mode_progress)
            4'd0: begin
              if (mode_timer >= 32'd40) begin
                mode_timer <= 32'd0;
                mode_progress <= 4'd1;
                if (power_ok) begin
                  $display("FAILED: invalid power_ok, mode = %d, mode_progress = %d", mode, mode_progress);
                  $finish;
                end
              end
            end
            4'd1: begin
              if (mode_timer >= 32'd40) begin
                sys_health <= {32{1'b1}};
                mode_timer <= 32'd0;
                mode_progress <= 4'd2;
                if (power_ok) begin
                  $display("FAILED: invalid power_ok, mode = %d, mode_progress = %d", mode, mode_progress);
                  $finish;
                end
              end
            end
            4'd2: begin
              if (power_ok) begin
                mode_timer <= 32'd0;
                mode_progress <= 4'd0;
                mode <= `MODE_WB_RESTART;
`ifdef DEBUG
                $display("mode: mode START_CHECK passed");
`endif
              end else if (mode_timer >= 32'd10000) begin
                $display("FAILED: expected power_ok, mode = %d, mode_progress = %d", mode, mode_progress);
                $finish;
              end
            end
          endcase
        end
        `MODE_WB_RESTART: begin
          mode_timer <= mode_timer + 1;
          case (mode_progress)
            4'd0: begin
              if (mode_done[0]) begin
                mode_timer <= 32'd0;
                mode_progress <= 4'd1;
                got_a_n_pwrok <= 1'b0;
              end
            end
            4'd1: begin
              if (mode_timer >= 32'd4000) begin
                $display("FAILED: expected power_ok, mode = %d, mode_progress = %d", mode, mode_progress);
                $finish;
              end
              if (~power_ok)
                got_a_n_pwrok <= 1'b1;
              if (power_ok & got_a_n_pwrok) begin
                mode <= `MODE_WB_SHUTDOWN;
                mode_progress <= 4'b0;
                mode_timer <= 32'b0;
`ifdef DEBUG
                $display("mode: mode WB_RESTART passed");
`endif
              end
            end
          endcase
        end
        `MODE_WB_SHUTDOWN: begin
          mode_timer <= mode_timer + 1;
          case (mode_progress)
            4'd0: begin
              if (mode_done[0]) begin
                mode_timer <= 32'd0;
                mode_progress <= 4'd1;
                got_a_n_pwrok <= 1'b0;
              end
            end
            4'd1: begin
              if (mode_timer >= 32'd20) begin
                if (~power_ok) begin
                mode <= `MODE_WB_POWERUP;
                mode_progress <= 4'b0;
                mode_timer <= 32'b0;
`ifdef DEBUG
                $display("mode: mode WB_SHUTDOWN passed");
`endif
                end else begin
                  $display("FAILED: expected ~power_ok, mode = %d, mode_progress = %d", mode, mode_progress);
                  $finish;
                end
              end
            end
          endcase
        end
        `MODE_WB_POWERUP: begin
          mode_timer <= mode_timer + 1;
          case (mode_progress)
            4'd0: begin
              if (mode_done[0]) begin
                mode_timer <= 32'd0;
                mode_progress <= 4'd1;
                got_a_n_pwrok <= 1'b0;
              end
            end
            4'd1: begin
              if (mode_timer >= 32'd4000) begin
                if (power_ok) begin
                  mode <= `MODE_CRASH;
                  mode_progress <= 4'b0;
                  mode_timer <= 32'b0;
`ifdef DEBUG
                  $display("mode: mode WB_POWERUP passed");
`endif
                end else begin
                  $display("FAILED: expected power_ok, mode = %d, mode_progress = %d", mode, mode_progress);
                  $finish;
                end
              end
            end
          endcase
        end
        `MODE_CRASH: begin
          mode_timer <= mode_timer + 1;
          case (mode_progress)
            4'd0: begin
              unsafe_sys_health <= 1'b1;
              mode_progress <= 4'd1;
              mode_timer <= 32'd0;
            end
            4'd1: begin
              if (mode_timer >= 20) begin
                if (~power_ok) begin
`ifdef DEBUG
                  $display("mode: mode CRASH passed");
`endif
                  $display("PASSED");
                  $finish;
                end else begin
                  $display("FAILED: expected power_ok, mode = %d, mode_progress = %d", mode, mode_progress);
                  $finish;
                end
              end
            end
          endcase
        end
      endcase
    end
  end

  /************ WB *******************/
  reg [1:0] wbm_state;
`define STATE_COMMAND 2'd0
`define STATE_COLLECT 2'd1
`define STATE_WAIT    2'd2

  always @(posedge clk) begin
    wb_cyc_i <= 1'b0;
    wb_stb_i <= 1'b0;
    mode_done[0] <= 1'b0;

    if (reset) begin
      wbm_state <= `STATE_COMMAND;
      wb_adr_i <= 16'b0;
    end else begin
      case (wbm_state)
        `STATE_COMMAND: begin
          if (mode_progress == 4'd0) begin
            case (mode)
              `MODE_WB_RESTART: begin
                wb_cyc_i <= 1'b1;
                wb_stb_i <= 1'b1;
                wb_we_i  <= 1'b1;
                wb_adr_i <= 16'd2;
                wb_dat_i <= 16'd0;
                wbm_state <= `STATE_COLLECT;
`ifdef DEBUG
                $display("wbm: resetting");
`endif
              end
              `MODE_WB_SHUTDOWN: begin
                wb_cyc_i <= 1'b1;
                wb_stb_i <= 1'b1;
                wb_we_i  <= 1'b1;
                wb_adr_i <= 16'd2;
                wb_dat_i <= 16'd1;
                wbm_state <= `STATE_COLLECT;
`ifdef DEBUG
                $display("wbm: powering down");
`endif
              end
              `MODE_WB_POWERUP: begin
                wb_cyc_i <= 1'b1;
                wb_stb_i <= 1'b1;
                wb_we_i  <= 1'b1;
                wb_adr_i <= 16'd1;
                wb_dat_i <= 16'd1;
                wbm_state <= `STATE_COLLECT;
`ifdef DEBUG
                $display("wbm: powering up");
`endif
              end
            endcase
          end
        end
        `STATE_COLLECT: begin
          if (wb_ack_o) begin
            wbm_state <= `STATE_WAIT;
            mode_done[0] <= 1'b1;
`ifdef DEBUG
            $display("wbm: got ack");
`endif
          end
        end
        `STATE_WAIT: begin
           wbm_state <= `STATE_COMMAND;
        end
      endcase
    end
  end 

endmodule
