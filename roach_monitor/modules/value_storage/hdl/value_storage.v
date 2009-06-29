`timescale 1ns/10ps
`include "value_storage.vh"
module value_storage(
    wb_clk_i, wb_rst_i,
    wb_stb_i, wb_cyc_i, wb_we_i,
    wb_adr_i, wb_dat_i, wb_dat_o,
    wb_ack_o,
    adc_result, adc_channel, adc_strb,
    ram_wen,
    ram_raddr, ram_waddr,
    ram_rdata, ram_wdata
  );
  input  wb_clk_i, wb_rst_i;
  input  wb_stb_i, wb_cyc_i, wb_we_i;
  input  [15:0] wb_adr_i;
  input  [15:0] wb_dat_i;
  output [15:0] wb_dat_o;
  output wb_ack_o;
 
  input  adc_strb;
  input   [4:0] adc_channel;
  input  [11:0] adc_result;

  output ram_wen;
  output [12:0] ram_raddr;
  output [12:0] ram_waddr;
  input  [11:0] ram_rdata;
  output [11:0] ram_wdata;

  wire [11:0] rb_head;
  wire [11:0] rb_check_point;
  wire [11:0] rb_read_index;
  wire        rb_pause;

  reg wb_ack_o;
  reg rb_read_index_inc;
  reg rb_pause_reg;
  reg [11:0] rb_read_index_reg;

  always @(posedge wb_clk_i) begin
    wb_ack_o          <= 1'b0;
    rb_read_index_inc <= 1'b0;
    if (wb_rst_i) begin
      rb_pause_reg <= 1'b0;
      rb_read_index_reg <= 12'b0;
    end else begin
      if (wb_stb_i && wb_cyc_i && !wb_ack_o) begin
        wb_ack_o <= 1'b1;
        if (wb_adr_i[5]) begin
          if (wb_we_i) begin
            if (wb_dat_i[0]) begin
              rb_pause_reg <= 1'b0;
            end else begin
              rb_pause_reg  <= 1'b1;
              rb_read_index_reg <= rb_head + 2;
            end
          end else begin
            if (rb_read_index != rb_head) begin
              rb_read_index_inc <= 1'b1;
            end
          end
        end
      end
    end
    
    if (rb_read_index_inc) begin
      rb_read_index_reg <= rb_read_index_reg + 1;
    end
  end
  assign rb_read_index = rb_read_index_reg;
  assign rb_pause = rb_pause_reg;
  
  reg [15:0] wb_dat_o_reg;
  reg [11:0] ram_raddr_reg;

  always @(*) begin
    if (wb_adr_i[5]) begin
      /* ring buffer */
      if (!rb_pause) begin
        wb_dat_o_reg <= 16'h8000;
      end else begin
        ram_raddr_reg <= rb_read_index;
        if (rb_read_index == rb_head) begin
          wb_dat_o_reg <= 16'hffff;
        end else if (rb_read_index == rb_check_point) begin
          wb_dat_o_reg  <= {3'b0, 1'b1, ram_rdata};
        end else begin
          wb_dat_o_reg  <= {4'b0, ram_rdata};
        end
      end
    end else begin
      /* sample access */
      wb_dat_o_reg  <= ram_rdata;
      ram_raddr_reg <= rb_check_point + wb_adr_i[4:0];
    end
  end
  
  assign ram_raddr = ram_raddr_reg;
  assign wb_dat_o  = wb_dat_o_reg;

  /******** Ring Buffer ********/

  reg [11:0] rb_progress;
  reg [11:0] rb_checkp;
  reg [11:0] rb_checkp_new;
  reg  [4:0] prev_channel;

  always @(posedge wb_clk_i) begin
    if (wb_rst_i) begin
      rb_progress   <= 12'b0;
      rb_checkp     <= 12'b0;
      rb_checkp_new <= 12'b0;
      prev_channel  <= 5'b0;
    end else begin
      if (!rb_pause) begin
        if (adc_strb) begin
          rb_progress  <= rb_progress + 1;
          prev_channel <= adc_channel;
          if (prev_channel > adc_channel) begin
            rb_checkp_new <= rb_progress; /* store the next checkpoint */
            rb_checkp     <= rb_checkp_new;
          end
        end
      end
    end
  end
  assign rb_check_point = rb_checkp;
  assign rb_head        = rb_progress;

  assign ram_waddr = rb_progress;
  assign ram_wdata = adc_result;
  assign ram_wen   = adc_strb && !rb_pause;

endmodule
