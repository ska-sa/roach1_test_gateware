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
    input  [7:0] mmc_data_i,
    output [7:0] mmc_data_o,
    output       mmc_data_oe,
    input        mmc_cdetect,

    output       irq_cdetect,
    output       irq_got_cmd,
    output       irq_got_dat,
    output       irq_got_busy
  );
  reg wb_ack_reg;
  wire wb_trans = wb_cyc_i && wb_stb_i && !wb_ack_reg;

  localparam REG_CMD      = 3'd0;
  localparam REG_DAT      = 3'd1;
  localparam REG_AUTO     = 3'd2;
  localparam REG_ADV      = 3'd3;
  localparam REG_CLK      = 3'd4;
  localparam REG_CRC_CMD  = 3'd5;
  localparam REG_CRC_DAT1 = 3'd6;
  localparam REG_CRC_DAT0 = 3'd7;

  wire [15:0] crc16;
  crc16_d8 crc_16_d8_inst (
    .clk  (wb_clk_i),
    .rst  (wb_trans && wb_we_i && wb_adr_i == REG_CRC_DAT1),
    .data (wb_dat_i),
    .dvld (wb_trans && wb_we_i && wb_adr_i == REG_DAT),
    .dout (crc16)
  );

  wire [6:0] crc7;
  crc7_d1 crc7_d1_inst (
    .clk  (wb_clk_i),
    .rst  (wb_trans && wb_we_i && wb_adr_i == REG_CRC_CMD),
    .data (wb_dat_i[0]),
    .dvld (wb_trans && wb_we_i && wb_adr_i == REG_CMD),
    .dout (crc7)
  );

  /*** Configuration Registers ***/
  reg [1:0] data_width;
  localparam DW_1 = 2'd0;
  localparam DW_4 = 2'd1;
  localparam DW_8 = 2'd2;

  reg [6:0] clk_width;

  reg [2:0] adv_mode;
  localparam ADV_CMD_NONE = 3'd0;
  localparam ADV_CMD_RD   = 3'd1;
  localparam ADV_CMD_WR   = 3'd2;
  localparam ADV_DAT_RD   = 3'd3;
  localparam ADV_DAT_WR   = 3'd4;

  wire adv_cmd_rd = adv_mode == ADV_CMD_RD && wb_trans && !wb_we_i && wb_adr_i == REG_CMD;
  wire adv_cmd_wr = adv_mode == ADV_CMD_WR && wb_trans &&  wb_we_i && wb_adr_i == REG_CMD;
  wire adv_dat_rd = adv_mode == ADV_DAT_RD && wb_trans && !wb_we_i && wb_adr_i == REG_DAT;
  wire adv_dat_wr = adv_mode == ADV_DAT_WR && wb_trans &&  wb_we_i && wb_adr_i == REG_DAT;

  wire adv_done;

  /* Manual Clock Control */
  wire man_adv_done;
  wire man_adv_en = wb_trans && wb_we_i && wb_adr_i == REG_ADV && wb_dat_i[3];

  /*** Hardware Registers ***/
  reg data_oe;
  reg cmd_oe;
  assign mmc_cmd_oe  = cmd_oe;
  assign mmc_data_oe = data_oe;

  /*** Auto Clock advance Controls ****/
  reg [1:0] auto_mode;
  localparam AUTO_NONE      = 0;
  localparam AUTO_CMD_START = 1;
  localparam AUTO_DAT_START = 2;
  localparam AUTO_BUSY      = 3;
  wire auto_done;

  /*** Data / CMD contents ******/
  wire [7:0] cmd_rd;
  wire [7:0] data_rd;

  reg       cmd_wr;
  reg [7:0] data_wr;

  /****** Wishbone State Machine *******/

  reg wb_state;
  localparam WB_IDLE     = 0;
  localparam WB_ADV_WAIT = 1;

  always @(posedge wb_clk_i) begin
    wb_ack_reg <= 1'b0;

    if (wb_rst_i) begin
      wb_state   <= WB_IDLE;
    end else begin
      case (wb_state)
        WB_IDLE: begin
          if (adv_cmd_rd || adv_cmd_wr || adv_dat_rd || adv_dat_wr) begin
            wb_state <= WB_ADV_WAIT;
          end else if (wb_trans) begin
            wb_ack_reg <= 1'b1;
          end
        end
        WB_ADV_WAIT: begin
          if (adv_done) begin
            wb_state   <= WB_IDLE;
          end
        end
      endcase
    end
  end
  assign wb_ack_o = wb_state == WB_IDLE ? wb_ack_reg : adv_done;

  /****** Wishbone Reg Write *******/

  always @(posedge wb_clk_i) begin
    if (wb_rst_i) begin
      data_width <= DW_1;
      clk_width  <= {7{1'b1}};
      data_oe    <= 1'b0;
      cmd_oe     <= 1'b0;
      auto_mode  <= AUTO_NONE;
    end else begin
      if (auto_done) begin
        auto_mode <= AUTO_NONE;
      end
      if (wb_trans && wb_we_i) begin
        case (wb_adr_i)
          REG_CMD: begin
            cmd_wr <= wb_dat_i[0];
          end
          REG_DAT: begin
            data_wr <= wb_dat_i;
          end
          REG_AUTO: begin
            data_oe    <= wb_dat_i[7];
            cmd_oe     <= wb_dat_i[6];
            data_width <= wb_dat_i[5:4];
            auto_mode  <= wb_dat_i[1:0];
          end
          REG_ADV: begin
            adv_mode <= wb_dat_i[2:0];
          end
          REG_CLK: begin
            clk_width <= wb_dat_i[6:0];
          end
          default: begin
          end
        endcase
      end
    end
  end

  /****** Wishbone Reg Read *******/

  reg [7:0] wb_dat_reg;
  always @(*) begin
    case (wb_adr_i)
      REG_CMD: begin
        wb_dat_reg <= cmd_rd;
      end
      REG_DAT: begin
        wb_dat_reg <= data_rd;
      end
      REG_AUTO: begin
        wb_dat_reg <= {data_oe, cmd_oe, data_width, 2'b0, auto_mode};
      end
      REG_ADV: begin
        wb_dat_reg <= {4'b0, man_adv_done, adv_mode};
      end
      REG_CLK: begin
        wb_dat_reg <= {1'b0, clk_width};
      end
      REG_CRC_CMD: begin
        wb_dat_reg <= {1'b0, crc7[6:0]};
      end
      REG_CRC_DAT1: begin
        wb_dat_reg <= crc16[15:8];
      end
      REG_CRC_DAT0: begin
        wb_dat_reg <= crc16[7:0];
      end
      default: begin
        wb_dat_reg <= 8'b0;
      end
    endcase
  end
  assign wb_dat_o = wb_dat_reg;

  /***** Primary Clock Control SM ********/

  reg [2:0] progress;
  
  reg ctrl_state;
  localparam CTRL_IDLE = 2'd0;
  localparam CTRL_WAIT = 2'd1;
  localparam CTRL_AUTO = 2'd2;
  localparam CTRL_TICK = 2'd3;

  wire clk_done;

  always @(posedge wb_clk_i) begin
    if (wb_rst_i) begin
      ctrl_state <= CTRL_IDLE;
      progress   <= 3'd0;
    end else begin
      case (ctrl_state)
        CTRL_IDLE: begin
          if (auto_mode != AUTO_NONE) begin
            ctrl_state <= CTRL_AUTO;
          end
          if (adv_cmd_rd || adv_cmd_wr || adv_dat_rd || adv_dat_wr || man_adv_en) begin
            ctrl_state <= CTRL_WAIT;
          end
        end
        CTRL_WAIT: begin
          if (clk_done) begin
            progress <= progress + 1;
          end
          if (adv_done) begin
            progress <= 2'd0;
          end
        end
        CTRL_AUTO: begin
          ctrl_state <= CTRL_TICK;
        end
        CTRL_TICK: begin
          if (clk_done) begin
            if (auto_mode == AUTO_NONE || auto_done) begin
              ctrl_state <= CTRL_IDLE;
            end
          end
        end
      endcase
    end
  end

  wire auto_cmd_start  = ctrl_state == CTRL_TICK && clk_done && auto_mode == AUTO_CMD_START && !mmc_cmd_i;
  wire auto_data_start = ctrl_state == CTRL_TICK && clk_done && auto_mode == AUTO_DAT_START && !mmc_data_i[0];
  wire auto_busy       = ctrl_state == CTRL_TICK && clk_done && auto_mode == AUTO_BUSY      &&  mmc_data_i[0];
  assign auto_done = auto_cmd_start || auto_data_start || auto_busy;

  /* Simply Tie the adv done to IDLE */
  assign man_adv_done = ctrl_state == CTRL_IDLE;

  reg adv_done_reg;
  always @(*) begin
    adv_done_reg <= 1'b0;
    if (clk_done) begin
      case (adv_mode)
        ADV_CMD_RD: begin
          if (progress == 3'd7) begin
            adv_done_reg <= 1'b1;
          end
        end
        ADV_CMD_WR: begin
          if (progress == 3'd7) begin
            adv_done_reg <= 1'b1;
          end
        end
        ADV_DAT_RD: begin
          case (data_width)
            DW_8: begin
              if (progress == 3'd0) begin
                adv_done_reg <= 1'b1;
              end
            end
            DW_4: begin
              if (progress == 3'd1) begin
                adv_done_reg <= 1'b1;
              end
            end
            default: begin
              if (progress == 3'd7) begin
                adv_done_reg <= 1'b1;
              end
            end
          endcase
        end
        ADV_DAT_WR: begin
        end
        default: begin
          adv_done_reg <= 1'b1;
        end
      endcase
    end
  end
  assign adv_done = adv_done_reg;

  /************** DATA/CMD I/O encoding / decoding ***************/

  /* Output Data/CMD */
  reg [7:0] mmc_dat_o_reg;
  reg       mmc_cmd_o_reg;
  always @(*) begin
    if (adv_mode == ADV_DAT_WR) begin
      case (data_width)
        DW_1: begin
          mmc_dat_o_reg <= wb_dat_i >> (progress[2:0]);
        end
        DW_4: begin
          mmc_dat_o_reg <= wb_dat_i >> (4*progress[0]);
        end
        default: begin
          mmc_dat_o_reg <= wb_dat_i;
        end
      endcase
    end else begin
      mmc_dat_o_reg <= data_wr;
    end

    if (adv_mode == ADV_CMD_WR) begin
      mmc_cmd_o_reg <= wb_dat_i >> (progress[2:0]);
      /* a little tacky ^^^^^^^^ */
    end else begin
      mmc_cmd_o_reg <= cmd_wr;
    end
  end
  assign mmc_data_o = mmc_dat_o_reg;
  assign mmc_cmd_o  = mmc_cmd_o_reg;


  /* Accumulate data */
  reg [6:0] cmd_accum;
  reg [6:0] data_accum;

  always @(posedge wb_clk_i) begin
    if (wb_rst_i) begin
      cmd_accum <= 7'b0;
      data_accum <= 7'b0;
    end else if (clk_done) begin
      case (data_width)
        DW_1: begin
          if (progress == 3'd0) begin
            data_accum <= {6'b0, mmc_data_i[0]};
          end else begin
            data_accum <= {data_accum[5:0], mmc_data_i[0]};
          end
        end
        default: begin
          data_accum[3:0] <= mmc_data_i[3:0];
        end
      endcase

      if (progress == 3'd0) begin
        cmd_accum <= {6'b0, mmc_cmd_i};
      end else begin
        cmd_accum <= {cmd_accum[5:0], mmc_cmd_i};
      end
    end
  end

  /* Piece together Accum + received data */
  assign cmd_rd = adv_mode == ADV_CMD_RD ? {cmd_accum, mmc_cmd_i} : {7'b0, mmc_cmd_i};

  reg [7:0] data_rd_reg;
  always @(*) begin
    if (adv_mode == ADV_DAT_RD) begin
      case (data_width)
        DW_1: begin
          data_rd_reg <= {data_accum[6:0], mmc_data_i[0]};
        end 
        DW_4: begin
          data_rd_reg <= {data_accum[3:0], mmc_data_i[3:0]};
        end 
        default: begin
          data_rd_reg <= mmc_data_i;
        end
      endcase
    end else begin
      data_rd_reg <= mmc_data_i;
    end
  end
  assign data_rd = data_rd_reg;


  /********* Clock Control *********/

  clk_ctrl clk_ctrl_inst(
    .clk     (wb_clk_i),
    .rst     (wb_rst_i),
    .width   (clk_width),
    .tick    (ctrl_state == CTRL_IDLE && (adv_cmd_rd || adv_cmd_wr || adv_dat_rd || adv_dat_wr || man_adv_en) || ctrl_state == CTRL_AUTO),
    .done    (clk_done),
    .mmc_clk (mmc_clk)
  );

  /************* IRQ Assignments ************/

  reg prev_cdetect;
  always @(posedge wb_clk_i) begin
    prev_cdetect <= mmc_cdetect;
  end

  assign irq_cdetect  = prev_cdetect != mmc_cdetect;
  assign irq_got_cmd  = auto_cmd_start;
  assign irq_got_dat  = auto_data_start;
  assign irq_got_busy = auto_busy;

endmodule
