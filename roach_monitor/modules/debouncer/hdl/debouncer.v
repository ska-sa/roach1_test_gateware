`timescale 1ns/10ps

module debouncer(
    clk, rst,
    in_switch, out_switch
  );

  parameter DELAY = 32'h08_00_00_00;

  input  clk, rst;
  input  in_switch;
  output out_switch;

  reg [31:0] counter;
  reg out_switch;

  reg state;

  always @(posedge clk) begin
    if (rst) begin
      state      <= 0;
      out_switch <= in_switch;
    end else begin
      case (state)
        0: begin
          if (out_switch != in_switch) begin
            state   <= 1;
            counter <= DELAY;
          end
        end
        1: begin
          if (counter) begin
            counter <= counter - 32'b1;
          end else begin
            out_switch <= in_switch;
            state <= 0;
          end
        end
      endcase
    end
  end

endmodule

