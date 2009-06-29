module vs_infrastructure(
    clk, reset,
    ram_raddr,
    ram_waddr,
    ram_rdata,
    ram_wdata,
    ram_wen
  );
  input  clk, reset;
  input  ram_wen;
  input  [11:0] ram_raddr;
  input  [11:0] ram_waddr;
  output [11:0] ram_rdata;
  input  [11:0] ram_wdata;

  /* a 4Kx12 buffer */

  RAM4K9 ram_0[11:0](
    .RESET   (!reset),
    /* PORT A */
    .CLKA    (clk),
    .ADDRA11 (ram_waddr[11]),
    .ADDRA10 (ram_waddr[10]),
    .ADDRA9  (ram_waddr[9] ),
    .ADDRA8  (ram_waddr[8] ),
    .ADDRA7  (ram_waddr[7] ),
    .ADDRA6  (ram_waddr[6] ),
    .ADDRA5  (ram_waddr[5] ),
    .ADDRA4  (ram_waddr[4] ),
    .ADDRA3  (ram_waddr[3] ),
    .ADDRA2  (ram_waddr[2] ),
    .ADDRA1  (ram_waddr[1] ),
    .ADDRA0  (ram_waddr[0] ),
    .DINA8   (1'b0),
    .DINA7   (1'b0),
    .DINA6   (1'b0),
    .DINA5   (1'b0),
    .DINA4   (1'b0),
    .DINA3   (1'b0),
    .DINA2   (1'b0),
    .DINA1   (1'b0),
    .DINA0   (ram_wdata),
    .DOUTA8  (),
    .DOUTA7  (),
    .DOUTA6  (),
    .DOUTA5  (),
    .DOUTA4  (),
    .DOUTA3  (),
    .DOUTA2  (),
    .DOUTA1  (),
    .DOUTA0  (),
    .WENA    (!ram_wen),
    .WIDTHA1 (1'b0),
    .WIDTHA0 (1'b0),
    .PIPEA   (1'b0),
    .WMODEA  (1'b0),
    .BLKA    (1'b0),
    /* PORT B */
    .CLKB    (clk),
    .ADDRB11 (ram_raddr[11]),
    .ADDRB10 (ram_raddr[10]),
    .ADDRB9  (ram_raddr[9] ),
    .ADDRB8  (ram_raddr[8] ),
    .ADDRB7  (ram_raddr[7] ),
    .ADDRB6  (ram_raddr[6] ),
    .ADDRB5  (ram_raddr[5] ),
    .ADDRB4  (ram_raddr[4] ),
    .ADDRB3  (ram_raddr[3] ),
    .ADDRB2  (ram_raddr[2] ),
    .ADDRB1  (ram_raddr[1] ),
    .ADDRB0  (ram_raddr[0] ),
    .DINB8   (1'b0),
    .DINB7   (1'b0),
    .DINB6   (1'b0),
    .DINB5   (1'b0),
    .DINB4   (1'b0),
    .DINB3   (1'b0),
    .DINB2   (1'b0),
    .DINB1   (1'b0),
    .DINB0   (1'b0),
    .DOUTB8  (),
    .DOUTB7  (),
    .DOUTB6  (),
    .DOUTB5  (),
    .DOUTB4  (),
    .DOUTB3  (),
    .DOUTB2  (),
    .DOUTB1  (),
    .DOUTB0  (ram_rdata),
    .WIDTHB1 (1'b0),
    .WIDTHB0 (1'b0),
    .PIPEB   (1'b0),
    .WMODEB  (1'b0),
    .BLKB    (1'b0),
    .WENB    (1'b1) /* Read Only */

  );

endmodule
