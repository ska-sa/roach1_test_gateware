`ifndef BOARD_ID
`define BOARD_ID 57005
`endif
`ifndef REV_MAJOR
`define REV_MAJOR 0
`endif
`ifndef REV_MINOR
`define REV_MINOR 0
`endif
`ifndef REV_RCS
`define REV_RCS   1000
`endif
module gen_build_parameters();
  initial begin
    $display("\`ifndef BUILD_PARAMETERS_VH");
    $display("\`define BUILD_PARAMETERS_VH");
    $display("\`define BOARD_ID  16'd`BOARD_ID");
    $display("\`define REV_MAJOR 16'd`REV_MAJOR");
    $display("\`define REV_MINOR 16'd`REV_MINOR");
    $display("\`define REV_RCS   16'd`REV_RCS");
    $display("\`endif");
    $finish;
  end
endmodule

