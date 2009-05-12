module clk_ctrl(
    input        clk,
    input        rst,
    input  [6:0] width,
    input        tick,
    output       done,
    output       mmc_clk
  );

  reg [7:0] progress;


  reg state;
  localparam IDLE = 0;
  localparam RUN  = 1;

  always @(posedge clk) begin
    if (rst) begin
      progress <= 8'd0;
      state <= IDLE;
    end else begin
      case (state)
        IDLE: begin
          if (tick) begin
            progress <= progress + 1;
            state    <= RUN;
          end
        end
        RUN: begin
          if (done) begin
            progress <= progress + 1;
            state <= IDLE;
          end
        end
      endcase
    end
  end

  assign mmc_clk = tick && state == IDLE || state == RUN && (progress < width);
  assign done = state == RUN && progress >= {width, 1'b0};
  /* optimize ^^^^^^^^^ could get rid of comparisons and decode in state machine*/

endmodule
