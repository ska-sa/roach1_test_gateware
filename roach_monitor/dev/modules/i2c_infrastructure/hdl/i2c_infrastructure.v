module i2c_infrastructure(
    sda_i, sda_o, sda_oen,
    scl_i, scl_o, scl_oen,
    sda_buf_o, sda_buf_i,
    scl_buf_o, scl_buf_i,
  );
  output sda_i;
  input  sda_o;
  input  sda_oen;
  output scl_i;
  input  scl_o;
  input  scl_oen;
  output sda_buf_o;
  input  sda_buf_i;
  output scl_buf_o;
  input  scl_buf_i;

  assign sda_buf_o = sda_oen ? sda_buf_i : ~sda_o;
  assign sda_i = sda_buf_i;
  assign scl_buf_o = scl_oen ? scl_buf_i : ~scl_o;
  assign scl_i = scl_buf_i;
  /* true i2c - oc
  assign sda_buf_o = ~sda_oen ? sda_o : 1'b0;
  assign sda_i = sda_buf_i;
  assign scl_buf_o = ~scl_oen ? scl_o : 1'b0;
  assign scl_i = scl_buf_i;
  */
endmodule
