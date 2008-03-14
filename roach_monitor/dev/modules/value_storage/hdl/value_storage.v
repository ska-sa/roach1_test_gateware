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

  /************* Common Signals ******************/
  reg rb_pause;
  reg [12:0] rb_checkpoint;
  reg [12:0] rb_tail;
  reg bus_wait;
  reg ram_wait;


  /************ Wishbone Interface ***************/
  wire adc_val_sel = wb_adr_i < 16'd32;
  reg  wb_ack_o;
  reg  [1:0] wb_dat_o_src;

  reg [12:0] rb_ctrl_addr;

  assign wb_dat_o = wb_dat_o_src == 2'd0 ? ram_rdata :
                    wb_dat_o_src == 2'd1 ? (~rb_pause ? 16'h10_00 : rb_ctrl_addr == rb_tail ? 16'hff_ff : ram_rdata) :
                    16'b0;
  reg [4:0] wb_adr_reg;


  wire [4:0] chan_index = 5'd31  - wb_adr_reg[4:0];
  wire [12:0] wb_direct_addr = rb_checkpoint >= chan_index ? rb_checkpoint - chan_index : (RAM_HIGH) - (chan_index - rb_checkpoint);
  assign ram_raddr = bus_wait | ram_wait ? wb_direct_addr : rb_ctrl_addr;

  wire [12:0] rb_ctrl_addr_next = rb_ctrl_addr == 13'b0 ? RAM_HIGH - 1 : rb_ctrl_addr - 1;


  always @(posedge wb_clk_i) begin
    bus_wait <= 1'b0;
    ram_wait <= 1'b0;
    wb_ack_o <= 1'b0;
    if (wb_rst_i) begin
      rb_pause <= 1'b0;
      rb_ctrl_addr <= 13'b0;
    end else if (bus_wait) begin
      wb_ack_o <= 1'b1;
      ram_wait <= 1'b1;
    end else begin
      if (wb_cyc_i & wb_stb_i & ~wb_ack_o) begin
        case (wb_adr_i)
          `REG_RB_CTRL: begin
            wb_dat_o_src <= 2'b1;
            wb_ack_o <= 1'b1;
            if (wb_we_i) begin
              if (wb_dat_i == 16'h0) begin
                rb_ctrl_addr <= rb_checkpoint;
                rb_pause <= 1'b1;
`ifdef DESPERATE_DEBUG
                $display("vs: indirect start");
`endif
              end else begin
                rb_pause <= 1'b0;
`ifdef DESPERATE_DEBUG
                $display("vs: indirect stop");
`endif
              end
            end else begin
              if (rb_ctrl_addr != rb_tail && rb_pause) begin
                rb_ctrl_addr <= rb_ctrl_addr_next;
`ifdef DESPERATE_DEBUG
                $display("vs: indirect read");
`endif
              end else begin
`ifdef DESPERATE_DEBUG
                $display("vs: indirect read, but empty");
`endif
              end
            end
          end
          default: begin
            if (adc_val_sel) begin
              wb_adr_reg <= wb_adr_i[4:0];
              wb_dat_o_src <= 2'b0;
              bus_wait <= 1'b1;
            //  $display("vs: direct read, checkpoint = %x, read addr = %x", rb_checkpoint, wb_direct_addr);
            end else begin
              wb_dat_o_src <= 2'd2;
              wb_ack_o <= 1'b1;
            end
          end
        endcase
      end
    end
  end

  /******************* Ring Buffer Control *******************/

  reg [12:0] rb_head;
  reg rb_full;

  reg [4:0] adc_chan_prev;

  wire [12:0] rb_tail_next = rb_tail == RAM_HIGH - 1 ? 13'b0 :  rb_tail + 1;
  wire [12:0] rb_head_next = rb_head == RAM_HIGH - 1 ? 13'b0 :  rb_head + 1;
  wire [12:0] rb_checkpoint_next = rb_head == 13'b0 ? RAM_HIGH - 1 : rb_head - 1;

  reg prev_rb_pause;

  reg moo_adc_strb;
  reg [4:0] moo_channel;
  reg [4:0] moo_adc_channel;
  reg [7:0] moo_counter;
  always @(posedge wb_clk_i) begin
    moo_adc_strb <= 1'b0;
    if (wb_rst_i) begin
      moo_counter <= 8'b0;
    end else begin
      moo_counter <= moo_counter + 1;
      if (moo_counter == 8'hff) begin
        moo_adc_strb <= 1'b1;
        moo_adc_channel <= moo_channel;
        moo_channel <= moo_channel + 1;
      end
    end
  end

  always @(posedge wb_clk_i) begin
    adc_chan_prev <= moo_adc_channel;
    prev_rb_pause <= rb_pause;
    if (wb_rst_i) begin
      rb_head <= 12'b0;
      rb_tail <= 12'b0;
      rb_checkpoint <= 12'b0;
      rb_full <= 1'b0;
    end else begin
      if (rb_pause) begin
      end else if (prev_rb_pause != rb_pause && ~rb_pause)begin
        rb_head <= 12'b0;
        rb_tail <= 12'b0;
        rb_checkpoint <= 12'b0;
        rb_full <= 1'b0;
      end else if (moo_adc_strb) begin
        rb_head <= rb_head_next;
        if (rb_head_next == rb_tail) begin
          rb_full <= 1'b1;
        end
        if (rb_full) begin
          rb_tail <= rb_tail_next;
        end
        if (moo_adc_channel < adc_chan_prev) begin //looped back
        //if (adc_channel < adc_chan_prev) begin //looped back
`ifdef DESPERATE_DEBUG
//          $display("vs: cp - adc_channel = %d, adc_val = %x, rb_head = %x, rb_checkpoint_next = %x",adc_channel, adc_result, rb_head, rb_checkpoint_next);
`endif
          rb_checkpoint <= rb_checkpoint_next; //store the location of the last complete sample set
        end
      end
    end
  end

  assign ram_wen = ~rb_pause & adc_strb;
  assign ram_wdata = {7'b0, moo_adc_channel};
  //assign ram_wdata = adc_result;
  assign ram_waddr = rb_head;
  
endmodule
