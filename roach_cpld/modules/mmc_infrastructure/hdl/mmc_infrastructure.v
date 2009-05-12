module mmc_infrastructure(
    mmc_cmd, mmc_data,
    mmc_cmd_i, mmc_cmd_o, mmc_cmd_oe,
    mmc_data_i, mmc_data_o, mmc_data_oe
  );
  inout  mmc_cmd;
  inout  [7:0] mmc_data;
  input  mmc_cmd_i;
  output mmc_cmd_o;
  input  mmc_cmd_oe;
  input  [7:0] mmc_data_i;
  output [7:0] mmc_data_o;
  input  mmc_data_oe;

  OBUFE OBUFE_data_inst[7:0](
    .E(mmc_data_oe), .I(mmc_data_i), .O(mmc_data)
  );

  IBUF IBUF_data_inst[7:0](
    .I(mmc_data), .O(mmc_data_o)
  );

  OBUFE OBUFE_cmd_inst(
    .E(mmc_cmd_oe), .I(mmc_cmd_i), .O(mmc_cmd)
  );

  IBUF IBUF_cmd_inst(
    .I(mmc_cmd), .O(mmc_cmd_o)
  );

endmodule
