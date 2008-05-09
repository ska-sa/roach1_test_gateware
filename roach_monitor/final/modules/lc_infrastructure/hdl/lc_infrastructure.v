module lc_infrastructure(
    clk, reset,
    ram_raddr,
    ram_waddr,
    ram_rdata,
    ram_wdata,
    ram_wen
  );
  input clk, reset;
  input   [6:0] ram_raddr;
  input   [6:0] ram_waddr;
  output [11:0] ram_rdata;
  input  [11:0] ram_wdata;
  input  ram_wen;

  wire [5:0] ram_rdata_nc;

  /*************** SRAM Block *************/
  /* A single port ram is unfortunate as sharing is required, but is unwasteful
   * fusion archicture supports only 8 bit dual ports */
  RAM512X18 RAM512X18_inst (
    .RESET(~reset),
    /* Read Port */
    .RCLK(clk), .REN(1'b0),
    .PIPE(1'b0), .RW1(1'b1), .RW0(1'b0), //non-pipelined, 256x18 mode
    .RADDR8(1'b0), .RADDR7(1'b0), .RADDR6(ram_raddr[6]), .RADDR5(ram_raddr[5]),
    .RADDR4(ram_raddr[4]), .RADDR3(ram_raddr[3]), .RADDR2(ram_raddr[2]), .RADDR1(ram_raddr[1]), .RADDR0(ram_raddr[0]),
    .RD17(ram_rdata_nc[5]), .RD16(ram_rdata_nc[4]), .RD15(ram_rdata_nc[3]),
    .RD14(ram_rdata_nc[2]), .RD13(ram_rdata_nc[1]), .RD12(ram_rdata_nc[0]),
    .RD11(ram_rdata[11]), .RD10(ram_rdata[10]), .RD9(ram_rdata[9]), .RD8(ram_rdata[8]), .RD7(ram_rdata[7]),.RD6(ram_rdata[6]),
    .RD5(ram_rdata[5]), .RD4(ram_rdata[4]), .RD3(ram_rdata[3]), .RD2(ram_rdata[2]), .RD1(ram_rdata[1]), .RD0(ram_rdata[0]),
    /* Write Port */
    .WCLK(clk), .WEN(~ram_wen),
    .WW1(1'b1), .WW0(1'b0), // 256x18 mode
    .WADDR8(1'b0),.WADDR7(1'b0),.WADDR6(ram_waddr[6]),.WADDR5(ram_waddr[5]),
    .WADDR4(ram_waddr[4]),.WADDR3(ram_waddr[3]),.WADDR2(ram_waddr[2]),.WADDR1(ram_waddr[1]),.WADDR0(ram_waddr[0]),
    .WD17(1'b0), .WD16(1'b0), .WD15(1'b0), .WD14(1'b0), .WD13(1'b0), .WD12(1'b0),
    .WD11(ram_wdata[11]), .WD10(ram_wdata[10]), .WD9(ram_wdata[9]), .WD8(ram_wdata[8]), .WD7(ram_wdata[7]),.WD6(ram_wdata[6]),
    .WD5(ram_wdata[5]), .WD4(ram_wdata[4]), .WD3(ram_wdata[3]), .WD2(ram_wdata[2]), .WD1(ram_wdata[1]), .WD0(ram_wdata[0])
  );
endmodule
