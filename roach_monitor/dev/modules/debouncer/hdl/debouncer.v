`timescale 1ns/10ps

module debouncer(
    clk, reset,
    in_switch, out_switch
  );

  parameter DELAY = 32'h08_00_00_00;

  input  clk;
  input  reset;
  input  in_switch;
  output out_switch;

  reg [31:0] counter;
  reg out_switch;

  always @(posedge clk) begin
    if (reset) begin
      counter <= DELAY;
    end else begin
      if (counter) begin
        counter <= counter - 32'b1;
      end else if (out_switch != in_switch) begin
        counter <= DELAY;
      end
    end
  end

  always @(posedge clk) begin
    out_switch <= counter == 32'b0 ? in_switch : out_switch;
  end

endmodule

