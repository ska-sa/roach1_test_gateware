`define REG_DAT_O    3'd0
`define REG_DAT_I    3'd1
`define REG_CMD_O    3'd2
`define REG_CMD_I    3'd3
`define REG_OENS     3'd4
`define REG_STATUS   3'd5
`define REG_ADV_TYPE 3'd6
`define REG_ADV_MAN  3'd7

module mmc_bb(
    wb_clk_i, wb_rst_i,
    wb_stb_i, wb_cyc_i, wb_we_i,
    wb_adr_i, wb_dat_i, wb_dat_o,
    wb_ack_o,
    mmc_clk,
    mmc_cmd_o, mmc_cmd_i, mmc_cmd_oen,
    mmc_data_i, mmc_data_o, mmc_data_oen,
    mmc_cdetect, mmc_wp
  );
  input  wb_clk_i, wb_rst_i;
  input  wb_cyc_i, wb_stb_i, wb_we_i;
  input  [2:0] wb_adr_i;
  input  [7:0] wb_dat_i;
  output [7:0] wb_dat_o;
  output wb_ack_o;

  output mmc_clk;
  output mmc_cmd_o;
  input  mmc_cmd_i;
  output mmc_cmd_oen; //active high
  output [7:0] mmc_data_o;
  input  [7:0] mmc_data_i;
  output mmc_data_oen; //active high
  input  mmc_cdetect, mmc_wp;

  localparam ADV_MANUAL = 3'd0;
  localparam ADV_CMD_RD = 3'd1;
  localparam ADV_CMD_WR = 3'd2;
  localparam ADV_DAT_RD = 3'd3;
  localparam ADV_DAT_WR = 3'd4;

  reg [2:0] advance_type;

  reg cmd_i, cmd_o;
  reg cmd_oen;
  reg [7:0] data_o;
  reg [7:0] data_i;
  reg data_oen;
  reg ident_mode;

  wire mmc_clk;
  wire trans_done;

  assign mmc_cmd_oen  = cmd_oen;
  assign mmc_data_oen = data_oen;
  assign mmc_cmd_o    = cmd_o;
  assign mmc_data_o   = data_o;


  assign wb_dat_o = wb_adr_i == `REG_DAT_O    ? data_o :
                    wb_adr_i == `REG_DAT_I    ? mmc_data_i :
                    wb_adr_i == `REG_CMD_O    ? {7'b0, cmd_o} :
                    wb_adr_i == `REG_CMD_I    ? {7'b0, mmc_cmd_i} :
                    wb_adr_i == `REG_OENS     ? {3'b0, ident_mode, 2'b0, data_oen, cmd_oen} :
                    wb_adr_i == `REG_STATUS   ? {3'b0, trans_done, 2'b0, mmc_wp, mmc_cdetect} :
                    wb_adr_i == `REG_ADV_TYPE ? {5'b0, advance_type} :
                    wb_adr_i == `REG_ADV_MAN  ? 8'b0 :
                    8'b0;
  wire wb_trans = wb_stb_i & wb_cyc_i;

  wire advance = wb_trans &  wb_we_i & wb_adr_i == `REG_ADV_MAN ||
                 wb_trans &  wb_we_i & wb_adr_i == `REG_DAT_O & advance_type == ADV_DAT_WR ||
                 wb_trans & ~wb_we_i & wb_adr_i == `REG_DAT_I & advance_type == ADV_DAT_RD ||
                 wb_trans &  wb_we_i & wb_adr_i == `REG_CMD_O & advance_type == ADV_CMD_WR ||
                 wb_trans & ~wb_we_i & wb_adr_i == `REG_CMD_I & advance_type == ADV_CMD_RD;
  reg wb_ack_o;

  always @(posedge wb_clk_i) begin
    //strobes
    wb_ack_o <= 1'b1;

    if (wb_rst_i) begin
      advance_type <= ADV_MANUAL;
      cmd_oen <= 1'b0;
      data_oen <= 1'b0;
      data_o <= 8'b1111_1111;
      cmd_o <= 1'b1;
      ident_mode <= 1'b1;
    end else begin
      if (wb_trans)
        wb_ack_o <= 1'b1;

      if (wb_trans & wb_we_i) begin
        case (wb_adr_i)
          `REG_DAT_O: begin
            data_o <= wb_dat_i;
          end
          `REG_DAT_I: begin
          end
          `REG_CMD_O: begin
            cmd_o <= wb_dat_i[0];
          end
          `REG_CMD_I: begin
          end
          `REG_OENS: begin
            cmd_oen    <= wb_dat_i[0];
            data_oen   <= wb_dat_i[1];
            ident_mode <= wb_dat_i[4];
          end
          `REG_STATUS: begin
          end
          `REG_ADV_TYPE: begin
            advance_type <= wb_dat_i[2:0];
          end
          `REG_ADV_MAN: begin
          end
        endcase
      end
    end
  end

  reg [7:0] mmc_clk_counter;
  reg done;

  assign mmc_clk    = ident_mode ? mmc_clk_counter[7] : mmc_clk_counter[1];
  assign trans_done = mmc_clk_counter == 8'b0;

  always @(posedge wb_clk_i) begin
    if (wb_rst_i) begin
      mmc_clk_counter <= 8'b0;
      done <= 1'b1;
    end else begin
      if (mmc_clk_counter) begin
        mmc_clk_counter <= !ident_mode && mmc_clk_counter == 8'b11 ? 8'b00 : mmc_clk_counter + 1;
      end else if (advance) begin
        mmc_clk_counter <= 8'b1;
      end
    end
  end

endmodule
