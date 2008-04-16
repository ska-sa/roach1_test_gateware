module RAMB36(
    DOA, DOB, DOPA, DOPB,
    ADDRA, ADDRB,
    CLKA, CLKB,
    DIA, DIB, DIPA, DIPB,
    ENA, ENB,
    REGCEA, REGCEB,
    SSRA, SSRB,
    WEA, WEB,
    CASCADEOUTLATA,
    CASCADEOUTLATB,
    CASCADEOUTREGA,
    CASCADEOUTREGB,
    CASCADEINLATA,
    CASCADEINLATB,
    CASCADEINREGA,
    CASCADEINREGB
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
  output [31:0] DOA;
  output [31:0] DOB;
  output  [3:0] DOPA;
  output  [3:0] DOPB;
  input  [15:0] ADDRA;
  input  [15:0] ADDRB;
  input  CLKA, CLKB;
  input  [31:0] DIA;
  input  [31:0] DIB;
  input   [3:0] DIPA;
  input   [3:0] DIPB;
  input  ENA, ENB;
  input  REGCEA, REGCEB;
  input  SSRA, SSRB;
  input  [3:0] WEA;
  input  [3:0] WEB;
  output CASCADEOUTLATA;
  output CASCADEOUTLATB;
  output CASCADEOUTREGA;
  output CASCADEOUTREGB;
  input  CASCADEINLATA;
  input  CASCADEINLATB;
  input  CASCADEINREGA;
  input  CASCADEINREGB;

  reg [15:0] ram_mem [4*1024-1:0];

  assign DOA = ram_mem [ADDRA[14:4]];

  always @(posedge CLKA) begin
    if (WEA[1:0] == 2'b11) begin
      ram_mem[ADDRA[14:4]] <= DIA;
`ifdef DEBUG
      $display("bram: write - addr = %x, data = %x", ADDRA[14:4], DIA);
`endif
    end
  end
endmodule
