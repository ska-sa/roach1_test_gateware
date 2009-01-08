module i2c_infrastructure(
    sda_i, sda_o, sda_oen,
    scl_i, scl_o, scl_oen,
    sda_buf,
    scl_buf
  );
  output sda_i;
  input  sda_o;
  input  sda_oen; //active low
  output scl_i;
  input  scl_o;
  input  scl_oen; //active low
  inout  sda_buf;
  input  scl_buf;

  BIBUF bibuf_sda(
    .PAD(sda_buf),
    .D(sda_o),
    .E(~sda_oen),
    .Y(sda_i)
  );

  assign scl_i = scl_buf;
  /* true i2c - oc
  assign sda_buf_o = ~sda_oen ? sda_o : 1'b0;
  assign sda_i = sda_buf_i;
  assign scl_buf_o = ~scl_oen ? scl_o : 1'b0;
  assign scl_i = scl_buf_i;
  */
endmodule
