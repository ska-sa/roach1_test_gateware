`timescale 1ns/1ns

module acm_controller(
    wb_clk_i, wb_rst_i,
    wb_cyc_i, wb_stb_i, wb_we_i,
    wb_adr_i, wb_dat_i, wb_dat_o,
    wb_ack_o,
    acm_wdata, acm_rdata,
    acm_addr,
    acm_wen,
    acm_clk, acm_reset
  );
  input  wb_clk_i, wb_rst_i;
  input  wb_cyc_i, wb_stb_i, wb_we_i;
  input  [15:0] wb_adr_i;
  input  [15:0] wb_dat_i;
  output [15:0] wb_dat_o;
  output wb_ack_o;
  output acm_clk, acm_reset;
  output acm_wen;
  output  [7:0] acm_wdata;
  input   [7:0] acm_rdata;
  output  [7:0] acm_addr;

  assign acm_reset = ~wb_rst_i;

  reg [1:0] acm_clk_counter;
  assign acm_clk = acm_clk_counter[1];

  reg wb_ack_o;

  reg [1:0] state; 
  localparam STATE_IDLE      = 2'd0; 
  localparam STATE_WAITCLK   = 2'd1; 
  localparam STATE_WAITTRANS = 2'd2; 

  assign acm_wdata = wb_dat_i[7:0];
  assign acm_addr  = wb_adr_i[7:0];
  reg acm_wen;

  reg [7:0] acm_rdata_reg;

  assign wb_dat_o = {8'b0, acm_rdata_reg[7:0]};

  always @(posedge wb_clk_i) begin
    wb_ack_o <= 1'b0;

    if (wb_rst_i) begin
      state <= STATE_IDLE;
      acm_wen <= 1'b0;
      acm_clk_counter <= 2'b0;
    end else begin
      acm_clk_counter <= acm_clk_counter + 2'b1;
      case (state)
        STATE_IDLE: begin
          if (wb_cyc_i & wb_stb_i & ~wb_ack_o) begin
            state <= STATE_WAITCLK;
          end
        end 
        STATE_WAITCLK: begin
          if (acm_clk_counter == 2'b00) begin
            if (wb_we_i)
              acm_wen <= 1'b1;
            state <= STATE_WAITTRANS;
          end
        end
        STATE_WAITTRANS: begin
          if (acm_clk_counter == 2'b11) begin
            acm_wen <= 1'b0;
            wb_ack_o <= 1'b1;
            acm_rdata_reg <= acm_rdata;
            state <= STATE_IDLE;
          end
        end
      endcase 
    end
  end

endmodule
