`timescale 1ns/10ps
`define DEBOUNCE_TIMEOUT 10
`define HLF_DEBOUNCE_TIMEOUT 5
`define SWITCHES 5

module TB_debouncer();
  reg clk,reset;
  wire [(`SWITCHES-1):0] swout;
  reg [(`SWITCHES-1):0] swin;

  debouncer #(
    .DELAY(`DEBOUNCE_TIMEOUT)
  ) debouncer [`SWITCHES - 1 : 0] (
    .clk(clk),
    .reset(reset),
    .in_switch(swin),
    .out_switch(swout)
  );

  initial begin
`ifdef DEBUG
    $display("starting sim");
`endif
    clk<=1'b0;
    reset<=1'b1;
    swin<=`SWITCHES'b0;
    #9 reset<=1'b0;

    #10 swin<=~swout;
    #2 
    if (swout!=`SWITCHES'b0) begin
      $display("FAILED: reacted too soon");
    $finish;
    end
    swin<=swout;

    #10 swin<=~swin;
    #2 
    if (swout!=~(`SWITCHES'b0)) begin
      $display("FAILED: did not react");
    $finish;
    end

    swin<=`SWITCHES'b0;
    #22
      if (swout!=(`SWITCHES'b0)) begin
        $display("FAILED: did not react");
    $finish;
      end


    #1 $display("PASSED");
    $finish;
  end 

  always begin
     #1 clk<=~clk;
  end
endmodule
