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
    output        get_ready_en,
    input         get_ready_done,
    input         man_adv_done, 
    input         rd_dat_avail,

    output        dat_oe,
    output        cmd_oe,
    output  [7:0] dat_wr,
    output        cmd_wr,
    input   [7:0] dat_rd,
    input   [7:0] cmd_rd,

    input  [16*4-1:0] crc16,
    output            crc_rst,

    output        data_width,
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

  reg       data_width_reg;
  localparam DW_1 = 1'd0;
  localparam DW_4 = 1'd1;

  reg [1:0] clk_width_reg;
  localparam W_40M  = 0;
  localparam W_20M  = 1;
  localparam W_10M  = 2;
  localparam W_365K = 3;

  reg [1:0] mem_adv_mode_reg;
  localparam ADV_NONE     = 2'd0;
  localparam ADV_DAT_RD   = 2'd1;
  localparam ADV_DAT_WR   = 2'd2;

  reg       cmd_wr_reg;
  reg [7:0] dat_wr_reg;

  reg dat_oe_reg;
  reg cmd_oe_reg;

  reg get_ready_en_reg;

  reg [1:0] crc_sel;



  /****** Wishbone State Machine *******/

  wire wb_trans = wb_cyc_i & wb_stb_i;

  reg wb_state;
  localparam WB_IDLE     = 0;
  localparam WB_ADV_WAIT = 1;

  reg wb_ack_o_reg;

  always @(posedge wb_clk_i) begin
    wb_ack_o_reg <= 1'b0;
    if (wb_rst_i) begin
      wb_state   <= WB_IDLE;
    end else begin
      case (wb_state)
        WB_IDLE: begin
          if (wb_trans) begin
            if (mem_adv_en && !mem_adv_done) begin
              wb_state <= WB_ADV_WAIT;
            end else begin
              wb_ack_o_reg <= 1'b1;
            end
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

  assign wb_ack_o = wb_ack_o_reg || wb_state == WB_ADV_WAIT && mem_adv_done;

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
        wb_dat_reg <= {1'b0, get_ready_en, mem_adv_mode, 3'b0, rd_dat_avail};
      end
      REG_ADV: begin
        wb_dat_reg <= {7'b0, man_adv_done};
      end
      REG_CLK: begin
        wb_dat_reg <= {2'b0, dat_oe, cmd_oe, 1'b0, data_width, clk_width};
      end
      REG_CRC_DAT1: begin
        case (crc_sel)
          0: begin
            wb_dat_reg <= crc16[16*(0+1) - 1:16*0+8];
          end
          1: begin
            wb_dat_reg <= crc16[16*(1+1) - 1:16*1+8];
          end
          2: begin
            wb_dat_reg <= crc16[16*(2+1) - 1:16*2+8];
          end
          3: begin
            wb_dat_reg <= crc16[16*(3+1) - 1:16*3+8];
          end
        endcase
      end
      REG_CRC_DAT0: begin
        case (crc_sel)
          0: begin
            wb_dat_reg <= crc16[16*(0+1) - 8 - 1:16*0];
          end
          1: begin
            wb_dat_reg <= crc16[16*(1+1) - 8 - 1:16*1];
          end
          2: begin
            wb_dat_reg <= crc16[16*(2+1) - 8 - 1:16*2];
          end
          3: begin
            wb_dat_reg <= crc16[16*(3+1) - 8 - 1:16*3];
          end
        endcase
      end
      default: begin
        wb_dat_reg <= 8'b0;
      end
    endcase
  end
  assign wb_dat_o = wb_dat_reg;

  /****** Wishbone Reg Write *******/

  always @(posedge wb_clk_i) begin
    if (get_ready_done)
      get_ready_en_reg <= 1'b0;
    if (wb_rst_i) begin
      mem_adv_mode_reg <= 2'b0;
      data_width_reg   <= DW_1;
      clk_width_reg    <= 2'b11;
      dat_oe_reg       <= 1'b0;
      cmd_oe_reg       <= 1'b0;
      get_ready_en_reg <= 1'b0;
    end else begin
      if (wb_trans && wb_we_i) begin
        case (wb_adr_i)
          REG_CMD: begin
            cmd_wr_reg <= wb_dat_i[0];
          end
          REG_DAT: begin
            dat_wr_reg <= wb_dat_i;
          end
          REG_AUTO: begin
            mem_adv_mode_reg <= wb_dat_i[5:4];
            get_ready_en_reg <= wb_dat_i[6];
          end
          REG_ADV: begin
          end
          REG_CLK: begin
            dat_oe_reg     <= wb_dat_i[5];
            cmd_oe_reg     <= wb_dat_i[4];
            data_width_reg <= wb_dat_i[2];
            clk_width_reg  <= wb_dat_i[1:0];
          end
          REG_CRC_CMD: begin
            crc_sel <= wb_dat_i[5:4];
          end
          default: begin
          end
        endcase
      end
    end
  end

  /********* Assignments **********/
  assign get_ready_en = get_ready_en_reg;

  assign mem_adv_en = wb_trans && wb_adr_i == 3'd1 && (mem_adv_mode == 1 || mem_adv_mode == 2);

  assign mem_adv_mode = mem_adv_mode_reg;
  assign man_adv_en = wb_trans && wb_we_i && wb_adr_i == REG_ADV;
  assign crc_rst    = wb_trans && wb_we_i && wb_adr_i == REG_CRC_DAT1;

  assign dat_oe     = dat_oe_reg;
  assign cmd_oe     = cmd_oe_reg;
  assign dat_wr     = dat_wr_reg;
  assign cmd_wr     = cmd_wr_reg;
  assign data_width = data_width_reg;
  assign clk_width  = clk_width_reg;

endmodule
