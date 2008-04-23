module epb_infrastructure(
    epb_data_buf,
    epb_data_oe_n_i,
    epb_data_out_i, epb_data_in_o,
    epb_cs_n_buf, epb_cs_n,
    epb_r_w_n_buf, epb_r_w_n, 
    epb_be_n_buf, epb_be_n,
    epb_addr_buf, epb_addr,
    epb_addr_gp_buf, epb_addr_gp
  );
  inout  [15:0] epb_data_buf;
  input  epb_data_oe_n_i;
  input  [15:0] epb_data_out_i;
  output [15:0] epb_data_in_o;
  input  epb_cs_n_buf;
  output epb_cs_n;
  input  epb_r_w_n_buf;
  output epb_r_w_n;
  input   [1:0] epb_be_n_buf;
  output  [1:0] epb_be_n;
  input  [22:0] epb_addr_buf;
  output [22:0] epb_addr;
  input   [5:0] epb_addr_gp_buf;
  output  [5:0] epb_addr_gp;

  IODELAY #(
    .IDELAY_TYPE("FIXED"),
    .IDELAY_VALUE(0),
    .ODELAY_VALUE(0)
  ) iodelay_inst [15:0] (
    .DATAOUT(epb_data_in_o),
    .DATAIN(epb_data_out_i),
    .IDATAIN(epb_data_buf),
    .ODATAIN(),
    .T(epb_data_oe_n_i),

    .C(1'b0),
    .CE(1'b0),
    .INC(1'b0),
    .RST(1'b0)
  );

  IDELAY #(
    .IOBDELAY_TYPE("DEFAULT"),
    .IOBDELAY_VALUE(0)
  ) idelay_inst [32:0] (
    .I({epb_cs_n_buf, epb_r_w_n_buf, epb_be_n_buf, epb_addr_buf, epb_addr_gp_buf}),
    .O({epb_cs_n,     epb_r_w_n,     epb_be_n,     epb_addr,     epb_addr_gp}),
    .C(1'b0),
    .CE(1'b0),
    .INC(1'b0),
    .RST(1'b0)
  );


endmodule
