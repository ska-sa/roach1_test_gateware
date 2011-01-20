`define SIM_RESET_DELAY 10
`define SIM_RESET_WIDTH 20

`define SIMLENGTH 6000

module TB_reset_block();
  
  wire reset_o;
  reg  reset_i;
  reg  areset;
  reg  clk;

  reg  state;
  reg  [31:0] counter;


  reset_block #(
    .DELAY(`SIM_RESET_DELAY),
    .WIDTH(`SIM_RESET_WIDTH)
  ) reset_block (
    .clk(clk), .async_reset_i(areset), .reset_i(reset_i), .reset_o(reset_o)
  );

  initial begin
    $dumpvars;
    clk<=1'b0;
    areset<=1'b1;

    reset_i<=1'b1;
    state<=1'b0;
    counter<=32'b0;
    #1
    areset<=1'b0;
  `ifdef DEBUG
    $display("starting sim");
  `endif
    #`SIMLENGTH 
    $display("FAILED: simulation timed out");
    $finish;
  end
  
  always begin
    #1 clk <=~clk;
  end

  always @(posedge clk) begin
    counter<=counter + 1;
    reset_i<=1'b0;
    case (state)
      0: begin
        if (counter == 3) begin
          if (reset_o) begin
            $display("FAILED: expected no reset 0");
            $finish;
          end
        end
        if (counter == `SIM_RESET_DELAY + 3) begin
          if (~reset_o) begin
            $display("FAILED: expected reset 0");
            $finish;
          end
        end
        if (counter == `SIM_RESET_DELAY + `SIM_RESET_WIDTH + 3) begin
          if (reset_o) begin
            $display("FAILED: expected reset deassert 0");
            $finish;
          end else begin
            state<=1'b1;
            counter<=32'b0;
            reset_i<=1'b1;
          end
        end
      end
      1: begin
        if (counter == 0) begin
          if (reset_o) begin
            $display("FAILED: expected no reset 1");
            $finish;
          end
        end
        if (counter == `SIM_RESET_DELAY + 2) begin
          if (~reset_o) begin
            $display("FAILED: expected reset 1");
            $finish;
          end
        end
        if (counter == `SIM_RESET_DELAY + `SIM_RESET_WIDTH + 4) begin
          if (reset_o) begin
            $display("FAILED: expected reset deassert 1");
            $finish;
          end else begin
            $display("PASSED");
            $finish;
          end
        end
      end
    endcase
  end


endmodule
