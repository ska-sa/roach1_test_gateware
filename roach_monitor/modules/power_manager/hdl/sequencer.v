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

  reg [2:0] state;
  localparam STATE_POWERED_DOWN = 3'd0;
  localparam STATE_UPSEQ_0      = 3'd1;
  localparam STATE_UPSEQ_1      = 3'd2;
  localparam STATE_POWERED_UP   = 3'd3;

  localparam TIME_0 = 32'd10;
  localparam TIME_1 = 32'd100;

  reg [31:0] timer;

  assign power_up_done   = state == STATE_POWERED_UP;
  assign power_down_done = state == STATE_POWERED_DOWN;

  assign ATX_PS_ON_N    = (reset || state == STATE_POWERED_DOWN) ? 1'b1 : 1'b0;
  assign TRACK_2V5      = (reset || state == STATE_POWERED_DOWN) ? 1'b0 : 1'b1;
  assign INHIBIT_2V5    = (reset || state == STATE_POWERED_DOWN) ? 1'b1 : 1'b0;
  assign INHIBIT_1V8    = (reset || state == STATE_POWERED_DOWN) ? 1'b1 : 1'b0;
  assign INHIBIT_1V5    = (reset || state == STATE_POWERED_DOWN) ? 1'b1 : 1'b0;
  assign INHIBIT_1V2    = (reset || state == STATE_POWERED_DOWN) ? 1'b1 : 1'b0;
  assign INHIBIT_1V0    = (reset || state == STATE_POWERED_DOWN) ? 1'b1 : 1'b0;
  assign MGT_AVCC_EN    = (reset || state == STATE_POWERED_DOWN) ? 1'b0 : 1'b1;
  assign MGT_AVTTX_EN   = (reset || state == STATE_POWERED_DOWN) ? 1'b0 : 1'b1;
  assign MGT_AVCCPLL_EN = (reset || state == STATE_POWERED_DOWN) ? 1'b0 : 1'b1;
  assign G12V_EN        = (reset || state == STATE_POWERED_DOWN) ? 1'b0 : 1'b1;
  assign G5V_EN         = (reset || state == STATE_POWERED_DOWN) ? 1'b0 : 1'b1;
  assign G3V3_EN        = (reset || state == STATE_POWERED_DOWN) ? 1'b0 : 1'b1;

  /******* Power State Machine *******/
  
  always @(posedge clk) begin
    if (reset) begin
      timer <= 32'b0;
      state <= STATE_POWERED_DOWN;
    end else begin
      case (state)
        STATE_POWERED_DOWN: begin
          if (power_up) begin
            state <= STATE_UPSEQ_0;
            timer <= TIME_0;
          end
        end
        STATE_UPSEQ_0: begin
          if(timer == 32'b0) begin
            state <= STATE_UPSEQ_1;
            timer <= TIME_1;
          end else begin
            timer <= timer - 32'b1;
          end
          if (power_down) begin
            state   <= STATE_POWERED_DOWN;
          end
        end
        STATE_UPSEQ_1: begin
          if(timer == 32'b0) begin
            state <= STATE_POWERED_UP;
          end else begin
            timer <=timer - 32'b1;
          end
          if (power_down) begin
            state   <= STATE_POWERED_DOWN;
          end
        end
        STATE_POWERED_UP: begin
          if (power_down) begin
            state   <= STATE_POWERED_DOWN;
          end
        end
      endcase
    end
  end

endmodule
