`define REG_DAT_O    3'd0
`define REG_DAT_I    3'd1
`define REG_CMD_O    3'd2
`define REG_CMD_I    3'd3
`define REG_OENS     3'd4
`define REG_STATUS   3'd5
`define REG_ADV_TYPE 3'd6
`define REG_ADV_MAN  3'd7

module mmc_bb(
    lb_clk, lb_rst,
    lb_we_i, lb_stb_i,
    lb_adr_i, lb_dat_i, lb_dat_o,
    mmc_clk,
    mmc_cmd_o, mmc_cmd_i, mmc_cmd_oen,
    mmc_data_i, mmc_data_o, mmc_data_oen,
    mmc_cdetect, mmc_wp
  );
  input  lb_clk, lb_rst;
  input  lb_we_i, lb_stb_i;
  input  [2:0] lb_adr_i;
  input  [7:0] lb_dat_i;
  output [7:0] lb_dat_o;

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

  wire mmc_clk;
  wire trans_done;

  assign mmc_cmd_oen  = cmd_oen;
  assign mmc_data_oen = data_oen;
  assign mmc_cmd_o    = cmd_o;
  assign mmc_data_o   = data_o;

  assign lb_dat_o = lb_adr_i == `REG_DAT_O    ? data_o :
                    lb_adr_i == `REG_DAT_I    ? data_i :
                    lb_adr_i == `REG_CMD_O    ? {7'b0, cmd_o} :
                    lb_adr_i == `REG_CMD_I    ? {7'b0, cmd_i} :
                    lb_adr_i == `REG_OENS     ? {6'b0, data_oen, cmd_oen} :
                    lb_adr_i == `REG_STATUS   ? {3'b0, trans_done, 2'b0, mmc_wp, mmc_cdetect} :
                    lb_adr_i == `REG_ADV_TYPE ? {5'b0, advance_type} :
                    lb_adr_i == `REG_ADV_MAN  ? 8'b0 :
                    8'b0;

  wire advance = lb_stb_i &  lb_we_i & lb_adr_i == `REG_ADV_MAN ||
                 lb_stb_i &  lb_we_i & lb_adr_i == `REG_DAT_O & advance_type == ADV_DAT_WR ||
                 lb_stb_i & ~lb_we_i & lb_adr_i == `REG_DAT_I & advance_type == ADV_DAT_RD ||
                 lb_stb_i &  lb_we_i & lb_adr_i == `REG_CMD_O & advance_type == ADV_CMD_WR ||
                 lb_stb_i & ~lb_we_i & lb_adr_i == `REG_CMD_I & advance_type == ADV_CMD_RD;

  always @(posedge lb_clk) begin
    if (lb_rst) begin
      advance_type <= ADV_MANUAL;
      cmd_oen <= 1'b0;
      data_oen <= 1'b0;
      data_o <= 8'b1111_1111;
      cmd_o <= 1'b1;
    end else begin
      if (lb_stb_i & lb_we_i) begin
        case (lb_adr_i)
          `REG_DAT_O: begin
            data_o <= lb_dat_i;
          end
          `REG_DAT_I: begin
          end
          `REG_CMD_O: begin
            cmd_o <= lb_dat_i[0];
          end
          `REG_CMD_I: begin
          end
          `REG_OENS: begin
            cmd_oen <= lb_dat_i[0];
            data_oen <= lb_dat_i[1];
          end
          `REG_STATUS: begin
          end
          `REG_ADV_TYPE: begin
            advance_type <= lb_dat_i[2:0];
          end
          `REG_ADV_MAN: begin
          end
        endcase
      end
    end
  end

  reg [1:0] mmc_clk_counter;

  assign mmc_clk = ~mmc_clk_counter[1];
  assign trans_done = mmc_clk_counter == 2'b0;

  always @(posedge lb_clk) begin
    if (lb_rst) begin
      mmc_clk_counter <= 2'b0;
    end else begin
      if (mmc_clk_counter) begin
        mmc_clk_counter <= mmc_clk_counter - 1;
      end else if (advance) begin
        mmc_clk_counter <= 2'b11;
      end
    end
  end

  always @(posedge lb_clk) begin
    if (mmc_clk_counter == 2'b1) begin //cycle after rising edge
      data_i <= mmc_data_i;
      cmd_i <= mmc_cmd_i;
    end
  end

endmodule
