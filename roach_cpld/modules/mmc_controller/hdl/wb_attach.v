module wb_attach(
    input         wb_clk_i,
    input         wb_rst_i,
    input         wb_cyc_i,
    input         wb_stb_i,
    input         wb_we_i,
    input   [2:0] wb_adr_i,
    input   [7:0] wb_dat_i,
    output  [7:0] wb_dat_o,
    output        wb_ack_o,

    output  [1:0] mem_adv_mode,
    output        mem_adv_en, 
    input         mem_adv_done, 
    output        man_adv_en, 
    input         man_adv_done, 

    output        dat_oe,
    output        cmd_oe,
    output  [7:0] dat_wr,
    output        cmd_wr,
    input   [7:0] dat_rd,
    input   [7:0] cmd_rd,

    output  [1:0] auto_mode,
    input         auto_done,

    input   [6:0] crc7,
    input  [15:0] crc16,
    output        crc16_dvld,
    output        crc_rst,

    output  [1:0] data_width,
    output  [1:0] clk_width
  );

  /********** Register Map *************/

  localparam REG_CMD      = 3'd0;
  localparam REG_DAT      = 3'd1;
  localparam REG_AUTO     = 3'd2;
  localparam REG_ADV      = 3'd3;
  localparam REG_CLK      = 3'd4;
  localparam REG_CRC_CMD  = 3'd5;
  localparam REG_CRC_DAT1 = 3'd6;
  localparam REG_CRC_DAT0 = 3'd7;

  /****** Configuration Registers ******/

  reg [1:0] data_width_reg;
  localparam DW_1 = 2'd0;
  localparam DW_4 = 2'd1;
  localparam DW_8 = 2'd2;

  reg [1:0] clk_width_reg;
  localparam W_40M  = 0;
  localparam W_20M  = 1;
  localparam W_10M  = 2;
  localparam W_365K = 3;

  reg [2:0] mem_adv_mode_reg;
  localparam ADV_CMD_RD   = 2'd0;
  localparam ADV_CMD_WR   = 2'd1;
  localparam ADV_DAT_RD   = 2'd2;
  localparam ADV_DAT_WR   = 2'd3;

  reg       cmd_wr_reg;
  reg [7:0] dat_wr_reg;

  reg [1:0] auto_mode_reg;
  localparam AUTO_NONE      = 0;
  localparam AUTO_CMD_START = 1;
  localparam AUTO_DAT_START = 2;
  localparam AUTO_BUSY      = 3;

  reg dat_oe_reg;
  reg cmd_oe_reg;

  /****** Wishbone State Machine *******/

  assign wb_trans = wb_cyc_i & wb_stb_i;

  reg wb_state;
  localparam WB_IDLE     = 0;
  localparam WB_ADV_WAIT = 1;

  reg wb_ack_reg;

  always @(posedge wb_clk_i) begin
    wb_ack_reg <= 1'b0;

    if (wb_rst_i) begin
      wb_state   <= WB_IDLE;
    end else begin
      case (wb_state)
        WB_IDLE: begin
          if (mem_adv_en) begin
            wb_state <= WB_ADV_WAIT;
          end else if (wb_trans) begin
            wb_ack_reg <= 1'b1;
          end
        end
        WB_ADV_WAIT: begin
          if (mem_adv_done) begin
            wb_state   <= WB_IDLE;
          end
        end
      endcase
    end
  end
  assign wb_ack_o = wb_state == WB_IDLE ? wb_ack_reg : mem_adv_done;

  /****** Wishbone Reg Read *******/

  reg [7:0] wb_dat_reg;
  always @(*) begin
    case (wb_adr_i)
      REG_CMD: begin
        wb_dat_reg <= cmd_rd;
      end
      REG_DAT: begin
        wb_dat_reg <= dat_rd;
      end
      REG_AUTO: begin
        wb_dat_reg <= {1'b0, mem_adv_mode, 2'b0, auto_mode};
      end
      REG_ADV: begin
        wb_dat_reg <= {7'b0, man_adv_done};
      end
      REG_CLK: begin
        wb_dat_reg <= {2'b0, dat_oe, cmd_oe, data_width, clk_width};
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

  /****** Wishbone Reg Write *******/

  always @(posedge wb_clk_i) begin
    if (wb_rst_i) begin
      data_width_reg <= DW_1;
      clk_width_reg  <= 2'b11;
      dat_oe_reg     <= 1'b0;
      cmd_oe_reg     <= 1'b0;
      auto_mode_reg  <= AUTO_NONE;
    end else begin
      if (auto_done) begin
        auto_mode_reg <= AUTO_NONE;
      end
      if (wb_trans && wb_we_i) begin
        case (wb_adr_i)
          REG_CMD: begin
            cmd_wr_reg     <= wb_dat_i[0];
          end
          REG_DAT: begin
            dat_wr_reg    <= wb_dat_i;
          end
          REG_AUTO: begin
            mem_adv_mode_reg   <= wb_dat_i[6:4];
            auto_mode_reg  <= wb_dat_i[1:0];
          end
          REG_ADV: begin
          end
          REG_CLK: begin
            dat_oe_reg     <= wb_dat_i[5];
            cmd_oe_reg     <= wb_dat_i[4];
            data_width_reg <= wb_dat_i[3:2];
            clk_width_reg  <= wb_dat_i[1:0];
          end
          default: begin
          end
        endcase
      end
    end
  end

  /********* Assignments **********/

  assign mem_adv_en = wb_trans && mem_adv_mode_reg[2] && wb_adr_i[2:1] == 2'd0 && {wb_adr_i[0], wb_we_i} == mem_adv_mode_reg[1:0];

  assign mem_adv_mode   = mem_adv_mode_reg[1:0];
  assign man_adv_en = wb_trans && wb_we_i && wb_adr_i == REG_ADV;
  assign crc_rst    = wb_trans && wb_we_i && wb_adr_i == REG_CRC_CMD;

  assign dat_oe     = dat_oe_reg;
  assign cmd_oe     = cmd_oe_reg;
  assign dat_wr     = dat_wr_reg;
  assign cmd_wr     = cmd_wr_reg;
  assign auto_mode  = auto_mode_reg;
  assign data_width = data_width_reg;
  assign clk_width  = clk_width_reg;

  assign crc16_dvld = wb_trans && wb_we_i && wb_adr_i == REG_DAT;




endmodule
