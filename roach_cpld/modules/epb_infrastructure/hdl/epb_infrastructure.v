module epb_infrastructure(
    epb_data,
    epb_data_i, epb_data_o,
    epb_oen
  );
  inout  [7:0] epb_data;
  input  [7:0] epb_data_i;
  output [7:0] epb_data_o;
  input  epb_oen;

  OBUFE OBUFE_inst[7:0](
    .E(epb_oen), .I(epb_data_i), .O(epb_data)
  );

  IBUF IBUF_inst[7:0](
    .I(epb_data), .O(epb_data_o)
  );

endmodule
