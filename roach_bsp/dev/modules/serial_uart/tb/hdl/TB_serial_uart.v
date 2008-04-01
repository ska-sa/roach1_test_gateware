`timescale 1ns/10ps
`define SIMLENGTH 64000
module TB_serial_uart();

wire serial_in;
wire serial_out;
wire [7:0] data_out;
wire busy;
wire gotdata;

reg ostrb;
reg clk;
reg [7:0] testval;
reg reset; 

assign serial_in=serial_out;

serial_uart #(
  ) uart(.serial_in(serial_in), .serial_out(serial_out), .clk(clk), .reset(reset),
        .as_data_i(testval), .as_data_o(data_out), .as_dstrb_i(ostrb), .as_busy_o(busy), .as_dstrb_o(gotdata));

reg [5:0] sim_cnt;

reg [63:0]words_sent;
reg [63:0]words_received;

initial begin
  clk<=1'b0;
  words_sent<=64'b0;
  words_received<=64'b0;
  reset<=1'b1;
  sim_cnt<=6'b0;
  #2 reset<=1'b0;
`ifdef DEBUG
  $display("starting sim");
`endif
  #`SIMLENGTH 
  if (words_sent - words_received <= 1)
    $display("PASSED");
  else
    $display("FAILED: lost data");
  $finish;
end

always begin
  #1 clk <=~clk;
end

reg busy_cleared;
reg gotdata_cleared;
always @(posedge clk) begin
  if (reset) begin
    busy_cleared<=1'b1;
    testval<=8'b0;
    ostrb<=1'b0;
    gotdata_cleared<=1'b1;
  end else begin
    if (~busy & busy_cleared) begin
`ifdef DEBUG
      $display("sent word: %d",testval +1'b1);
`endif
      ostrb<=1'b1;
      busy_cleared<=1'b0;
      sim_cnt<=sim_cnt + 6'b1;
      testval<=testval+8'b1;
      words_sent<=words_sent + 64'b1;
    end else if (busy) begin
      ostrb<=1'b0;
      busy_cleared<=1'b1;
    end

    if (gotdata & gotdata_cleared) begin
`ifdef DEBUG
      $display("got word: %d",data_out);
`endif
      words_received<=words_received + 64'b1;
      if (!(testval === data_out)) begin
        $display("FAILED: data mismatch");
	$finish;
      end
      gotdata_cleared<=1'b0;
    end else if (~gotdata) begin
      gotdata_cleared<=1'b1;
    end
  end
end

endmodule
