`timescale 1ns/10ps

module wbm_arbiter(
    /*generic wb signals*/
    wb_clk_i, wb_rst_i,
    /*wbm signals*/
    wbm_cyc_i, wbm_stb_i, wbm_we_i,
    wbm_adr_i, wbm_dat_i, wbm_dat_o,
    wbm_ack_o, wbm_err_o,
    /*wbs signals*/
    wbs_cyc_o, wbs_stb_o, wbs_we_o,
    wbs_adr_o, wbs_dat_o, wbs_dat_i,
    wbs_ack_i, 
    /*special signals*/
    wbm_mask,
    wbm_id,
    wb_timeout
  );
  parameter NUM_MASTERS = 2;

  input  wb_clk_i, wb_rst_i;

  input  [NUM_MASTERS - 1:0] wbm_cyc_i;
  input  [NUM_MASTERS - 1:0] wbm_stb_i;
  input  [NUM_MASTERS - 1:0] wbm_we_i;
  input  [16*NUM_MASTERS - 1:0] wbm_adr_i;
  input  [16*NUM_MASTERS - 1:0] wbm_dat_i;
  output [15:0] wbm_dat_o;
  output [NUM_MASTERS - 1:0] wbm_ack_o;
  output [NUM_MASTERS - 1:0] wbm_err_o;

  output wbs_cyc_o;
  output wbs_stb_o;
  output wbs_we_o;
  output [15:0] wbs_adr_o;
  output [15:0] wbs_dat_o;
  input  [15:0] wbs_dat_i;
  input  wbs_ack_i;

  output [NUM_MASTERS - 1:0] wbm_id;
  input  [NUM_MASTERS - 1:0] wbm_mask;
  input  wb_timeout;

  integer active_master;

  genvar gen_i, gen_j;

  generate for (gen_i=0; gen_i < NUM_MASTERS; gen_i=gen_i+1) begin : G0
    assign wbm_ack_o[gen_i] = active_master == gen_i ? wbs_ack_i : 1'b0;
  end endgenerate

  generate for (gen_j=0; gen_j < NUM_MASTERS; gen_j=gen_j+1) begin : G1
    assign wbm_err_o[gen_j] = active_master == gen_j ? wb_timeout & ~wbs_ack_i : 1'b0;
  end endgenerate

  assign wbm_dat_o = wbs_dat_i;

  assign wbs_we_o  = wbm_we_i[active_master];

  genvar gen_k, gen_l;

  generate for (gen_k=0; gen_k < 16; gen_k=gen_k+1) begin : G2
    assign wbs_adr_o[gen_k] = wbm_adr_i[16*active_master + gen_k];
  end endgenerate

  generate for (gen_l=0; gen_l < 16; gen_l=gen_l+1) begin : G3
    assign wbs_dat_o[gen_l] = wbm_dat_i[16*active_master + gen_l];
  end endgenerate

  assign wbm_id = active_master;

  integer i,j;

  reg wbs_cyc_o;
  reg wbs_stb_o;

  reg [NUM_MASTERS - 1:0] pending;

  reg wb_busy;

  always @(posedge wb_clk_i) begin
    if (wb_rst_i) begin
      wbs_cyc_o <= 1'b0;
      wbs_stb_o <= 1'b0;
      pending <= {NUM_MASTERS{1'b0}};
      wb_busy <= 1'b0;
      active_master <= 1'b1;
    end else begin
      wbs_cyc_o <= 1'b0;
      wbs_stb_o <= 1'b0;

      for (i=0; i < NUM_MASTERS; i=i+1) begin
        if (wbm_cyc_i[i] & wbm_stb_i[i] & wbm_mask[i]) begin
          pending[i] <= 1'b1;
`ifdef DEBUG
          $display("arb: event on %d, now pending", i);
`endif
        end
      end

      if (wbs_ack_i | wb_timeout) begin
        pending[active_master] <= 1'b0;
        wb_busy <= 1'b0;
`ifdef DEBUG
        $display("arb: got response, clearing pending on %d", active_master);
`endif
      end

      if (~wb_busy) begin
        if (pending) begin
          wbs_cyc_o <= 1'b1;
          wbs_stb_o <= 1'b1;
          wb_busy <= 1'b1;
        end
        for (j=0; j < NUM_MASTERS; j=j+1) begin
          if (pending[j]) begin
            active_master <= j; //last master gets preference
          end
        end
      end
    end
  end

endmodule
