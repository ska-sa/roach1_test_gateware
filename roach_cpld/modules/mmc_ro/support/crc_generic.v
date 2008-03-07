`include "crc.vh"
module crc_generic();

  wire  [`M_LENGTH-1:0] message = `MESSAGE;
  wire  [`CRC_ORDER - 2:0] divisor = `DIVISOR;


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

  always @(posedge clk) begin
    if (reset) begin
      counter <= 32'b0;
      crc_reg <= {`CRC_ORDER-1{1'b0}};
      counter <= 0;
    end else begin
      if (counter < `M_LENGTH) begin
        crc_reg <= crc_reg[`CRC_ORDER - 2] ? {crc_reg[`CRC_ORDER - 3:0], message[`M_LENGTH - 1 - counter]} ^ divisor :
                                             {crc_reg[`CRC_ORDER - 3:0], message[`M_LENGTH - 1 - counter]};
      end else begin
        crc_reg <= crc_reg[`CRC_ORDER - 2] ? {crc_reg[`CRC_ORDER - 3:0], 1'b0} ^ divisor : {crc_reg[`CRC_ORDER - 3:0], 1'b0};
      end


      if (counter == `M_LENGTH + `CRC_ORDER - 1) begin
        $display("CRC: b%b == x%x", crc_reg, crc_reg);
        $finish;
      end else begin
        counter <= counter + 1;
      end
    end
  end

endmodule
