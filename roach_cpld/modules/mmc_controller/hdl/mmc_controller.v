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
  wire [2:0] mem_adv_mode;
  wire       mem_adv_en;
  wire       mem_adv_done;
  wire       mem_adv_tick;

  /* Single Clock advance */
  wire man_adv_en;
  wire man_adv_done;

  /***** Auto Clock Tick Signals ****/
  wire [1:0] auto_mode;
  wire       auto_tick;
  wire       auto_done;

  /**** Data / CMD Read Contents ****/
  wire [7:0] cmd_rd;
  wire [7:0] dat_rd;

  /** Data / CMD Simple Write Data **/
  wire       cmd_wr;
  wire [7:0] dat_wr;

  /********** CRC Signals ***********/
  wire  [6:0] crc7;
  wire [15:0] crc16;
  wire        crc16_dvld;
  wire        crc_rst;

  /********* MMC Parameters *********/
  wire  [1:0] data_width;
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

    .man_adv_en   (man_adv_en), 
    .man_adv_done (man_adv_done), 

    .dat_oe (mmc_dat_oe),
    .cmd_oe (mmc_cmd_oe),

    .dat_wr (dat_wr),
    .cmd_wr (cmd_wr),
    .dat_rd (dat_rd),
    .cmd_rd (cmd_rd),

    .auto_mode (auto_mode),
    .auto_done (auto_done),

    .crc7       (crc7),
    .crc16      (crc16),
    .crc16_dvld (crc16_dvld),
    .crc_rst    (crc_rst),

    .data_width (data_width),
    .clk_width  (clk_width)
  );

  /********* Clock Control *********/

  wire clk_done;
  wire clk_rdy;
  wire clk_ack;
  wire clk_tick = man_adv_en || mem_adv_tick || auto_tick;

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

  /*********** Auto Mode Logic ***********/

  assign irq_got_cmd  = clk_done && auto_mode == 1 && !mmc_cmd_i;
  assign irq_got_dat  = clk_done && auto_mode == 2 && !mmc_dat_i[0];
  assign irq_got_busy = clk_done && auto_mode == 3 &&  mmc_dat_i[0];

  assign auto_done = irq_got_cmd || irq_got_dat || irq_got_busy;

  reg auto_stb;
  reg auto_pend;

  always @(posedge wb_clk_i) begin
    auto_stb  <= 1'b0;

    if (wb_rst_i) begin
      auto_pend <= 1'b0;
    end else begin
      if ((|auto_mode) && !auto_pend) begin
        auto_stb  <= 1'b1;
        auto_pend <= 1'b1;
      end 
      if (clk_done) begin
        auto_pend <= 1'b0;
      end
    end
  end
  assign auto_tick = auto_stb;

  /******* Memory Op Clock Advance *******/

  localparam ADV_CMD_RD   = 2'd0;
  localparam ADV_CMD_WR   = 2'd1;
  localparam ADV_DAT_RD   = 2'd2;
  localparam ADV_DAT_WR   = 2'd3;

  wire [7:0] adv_wr_dat;
  wire       adv_wr_cmd;
  wire [7:0] adv_rd_dat;
  wire [7:0] adv_rd_cmd;

  /* MMC Data assignments */ 

  assign mmc_dat_o = mem_adv_mode[2] && mem_adv_mode[1:0] == ADV_DAT_WR ? adv_wr_dat : dat_wr;
  assign mmc_cmd_o = mem_adv_mode[2] && mem_adv_mode[1:0] == ADV_CMD_WR ? adv_wr_cmd : cmd_wr;
  assign dat_rd    = mem_adv_mode[2] && mem_adv_mode[1:0] == ADV_DAT_RD ? adv_rd_dat : mmc_dat_i;
  assign cmd_rd    = mem_adv_mode[2] && mem_adv_mode[1:0] == ADV_CMD_RD ? adv_rd_cmd : {7'b0, mmc_cmd_i};

  /* Memory operation advance */

  adv_proc adv_proc (
    .clk (wb_clk_i),
    .rst (wb_rst_i),

    .adv_mode (mem_adv_mode[1:0]),
    .adv_en   (mem_adv_en),
    .adv_tick (mem_adv_tick),
    .adv_done (mem_adv_done),

    .data_width (data_width),

    .mmc_dat_i (mmc_dat_i),
    .mmc_cmd_i (mmc_cmd_i),
    .dat_rd    (adv_rd_dat),
    .cmd_rd    (adv_rd_cmd),

    .bus_dat_i (wb_dat_i),
    .bus_cmd_i (wb_dat_i),
    .dat_wr    (adv_wr_dat),
    .cmd_wr    (adv_wr_cmd),
    
    .clk_ack   (clk_ack),
    .clk_done  (clk_done)
  );
  
  /********** CRCs ***********/

  crc16_d8 crc_16_d8_inst (
    .clk  (wb_clk_i),
    .rst  (crc_rst),
    .data (wb_dat_i),
    .dvld (crc16_dvld),
    .dout (crc16)
  );

  crc7_d1 crc7_d1_inst (
    .clk  (wb_clk_i),
    .rst  (crc_rst),
    .data (mmc_cmd_o),
    .dvld (clk_rdy && clk_tick),
    .dout (crc7)
  );

endmodule
