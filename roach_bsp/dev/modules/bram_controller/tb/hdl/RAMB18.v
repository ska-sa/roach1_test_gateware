module RAMB18(
    DOA, DOB, DOPA, DOPB,
    ADDRA, ADDRB,
    CLKA, CLKB,
    DIA, DIB, DIPA, DIPB,
    ENA, ENB,
    REGCEA, REGCEB,
    SSRA, SSRB,
    WEA, WEB
  );
  parameter INIT_00 = 0;
  parameter DOA_REG = 0;
  parameter DOB_REG = 0;
  parameter INIT_A = 0;
  parameter INIT_B = 0;
  parameter READ_WIDTH_A = 0;
  parameter READ_WIDTH_B = 0;
  parameter SRVAL_A = 0;
  parameter SRVAL_B = 0;
  parameter WRITE_MODE_A = 0;
  parameter WRITE_MODE_B = 0;
  parameter WRITE_WIDTH_A = 0;
  parameter WRITE_WIDTH_B = 0;
  output [15:0] DOA;
  output [15:0] DOB;
  output  [1:0] DOPA;
  output  [1:0] DOPB;
  input  [13:0] ADDRA;
  input  [13:0] ADDRB;
  input  CLKA, CLKB;
  input  [15:0] DIA;
  input  [15:0] DIB;
  input   [1:0] DIPA;
  input   [1:0] DIPB;
  input  ENA, ENB;
  input  REGCEA, REGCEB;
  input  SSRA, SSRB;
  input  [1:0] WEA;
  input  [1:0] WEB;

  reg [15:0] ram_mem [2*1024-1:0];

  assign DOA = ram_mem [ADDRA[13:4]];

  always @(posedge CLKA) begin
    if (WEA == 2'b11) begin
      ram_mem[ADDRA[13:4]] <= DIA;
`ifdef DEBUG
      $display("bram: write - addr = %x, data = %x", ADDRA[13:4], DIA);
`endif
    end
  end
endmodule
