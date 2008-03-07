`define REG_SM_STATUS 2'd0
`define REG_SM_OREGS  2'd1
`define REG_SM_DATA   2'd2
`define REG_SM_CTRL   2'd3

module v5c_sm(
    lb_clk, lb_rst,
    lb_stb_i, lb_we_i,
    lb_adr_i, lb_dat_i, lb_dat_o,
    v5c_rdwr_n, v5c_cs_n, v5c_prog_n,
    v5c_done, v5c_busy,
    v5c_init_n_i, v5c_init_n_o, v5c_init_n_oen,
    v5c_mode,
    sm_busy // the serial interface owns the bus
  );
  input  lb_clk, lb_rst;
  input  lb_stb_i, lb_we_i;
  input  [1:0] lb_adr_i;
  input  [7:0] lb_dat_i;
  output [7:0] lb_dat_o;
  output v5c_rdwr_n, v5c_cs_n, v5c_prog_n;
  output [2:0] v5c_mode;
  input  v5c_done, v5c_busy;
  input  v5c_init_n_i;
  output v5c_init_n_o, v5c_init_n_oen;
  input  sm_busy;

  reg v5c_rdwr_n, v5c_cs_n, v5c_prog_n;
  reg v5c_init_n_o, v5c_init_n_oen;

  assign v5c_mode = 3'b110;

  assign lb_dat_o = lb_adr_i == `REG_SM_STATUS ? {4'b0, sm_busy, v5c_busy, v5c_done, v5c_init_n_i} :
                    lb_adr_i == `REG_SM_OREGS  ? {5'b0, v5c_rdwr_n, v5c_init_n_o, v5c_prog_n} :
                    lb_adr_i == `REG_SM_DATA   ? 8'b0 :
                    lb_adr_i == `REG_SM_CTRL   ? {7'b0, v5c_init_n_oen} :
                                               8'b0;


  always @(posedge lb_clk) begin
    v5c_cs_n <= 1'b0;
    if (lb_rst) begin
      v5c_rdwr_n <= 1'b0;
      v5c_cs_n <= 1'b1;
      v5c_prog_n <= 1'b1;
      v5c_init_n_oen <= 1'b0;
      v5c_init_n_o <= 1'b1;
    end else begin
      if (lb_stb_i & lb_we_i) begin
        case (lb_adr_i)
          `REG_SM_STATUS: begin
          end
          `REG_SM_OREGS: begin
            v5c_prog_n   <= lb_dat_i[0];
            v5c_init_n_o <= lb_dat_i[1];
            v5c_rdwr_n   <= lb_dat_i[2];
          end
          `REG_SM_DATA: begin
            v5c_cs_n <= 1'b1;
          end
          `REG_SM_CTRL: begin
            v5c_init_n_oen <= lb_dat_i[0];
          end
        endcase
      end
    end
  end
endmodule
