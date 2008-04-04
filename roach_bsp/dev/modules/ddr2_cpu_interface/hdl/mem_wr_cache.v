module mem_wr_cache(
    clk, reset,
    wr_sel_i,
    wr_strb_i, wr_addr_i, wr_data_i,
    wr_ack_i,
    wr_eob, //end-of-burst strobe
    ddr_data_o, ddr_mask_o, ddr_data_wen_o,
    ddr_addr_o, ddr_addr_wen_o,
    ddr_af_full, ddr_df_full
  );
  input  clk, reset;
  input   [1:0] wr_sel_i;
  input  wr_strb_i;
  input   [32:0] wr_addr_i;
  input   [15:0] wr_data_i;
  output wr_ack_i;

  output [127:0] ddr_data_o;
  output  [15:0] ddr_mask_o;
  output ddr_data_wen_o;
  output  [30:0] ddr_addr_o;
  output ddr_addr_wen_o;
  input  ddr_af_full, ddr_df_full; /* TODO: should use these */

  /* TODO: implement proper caching before writes
   *       ie maintain one bursts worth of data in a register
   *          and commit when full/eob/non-contiguous write*/

  reg [255:0] data_buffer;
  reg  [31:0] mask_buffer;

  /************** Commit Decision ****************/

  /********** User collect interface *************/
  reg collect_state;
  localparam COLLECT_IDLE = 1'b0;
  localparam COLLECT_WAIT = 1'b1;

  wire send_strb = wr_strb_i;
  reg  send_done;

  always @(posedge clk) begin
    if (reset) begin
      collect_state <= COLLECT_IDLE;
    end else begin
      case (collect_state)
        COLLECT_IDLE: begin
          if (send_done) begin
            mask_buffer <= {32{1'b0}};  //clear - this is a special case for mask buffer
          end

          if (wr_strb_i) begin
            mask_buffer <=  (wr_sel_i << wr_addr_i[3:0]);
            data_buffer <= (wr_data_i << wr_addr_i[3:0]); /*TODO: implement sel here*/
          end

          if (send_strb) begin
            collect_state <= COLLECT_WAIT;
          end
        end
        COLLECT_WAIT: begin //wait a cycle before next possible commit
            collect_state <= COLLECT_IDLE;
        end
      endcase
    end
  end

  /******** DDR2 send interface ***********/

  reg send_state;
  localparam SEND_IDLE   = 1'b0;
  localparam SEND_SECOND = 1'b1;

  reg ddr_data_wen_o;
  reg ddr_addr_wen_o;
  reg ddr_src;

  assign ddr_data_o = ddr_src == 1'b0 ? data_buffer[127:0] : data_buffer[255:128];
  assign ddr_mask_o = ddr_src == 1'b0 ? mask_buffer[15:0]  : mask_buffer[31:16];
  assign ddr_addr_o = {wr_addr_i[32:4], 2'b00}; //column addressing
  assign ddr_addr_wen_o = ddr_data_wen_o 

  always @(posedge clk) begin
    ddr_data_wen_o <= 1'b0;
    ddr_addr_wen_o <= 1'b0;
    if (reset) begin
      send_state <= SEND_IDLE;
      send_done <= 1'b1;
    end else begin
      case (send_state)
        SEND_IDLE: begin
          if (send_strb) begin
            send_done <= 1'b0;
            ddr_src         <= 1'b0;
            ddr_data_wen_o  <= 1'b1;
            send_state      <= SEND_SECOND;
          end
        end
        SEND_SECOND: begin
          ddr_src        <= 1'b1;
          ddr_data_wen_o <= 1'b1;
          ddr_addr_wen_o <= 1'b1;
          send_done      <= 1'b1;
          send_state     <= SEND_IDLE;
        end
      endcase
    end
  end
  

endmodule

