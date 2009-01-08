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
  parameter RAM_HIGH = 1024 * 7;
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

  /********************* Common Signals ***********************/
  reg [12:0] rb_checkpoint;
  reg [12:0] rb_head;
  reg rb_pause;

  /******************* Wishbone Attachment *********************/


  reg [12:0] rb_ctrl_addr;

  reg bus_wait, ram_wait, direct_wait;

  wire adc_sel = wb_adr_i < 32;
  reg  [4:0] chan_addr;
  wire [12:0] wb_ram_addr = rb_checkpoint >=  chan_addr ? rb_checkpoint  - chan_addr : RAM_HIGH - (chan_addr - rb_checkpoint[4:0]);

  assign ram_raddr = bus_wait || ram_wait ? wb_ram_addr : rb_ctrl_addr;

  reg wb_ack_o;
  reg [1:0] wb_dat_o_src;
  assign wb_dat_o = wb_dat_o_src == 2'd0 ? ram_rdata :
                    wb_dat_o_src == 2'd1 ? (~rb_pause ? 16'h8000 : rb_ctrl_addr == rb_head ? 16'hffff : ram_rdata) :
                    16'd0;

//  always @(*) begin
//    $display("ram_raddr = %x, ram_wen = %b, ram_waddr = %x, ram_wdata = %x", ram_raddr, ram_wen, ram_waddr, ram_wdata);
//  end


   

  always @(posedge wb_clk_i) begin
    wb_ack_o <= 1'b0;
    if (wb_rst_i) begin
      rb_pause <= 1'b0;
      bus_wait <= 1'b0;
      ram_wait <= 1'b0;
      direct_wait <= 1'b0;
      chan_addr <= 5'b0;
      wb_dat_o_src <= 2'b0;
      rb_ctrl_addr <= 13'd0;
    end else if (bus_wait | ram_wait | direct_wait) begin
      if (ram_wait) begin
        ram_wait <= 1'b0;
        bus_wait <= 1'b0;
      end
      if (bus_wait) begin
        ram_wait <= 1'b1;
        bus_wait <= 1'b0;
        wb_ack_o <= 1'b1;
      end 
      if (direct_wait) begin
        direct_wait <= 1'b0;
        rb_ctrl_addr <= rb_ctrl_addr == 13'd0 ? RAM_HIGH - 1 : rb_ctrl_addr - 1;
      end 
    end else begin
      if (wb_cyc_i & wb_stb_i & ~wb_ack_o) begin
        case (wb_adr_i)
          `REG_RB_CTRL: begin
            wb_dat_o_src <= 2'b1;
            if (wb_we_i) begin
              if (wb_dat_i == 16'h0) begin
                rb_ctrl_addr <= rb_checkpoint;
                rb_pause <= 1'b1;
                wb_ack_o <= 1'b1;
`ifdef DESPERATE_DEBUG
                $display("vs: indirect start");
`endif
              end else begin
                rb_pause <= 1'b0;
                wb_ack_o <= 1'b1;
`ifdef DESPERATE_DEBUG
                $display("vs: indirect stop");
`endif
              end
            end else begin
              if (rb_ctrl_addr != rb_head && rb_pause) begin
                direct_wait <= 1'b1;
                wb_ack_o <= 1'b1;
`ifdef DESPERATE_DEBUG
                $display("vs: indirect read");
`endif
              end else begin
                wb_ack_o <= 1'b1;
`ifdef DESPERATE_DEBUG
                $display("vs: indirect read, but empty");
`endif
              end
            end
          end
          default: begin
            if (adc_sel) begin
`ifdef DESPERATE_DEBUG
              $display("vs: direct read - chan = %d", wb_adr_i[4:0]);
`endif
              chan_addr <= 31 - wb_adr_i[4:0];
              wb_dat_o_src <= 2'b0;
              bus_wait <= 1'b1;
            //  $display("vs: direct read, checkpoint = %x, read addr = %x", rb_checkpoint, wb_direct_addr);
            end else begin
              wb_ack_o <= 1'b1;
              wb_dat_o_src <= 2'd2;
            end
          end
        endcase
      end
    end
  end

  /******************* Ring Buffer Control *******************/

  reg [4:0] adc_chan_prev;

  always @(posedge wb_clk_i) begin
    if (wb_rst_i) begin
      rb_head <= 12'b0;
      rb_checkpoint <= 12'b0;
      adc_chan_prev <= adc_channel;
    end else if (~rb_pause) begin
      if (adc_strb) begin
        adc_chan_prev <= adc_channel;
        if (rb_head == RAM_HIGH - 1) begin
          rb_head <= 13'd0;
        end else begin
          rb_head <= rb_head + 1;
        end
        if (adc_channel < adc_chan_prev) begin //looped back
          if (rb_head == 13'b0) begin
            rb_checkpoint <= RAM_HIGH - 1;
          end else begin
            rb_checkpoint <= rb_head - 1;
          end
        end
      end
    end
  end

  assign ram_wen = ~rb_pause & adc_strb;
  assign ram_wdata = adc_result;
  assign ram_waddr = rb_head;
endmodule
