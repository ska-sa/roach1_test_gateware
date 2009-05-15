module clk_ctrl(
    input        clk,
    input        rst,
    input  [1:0] width,
    input        tick,
    output       done,
    output       rdy,
    output       ack,
    output       mmc_clk
  );
  localparam W_40M  = 0;
  localparam W_20M  = 1;
  localparam W_10M  = 2;
  localparam W_365K = 3;

  reg [1:0] state;
  localparam IDLE = 0;
  localparam HIGH = 1;
  localparam LOW  = 2;

  assign mmc_clk = state == HIGH;

  reg [7:0] progress;

  wire half_bit_done;
  reg ack_reg;

  always @(posedge clk) begin
    ack_reg <= 1'b0;
    if (rst) begin
      state <= IDLE;
    end else begin
      case (state)
        IDLE: begin
          if (tick) begin
            progress <= 7'b1;
            state    <= HIGH;
            ack_reg  <= 1'b1;
          end
        end
        HIGH: begin
          progress <= progress + 1;
          if (half_bit_done) begin
            state <= LOW;
            progress <= 1;
          end
        end
        LOW: begin
          progress <= progress + 1;
          if (half_bit_done) begin
            progress <= 1;
            if (tick) begin
              state <= HIGH;
              ack_reg  <= 1'b1;
            end else begin
              state <= IDLE;
            end
          end
        end
        default: begin
          state <= IDLE;
        end
      endcase
    end
  end
  assign rdy = state == IDLE || state == LOW && half_bit_done;
  assign ack = ack_reg;

  assign done = state == LOW && half_bit_done;

  reg half_bit_done_reg;

  always @(*) begin
    half_bit_done_reg <= 1'b0;
    case (width)
      W_40M: begin
        half_bit_done_reg <= 1'b1;
      end
      W_20M: begin
        if (progress[1]) begin
          half_bit_done_reg <= 1'b1;
        end
      end
      W_10M: begin
        if (progress[2]) begin
          half_bit_done_reg <= 1'b1;
        end
      end
      W_365K: begin
        if (progress[7]) begin
          half_bit_done_reg <= 1'b1;
        end
      end
    endcase
  end
  assign half_bit_done = half_bit_done_reg;


endmodule
