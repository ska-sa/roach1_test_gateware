`timescale 1ns/10ps

module qdr_controller(
    input  clk,
    input  rst,
    input  [31:0] qdr_addr,
    input  qdr_wr_en,
    input   [3:0] qdr_be,
    input  [35:0] qdr_wr_data,
    input  qdr_rd_en,
    output [35:0] qdr_rd_data,
    output qdr_rdy
  );
  parameter QDR_LATENCY = 10;
  parameter QDR_DEPTH   = 1024;

  wire master_rd_strb = qdr_rd_en;
  wire master_wr_strb = qdr_wr_en;
  wire [3:0] master_wr_be   = qdr_be;
  wire [31:0] master_addr = qdr_addr;
  wire qdr_clk = clk;
  wire sys_rst = rst;
  wire [35:0] master_wr_data = qdr_wr_data;
  wire [35:0] master_rd_data;
  assign qdr_rd_data = master_rd_data;
  assign qdr_rdy = 1'b1;

  /******* Simulated QDR Interface ********/

  localparam QDR_DEPTH = 1024*64;

  reg [8:0] data_byte0 [QDR_DEPTH - 1:0];
  reg [8:0] data_byte1 [QDR_DEPTH - 1:0];
  reg [8:0] data_byte2 [QDR_DEPTH - 1:0];
  reg [8:0] data_byte3 [QDR_DEPTH - 1:0];
  reg [8:0] data_byte4 [QDR_DEPTH - 1:0];
  reg [8:0] data_byte5 [QDR_DEPTH - 1:0];
  reg [8:0] data_byte6 [QDR_DEPTH - 1:0];
  reg [8:0] data_byte7 [QDR_DEPTH - 1:0];

  reg [36*(QDR_LATENCY+1) - 1:0] qdr_q_shifter;

  reg second_read;
  reg second_write;

  wire first_read  = master_rd_strb  && !second_read;
  wire first_write = !first_read && master_wr_strb && !second_write;

  reg [31:0] master_addr_z;

  always @(posedge qdr_clk) begin
    second_read  <= 1'b0;
    second_write <= 1'b0;
    master_addr_z <= master_addr;

    if (sys_rst) begin
    end else begin
//      $display(". r = %b, w = %b, a = %x, d = %x", master_rd_strb, master_wr_strb, master_addr, master_wr_data);
      if (first_read) begin
        second_read <= 1'b1;
        qdr_q_shifter <= {qdr_q_shifter[36*QDR_LATENCY - 1:0], data_byte3[master_addr], data_byte2[master_addr], 
                                                               data_byte1[master_addr], data_byte0[master_addr]};
`ifdef DESPERATE_DEBUG
        $display("qdr_master: read0 - addr = %x, q = %x", master_addr, {data_byte3[master_addr], data_byte2[master_addr], data_byte1[master_addr] ,data_byte0[master_addr]});
`endif
      end else if (second_read) begin
        qdr_q_shifter <= {qdr_q_shifter[36*QDR_LATENCY - 1:0], data_byte7[master_addr_z], data_byte6[master_addr_z], 
                                                               data_byte5[master_addr_z], data_byte4[master_addr_z]};
`ifdef DESPERATE_DEBUG
        $display("qdr_master: read1 - addr = %x, q = %x", master_addr, {data_byte7[master_addr_z], data_byte6[master_addr_z], data_byte5[master_addr_z] ,data_byte4[master_addr_z]});
`endif
      end else begin
        qdr_q_shifter <= {qdr_q_shifter[36*QDR_LATENCY - 1:0], {36{1'b0}}};
      end

      if (first_write) begin
        second_write <= 1'b1;

        if (master_wr_be[0])
          data_byte0[master_addr] <= master_wr_data[8:0];
        if (master_wr_be[1])
          data_byte1[master_addr] <= master_wr_data[17:9];
        if (master_wr_be[2])
          data_byte2[master_addr] <= master_wr_data[26:18];
        if (master_wr_be[3])
          data_byte3[master_addr] <= master_wr_data[35:27];

`ifdef DESPERATE_DEBUG
        $display("qdr_master: write0 - addr = %x, data = %x, be = %b", master_addr, master_wr_data, master_wr_be);
`endif
      end else if (second_write) begin

        if (master_wr_be[0])
          data_byte4[master_addr_z] <= master_wr_data[8:0];
        if (master_wr_be[1])
          data_byte5[master_addr_z] <= master_wr_data[17:9];
        if (master_wr_be[2])
          data_byte6[master_addr_z] <= master_wr_data[26:18];
        if (master_wr_be[3])
          data_byte7[master_addr_z] <= master_wr_data[35:27];

`ifdef DESPERATE_DEBUG
        $display("qdr_master: write1 - addr = %x, data = %x, be = %b", master_addr_z, master_wr_data, master_wr_be);
`endif
      end
    end
  end

  assign master_rd_data = qdr_q_shifter[36*(QDR_LATENCY) - 1:36*(QDR_LATENCY-1)];
endmodule
