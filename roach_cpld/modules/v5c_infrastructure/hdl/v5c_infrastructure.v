module v5c_infrastructure(
    v5c_init_n,
    v5c_init_n_i, v5c_init_n_o, v5c_init_n_oen, 
    v5c_cclk,
    v5c_cclk_i, v5c_cclk_oen
  );
  inout  v5c_init_n;
  input  v5c_init_n_i;
  output v5c_init_n_o;
  input  v5c_init_n_oen;

  inout  v5c_cclk;
  input  v5c_cclk_i, v5c_cclk_oen;

  OBUFE OBUFE_init_inst(
    .E(v5c_init_n_oen), .I(v5c_init_n_i), .O(v5c_init_n)
  );

  IBUF IBUF_init_inst(
    .I(v5c_init_n), .O(v5c_init_n_o)
  );

  OBUFE OBUFE_cclk_inst(
    .E(v5c_cclk_oen), .I(v5c_cclk_i), .O(v5c_cclk)
  );

endmodule
