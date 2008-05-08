/******* XGMII Defines *********/
`define XGMII_IDLE      8'h07
`define XGMII_START     8'hFB
`define XGMII_TERM      8'hFD
`define XGMII_ERROR     8'hFE

/******* XAUI Receive States *********/

`define RX_STATE_IDLE 1'b0
`define RX_STATE_RX   1'b1

/******* XAUI Transmit States *********/
`define TX_STATE_IDLE  2'd0
`define TX_STATE_START 2'd1
`define TX_STATE_DATA  2'd2
`define TX_STATE_TERM  2'd3

module transfer_engine(
  clk, reset,

  xgmii_rxd, xgmii_rxc,
  xgmii_txd, xgmii_txc,

  rx_fifo_wr_en, rx_fifo_wr_data,
  tx_fifo_rd_en, tx_fifo_rd_data,
  tx_fifo_rd_status, tx_fifo_wr_status,

  user_tx_en,

  rx_strb, tx_strb, link_down_strb
`ifdef XAUI_ERROR_TEST
  , error_count, data_count
`endif

  );
  input  clk, reset;
  input  [63:0] xgmii_rxd;
  input   [7:0] xgmii_rxc;

  output [63:0] xgmii_txd;
  output  [7:0] xgmii_txc;

  output [63:0] rx_fifo_wr_data;
  output rx_fifo_wr_en;
  input  [63:0] tx_fifo_rd_data;
  output tx_fifo_rd_en;
  input   [1:0] tx_fifo_rd_status;
  input   [1:0] tx_fifo_wr_status;

  input user_tx_en;
  output rx_strb, tx_strb, link_down_strb;
`ifdef XAUI_ERROR_TEST
  output [63:0] error_count;
  output [63:0] data_count;
`endif

  reg [63:0] xgmii_txd;
  reg  [7:0] xgmii_txc;
 
  reg [63:0] rx_fifo_wr_data;
  reg rx_fifo_wr_en,tx_fifo_rd_en;

  reg rx_strb, tx_strb, link_down_strb;

  reg rx_state;
  reg rx_aligned;

  reg first; //the first is always invalid -> TODO: check documentation
  reg [31:0] leftovers;

`ifdef XAUI_ERROR_TEST
  reg [1:0] ignore;
  reg [63:0] prev;
  reg [63:0] error_count;
  reg [63:0] data_count;
`endif

  always @(posedge clk) begin
    if (reset) begin
      rx_state<=`RX_STATE_IDLE;
      rx_fifo_wr_en<=1'b0;

      link_down_strb<=1'b0;
      rx_strb<=1'b0;
`ifdef XAUI_ERROR_TEST
      ignore<=2'b0;
      error_count<=64'b0;
      data_count<=64'b0;
`endif
    end else begin
      if (xgmii_rxd != rx_fifo_wr_data)
        rx_fifo_wr_en <= 1'b1;

      rx_fifo_wr_data <= xgmii_rxd;
      
      link_down_strb<=1'b0;
      rx_strb<=1'b0;

      case (xgmii_rxd)
        64'h0100009c_0100009c: link_down_strb<=1'b1;
      endcase

      case (rx_state)
        `RX_STATE_IDLE: begin
`ifdef XAUI_ERROR_TEST
          ignore<=2'b11;
`endif
          first<=1'b1;
          if (xgmii_rxc[0] && xgmii_rxd[7:0] == `XGMII_START) begin
            rx_state<=`RX_STATE_RX;
            rx_aligned<=1'b1;
            rx_strb<=1'b1;
          end else if (xgmii_rxc[4] && xgmii_rxd[39:32] == `XGMII_START) begin   
            rx_state<=`RX_STATE_RX;
            rx_aligned<=1'b0;
            rx_strb<=1'b1;
          end
        end
        `RX_STATE_RX: begin
`ifdef XAUI_ERROR_TEST
          if (ignore)
            ignore<=ignore - 1;
`endif
          if (rx_aligned) begin
            if (xgmii_rxc[0] && xgmii_rxd[7:0] == `XGMII_TERM) begin
              rx_state<=`RX_STATE_IDLE;
            end else begin
`ifdef XAUI_ERROR_TEST
              if (!ignore) begin
                data_count<=data_count + 1;
                if (prev + 1 != xgmii_rxd[63:0]) begin
                  error_count<=error_count + 1;
                end
              end
              prev<=xgmii_rxd;
`else
              if (first) begin
                first<=1'b0;
              end else begin
                rx_fifo_wr_en<=1'b1;
                rx_fifo_wr_data<=xgmii_rxd;
              end
`endif
            end
          end else begin
            if (xgmii_rxc[4] && xgmii_rxd[39:32] == `XGMII_TERM) begin
              rx_state<=`RX_STATE_IDLE;
`ifdef XAUI_ERROR_TEST
`else
              rx_fifo_wr_en<=1'b1;
              rx_fifo_wr_data<={xgmii_rxd[31:0],leftovers};
`endif
            end else if (xgmii_rxc != 8'b0) begin
              /*TODO: work out what f0f0f0f0 + data ==*/
            end else begin
              leftovers<=xgmii_rxd[63:32];
              if (first) begin
                first<=1'b0;
              end else begin
`ifdef XAUI_ERROR_TEST
                if (!ignore) begin
                  data_count<=data_count + 1;
                  if (prev + 1 != {xgmii_rxd[31:0], leftovers}) begin
                    error_count<=error_count + 1;
                  end
                end
                prev<={xgmii_rxd[31:0], leftovers};
`else
                rx_fifo_wr_en<=1'b1;
                rx_fifo_wr_data<={xgmii_rxd[31:0], leftovers};
`endif
              end
//              if (~first) begin
//              end else begin
//                first<=1'b0;
//              end
            end
          end
        end
      endcase
    end
  end

  reg [1:0] tx_state;
`ifdef XAUI_ERROR_TEST
  reg [63:0] test_counter;
  reg [12:0] send_counter;
`endif
  always @(posedge clk) begin
    if (reset) begin
`ifdef XAUI_ERROR_TEST
      test_counter<=64'b0;
      send_counter<=13'b0;
`endif
      tx_fifo_rd_en<=1'b0;
      tx_state<=`TX_STATE_IDLE;
      xgmii_txc<=8'b1111_1111;
      xgmii_txd<={`XGMII_IDLE,`XGMII_IDLE,`XGMII_IDLE,`XGMII_IDLE,
                  `XGMII_IDLE,`XGMII_IDLE,`XGMII_IDLE,`XGMII_IDLE};

      tx_strb<=1'b0;
    end else begin
      tx_strb<=1'b0;
      tx_fifo_rd_en<=1'b0;
      case (tx_state)
        `TX_STATE_IDLE: begin
          xgmii_txc<=8'b1111_1111;
          xgmii_txd<={`XGMII_IDLE,`XGMII_IDLE,`XGMII_IDLE,`XGMII_IDLE,
                      `XGMII_IDLE,`XGMII_IDLE,`XGMII_IDLE,`XGMII_IDLE};                      

`ifdef XAUI_ERROR_TEST
          if (send_counter) begin
            send_counter<=send_counter + 1;
          end

          if (user_tx_en && !send_counter) begin
`else
          if (user_tx_en && tx_fifo_wr_status[0]) begin
`endif
            /*transmit when link is working, tx enabled and tx_fifo almost full */ 
            tx_state<=`TX_STATE_START;
          end
        end
        `TX_STATE_START: begin
          xgmii_txc<=8'b1111_1111;
          xgmii_txd<={`XGMII_ERROR,`XGMII_ERROR,`XGMII_ERROR,`XGMII_ERROR,       
                      `XGMII_ERROR,`XGMII_ERROR,`XGMII_ERROR,`XGMII_START};                  
  
          tx_state<=`TX_STATE_DATA;
          tx_strb<=1'b1;
        end
        `TX_STATE_DATA: begin
          xgmii_txc<=8'b0000_0000;
`ifdef XAUI_ERROR_TEST
          test_counter<=test_counter + 1;
          xgmii_txd<=test_counter;
          send_counter<=send_counter + 1;
`else
          xgmii_txd<={tx_fifo_rd_data[63:32], tx_fifo_rd_data[31:0]};
          tx_fifo_rd_en<=1'b1;
`endif
    
`ifdef XAUI_ERROR_TEST
          if (send_counter >= 13'b111_11111_00000) begin //save a few idle cycles
`else
          if (tx_fifo_rd_status[0]) begin //almost empty == 1
`endif

            tx_state<=`TX_STATE_TERM;
          end
        end
        `TX_STATE_TERM: begin
          xgmii_txc<=8'b1111_1111;
          xgmii_txd<={`XGMII_IDLE,`XGMII_IDLE,`XGMII_IDLE,`XGMII_IDLE,
                      `XGMII_IDLE,`XGMII_IDLE,`XGMII_IDLE,`XGMII_TERM};                      
          tx_state<=`TX_STATE_IDLE;
        end
      endcase
    end
  end

endmodule
