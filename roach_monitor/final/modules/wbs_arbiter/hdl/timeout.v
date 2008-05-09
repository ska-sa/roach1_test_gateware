module timeout(
    clk, reset,
    adr,
    timeout
  );
  parameter TOCONF0 = 52'b0;
  parameter TOCONF1 = 52'b0;
  parameter TODEFAULT = 20'b0;

  input  clk, reset;
  input  [15:0] adr;
  output timeout;

  reg [19:0] counter;

  wire addr_match0 = adr >= TOCONF0[15:0] && adr <= TOCONF0[31:16];
  wire addr_match1 = adr >= TOCONF1[15:0] && adr <= TOCONF1[31:16];

  assign timeout = addr_match0 ? counter >= TOCONF0[51:32] :
                   addr_match1 ? counter >= TOCONF1[51:32] :
                   counter >= TODEFAULT;

  always @(posedge clk) begin
    if (reset | timeout) begin
      counter <= 20'b0;
    end else begin
      counter <= counter + 20'b1;
    end
  end
endmodule
