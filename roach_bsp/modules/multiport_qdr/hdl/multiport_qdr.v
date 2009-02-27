module multiport_qdr(
   // System inputs
   clk,
   rst,

   // Memory interface in 0 (non-shared)
   in0_cmd_addr,
   in0_cmd_ack,
   in0_wr_strb,
   in0_wr_data,
   in0_wr_be,
   in0_rd_strb,
   in0_rd_dvld,
   in0_rd_data,

   // Memory interface in 1 (non-shared)
   in1_cmd_addr,
   in1_cmd_ack,
   in1_wr_strb,
   in1_wr_data,
   in1_wr_be,
   in1_rd_strb,
   in1_rd_dvld,
   in1_rd_data,

   // Memory interface out (shared)
   out_cmd_addr,
   out_wr_strb,
   out_wr_data,
   out_wr_be,
   out_rd_strb,
   out_rd_dvld,
   out_rd_data
  );
  parameter C_WIDE_DATA  = 0;

  localparam QDR_LATENCY = 10;

  input clk, rst;

  input  [31:0] in0_cmd_addr;
  output in0_cmd_ack;
  input  in0_wr_strb;
  input  [36*(1+C_WIDE_DATA) - 1:0] in0_wr_data;
  input   [4*(1+C_WIDE_DATA) - 1:0] in0_wr_be;
  input  in0_rd_strb;
  output in0_rd_dvld;
  output [36*(1+C_WIDE_DATA) - 1:0] in0_rd_data;

  input  [31:0] in1_cmd_addr;
  output in1_cmd_ack;
  input  in1_wr_strb;
  input  [36*(1+C_WIDE_DATA) - 1:0] in1_wr_data;
  input   [4*(1+C_WIDE_DATA) - 1:0] in1_wr_be;
  input  in1_rd_strb;
  output in1_rd_dvld;
  output [36*(1+C_WIDE_DATA) - 1:0] in1_rd_data;

  output [31:0] out_cmd_addr;
  output out_wr_strb;
  output [36*(1+C_WIDE_DATA) - 1:0] out_wr_data;
  output  [4*(1+C_WIDE_DATA) - 1:0] out_wr_be;
  output out_rd_strb;
  input  out_rd_dvld; //this is currently unused as the timing is fixed...
  input  [36*(1+C_WIDE_DATA) - 1:0] out_rd_data;

  reg [QDR_LATENCY - 1:0] in0_rd_pipe;
  reg [QDR_LATENCY - 1:0] in1_rd_pipe;

  assign in0_cmd_wr  = in0_wr_strb;
  assign in0_cmd_rd  = in0_rd_strb;
  assign in0_cmd_ack = in0_cmd_wr || in0_cmd_rd;
  /* TODO: check if this becomes problematic at higher frequencies */
  assign in1_cmd_wr  = in1_wr_strb && !(in0_cmd_ack);
  assign in1_cmd_rd  = in1_rd_strb && !(in0_cmd_ack);
  assign in1_cmd_ack = in1_cmd_wr || in1_cmd_rd;

  reg in0_cmd_wr_z;

  always @(posedge clk) begin

    if (rst) begin
      in0_cmd_wr_z <= 1'b0;
      in0_rd_pipe <= {QDR_LATENCY{1'b0}};
      in1_rd_pipe <= {QDR_LATENCY{1'b0}};
    end else begin
      in0_cmd_wr_z <= in0_cmd_wr;
      in0_rd_pipe <= {in0_rd_pipe[QDR_LATENCY - 2:0], in0_cmd_rd};
      in1_rd_pipe <= {in1_rd_pipe[QDR_LATENCY - 2:0], in1_cmd_rd};
    end
  end

  assign out_cmd_addr = in0_cmd_ack ? in0_cmd_addr : in1_cmd_addr;
  assign out_wr_data  = in0_cmd_wr || in0_cmd_wr_z ? in0_wr_data : in1_wr_data;
  assign out_wr_be    = in0_cmd_wr || in0_cmd_wr_z ? in0_wr_be   : in1_wr_be;
  assign out_wr_strb  = in0_cmd_wr || in1_cmd_wr;
  assign out_rd_strb  = in0_cmd_rd || in1_cmd_rd;

  assign in0_rd_dvld = in0_rd_pipe[QDR_LATENCY - 1];
  assign in1_rd_dvld = in1_rd_pipe[QDR_LATENCY - 1];
  assign in0_rd_data = out_rd_data;
  assign in1_rd_data = out_rd_data;

endmodule
