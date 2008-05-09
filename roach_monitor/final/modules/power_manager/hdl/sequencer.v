`timescale 1ns/10ps


module sequencer(
    reset, clk,
    power_up, power_down,
    power_up_done, power_down_done,
    /* Power Control Signals */
    ATX_PS_ON_N,
    TRACK_2V5,
    INHIBIT_2V5, INHIBIT_1V8, INHIBIT_1V5, INHIBIT_1V2, INHIBIT_1V0,
    MGT_AVCC_EN, MGT_AVTTX_EN, MGT_AVCCPLL_EN,
    G12V_EN, G5V_EN, G3V3_EN
  );
  input  reset,clk;
  input  power_up, power_down;
  output power_up_done, power_down_done;
  output ATX_PS_ON_N;
  output TRACK_2V5;
  output INHIBIT_2V5, INHIBIT_1V8, INHIBIT_1V5, INHIBIT_1V2, INHIBIT_1V0;
  output MGT_AVCC_EN, MGT_AVTTX_EN, MGT_AVCCPLL_EN;
  output G12V_EN, G5V_EN, G3V3_EN;

  reg ATX_PS_ON_N;
  reg TRACK_2V5;
  reg INHIBIT_2V5, INHIBIT_1V8, INHIBIT_1V5, INHIBIT_1V2, INHIBIT_1V0;
  reg MGT_AVCC_EN, MGT_AVTTX_EN, MGT_AVCCPLL_EN;
  reg G12V_EN, G5V_EN, G3V3_EN;

  reg [2:0] state;
  localparam STATE_POWERED_DOWN = 3'd0;
  localparam STATE_POWERED_UP   = 3'd1;
  localparam STATE_UPSEQ_0      = 3'd2;
  localparam STATE_UPSEQ_1      = 3'd3;
  localparam STATE_DOWNSEQ_0    = 3'd4;
  localparam STATE_DOWNSEQ_1    = 3'd5;

  localparam TIME_0 = 32'd0;
  localparam TIME_1 = 32'd1000;

  reg [31:0] timer_0;

  reg power_up_done;
  reg power_down_done;
  
  always @(posedge clk) begin
    if (reset) begin
      ATX_PS_ON_N    <= 1'b1;
      TRACK_2V5      <= 1'b0;
      INHIBIT_2V5    <= 1'b1;
      INHIBIT_1V8    <= 1'b1;
      INHIBIT_1V5    <= 1'b1;
      INHIBIT_1V2    <= 1'b1;
      INHIBIT_1V0    <= 1'b1;
      MGT_AVCC_EN    <= 1'b0;
      MGT_AVTTX_EN   <= 1'b0;
      MGT_AVCCPLL_EN <= 1'b0;
      G12V_EN        <= 1'b0;
      G5V_EN         <= 1'b0;
      G3V3_EN        <= 1'b0;
      timer_0 <= 32'b0;
      state <= STATE_POWERED_DOWN;
      power_up_done <= 1'b0;
      power_down_done <= 1'b1;
    end else if (power_down) begin
      state <= STATE_DOWNSEQ_0;
      timer_0 <= 32'b0;
      power_up_done <= 1'b0;
      power_down_done <= 1'b0;
    end else if (power_up) begin
      state <= STATE_UPSEQ_0;
      timer_0 <= TIME_0;
      power_up_done <= 1'b0;
      power_down_done <= 1'b0;
    end else begin
      case (state)
        STATE_POWERED_DOWN: begin
          if (timer_0) begin
            timer_0 <= timer_0 - 1;
          end else begin
            power_down_done <= 1'b1;
          end
        end
        STATE_DOWNSEQ_0: begin
          if(timer_0 == 32'b0) begin
            ATX_PS_ON_N    <= 1'b1;
            TRACK_2V5      <= 1'b0;
            INHIBIT_2V5    <= 1'b1;
            INHIBIT_1V8    <= 1'b1;
            INHIBIT_1V5    <= 1'b1;
            INHIBIT_1V2    <= 1'b1;
            INHIBIT_1V0    <= 1'b1;
            MGT_AVCC_EN    <= 1'b0;
            MGT_AVTTX_EN   <= 1'b0;
            MGT_AVCCPLL_EN <= 1'b0;
            G12V_EN        <= 1'b0;
            G5V_EN         <= 1'b0;
            G3V3_EN        <= 1'b0;
            state <= STATE_POWERED_UP;
            timer_0 <= TIME_1;
          end else begin
            timer_0<=timer_0 + 32'b1;
          end
        end
        STATE_POWERED_UP: begin
          if (timer_0) begin
            timer_0 <= timer_0 - 1;
          end else begin
            power_up_done <= 1'b1;
          end
        end
        STATE_UPSEQ_0: begin
          if(timer_0 == 32'b0) begin
            ATX_PS_ON_N    <= 1'b0;
            TRACK_2V5      <= 1'b1;
            INHIBIT_2V5    <= 1'b0;
            INHIBIT_1V8    <= 1'b0;
            INHIBIT_1V5    <= 1'b0;
            INHIBIT_1V2    <= 1'b0;
            INHIBIT_1V0    <= 1'b0;
            MGT_AVCC_EN    <= 1'b1;
            MGT_AVTTX_EN   <= 1'b1;
            MGT_AVCCPLL_EN <= 1'b1;
            G12V_EN        <= 1'b1;
            G5V_EN         <= 1'b1;
            G3V3_EN        <= 1'b1;
            state <= STATE_POWERED_UP;
            timer_0 <= TIME_1;
          end else begin
            timer_0<=timer_0 + 32'b1;
          end
        end
      endcase
    end
  end

endmodule
