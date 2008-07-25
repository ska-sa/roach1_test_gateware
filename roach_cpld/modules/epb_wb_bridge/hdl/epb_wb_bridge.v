module epb_wb_bridge(
    clk, reset,
    epb_cs_n, epb_oen_n, epb_we_n, epb_be_n,
    epb_addr,
    epb_data_i, epb_data_o, epb_data_oen,
    wb_cyc_o, wb_stb_o, wb_we_o, wb_sel_o,
    wb_adr_o, wb_dat_o, wb_dat_i,
    wb_ack_i
  );
  parameter TRANS_LENGTH = 1;
  input  clk, reset;
  input  epb_cs_n, epb_oen_n, epb_we_n, epb_be_n;
  input  [4:0] epb_addr;
  input  [7:0] epb_data_i;
  output [7:0] epb_data_o;
  output epb_data_oen;
  output wb_cyc_o, wb_stb_o, wb_we_o, wb_sel_o;
  output [4:0] wb_adr_o;
  output [7:0] wb_dat_o;
  input  [7:0] wb_dat_i;
  input  wb_ack_i; //unused - fixed timing

  wire epb_trans_strb;
  wire epb_trans_busy;


  assign wb_cyc_o     = epb_trans_strb;
  assign wb_stb_o     = epb_trans_strb;
  assign wb_we_o      = !epb_we_n;
  assign wb_sel_o     = !epb_be_n;
  assign wb_adr_o     = epb_addr;
  assign wb_dat_o     = epb_data_i;
  assign epb_data_o   = wb_dat_i;
  assign epb_data_oen = epb_trans_busy & epb_we_n ? !epb_oen_n : 1'b0; //output enable on reads

  /* EPB transaction decoding */

  reg [TRANS_LENGTH - 1:0] trans_shift_reg;
 
  reg prev_epb_cs_n;

  assign epb_trans_strb = prev_epb_cs_n != epb_cs_n && !epb_cs_n;
  assign epb_trans_busy = epb_trans_strb || trans_shift_reg != {TRANS_LENGTH{1'b0}};

  always @(posedge clk) begin
    prev_epb_cs_n   <= epb_cs_n;
    trans_shift_reg <= trans_shift_reg << 1;

    if (reset) begin
      prev_epb_cs_n <= epb_cs_n;
      trans_shift_reg <= {TRANS_LENGTH{1'b0}};
    end else begin
      if (epb_trans_strb) begin
        trans_shift_reg <= {TRANS_LENGTH{1'b1}};
      end
    end
  end

endmodule
