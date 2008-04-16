`timescale 1ns/10ps

module epb_wb_bridge_reg(
    wb_clk_i, wb_rst_i,
    wb_cyc_o, wb_stb_o, wb_we_o, wb_sel_o,
    wb_adr_o, wb_dat_o, wb_dat_i,
    wb_ack_i, wb_err_i,

    epb_clk,
    epb_cs_n, epb_r_w_n, epb_oe_n, epb_be_n, 
    epb_addr, epb_addr_gb,
    epb_data_i, epb_data_o,
    epb_rdy
  );
  input  wb_clk_i, wb_rst_i;
  output wb_cyc_o, wb_stb_o, wb_we_o;
  output  [1:0] wb_sel_o;
  output [31:0] wb_adr_o;
  output [15:0] wb_dat_o;
  input  [15:0] wb_dat_i;
  input  wb_ack_i, wb_err_i;

  input  epb_clk;
  input  epb_cs_n, epb_r_w_n, epb_oe_n;
  input   [1:0] epb_be_n;
  input  [22:0] epb_addr;
  input   [5:0] epb_addr_gb;
  input  [15:0] epb_data_i;
  output [15:0] epb_data_o;
  output epb_rdy;

  /******* Common Signals *******/

  reg cmnd_got, cmnd_ack;
  reg resp_got, resp_ack;

  wire cmnd_got_unstable, cmnd_ack_unstable;
  wire resp_got_unstable, resp_ack_unstable;

  /******* EPB Bus control ******/

  reg cmnd_got_reg;
  assign cmnd_got_unstable = prev_cs_n != epb_cs_n && !epb_cs_n | cmnd_got_reg; 
  reg prev_cs_n; 

  /* Command Generation */
  always @(posedge epb_clk) begin
    prev_cs_n <= epb_cs_n;
    if (wb_rst_i) begin
      cmnd_got_reg <= 1'b0;
    end else begin
      if (prev_cs_n != epb_cs_n && !epb_cs_n) begin
        cmnd_got_reg <= 1'b1;
      end

      if (cmnd_ack) begin
        cmnd_got_reg <= 1'b0;
      end
    end
  end

  /* Response Collection */

  reg resp_ack_reg;
  assign resp_ack_unstable = resp_ack_reg | resp_got;

  reg epb_rdy;

  always @(posedge wb_clk_i) begin
    if (wb_rst_i) begin
      resp_ack_reg <= 1'b0;
      epb_rdy <= 1'b0;
    end else begin
      if (cmnd_got_unstable) begin
        epb_rdy <= 1'b0;
      end
      if (resp_got) begin
        if (~resp_ack_reg) begin
          epb_rdy <= 1'b1;
        end
        resp_ack_reg <= 1'b1;
      end else begin
        resp_ack_reg <= 1'b0;
      end
    end
  end

  /**** WishBone Generation ****/
  reg [15:0] wb_dat_i_reg;
  assign epb_data_o = wb_dat_i_reg;
  assign wb_dat_o   = epb_data_i;
  assign wb_adr_o   = {2'b0, epb_addr_gb, epb_addr, 1'b0};
  assign wb_sel_o   = ~epb_be_n;
  assign wb_we_o    = ~epb_r_w_n;

  /* Register Data */
  always @(posedge wb_clk_i) begin
    if (wb_ack_i) begin
      wb_dat_i_reg <= wb_dat_i;
    end
  end

  /* Command collection */

  reg wb_cyc_o;
  assign wb_stb_o = wb_cyc_o;

  reg cmnd_ack_reg;
  assign cmnd_ack_unstable = cmnd_ack_reg | cmnd_got;

  always @(posedge wb_clk_i) begin
    //strobes
    wb_cyc_o <= 1'b0;
    if (wb_rst_i) begin
      cmnd_ack_reg <= 1'b0;
    end else begin
      if (cmnd_got) begin
        if (~cmnd_ack_reg) begin //on first
          wb_cyc_o <= 1'b1;
        end
        cmnd_ack_reg <= 1'b1;
      end else begin
        cmnd_ack_reg <= 1'b0;
      end
    end
  end

  /* Response generation */
  reg resp_got_reg;
  assign resp_got_unstable = wb_ack_i | resp_got_reg;

  always @(posedge wb_clk_i) begin
    if (wb_rst_i) begin
      resp_got_reg <= 1'b0;
    end else begin
      if (wb_ack_i || wb_err_i) begin
        resp_got_reg <= 1'b1;
      end
      if (resp_ack) begin
        resp_got_reg <= 1'b0;
      end
    end
  end

  /******** Clock Domain Crossing **********/

  reg resp_got_retimed;
  always @(posedge epb_clk) begin
    resp_got_retimed <= resp_got_unstable;
    resp_got         <= resp_got_retimed;
  end
  //synthesis attribute USET of resp_got_retimed is SET0
  //synthesis attribute USET of resp_got         is SET0
  //synthesis attribute RLOC of resp_got_retimed is R0C0
  //synthesis attribute RLOC of resp_got         is R0C1

  reg resp_ack_retimed;
  always @(posedge wb_clk_i) begin
    resp_ack_retimed <= resp_ack_unstable;
    resp_ack         <= resp_ack_retimed;
  end
  //synthesis attribute USET of resp_ack_retimed is SET1
  //synthesis attribute USET of resp_ack         is SET1
  //synthesis attribute RLOC of resp_ack_retimed is R0C0
  //synthesis attribute RLOC of resp_ack         is R0C1

  reg cmnd_got_retimed;
  always @(posedge wb_clk_i) begin
    cmnd_got_retimed <= cmnd_got_unstable;
    cmnd_got         <= cmnd_got_retimed;
  end
  //synthesis attribute USET of cmnd_got_retimed is SET2
  //synthesis attribute USET of cmnd_got         is SET2
  //synthesis attribute RLOC of cmnd_got_retimed is R0C0
  //synthesis attribute RLOC of cmnd_got         is R0C1

  reg cmnd_ack_retimed;
  always @(posedge epb_clk) begin
    cmnd_ack_retimed <= cmnd_ack_unstable;
    cmnd_ack         <= cmnd_ack_retimed;
  end
  //synthesis attribute USET of cmnd_ack_retimed is SET3
  //synthesis attribute USET of cmnd_ack         is SET3
  //synthesis attribute RLOC of cmnd_ack_retimed is R0C0
  //synthesis attribute RLOC of cmnd_ack         is R0C1

endmodule
