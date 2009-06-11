module crc16(
    input         clk,
    input         rst,
    input         data,
    input         dvld,
    output [15:0] dout
  );

  function [15:0] crc16;
    input [15:0] crcin;
    input        data;
    begin
      crc16[ 0] = data ^ crcin[15];
      crc16[ 1] = crcin[ 0];
      crc16[ 2] = crcin[ 1];
      crc16[ 3] = crcin[ 2];
      crc16[ 4] = crcin[ 3];
      crc16[ 5] = crcin[ 4] ^ data ^ crcin[15];
      crc16[ 6] = crcin[ 5];
      crc16[ 7] = crcin[ 6];
      crc16[ 8] = crcin[ 7];
      crc16[ 9] = crcin[ 8];
      crc16[10] = crcin[ 9];
      crc16[11] = crcin[10];
      crc16[12] = crcin[11] ^ data ^ crcin[15];
      crc16[13] = crcin[12];
      crc16[14] = crcin[13];
      crc16[15] = crcin[14];
    end
  endfunction

  reg [15:0] crc_reg;

  /* TODO: this is wrong */

  always @(posedge clk) begin
    if (rst) begin
      crc_reg <= 0;
    end else begin
      if (dvld) begin
        crc_reg <= crc16(crc_reg, data);
      end
    end
  end
  assign dout = crc_reg;

endmodule
