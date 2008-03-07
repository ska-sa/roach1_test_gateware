`define CRC_ORDER 8
`define M_LENGTH  40
module crc_mmc();

  wire  [`M_LENGTH-1:0] message = {1'b0,1'b1,6'b1,32'h80_ff_80_00};
  wire  [`CRC_ORDER - 2:0] divisor = {7'b000_1001};


  reg clk, reset;
  initial begin
    clk <= 1'b0;
    reset <= 1'b1;
    #100
    reset <= 1'b0;
  end

  always begin
    #1 clk <= ~clk;
  end

  reg [31:0] counter;
  reg [`CRC_ORDER - 2:0] crc_reg;

  wire din = counter < `M_LENGTH ? message[`M_LENGTH - 1 - counter] : 1'b0;

  always @(posedge clk) begin
    if (reset) begin
      crc_reg <= {`CRC_ORDER-1{1'b0}};
      counter <= 0;
    end else begin
      counter <= counter + 1;
      crc_reg[0] <= din ^ crc_reg[6];
      crc_reg[1] <= crc_reg[0];
      crc_reg[2] <= crc_reg[1];
      crc_reg[3] <= crc_reg[2] ^ crc_reg[6] ^ din;
      crc_reg[4] <= crc_reg[3];
      crc_reg[5] <= crc_reg[4];
      crc_reg[6] <= crc_reg[5];


      if (counter == `M_LENGTH) begin
        $display("CRC: counter = %d, b%b == x%x", counter, crc_reg, crc_reg);
        $finish;
      end else begin
        counter <= counter + 1;
      end
    end
  end
endmodule
