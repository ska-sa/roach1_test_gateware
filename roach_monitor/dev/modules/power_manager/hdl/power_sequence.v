`timescale 1ns/10ps
`define STATE_IDLE 2'd0
`define STATE_DONE 2'd1
`define STATE_1    2'd2
`define STATE_2    2'd3

`ifdef SIMULATION 
`define TIME_0   32'd1
`define TIME_1   32'd1
`define TIME_2   32'd1
`define TIME_3   32'd1
`define TIME_4   32'd1
`define TIME_5   32'd1
`define TIME_6   32'd1
`define TIME_7   32'd1
`else
`define TIME_0   32'd1000
`define TIME_1   32'd1000
`define TIME_2   32'd1000
`define TIME_3   32'd1000
`define TIME_4   32'd1000
`define TIME_5   32'd1000
`define TIME_6   32'd1000
`define TIME_7   32'd1000
`endif

module power_sequence(
  reset, clk,
  power_up, power_down,
  sequence_complete,
  /* Power Control Signals */
  ATX_PS_ON_N,
  TRACK_2V5,
  SLP_0V9_0,SLP_0V9_1,
  INHIBIT_1V2,INHIBIT_1V8,INHIBIT_2V5,MARGIN_UP_2V5,MARGIN_DOWN_2V5,
  MGT0_1V2_EN,MGT1_1V2_EN,
  ENABLE_1V5,
  AG_EN
  );
  input  reset,clk;
  input  power_up, power_down;
  output sequence_complete;
  output ATX_PS_ON_N;
  output TRACK_2V5;
  output [1:0] SLP_0V9_0;
  output [1:0] SLP_0V9_1;
  output INHIBIT_1V2,INHIBIT_1V8;
  output INHIBIT_2V5,MARGIN_UP_2V5,MARGIN_DOWN_2V5;
  output MGT0_1V2_EN,MGT1_1V2_EN,ENABLE_1V5;
  output [9:0] AG_EN;


  reg ATX_PS_ON_N;
  reg TRACK_2V5;
  reg [1:0] SLP_0V9_0;
  reg [1:0] SLP_0V9_1;
  reg INHIBIT_1V2,INHIBIT_1V8;
  reg INHIBIT_2V5,MARGIN_UP_2V5,MARGIN_DOWN_2V5;
  reg MGT0_1V2_EN,MGT1_1V2_EN,ENABLE_1V5;
  reg [9:0] AG_EN;
  
  reg [1:0] state;
  wire sequence_complete = (state == `STATE_DONE);

  reg [31:0] timer_0;
  
  always @(posedge clk) begin
    if (reset) begin
      TRACK_2V5<=1'b0;
      SLP_0V9_0<=2'b0;
      SLP_0V9_1<=2'b0;
      INHIBIT_1V2<=1'b1;
      INHIBIT_1V8<=1'b1;
      INHIBIT_2V5<=1'b1;
      MARGIN_UP_2V5<=1'b0;
      MARGIN_DOWN_2V5<=1'b0;
      MGT0_1V2_EN<=1'b0;
      MGT1_1V2_EN<=1'b0;
      ENABLE_1V5<=1'b0;
      AG_EN<=10'b00000_00000;
      ATX_PS_ON_N<=1'b1;
      timer_0<=32'b0;
      state<=`STATE_IDLE;
    end begin
      if (power_down) begin
        case (state)
          `STATE_IDLE: begin
            if(timer_0 == 32'b0) begin
`ifdef DEBUG
              $display("powerdown: start");
`endif
              state<=`STATE_1;
              timer_0<=`TIME_1;
              TRACK_2V5<=1'b0;
              SLP_0V9_0<=1'b0;
              SLP_0V9_1<=1'b0;
              INHIBIT_1V2<=1'b1;
              INHIBIT_1V8<=1'b1;
              INHIBIT_2V5<=1'b1;
              MGT0_1V2_EN<=1'b0;
              MGT1_1V2_EN<=1'b0;
              ENABLE_1V5<=1'b0;
              AG_EN<=10'b00000_00000;
              ATX_PS_ON_N<=1'b1;
            end else begin
              timer_0<=timer_0 + 32'b1;
            end
          end
          `STATE_1: begin
            if(timer_0 == 32'b0) begin
              state<=`STATE_DONE;
            end else begin
              timer_0<=timer_0 - 32'b1;
            end
          end
          `STATE_DONE: begin
`ifdef DEBUG
              $display("powerdown: done");
`endif
          end
        endcase
      end else if (power_up) begin
        case (state)
          `STATE_IDLE: begin
            if (timer_0 == `TIME_0) begin
`ifdef DEBUG
              $display("powerup: start");
`endif
              state<=`STATE_1;
              timer_0<=`TIME_1;
`ifdef ACTEL_DEV_BOARD
              AG_EN<=10'b11111_11111;
`else
              AG_EN<=10'b00010_01100;
`endif
            end else begin
              timer_0<=timer_0 + 32'b1;
            end
          end
          `STATE_1: begin
            if (timer_0 == 32'b0) begin
              state<=`STATE_2;
              timer_0<=`TIME_2;
              ATX_PS_ON_N<=1'b0;
              TRACK_2V5<=1'b1;
              SLP_0V9_0<=2'b11;
              SLP_0V9_1<=2'b11;
              INHIBIT_1V2<=1'b0;
              INHIBIT_1V8<=1'b0;
              INHIBIT_2V5<=1'b0;
              MGT0_1V2_EN<=1'b1;
              MGT1_1V2_EN<=1'b1;
              ENABLE_1V5<=1'b1;
            end else begin
              timer_0<=timer_0 - 32'b1;
            end
          end
          `STATE_2: begin
            if (timer_0 == 32'b0) begin
              state<=`STATE_DONE;
            end else begin
              timer_0<=timer_0 - 32'b1;
            end
          end
          `STATE_DONE: begin
`ifdef DEBUG
              $display("powerup: done");
`endif
          end
        endcase
      end else begin
        state<=`STATE_IDLE;
        timer_0<=32'b0;
      end
    end
  end

endmodule
