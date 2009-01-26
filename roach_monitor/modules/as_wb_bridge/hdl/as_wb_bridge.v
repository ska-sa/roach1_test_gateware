module as_wb_bridge(
    clk, reset, 
    as_data_i, as_dstrb_i, as_busy_o,
    as_data_o, as_dstrb_o, as_busy_i,

    wb_we_o, wb_cyc_o, wb_stb_o,
    wb_adr_o, wb_dat_o, wb_dat_i,
    wb_ack_i, wb_err_i
  ); 
  parameter USE_INPUT_FIFO  = 0;
  parameter USE_OUTPUT_FIFO = 0;

  input  clk, reset;
  
  input  [7:0] as_data_i;
  output [7:0] as_data_o;
  input  as_dstrb_i, as_busy_i;
  output as_dstrb_o, as_busy_o;
  
  output wb_we_o, wb_cyc_o, wb_stb_o;
  output [15:0] wb_adr_o;
  output [15:0] wb_dat_o;
  input  [15:0] wb_dat_i;
  input  wb_ack_i, wb_err_i;

  localparam COMMAND_NOP       = 8'd0;
  localparam COMMAND_READ      = 8'd1;
  localparam COMMAND_WRITE     = 8'd2;
  localparam COMMAND_PING      = 8'd8;

  localparam RESPONSE_ACK      = 8'd1;
  localparam RESPONSE_PING     = 8'd8;
  localparam RESPONSE_CMDERROR = 8'd253;
  localparam RESPONSE_BUSERROR = 8'd254;
  localparam RESPONSE_OVERFLOW = 8'd255;

  /* Global Data-In Signals */
  wire [7:0] datai;
  wire datai_valid;
  wire datai_rd;
  wire datai_overflow;

  /* Global Data-Out Signals */

  wire [7:0] datao;
  wire datao_valid;
  wire datao_ready;

  /* Wishbone Transmit Strobe */
  reg wb_transmit_strb;

  /* State Machine */

  reg [1:0] state;

  localparam STATE_COMMAND  = 3'd0;
  localparam STATE_COLLECT  = 3'd1;
  localparam STATE_WAIT     = 3'd2;
  localparam STATE_RESPONSE = 3'd3;

  reg  [7:0] cmd_type;
  reg [15:0] cmd_addr; 
  reg [15:0] cmd_data; 

  reg  [2:0] collect_progress;

  reg  [7:0] resp_type;
  reg [15:0] resp_data;

  reg datai_overflow_reg;

  wire response_ack;
  /* ack from response transmission logic */

  always @(posedge clk) begin
    /* Single-cycle strobes */
    wb_transmit_strb <= 1'b0;

    if (reset) begin
      state              <= STATE_COMMAND;
      collect_progress   <= 3'b0;
      datai_overflow_reg <= 1'b0;
    end else begin
      datai_overflow_reg <= datai_overflow_reg | datai_overflow;
      /* set overflow_reg if you get an overflow strb, but don't clear it if you don't */

      case (state)
        /* Command Type Processing */
        STATE_COMMAND: begin
          collect_progress  <= 3'b0;
          cmd_type          <= datai;

          if (datai_overflow_reg) begin
            datai_overflow_reg <= 1'b0;
            resp_type <= RESPONSE_OVERFLOW;
            state     <= STATE_RESPONSE;
          end else if (datai_valid) begin
            case (datai)
              COMMAND_NOP:   begin
              end
              COMMAND_READ:  begin
                state <= STATE_COLLECT;
              end
              COMMAND_WRITE: begin
                state <= STATE_COLLECT;
              end
              COMMAND_PING: begin
                resp_type <= RESPONSE_PING;
                state     <= STATE_RESPONSE;
              end
              default: begin
                resp_type <= RESPONSE_CMDERROR;
                state     <= STATE_RESPONSE;
              end
            endcase
          end
        end
        /* Command Collection */
        STATE_COLLECT: begin
          if (datai_valid) begin
            collect_progress <= collect_progress + 1;
            case (collect_progress)
              0: begin
                cmd_addr[ 7:0] <= datai;
              end
              1: begin
                cmd_addr[15:8] <= datai;
                if (cmd_type == COMMAND_READ) begin
                  wb_transmit_strb <= 1'b1;
                  state            <= STATE_WAIT;
                end
              end
              2: begin
                cmd_data[ 7:0] <= datai;
              end
              3: begin
                cmd_data[15:8]   <= datai;
                wb_transmit_strb <= 1'b1;
                state            <= STATE_WAIT;
              end
            endcase
          end
        end
        /* Wait for wishbone response */
        STATE_WAIT: begin
          if (wb_ack_i) begin
            resp_data <= wb_dat_i;
            resp_type <= RESPONSE_ACK;
            state     <= STATE_RESPONSE;
          end
          if (wb_err_i) begin
            resp_type <= RESPONSE_BUSERROR;
            state     <= STATE_RESPONSE;
          end
        end
        STATE_RESPONSE: begin
          if (response_ack) begin
            state     <= STATE_COMMAND;
          end
        end
      endcase
    end
  end 

  /* Response transmission logic */

  reg response_state;
  reg  [2:0] response_progress;

  reg  [7:0] cmd_type_buf;
  reg  [7:0] resp_type_buf;
  reg [15:0] resp_data_buf;

  assign response_ack = response_state == 1'b0;

  always @(posedge clk) begin
    if (reset) begin
      response_state <= 1'b0;
      response_progress <= 3'd0;
    end else begin
      case (response_state)
        0: begin
          response_progress <= 3'd0;
          if (state == STATE_RESPONSE) begin
            cmd_type_buf  <= cmd_type;
            resp_data_buf <= resp_data;
            resp_type_buf <= resp_type;
            response_state <= 1;
          end
        end
        1: begin
          if (datao_ready) begin
            response_progress <= response_progress + 1;
            case (response_progress)
              0: begin
                if (cmd_type_buf != COMMAND_READ) begin
                  response_state <= 0;
                end
              end
              1: begin
              end
              2: begin
                response_state <= 0;
              end
            endcase
          end
        end
      endcase
    end
  end

  assign datao_valid = response_state == 1'b1;
  assign datao       = response_progress == 0 ? resp_type_buf     :
                       response_progress == 1 ? resp_data_buf[7:0] :
                                                resp_data_buf[15:8];

  /* Wishbone Assignments */

  assign wb_cyc_o = wb_transmit_strb;
  assign wb_stb_o = wb_transmit_strb;
  assign wb_we_o  = cmd_type == COMMAND_WRITE;
  assign wb_adr_o = cmd_addr;
  assign wb_dat_o = cmd_data;

  /* AS interface <-> FIFOs Assignments */

  wire as_rx_busy = !(datai_valid && (state == STATE_COMMAND || state == STATE_COLLECT));

generate if (USE_INPUT_FIFO) begin : input_fifo_enabled

  /* FWFT */

  wire in_fifo_empty;
  wire in_fifo_afull;

  fifo_512_8 data_fifo_in (
    .reset   (reset),

    .rd_clk    (clk),
    .rd_data   (datai),
    .rd_en     (datai_valid && !as_rx_busy),

    .wr_clk    (clk),
    .wr_data   (as_data_i),
    .wr_en     (as_dstrb_i),

    .empty     (in_fifo_empty),
    .full      (),
    .aempty    (),
    .afull     (in_fifo_afull)
  );

  assign datai_valid = !in_fifo_empty;
  assign as_busy_o   = in_fifo_afull;

end else begin : input_fifo_disabled
  /* datai */
  assign datai          = as_data_i;
  assign datai_valid    = as_dstrb_i;
  assign datai_overflow = 1'b0;
  assign as_busy_o      = as_rx_busy;
end endgenerate

  /* datao */

generate if (USE_OUTPUT_FIFO) begin : output_fifo_enabled

  wire out_fifo_empty;
  wire out_fifo_afull;

  fifo_512_8 data_fifo_in (
    .reset   (reset),

    .rd_clk    (clk),
    .rd_data   (as_data_o),
    .rd_en     (as_dstrb_o && !as_busy_i),

    .wr_clk    (clk),
    .wr_data   (datao),
    .wr_en     (datao_valid && datao_ready),

    .empty     (out_fifo_empty),
    .full      (),
    .aempty    (),
    .afull     (out_fifo_afull)
  );
  assign as_dstrb_o  = !out_fifo_empty;
  assign datao_ready = !out_fifo_afull;
  
end else begin : output_fifo_disabled
  assign as_data_o   = datao;
  assign as_dstrb_o  = datao_valid;
  assign datao_ready = !as_busy_i;
end endgenerate

endmodule
