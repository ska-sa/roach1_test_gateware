module mem_wr_cache(
    clk, reset,
    wr_sel_i,
    wr_strb_i, wr_addr_i, wr_data_i,
    wr_ack_o,
    wr_eob, //end-of-burst strobe
    ddr_data_o, ddr_mask_o, ddr_data_wen_o,
    ddr_addr_o, ddr_addr_wen_o,
    ddr_af_afull_i, ddr_df_afull_i
  );
  input  clk, reset;
  input   [1:0] wr_sel_i;
  input  wr_strb_i;
  input   [33:0] wr_addr_i;
  input   [15:0] wr_data_i;
  output wr_ack_o;
  input  wr_eob;

  output [127:0] ddr_data_o;
  output  [15:0] ddr_mask_o;
  output ddr_data_wen_o;
  output  [30:0] ddr_addr_o;
  output ddr_addr_wen_o;
  input  ddr_af_afull_i, ddr_df_afull_i;

  wire send_busy, send_wait;

  wire [29:0] wr_word_addr = wr_addr_i[33:4];

  wire buffer_hit = buffer_empty || buffer_addr == wr_word_addr;

  reg  buffer_empty;
  reg  [29:0] buffer_addr;
  reg [127:0] data_buffer;
  reg  [15:0] mask_buffer;

  wire [127:0] data_overlay = (wr_data_i << 16*wr_addr_i[3:1]);
  wire  [15:0] mask_overlay =  (wr_sel_i <<  2*wr_addr_i[3:1]);

  genvar i;
  wire [127:0] data_next;
  generate for (gen_i = 0; gen_i < 16; gen_i = gen_i + 1) begin : G0
    assign data_next[8*(gen_i+1) - 1:8*(gen_i)] = mask_overlay[gen_i] ? data_overlay[8*(gen_i+1) - 1:8*(gen_i)] : data_buffer[8*(gen_i+1) - 1:8*(gen_i)];
  end endgenerate

  /********** User collect interface *************/
  reg  delayed_send;
  reg  commit_send;

  assign wr_ack_o = commit_send ? 1'b0 : delayed_send ? ~send_wait  & ~send_busy : wr_strb_i & (buffer_hit  || !(send_busy | send_wait));

  always @(posedge clk) begin
    if (reset) begin
      buffer_empty  <= 1'b1;
      mask_buffer  <= 16'b0;
      delayed_send <= 1'b0;
      commit_send <= 1'b0;
    end else if (commit_send) begin
      if (~send_wait & ~send_busy) begin
        commit_send <= 1'b0;
        mask_buffer  <= 16'b0;
        buffer_empty <= 1'b1;
        $display("commit complete 1 - %d  %b", send_wait, send_busy);
      end
      if (wr_strb_i) begin
        delayed_send <= 1'b1;
        $display("got wr when committing");
      end
    end else if (delayed_send) begin
      if (~send_wait & ~send_busy) begin
        delayed_send <= 1'b0;
        buffer_empty <= 1'b0;
        buffer_addr <= wr_word_addr;
        data_buffer <= data_overlay;
        mask_buffer <= mask_overlay;
        $display("dirty miss buffering -  dat = %x, adr = %x, offset = %x", wr_data_i, wr_word_addr, wr_addr_i[3:1]);
      end
    end else begin
      if (wr_strb_i) begin
        buffer_empty  <= 1'b0;
        if (buffer_hit) begin
          data_buffer <= data_next;
          mask_buffer <= mask_buffer | mask_overlay;
          buffer_addr <= wr_word_addr;
          $display("buffering - true adr = %x, adr = %x, offset = %x", wr_addr_i, wr_word_addr, wr_addr_i[3:1]);
        end else begin
          if (send_busy | send_wait) begin
            delayed_send <= 1'b1;
          end else begin
            buffer_addr <= wr_word_addr;
            data_buffer <= data_overlay;
            mask_buffer   <= mask_overlay;
          $display("clean miss buffering - true adr = %x, adr = %x, offset = %x", wr_addr_i, wr_word_addr, wr_addr_i[3:1]);
          end
        end
      end else if (wr_eob & !buffer_empty) begin
        if (send_busy | send_wait) begin
          commit_send <= 1'b1;
          $display("commit pending");
        end else begin
          buffer_empty <= 1'b1;
          mask_buffer  <= 16'b0;
          $display("commit complete 0");
        end
      end
    end
  end

  /******** DDR2 send interface ***********/
  reg send_state;
  localparam SEND_IDLE   = 1'b0;
  localparam SEND_SECOND = 1'b1;

  reg waiting;

  reg [29:0] addr_buff;

  assign ddr_addr_wen_o = ~send_wait & (send_state == SEND_SECOND);
  assign ddr_data_wen_o = ~send_wait & (send_state == SEND_SECOND) |
                          ~send_wait & ~send_busy & (commit_send | delayed_send | (wr_strb_i & !buffer_hit) | (wr_eob & !buffer_empty));

  assign ddr_data_o = data_buffer;
  assign ddr_mask_o = send_state == SEND_IDLE ? mask_buffer : 16'b0;
  assign ddr_addr_o = {addr_buff, 1'b0};

  assign send_busy = send_state == SEND_SECOND;

  assign send_wait = send_state == SEND_SECOND & (ddr_af_afull_i | ddr_df_afull_i) || send_state == SEND_IDLE & ddr_df_afull_i;

  always @(posedge clk) begin
    if (reset) begin
      send_state <= SEND_IDLE;
    end else begin
      case (send_state)
        SEND_IDLE: begin
          if (ddr_data_wen_o) begin
            send_state <= SEND_SECOND;
            addr_buff <= buffer_addr;
          end
        end
        SEND_SECOND: begin
          if (ddr_addr_wen_o) begin
            send_state <= SEND_IDLE;
          end
        end
      endcase
    end
  end
  
  always @(posedge clk) begin
    if (ddr_data_wen_o & ~ddr_addr_wen_o) begin
      $display("%b - %b - d: %x, m: %b, a: %x", ddr_data_wen_o, ddr_addr_wen_o, ddr_data_o, ddr_mask_o, buffer_addr);
      $display("commit - %b %b %b %b %b", ~send_wait & ~send_busy, commit_send, delayed_send, (wr_strb_i & !buffer_hit),(wr_eob & !buffer_empty));
    end
  end

endmodule

