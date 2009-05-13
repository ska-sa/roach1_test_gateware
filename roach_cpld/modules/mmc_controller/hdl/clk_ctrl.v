module clk_ctrl(
    input        clk,
    input        rst,
    input  [6:0] width,
    input        tick,
    output       done,
    output       mmc_clk
  );

  reg [7:0] progress;
  reg run;
  always @(posedge clk) begin
    if (done) begin
      progress <= 0;
    end else if (tick || run) begin
      progress <= progress + 1;
    end
  end

  always @(posedge clk) begin
    if (done) begin
      run <= 1'b0;
    end else if (tick) begin
      run <= 1'b1;
    end
  end

  assign mmc_clk = tick || (progress < {width});
  assign done    = progress >= {width, 1'b0};

endmodule
