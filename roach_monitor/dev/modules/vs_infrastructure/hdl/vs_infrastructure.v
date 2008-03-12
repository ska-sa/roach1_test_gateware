module vs_infrastructure(
    clk, reset,
    ram_raddr,
    ram_waddr,
    ram_rdata,
    ram_wdata,
    ram_wen, ram_ren
  );
  parameter RAM_HIGH = 7*1024;

  input  clk, reset;
  input  ram_ren, ram_wen;
  input  [12:0] ram_raddr;
  input  [12:0] ram_waddr;
  output [11:0] ram_rdata;
  input  [11:0] ram_wdata;

  localparam NUM_SRAM_TRIPS = (RAM_HIGH - 1)/1024 + 1; //round up


  wire [NUM_SRAM_TRIPS - 1:0] ram_sel = (1 << ram_waddr[12:10]); //select which set of trips we are using
  wire [NUM_SRAM_TRIPS - 1:0] ram_we_b = ~(ram_sel & {NUM_SRAM_TRIPS{ram_wen}});

  wire [NUM_SRAM_TRIPS - 1:0] ram_rdata_arr [11:0];

  wire [2:0] r_trip_sel = ram_raddr[12:10];
  genvar gen_i;
  generate for (gen_i=0; gen_i < 12; gen_i=gen_i+1) begin : G0
    assign ram_rdata[gen_i] = ram_rdata_arr[gen_i][r_trip_sel];
  end endgenerate


  RAM4K9 ram_0[NUM_SRAM_TRIPS - 1:0](
    .RESET(~reset),
    .CLKA(clk),
    .ADDRA11(1'b0), .ADDRA10(1'b0), .ADDRA9(ram_waddr[9]), .ADDRA8(ram_waddr[8]),
    .ADDRA7(ram_waddr[7]), .ADDRA6(ram_waddr[6]), .ADDRA5(ram_waddr[5]), .ADDRA4(ram_waddr[4]),
    .ADDRA3(ram_waddr[3]), .ADDRA2(ram_waddr[2]), .ADDRA1(ram_waddr[1]), .ADDRA0(ram_waddr[0]),
    .DINA8(1'b0), .DINA7(1'b0), .DINA6(1'b0), .DINA5(1'b0),.DINA4(1'b0),
    .DINA3(ram_wdata[3]), .DINA2(ram_wdata[2]), .DINA1(ram_wdata[1]), .DINA0(ram_wdata[0]),
    .DOUTA8(), .DOUTA7(), .DOUTA6(), .DOUTA5(),.DOUTA4(), .DOUTA3(),.DOUTA2(),.DOUTA1(),.DOUTA0(),
    .WIDTHA1(1'b1), .WIDTHA0(1'b0), .PIPEA(1'b0), .WMODEA(1'b0), .BLKA(1'b0), .WENA(ram_we_b),
    .CLKB(clk),
    .ADDRB11(1'b0), .ADDRB10(1'b0), .ADDRB9(ram_raddr[9]), .ADDRB8(ram_raddr[8]),
    .ADDRB7(ram_raddr[7]), .ADDRB6(ram_raddr[6]), .ADDRB5(ram_raddr[5]), .ADDRB4(ram_raddr[4]),
    .ADDRB3(ram_raddr[3]), .ADDRB2(ram_raddr[2]), .ADDRB1(ram_raddr[1]), .ADDRB0(ram_raddr[0]),
    .DINB8(1'b0), .DINB7(1'b0), .DINB6(1'b0), .DINB5(1'b0),.DINB4(1'b0),
    .DINB3(1'b0), .DINB2(1'b0), .DINB1(1'b0), .DINB0(1'b0),
    .DOUTB8(), .DOUTB7(), .DOUTB6(), .DOUTB5(),.DOUTB4(),
    .DOUTB3(ram_rdata_arr[3]),.DOUTB2(ram_rdata_arr[2]),.DOUTB1(ram_rdata_arr[1]),.DOUTB0(ram_rdata_arr[0]),
    .WIDTHB1(1'b1), .WIDTHB0(1'b0), .PIPEB(1'b0), .WMODEB(1'b0), .BLKB(1'b0), .WENB(1'b1)

  );
  RAM4K9 ram_1[NUM_SRAM_TRIPS - 1:0](
    .RESET(~reset),
    .CLKA(clk),
    .ADDRA11(1'b0), .ADDRA10(1'b0), .ADDRA9(ram_waddr[9]), .ADDRA8(ram_waddr[8]),
    .ADDRA7(ram_waddr[7]), .ADDRA6(ram_waddr[6]), .ADDRA5(ram_waddr[5]), .ADDRA4(ram_waddr[4]),
    .ADDRA3(ram_waddr[3]), .ADDRA2(ram_waddr[2]), .ADDRA1(ram_waddr[1]), .ADDRA0(ram_waddr[0]),
    .DINA8(1'b0), .DINA7(1'b0), .DINA6(1'b0), .DINA5(1'b0),.DINA4(1'b0),
    .DINA3(ram_wdata[7]), .DINA2(ram_wdata[6]), .DINA1(ram_wdata[5]), .DINA0(ram_wdata[4]),
    .DOUTA8(), .DOUTA7(), .DOUTA6(), .DOUTA5(),.DOUTA4(), .DOUTA3(),.DOUTA2(),.DOUTA1(),.DOUTA0(),
    .WIDTHA1(1'b1), .WIDTHA0(1'b0), .PIPEA(1'b0), .WMODEA(1'b0), .BLKA(1'b0), .WENA(ram_we_b),
    .CLKB(clk),
    .ADDRB11(1'b0), .ADDRB10(1'b0), .ADDRB9(ram_raddr[9]), .ADDRB8(ram_raddr[8]),
    .ADDRB7(ram_raddr[7]), .ADDRB6(ram_raddr[6]), .ADDRB5(ram_raddr[5]), .ADDRB4(ram_raddr[4]),
    .ADDRB3(ram_raddr[3]), .ADDRB2(ram_raddr[2]), .ADDRB1(ram_raddr[1]), .ADDRB0(ram_raddr[0]),
    .DINB8(1'b0), .DINB7(1'b0), .DINB6(1'b0), .DINB5(1'b0),.DINB4(1'b0),
    .DINB3(1'b0), .DINB2(1'b0), .DINB1(1'b0), .DINB0(1'b0),
    .DOUTB8(), .DOUTB7(), .DOUTB6(), .DOUTB5(),.DOUTB4(),
    .DOUTB3(ram_rdata_arr[7]),.DOUTB2(ram_rdata_arr[6]),.DOUTB1(ram_rdata_arr[5]),.DOUTB0(ram_rdata_arr[4]),
    .WIDTHB1(1'b1), .WIDTHB0(1'b0), .PIPEB(1'b0), .WMODEB(1'b0), .BLKB(1'b0), .WENB(1'b1)
  );

  RAM4K9 ram_2[NUM_SRAM_TRIPS - 1:0](
    .RESET(~reset),
    .CLKA(clk),
    .ADDRA11(1'b0), .ADDRA10(1'b0), .ADDRA9(ram_waddr[9]), .ADDRA8(ram_waddr[8]),
    .ADDRA7(ram_waddr[7]), .ADDRA6(ram_waddr[6]), .ADDRA5(ram_waddr[5]), .ADDRA4(ram_waddr[4]),
    .ADDRA3(ram_waddr[3]), .ADDRA2(ram_waddr[2]), .ADDRA1(ram_waddr[1]), .ADDRA0(ram_waddr[0]),
    .DINA8(1'b0), .DINA7(1'b0), .DINA6(1'b0), .DINA5(1'b0),.DINA4(1'b0),
    .DINA3(ram_wdata[11]), .DINA2(ram_wdata[10]), .DINA1(ram_wdata[9]), .DINA0(ram_wdata[8]),
    .DOUTA8(), .DOUTA7(), .DOUTA6(), .DOUTA5(),.DOUTA4(), .DOUTA3(),.DOUTA2(),.DOUTA1(),.DOUTA0(),
    .WIDTHA1(1'b1), .WIDTHA0(1'b0), .PIPEA(1'b0), .WMODEA(1'b0), .BLKA(1'b0), .WENA(ram_we_b),
    .CLKB(clk),
    .ADDRB11(1'b0), .ADDRB10(1'b0), .ADDRB9(ram_raddr[9]), .ADDRB8(ram_raddr[8]),
    .ADDRB7(ram_raddr[7]), .ADDRB6(ram_raddr[6]), .ADDRB5(ram_raddr[5]), .ADDRB4(ram_raddr[4]),
    .ADDRB3(ram_raddr[3]), .ADDRB2(ram_raddr[2]), .ADDRB1(ram_raddr[1]), .ADDRB0(ram_raddr[0]),
    .DINB8(1'b0), .DINB7(1'b0), .DINB6(1'b0), .DINB5(1'b0),.DINB4(1'b0),
    .DINB3(1'b0), .DINB2(1'b0), .DINB1(1'b0), .DINB0(1'b0),
    .DOUTB8(), .DOUTB7(), .DOUTB6(), .DOUTB5(),.DOUTB4(),
    .DOUTB3(ram_rdata_arr[11]),.DOUTB2(ram_rdata_arr[10]),.DOUTB1(ram_rdata_arr[9]),.DOUTB0(ram_rdata_arr[8]),
    .WIDTHB1(1'b1), .WIDTHB0(1'b0), .PIPEB(1'b0), .WMODEB(1'b0), .BLKB(1'b0), .WENB(1'b1)
  );

endmodule
