module reset_block(
    clk, async_reset_i, reset_i, reset_o
  );

  input  clk;
  input  async_reset_i;
  input  reset_i;
  output reset_o;
  parameter DELAY = 10;
  parameter WIDTH = 50;

  reg [31:0] delay_counter;
  reg [31:0] width_counter;

  reg reset_o_reg;
  assign reset_o = reset_o_reg;

  reg state;

  always @(posedge clk or posedge async_reset_i) begin

    if (async_reset_i) begin
      delay_counter <= 32'b0;
      width_counter <= 32'b0;
      reset_o_reg   <= 1'b0;
      state         <= 0;
`ifdef DEBUG
      $display("rb: got async reset");
`endif
    end else begin
      if (reset_i) begin
`ifdef DEBUG
        $display("rb: got sync reset");
`endif
        delay_counter <= 32'b0;
        width_counter <= 32'b0;
        reset_o_reg   <= 1'b0;
        state         <= 0;
      end else begin
        case (state)
          0: begin
            if (delay_counter < DELAY) begin
              delay_counter <= delay_counter + 1;
            end else begin
              reset_o_reg <= 1'b1;
              state <= 1;
            end
          end
          1: begin
            if (width_counter < WIDTH) begin
              width_counter <= width_counter + 1;
            end else begin
              reset_o_reg <= 1'b0;
            end
          end
        endcase
      end
    end
  end

endmodule
