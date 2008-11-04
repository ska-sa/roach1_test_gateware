`ifndef BOARD_ID
`define BOARD_ID "57005"
`endif
`ifndef REV_MAJOR
`define REV_MAJOR "0"
`endif
`ifndef REV_MINOR
`define REV_MINOR "0"
`endif
`ifndef REV_RCS
`define REV_RCS   "0"
`endif
`ifndef RCS_UPTODATE
`define RCS_UPTODATE "0"
`endif
module gen_build_parameters();
  initial begin
    $display("\140ifndef BUILD_PARAMETERS_VH");
    $display("\140define BUILD_PARAMETERS_VH");
    $display("\140define BOARD_ID     16'd%s", `BOARD_ID);
    $display("\140define REV_MAJOR    16'd%s", `REV_MAJOR);
    $display("\140define REV_MINOR    16'd%s", `REV_MINOR);
    $display("\140define REV_RCS      16'd%s", `REV_RCS);
    $display("\140define RCS_UPTODATE 16'd%s", `RCS_UPTODATE);
    $display("\140endif");
    $finish;
  end
endmodule

