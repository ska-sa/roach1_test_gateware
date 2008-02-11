module from_controller(
    wb_clk_i, wb_rst_i,
    wb_cyc_i, wb_stb_i, wb_we_i,
    wb_adr_i, wb_dat_i, wb_dat_o,
    wb_ack_o,
    from_clk, from_addr, from_data
  );
  input  wb_clk_i, wb_rst_i;
  input  wb_cyc_i, wb_stb_i, wb_we_i;
  input  [15:0] wb_adr_i;
  input  [15:0] wb_dat_i;
  output [15:0] wb_dat_o;
  output wb_ack_o;

  output from_clk;
  output [6:0] from_addr;
  input  [7:0] from_data;

  assign from_addr = wb_adr_i[6:0];

  reg wb_ack_o;
  assign wb_dat_o = {8'b0, from_data};

  assign from_clk = wb_clk_i;

  always @(posedge wb_clk_i) begin
    //strobe
    wb_ack_o <= 1'b0;
    if (wb_rst_i) begin
    end else begin
      if (wb_cyc_i & wb_stb_i & ~wb_ack_o) begin
        wb_ack_o <= 1'b1;
      end
    end
  end

endmodule
