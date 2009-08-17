//`define ENABLE_CRC16
module mmc_controller(
    input        wb_clk_i,
    input        wb_rst_i,
    input        wb_cyc_i,
    input        wb_stb_i,
    input        wb_we_i,
    input  [2:0] wb_adr_i,
    input  [7:0] wb_dat_i,
    output [7:0] wb_dat_o,
    output       wb_ack_o,

    output       mmc_clk,
    output       mmc_cmd_o,
    input        mmc_cmd_i,
    output       mmc_cmd_oe,
    input  [7:0] mmc_dat_i,
    output [7:0] mmc_dat_o,
    output       mmc_dat_oe,
    input        mmc_cdetect,

    output       irq_cdetect,
    output       irq_got_cmd,
    output       irq_got_dat,
    output       irq_got_busy
  );

  /********* Common Signals **********/

  /***** Clock Advance Controls ******/
  /* Memory operation advance */
  wire [1:0] mem_adv_mode;
  wire       mem_adv_en;
  wire       mem_adv_done;
  wire       rd_dat_avail;

  wire       mem_adv_tick;

  /* Single Clock advance */
  wire man_adv_en;
  wire man_adv_done;

  /**** Data / CMD Read Contents ****/
  wire [7:0] cmd_rd;
  wire [7:0] dat_rd;

  /** Data / CMD Simple Write Data **/
  wire       cmd_wr;
  wire [7:0] dat_wr;

  /********** CRC Signals ***********/

  wire [16*4-1:0] crc16;
  wire            crc16_dvld;
  wire            crc_rst;

  /********* Get MMC Ready *********/
  wire get_ready_en;
  wire get_ready_done;
  wire get_ready_tick;

  /********* MMC Parameters *********/
  wire        data_width;
  wire  [1:0] clk_width;

  wb_attach wb_attach_inst(
    .wb_clk_i (wb_clk_i),
    .wb_rst_i (wb_rst_i),
    .wb_cyc_i (wb_cyc_i),
    .wb_stb_i (wb_stb_i),
    .wb_we_i  (wb_we_i),
    .wb_adr_i (wb_adr_i),
    .wb_dat_i (wb_dat_i),
    .wb_dat_o (wb_dat_o),
    .wb_ack_o (wb_ack_o),

    .mem_adv_mode (mem_adv_mode), 
    .mem_adv_en   (mem_adv_en), 
    .mem_adv_done (mem_adv_done), 

    .get_ready_en   (get_ready_en),
    .get_ready_done (get_ready_done),

    .rd_dat_avail (rd_dat_avail), 

    .man_adv_en   (man_adv_en), 
    .man_adv_done (man_adv_done), 

    .dat_oe (mmc_dat_oe),
    .cmd_oe (mmc_cmd_oe),

    .dat_wr (dat_wr),
    .cmd_wr (cmd_wr),
    .dat_rd (dat_rd),
    .cmd_rd (cmd_rd),


    .crc16      (crc16),
    .crc_rst    (crc_rst),

    .data_width (data_width),
    .clk_width  (clk_width)
  );

  /********* Clock Control *********/

  wire clk_done;
  wire clk_rdy;
  wire clk_ack;
  wire clk_tick = man_adv_en || mem_adv_tick || get_ready_tick;

  clk_ctrl clk_ctrl_inst(
    .clk     (wb_clk_i),
    .rst     (wb_rst_i),
    .width   (clk_width),
    .tick    (clk_tick),
    .rdy     (clk_rdy),
    .ack     (clk_ack),
    .done    (clk_done),
    .mmc_clk (mmc_clk)
  );

  /************ Ready Condition Search *************/

  assign get_ready_tick = get_ready_en; 
  assign irq_got_busy = get_ready_en && clk_done && mmc_dat_i[0];
  assign get_ready_done = irq_got_busy;

  /************ Manual Advance Logic *************/

  reg man_adv_done_reg;
  always @(posedge wb_clk_i) begin
    if (man_adv_en) begin
      man_adv_done_reg <= 1'b0;
    end else if (clk_done) begin
      man_adv_done_reg <= 1'b1;
    end
  end
  assign man_adv_done = man_adv_done_reg;

  /******* Memory Op Clock Advance *******/

  localparam ADV_DAT_RD   = 2'd1;
  localparam ADV_DAT_WR   = 2'd2;

  wire [7:0] adv_wr_dat;
  wire       adv_wr_cmd;
  wire [7:0] adv_rd_dat;
  wire [7:0] adv_rd_cmd;

  /****************** Rd Logic *******************/
  wire mem_adv_done_rd;
  wire mem_adv_tick_rd;

  rd_adv rd_adv_inst(
    .clk        (wb_clk_i),
    .rst        (wb_rst_i),
    .enable     (mem_adv_mode == ADV_DAT_RD),
    .data_width (data_width),     
    .mmc_dat_i  (mmc_dat_i),
    .bus_data   (adv_rd_dat),
    .bus_req    (mem_adv_en),
    .bus_ack    (mem_adv_done_rd),
    .clk_tick   (mem_adv_tick_rd),
    .clk_done   (clk_done)
  );
  assign rd_dat_avail = mem_adv_done_rd;

  /****************** Wr Logic *******************/
  wire mem_adv_done_wr;
  wire mem_adv_tick_wr;
  wire [7:0] adv_dat_wr;

  wr_adv wr_adv (
    .clk        (wb_clk_i),
    .rst        (wb_rst_i),
    .data_width (data_width),     
    .bus_req    (mem_adv_en && mem_adv_mode == ADV_DAT_WR),
    .bus_dat_i  (wb_dat_i),
    .bus_ack    (mem_adv_done_wr),
    .dat_wr     (adv_dat_wr),
    .clk_tick   (mem_adv_tick_wr),
    .clk_done   (clk_done),
    .clk_ack    (clk_ack)
  );

  assign mem_adv_done = mem_adv_mode == ADV_DAT_WR ? mem_adv_done_wr : mem_adv_done_rd;
  assign mem_adv_tick = mem_adv_mode == ADV_DAT_WR ? mem_adv_tick_wr : mem_adv_tick_rd;

  /* MMC Data assignments */ 

  assign mmc_cmd_o = cmd_wr;
  assign mmc_dat_o = mem_adv_mode == ADV_DAT_WR ? adv_dat_wr : dat_wr;
  assign dat_rd    = mem_adv_mode == ADV_DAT_RD ? adv_rd_dat : mmc_dat_i;
  assign cmd_rd    = {7'b0, mmc_cmd_i};

  /* Memory operation advance */

  /********** CRCs ***********/

`ifdef ENABLE_CRC16
  assign crc16_dvld = clk_ack;

  crc16 crc_16_inst[3:0] (
    .clk  (wb_clk_i),
    .rst  (crc_rst),
    .data (mmc_dat_i[3:0]),
    .dvld (crc16_dvld),
    .dout (crc16)
  );
`endif

  /* cdetect irq */

  reg prev_cdetect;

  always @(posedge wb_clk_i) begin
    prev_cdetect <= mmc_cdetect;
  end
  assign irq_cdetect = prev_cdetect != mmc_cdetect;

endmodule
