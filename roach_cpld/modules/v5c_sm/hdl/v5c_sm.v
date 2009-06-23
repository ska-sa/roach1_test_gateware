
module v5c_sm(
    wb_clk_i, wb_rst_i,
    wb_cyc_i, wb_stb_i, wb_we_i,
    wb_adr_i, wb_dat_i, wb_dat_o,
    wb_ack_o,
    sm_cs_n,
    v5c_rdwr_n, v5c_cs_n, v5c_prog_n,
    v5c_done, v5c_busy,
    v5c_init_n_i, v5c_init_n_o, v5c_init_n_oe,
    v5c_mode
  );
  input  wb_clk_i, wb_rst_i;
  input  wb_cyc_i, wb_stb_i, wb_we_i;
  input  [1:0] wb_adr_i;
  input  [7:0] wb_dat_i;
  output [7:0] wb_dat_o;
  output wb_ack_o;
  input sm_cs_n;

  output v5c_rdwr_n, v5c_cs_n, v5c_prog_n;
  output [2:0] v5c_mode;
  input  v5c_done, v5c_busy;
  input  v5c_init_n_i;
  output v5c_init_n_o, v5c_init_n_oe;

  localparam REG_SM_STATUS = 2'd0;
  localparam REG_SM_OREGS  = 2'd1;
  localparam REG_SM_CTRL   = 2'd3;

  reg v5c_rdwr_n, v5c_prog_n;
  reg v5c_init_n_o, v5c_init_n_oe;
	//synthesis attribute INIT of v5c_prog_n is 1
	//synthesis attribute INIT of v5c_init_n_oe is 0

  //Slave selectMAP 
  assign v5c_mode = 3'b110;

  //Select Map Strb
  wire sm_strb;

  assign sm_strb = sm_cs_n; //sm_cs_n must be one cycle long

  assign wb_dat_o = wb_adr_i == REG_SM_STATUS ? {5'b0, v5c_busy, v5c_done, v5c_init_n_i} :
                    wb_adr_i == REG_SM_OREGS  ? {5'b0, v5c_rdwr_n, v5c_init_n_o, v5c_prog_n} :
                    wb_adr_i == REG_SM_CTRL   ? {7'b0, v5c_init_n_oe} :
                                                8'b0;

  reg wb_ack_o;
  wire wb_trans = wb_stb_i && wb_cyc_i && !wb_ack_o;
  //strobe the v5c_cs_n if wb access to data reg or is strobe on sm_cs
  assign v5c_cs_n = sm_strb;



  always @(posedge wb_clk_i) begin
    //strobes
    wb_ack_o <= 1'b0;

    if (wb_rst_i) begin
      v5c_rdwr_n <= 1'b0;
      v5c_prog_n <= 1'b1;
      v5c_init_n_oe <= 1'b1;
      v5c_init_n_o <= 1'b1;
    end else begin
      if (wb_trans) begin
        wb_ack_o <= 1'b1;
      end
      if (wb_trans & wb_we_i) begin
        case (wb_adr_i)
          REG_SM_STATUS: begin
          end
          REG_SM_OREGS: begin
            v5c_prog_n   <= wb_dat_i[0];
            v5c_init_n_o <= wb_dat_i[1];
            v5c_rdwr_n   <= wb_dat_i[2];
          end
          REG_SM_CTRL: begin
            v5c_init_n_oe <= wb_dat_i[0];
          end
        endcase
      end
    end
  end
endmodule
