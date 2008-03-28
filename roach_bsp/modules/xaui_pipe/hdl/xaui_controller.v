module xaui_controller(
  clk, reset,
  mgt_reset,
  mgt_txdata, mgt_txcharisk,
  mgt_rxdata, mgt_rxcharisk,
  mgt_enable_align,
  mgt_code_valid, mgt_code_comma, mgt_rxlock,
  mgt_rx_status,
  mgt_loopback, mgt_en_chan_sync, mgt_powerdown,
  mgt_tx_reset, mgt_rx_reset,
  xgmii_rxd, xgmii_rxc,
  xgmii_txd, xgmii_txc,
  user_loopback, user_powerdown,
  link_status
  );

  input clk, reset;

  output mgt_reset;
  output [63:0] mgt_txdata;
  output  [7:0] mgt_txcharisk;
  input  [63:0] mgt_rxdata;
  input   [7:0] mgt_rxcharisk;
  output  [3:0] mgt_enable_align;
  input   [7:0] mgt_code_valid;
  input   [7:0] mgt_code_comma;
  output  [3:0] mgt_rx_reset;
  output  [3:0] mgt_tx_reset;
  output  [1:0] mgt_loopback;
  output mgt_powerdown;
  output mgt_en_chan_sync;
  input   [3:0] mgt_rxlock;
  input  [23:0] mgt_rx_status;

  output [63:0] xgmii_rxd;
  output  [7:0] xgmii_rxc;
  input  [63:0] xgmii_txd;
  input   [7:0] xgmii_txc;

  input   [1:0] user_loopback;
  input  user_powerdown;

  output  [7:0] link_status;

  wire [6:0] xaui_configuration_vector;
  
  assign xaui_configuration_vector = {
    2'b00, //Test Select
    1'b0,  //Test Enable,
    reset, //reset link status
    reset, //reset fault status
    user_powerdown,  //power down
    user_loopback != 2'b00  //loopback
    };

  assign mgt_loopback = user_loopback;

  xaui_v7_1 xaui_0(
    .reset(reset),   
    .usrclk(clk),
    /* client side */
    .xgmii_txd(xgmii_txd), .xgmii_txc(xgmii_txc),
    .xgmii_rxd(xgmii_rxd), .xgmii_rxc(xgmii_rxc),
    /* mgt side */
    .mgt_txdata(mgt_txdata), .mgt_txcharisk(mgt_txcharisk),
    .mgt_rxdata(mgt_rxdata), .mgt_rxcharisk(mgt_rxcharisk),
    .mgt_codevalid(mgt_code_valid), .mgt_codecomma(mgt_code_comma),
    .mgt_enable_align(mgt_enable_align), .mgt_enchansync(mgt_en_chan_sync),
    .mgt_syncok(4'b1111), .mgt_loopback(), .mgt_powerdown(mgt_powerdown),
    .mgt_rxlock(mgt_rxlock),
    /* status & configuration*/
    .configuration_vector(xaui_configuration_vector),
    .status_vector(link_status),
    .align_status(), .sync_status(),
    .mgt_tx_reset(mgt_tx_reset), .mgt_rx_reset(mgt_rx_reset),
    .signal_detect(4'b1111)
  );


  /**************** Resets ***********************/

  reg mgt_reset;
  reg [3:0] mgt_reset_stretch;

  always @(posedge clk) begin
    if (reset) begin
      mgt_reset<=1'b1;
      mgt_reset_stretch<=4'b1111;
    end else begin
      if (mgt_reset_stretch) begin
        mgt_reset_stretch<=mgt_reset_stretch-1;
      end else begin
        mgt_reset<=1'b0;
      end
    end
  end
  assign mgt_tx_reset = {4{mgt_reset}};
  assign mgt_rx_reset = {4{mgt_reset}};

endmodule
