module posneg_capture (
    input  clk,
    input  sig_in,
    output sig_out
  );
  
  /*
  (* HU_SET = "capture", RLOC = "X0Y0" *) reg sig_in_0;
  (* HU_SET = "capture", RLOC = "X1Y0" *) reg sig_in_180;
  */

  (* RLOC = "X0Y0" *) reg sig_in_0;
  (* RLOC = "X1Y0" *) reg sig_in_180;

  always @(posedge clk) begin
    sig_in_0 <= sig_in;
  end

  always @(negedge clk) begin
    sig_in_180 <= sig_in_0;
  end
  assign sig_out = sig_in_180;

endmodule
