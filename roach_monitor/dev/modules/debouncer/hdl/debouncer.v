`timescale 1ns/10ps

module debouncer(
    clk,
    in_switch, out_switch
  );

  parameter DELAY = 32'h08_00_00_00;

  input  clk;
  input  in_switch;
  output out_switch;

  reg [31:0] counter;
  reg out_switch;
`ifdef SIMULATION
  initial 
    counter <= 0;
`endif

  always @(posedge clk) begin
    if (counter > DELAY) begin
      counter <= DELAY;
    end else if (counter != 0) begin
      counter <= counter - 32'b1;
    end else if (out_switch != in_switch) begin
      counter <= DELAY;
    end
  end

  always @(posedge clk) begin
    out_switch <= counter == 32'b0 ? in_switch : out_switch;
  end

endmodule

