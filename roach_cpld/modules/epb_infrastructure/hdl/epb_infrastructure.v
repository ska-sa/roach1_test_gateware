module epb_infrastructure(
    epb_data,
    epb_rdy,
    epb_data_i, epb_data_o,
    epb_data_oe,
    epb_rdy_i,
    epb_rdy_oe
  );

  inout  [7:0] epb_data;
  inout        epb_rdy;

  input  [7:0] epb_data_i;
  output [7:0] epb_data_o;
  input        epb_data_oe;

  input        epb_rdy_oe;
  input        epb_rdy_i;

  OBUFE OBUFE_inst[7:0](
    .E(epb_data_oe), .I(epb_data_i), .O(epb_data)
  );

  IBUF IBUF_inst[7:0](
    .I(epb_data), .O(epb_data_o)
  );

  OBUFE OBUFE_epb_rdy(
    .E(epb_rdy_oe), .I(epb_rdy_i), .O(epb_rdy)
  );

endmodule
