module epb_wb_bridge(
    clk, reset,
    epb_cs_n, epb_oe_n, epb_we_n, epb_be_n,
    epb_addr,
    epb_data_i, epb_data_o, epb_data_oe,
    epb_rdy_o, epb_rdy_oe,
    wb_cyc_o, wb_stb_o, wb_we_o, wb_sel_o,
    wb_adr_o, wb_dat_o, wb_dat_i,
    wb_ack_i
  );
  input  clk, reset;
  input  epb_cs_n, epb_oe_n, epb_we_n, epb_be_n;
  input  [4:0] epb_addr;
  input  [7:0] epb_data_i;
  output [7:0] epb_data_o;
  output epb_data_oe;
  output epb_rdy_o;
  output epb_rdy_oe;
  output wb_cyc_o, wb_stb_o, wb_we_o, wb_sel_o;
  output [4:0] wb_adr_o;
  output [7:0] wb_dat_o;
  input  [7:0] wb_dat_i;
  input  wb_ack_i;

  wire epb_trans_strb;

  assign wb_cyc_o    = epb_trans_strb;
  assign wb_stb_o    = epb_trans_strb;
  assign wb_we_o     = !epb_we_n;
  assign wb_sel_o    = !epb_be_n;
  assign wb_adr_o    = epb_addr;
  assign wb_dat_o    = epb_data_i;
  assign epb_data_oe = !epb_cs_n && !epb_oe_n;

  /* EPB transaction decoding */

  reg [1:0] epb_state;
  localparam IDLE      = 0;
  localparam WB_WAIT   = 1;
  localparam BUS_WAIT0 = 2;
  localparam BUS_WAIT1 = 3;

  reg [7:0] epb_data_reg;
  always @(posedge clk) begin
    if (reset) begin
      epb_state <= IDLE;
    end else begin
      case (epb_state)
        IDLE: begin
          if (!epb_cs_n) begin
            epb_state <= WB_WAIT;
          end
        end
        WB_WAIT: begin
          if (wb_ack_i || epb_cs_n) begin
            epb_state <= BUS_WAIT0;
            epb_data_reg <= wb_dat_i;
          end
        end
        BUS_WAIT0: begin
          epb_state <= BUS_WAIT1;
        end
        BUS_WAIT1: begin
          epb_state <= IDLE;
        end
      endcase
    end
  end

  assign epb_trans_strb = !epb_cs_n && (epb_state == IDLE);
  
  assign epb_rdy_oe = !epb_cs_n;
  assign epb_rdy_o = epb_state[1];

  assign epb_data_o = epb_state == WB_WAIT || epb_state == IDLE ? wb_dat_i : epb_data_reg;

endmodule
