module crc7_d1(
    input        clk,
    input        rst,
    input        data,
    input        dvld,
    output [6:0] dout
  );

  reg [6:0] crc;
  /* TODO: this is wrong */

  always @(posedge clk) begin
    if (rst) begin
      crc <= 0;
    end else begin
      if (dvld) begin
        crc[0] <= data ^ crc[6];
        crc[1] <= crc[0];
        crc[2] <= crc[1];
        crc[3] <= crc[2] ^ data ^ crc[6];
        crc[4] <= crc[3];
        crc[5] <= crc[4];
        crc[6] <= crc[5];
      end
    end
  end
  assign dout = crc;

endmodule
