module kat_iic_controller(
    input         OPB_Clk,
    input         OPB_Rst,
    output [0:31] Sl_DBus,
    output        Sl_errAck,
    output        Sl_retry,
    output        Sl_toutSup,
    output        Sl_xferAck,
    input  [0:31] OPB_ABus,
    input  [0:3]  OPB_BE,
    input  [0:31] OPB_DBus,
    input         OPB_RNW,
    input         OPB_select,
    input         OPB_seqAddr,

	  input         sda_i,
	  output        sda_o,
	  output        sda_t,
	  input         scl_i,
	  output        scl_o,
	  output        scl_t
  );
  parameter C_BASEADDR    = 32'h00000000;
  parameter C_HIGHADDR    = 32'h0000FFFF;
  parameter C_OPB_AWIDTH  = 32;
  parameter C_OPB_DWIDTH  = 32;
  parameter IIC_FREQ      = 100;  //kHz
  parameter CORE_FREQ     = 100000; //kHz

  wire op_valid;
  wire op_start;
  wire op_stop;
  wire op_rnw;
  wire [7:0] op_wr_data;
  wire [7:0] op_rd_data;
  wire op_ack;

  /************* Operation Processing ************/

  miic_ops #(
    .IIC_FREQ  (IIC_FREQ),
    .CORE_FREQ (CORE_FREQ),
  ) miic_ops_inst(
    .clk (OPB_Clk),
    .rst (OPB_Rst),
    .op_valid   (op_valid),
    .op_start   (op_start),
    .op_stop    (op_stop),
    .op_rnw     (op_rnw),
    .op_wr_data (op_wr_data),
    .op_rd_data (op_rd_data),
    .op_ack     (op_ack)
  );

  always @(posedge clk) begin
  end

endmodule
