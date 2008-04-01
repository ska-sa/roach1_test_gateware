module xaui_pipe(
    reset,
    /*mgt signals*/
    mgt_clk,
    mgt_txdata, mgt_txcharisk,
    mgt_rxdata, mgt_rxcharisk,
    mgt_enable_align,
    mgt_code_valid, mgt_code_comma, mgt_rxlock, mgt_syncok,
    mgt_rxbufferr,
    mgt_loopback, mgt_en_chan_sync, mgt_powerdown,
    mgt_tx_reset, mgt_rx_reset,
    mgt_rxeqmix, mgt_rxeqpole, mgt_txpreemphasis, mgt_txdiffctrl,
    /*wb if*/
    wb_clk_i,
    wb_cyc_i, wb_stb_i, wb_we_i, wb_sel_i,
    wb_adr_i, wb_dat_i, wb_dat_o,
    wb_ack_o,
    /*leds*/
    leds //rx, tx, linkup
  );
  parameter DEFAULT_POWERDOWN = 0;
  parameter DEFAULT_LOOPBACK  = 0;
  parameter DEFAULT_TXEN      = 1;

  input  reset;

  input  mgt_clk;
  output [63:0] mgt_txdata;
  output  [7:0] mgt_txcharisk;
  input  [63:0] mgt_rxdata;
  input   [7:0] mgt_rxcharisk;
  output  [3:0] mgt_enable_align;
  input   [7:0] mgt_code_comma;
  input   [7:0] mgt_code_valid;
  input   [3:0] mgt_syncok;
  output  [3:0] mgt_rx_reset;
  output  [3:0] mgt_tx_reset;
  output mgt_loopback;
  output mgt_powerdown;
  output mgt_en_chan_sync;
  input   [3:0] mgt_rxlock;
  input   [3:0] mgt_rxbufferr;
  output  [1:0] mgt_rxeqmix;
  output  [3:0] mgt_rxeqpole;
  output  [2:0] mgt_txpreemphasis;
  output  [2:0] mgt_txdiffctrl;

  input  wb_clk_i;
  input  wb_cyc_i, wb_stb_i, wb_we_i;
  input   [1:0] wb_sel_i;
  input  [31:0] wb_adr_i;
  input  [15:0] wb_dat_i;
  output [15:0] wb_dat_o;
  output wb_ack_o;

  output  [2:0] leds;

  /********************** Common Signals **************************/

  /* TX/RX fifo signals */
  wire rx_fifo_rd_clk;
  wire [63:0] rx_fifo_rd_data;
  wire rx_fifo_rd_en;
  wire rx_fifo_rd_err;
  wire  [1:0] rx_fifo_rd_status;

  wire rx_fifo_wr_clk;
  wire [63:0] rx_fifo_wr_data;
  wire rx_fifo_wr_en;
  wire rx_fifo_wr_err;
  wire  [1:0] rx_fifo_wr_status;

  wire tx_fifo_rd_clk;
  wire [63:0] tx_fifo_rd_data;
  wire tx_fifo_rd_en;
  wire tx_fifo_rd_err;
  wire  [1:0] tx_fifo_rd_status;

  wire tx_fifo_wr_clk;
  wire [63:0] tx_fifo_wr_data;
  wire tx_fifo_wr_en;
  wire tx_fifo_wr_err;
  wire  [1:0] tx_fifo_wr_status;

  /* xaui reset -- soft and hard */
  wire xaui_reset;

  /* xaui signals */
  wire [63:0] xgmii_rxd;
  wire  [7:0] xgmii_rxc;
  wire [63:0] xgmii_txd;
  wire  [7:0] xgmii_txc;

  wire  [7:0] link_status;

  /* signals from WB_attach */
  wire  user_loopback;
  wire user_powerdown;
  wire user_txen;
  wire user_xaui_reset_strb;

  /* signals for status LED */
  wire xaui_rx_strb, xaui_tx_strb, xaui_link_down_strb;

  /********************** RX/TX FIFOS *****************************/
  
  wire tx_underflow, tx_overflow, tx_almost_full, tx_almost_empty, tx_full, tx_empty;

  assign tx_fifo_rd_status = {tx_empty, tx_almost_empty};
  assign tx_fifo_rd_err = tx_underflow;

  assign tx_fifo_wr_status = {tx_full, tx_almost_full};
  assign tx_fifo_wr_err = tx_overflow;
  xaui_fifo tx_fifo(
    .rst(xaui_reset), 
    .rd_clk(tx_fifo_rd_clk),
    .dout(tx_fifo_rd_data),
    .rd_en(tx_fifo_rd_en),

    .wr_clk(tx_fifo_wr_clk),
    .din(tx_fifo_wr_data),
    .wr_en(tx_fifo_wr_en),
    .overflow(tx_overflow), .underflow(tx_underflow),
    .almost_full(tx_almost_full), .almost_empty(tx_almost_empty),
    .full(tx_full), .empty(tx_empty)
  );

  wire rx_underflow, rx_overflow, rx_almost_full, rx_almost_empty, rx_full, rx_empty;
  assign rx_fifo_rd_status = {2'b0, rx_empty, rx_almost_empty};
  assign rx_fifo_rd_err = rx_underflow;

  assign rx_fifo_wr_status = {2'b0, rx_full, rx_almost_full};
  assign rx_fifo_wr_err = rx_overflow;
  xaui_fifo rx_fifo(
    .rst(xaui_reset),
    .rd_clk(rx_fifo_rd_clk),
    .dout(rx_fifo_rd_data),
    .rd_en(rx_fifo_rd_en),

    .wr_clk(rx_fifo_wr_clk),
    .din(rx_fifo_wr_data),
    .wr_en(rx_fifo_wr_en),
    .overflow(rx_overflow), .underflow(rx_underflow),
    .almost_full(rx_almost_full), .almost_empty(rx_almost_empty),
    .full(rx_full), .empty(rx_empty)
  );

  assign rx_fifo_wr_clk = mgt_clk;
  assign tx_fifo_rd_clk = mgt_clk;
  assign rx_fifo_rd_clk = wb_clk_i;
  assign tx_fifo_wr_clk = wb_clk_i;

  /********************************* LEDs ********************************************/

  reg [23:0] led_rx_stretch;
  reg [23:0] led_tx_stretch;
  reg [23:0] led_link_down_stretch;

  assign leds = {led_rx_stretch != 24'b0, led_tx_stretch != 24'b0, led_link_down_stretch != 24'b0};

  always @(posedge mgt_clk) begin
    if (xaui_reset) begin
      led_rx_stretch<=24'b0;
      led_tx_stretch<=24'b0;
      led_link_down_stretch<=24'b0;
    end else begin
      if (led_rx_stretch) begin
        led_rx_stretch<=led_rx_stretch - 24'b1;
      end else if (xaui_rx_strb) begin
        led_rx_stretch<=24'hff_ff_ff;
      end
      if (led_tx_stretch) begin
        led_tx_stretch<=led_tx_stretch - 24'b1;
      end else if (xaui_tx_strb) begin
        led_tx_stretch<=24'hff_ff_ff;
      end
      if (led_link_down_stretch) begin
        led_link_down_stretch<=led_link_down_stretch - 24'b1;
      end else if (xaui_link_down_strb) begin
        led_link_down_stretch<=24'hff_ff_ff;
      end
    end
  end

  /***************************** XAUI Controller ****************************************/

  xaui_controller xaui_controller_0(
    .clk(mgt_clk), .reset(xaui_reset),
    .mgt_txdata(mgt_txdata), .mgt_txcharisk(mgt_txcharisk),
    .mgt_rxdata(mgt_rxdata), .mgt_rxcharisk(mgt_rxcharisk),
    .mgt_enable_align(mgt_enable_align),
    .mgt_code_valid(mgt_code_valid), .mgt_code_comma(mgt_code_comma),
    .mgt_rxlock(mgt_rxlock), .mgt_syncok(mgt_syncok),
    .mgt_rxbufferr(mgt_rxbufferr),
    .mgt_loopback(mgt_loopback), .mgt_en_chan_sync(mgt_en_chan_sync), .mgt_powerdown(mgt_powerdown),
    .mgt_tx_reset(mgt_tx_reset), .mgt_rx_reset(mgt_rx_reset), 
    .xgmii_rxd(xgmii_rxd), .xgmii_rxc(xgmii_rxc),
    .xgmii_txd(xgmii_txd), .xgmii_txc(xgmii_txc),
    .user_loopback(user_loopback), .user_powerdown(user_powerdown),
    .link_status(link_status)
  );

  /********************************** User TX/RX ********************************/
  `ifdef XAUI_ERROR_TEST
  wire [63:0] error_count; 
  wire [63:0] data_count; 
  `endif

  transfer_engine transfer_engine_inst(
    .clk(mgt_clk), .reset(xaui_reset),
    .xgmii_rxd(xgmii_rxd), .xgmii_rxc(xgmii_rxc),
    .xgmii_txd(xgmii_txd), .xgmii_txc(xgmii_txc),
    .rx_fifo_wr_en(rx_fifo_wr_en), .rx_fifo_wr_data(rx_fifo_wr_data),
    .tx_fifo_rd_en(tx_fifo_rd_en), .tx_fifo_rd_data(tx_fifo_rd_data),
    .tx_fifo_rd_status(tx_fifo_rd_status), .tx_fifo_wr_status(tx_fifo_wr_status),
    .user_tx_en(user_txen),
    .rx_strb(xaui_rx_strb), .tx_strb(xaui_tx_strb), .link_down_strb(xaui_link_down_strb)
    `ifdef XAUI_ERROR_TEST
    , .error_count(error_count), .data_count(data_count)
    `endif

  );

  /**************************** Wishbone Attachment *********************************/

  xaui_wb_attach #(
    .DEFAULT_POWERDOWN(DEFAULT_POWERDOWN),
    .DEFAULT_LOOPBACK(DEFAULT_LOOPBACK),
    .DEFAULT_TXEN(DEFAULT_TXEN)
  ) xaui_wb_attach_0 (
    .reset(reset),
    .wb_clk_i(wb_clk_i),
    .wb_cyc_i(wb_cyc_i), .wb_stb_i(wb_stb_i), .wb_we_i(wb_we_i), .wb_sel_i(wb_sel_i),
    .wb_adr_i(wb_adr_i), .wb_dat_i(wb_dat_i), .wb_dat_o(wb_dat_o),
    .wb_ack_o(wb_ack_o),

    .user_loopback(user_loopback), .user_powerdown(user_powerdown), .user_txen(user_txen),
    .user_xaui_reset_strb(user_xaui_reset_strb), 

    .rx_fifo_rd_en(rx_fifo_rd_en), .tx_fifo_wr_en(tx_fifo_wr_en),
    .rx_fifo_status({rx_fifo_wr_status, rx_fifo_rd_status}),
    .tx_fifo_status({tx_fifo_wr_status, tx_fifo_rd_status}),
    .rx_fifo_data(rx_fifo_rd_data), .tx_fifo_data(tx_fifo_wr_data),

    .xaui_status(link_status),
    .mgt_rxeqmix(mgt_rxeqmix), .mgt_rxeqpole(mgt_rxeqpole),
    .mgt_txpreemphasis(mgt_txpreemphasis), .mgt_txdiffctrl(mgt_txdiffctrl)
    `ifdef XAUI_ERROR_TEST
    , .error_count(error_count), .data_count(data_count)
    `else
    , .error_count(64'd0), .data_count(64'd0)
    `endif
  );

  /************************** Clock Domain Crossing *********************/
 

  reg [1:0] reset_stretch; // Stretch pulse from WB to ensure detection by Xaui
  always @(posedge wb_clk_i) begin
    if (reset | user_xaui_reset_strb) begin
      reset_stretch <= 2'b11;
    end else begin
      if (reset_stretch) begin
        reset_stretch <= reset_stretch - 1;
      end
    end
  end

  reg xaui_reset_prev, xaui_reset_reg;
  wire xaui_reset_stretched = (reset_stretch != 2'b0);

  assign xaui_reset = xaui_reset_prev != xaui_reset_reg & xaui_reset_reg; //posedge of xaui_reset_reg

  always @(posedge mgt_clk) begin
    if (reset) begin
      xaui_reset_reg <= xaui_reset_stretched;
      xaui_reset_prev <= xaui_reset_reg;
    end else begin
      xaui_reset_reg <= xaui_reset_stretched;
      xaui_reset_prev <= xaui_reset_reg;
    end
  end


endmodule
