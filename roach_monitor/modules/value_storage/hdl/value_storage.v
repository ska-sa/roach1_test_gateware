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
  /* the check point represents the point at which the last full set
  of input samples were stored */
  reg rb_pause;
  /* when rb_pause is cleared, new adc values simply added to the head
  of the ring buffer. When pause is set, values are only written to the
  region immediately beyond the checkpoint so as not to destroy the history.
  */

  /******************* Wishbone Attachment *********************/

  reg [12:0] rb_progress;
  /* the progress in reading back the whole ring buffer */

  reg wb_dat_o_src;
  reg wb_ack_o;

  reg wb_state;
  localparam WB_STATE_IDLE = 0;
  localparam WB_STATE_WAIT = 1;

  reg [12:0] ram_raddr;

  assign wb_dat_o = wb_dat_o_src == 1 ? (rb_pause ? 16'hffff : 16'h8000) :
                                      ram_rdata;

  always @(posedge wb_clk_i) begin
    wb_ack_o <= 1'b0;

    if (wb_rst_i) begin
      rb_pause    <= 1'b0;
      rb_progress <= 13'd0;
      ram_raddr   <= 13'b0;
      wb_state    <= WB_STATE_IDLE;
    end else begin
      case (wb_state)
        WB_STATE_IDLE: begin
          if (wb_cyc_i & wb_stb_i & ~wb_ack_o) begin
            case (wb_adr_i)
      /************ RING BUFFER register *************/
              `REG_RB_CTRL: begin
                if (wb_we_i) begin
                  wb_ack_o    <= 1'b1;
                  if (wb_dat_i == 16'h0) begin
                    rb_progress <= 0;
                    rb_pause    <= 1'b1;
`ifdef DESPERATE_DEBUG
                    $display("vs: indirect start");
`endif
                  end else begin
                    rb_pause <= 1'b0;
`ifdef DESPERATE_DEBUG
                    $display("vs: indirect stop");
`endif
                  end
                end else begin /* read transaction*/
                  if (rb_pause && (rb_progress < RAM_HIGH - 33 )) begin
                    if (rb_checkpoint >= rb_progress) begin
                      ram_raddr <= rb_checkpoint - rb_progress;
                    end else begin
                      ram_raddr <= RAM_HIGH - (rb_progress - rb_checkpoint);
                    end
                    rb_progress  <= rb_progress + 1;
                    wb_state     <= WB_STATE_WAIT;
 `ifdef DESPERATE_DEBUG
                   $display("vs: indirect read");
 `endif
                  end else begin
                    wb_ack_o     <= 1'b1;
                    wb_dat_o_src <= 1'b1;
 `ifdef DESPERATE_DEBUG
                    $display("vs: indirect read, but empty");
 `endif
                  end
                end
              end
    /**** Direct Value Access ******/
              default: begin
                if (!rb_pause) begin
                  if (rb_checkpoint >= (31 - wb_adr_i[4:0])) begin
                    ram_raddr <= rb_checkpoint - (31 - wb_adr_i[4:0]);
                  end else begin
                    ram_raddr <= RAM_HIGH - ((31 - wb_adr_i[4:0]) - rb_checkpoint);
                  end
                end else begin
                  if (rb_checkpoint + 1 + wb_adr_i < RAM_HIGH) begin
                    ram_raddr <= rb_checkpoint + 1 + wb_adr_i;
                  end else begin
                    ram_raddr <= wb_adr_i[4:0] - (RAM_HIGH - 1 - rb_checkpoint);
                  end
                end
                wb_state <= WB_STATE_WAIT;
`ifdef DESPERATE_DEBUG
                $display("vs: direct read - chan = %d", wb_adr_i[4:0]);
`endif
              end
            endcase
          end
        end
        WB_STATE_WAIT: begin
        /* just wait a bit */
          wb_ack_o     <= 1'b1;
          wb_dat_o_src <= 1'b0;
          wb_state     <= WB_STATE_IDLE;
        end
      endcase
    end
  end

  /******************* Ring Buffer Control *******************/

  reg [11:0] rb_head;

  reg [4:0] adc_chan_prev;

  reg rbw_wen;
  reg [11:0] rbw_data;
  reg [12:0] rbw_addr;

  always @(posedge wb_clk_i) begin
    rbw_wen <= 1'b0;
    rbw_data <= adc_result;

    if (wb_rst_i) begin
      rb_head <= 12'b0;
      rb_checkpoint <= 12'b0;
      adc_chan_prev <= adc_channel;
    end else begin
      if (adc_strb) begin
        /* always write */
        rbw_wen <= 1'b1;
        /* default write location is the head of the buffer*/
        rbw_addr <= rb_head;

        /* register the channel index */
        adc_chan_prev <= adc_channel;
        /* advance the ring buffer head, ensuring that it doesn't run over the range */
        if (rb_head == RAM_HIGH - 1) begin
          rb_head <= 13'd0;
        end else begin
          rb_head <= rb_head + 1;
        end

        if (adc_channel < adc_chan_prev) begin
        /* if adc_channel is reset (less than the previous), thats means the adc controller has
           gone onto the next batch of samples so we then set a new checkpoint */

          if (!rb_pause) begin
            /* if the ring buffer is not paused we set a new checkpoint */
            if (rb_head == 13'b0) begin
              rb_checkpoint <= RAM_HIGH - 1;
            end else begin
              rb_checkpoint <= rb_head - 1;
            end
          end else begin
            /* if the ring buffer is paused we keep the old checkpoint and revert the head */
            /* BUT - we now need to ensure the write address is to the new head location 
               This is because we want to jump back*/
            if (rb_checkpoint == RAM_HIGH - 1) begin
              rb_head  <= 0;
              rbw_addr <= 0;
            end else begin
              rb_head  <= rb_checkpoint + 1;
              rbw_addr <= rb_checkpoint + 1;
            end
          end
        end
      end
    end
  end

  assign ram_wen   = rbw_wen;
  assign ram_wdata = rbw_data;
  assign ram_waddr = rbw_addr;
endmodule
