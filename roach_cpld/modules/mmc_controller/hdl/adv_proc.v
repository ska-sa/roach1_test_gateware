module adv_proc (
    input        clk,
    input        rst,

    input  [2:0] adv_mode,
    input        adv_en,
    output       adv_tick,
    output       adv_done,

    input  [1:0] data_width,

    input  [7:0] mmc_dat_i,
    input        mmc_cmd_i,
    output [7:0] dat_rd,
    output [7:0] cmd_rd,

    input  [7:0] bus_dat_i,
    input  [7:0] bus_cmd_i,
    output [7:0] dat_wr,
    output       cmd_wr,
    
    input        clk_done
  );

  localparam ADV_CMD_RD = 2'd0;
  localparam ADV_CMD_WR = 2'd1;
  localparam ADV_DAT_RD = 2'd2;
  localparam ADV_DAT_WR = 2'd3;

  localparam DW_1 = 2'd0;
  localparam DW_4 = 2'd1;
  localparam DW_8 = 2'd2;

  /* Write Logic */

  reg [2:0] wr_index;  
  reg wr_wait;

  always @(posedge clk) begin
    if (adv_done || rst) begin
      wr_index <= 3'd0;
      wr_wait <= 1'b0;
    end else begin
      if (adv_tick) begin
        wr_wait <= 1'b1;
        if (!wr_wait)
          wr_index <= wr_index + 1;
      end
      if (clk_done) begin
        wr_wait <= 1'b0;
      end
    end
  end

  /* TODO: hopefully synthesis will work this out */
  assign cmd_wr = bus_cmd_i >> (7 - wr_index);
  assign dat_wr = data_width == DW_1 ? bus_dat_i >> (7 - wr_index)                     :
                  data_width == DW_4 ? (wr_index[1] ? bus_dat_i[3:0] : bus_dat_i[7:4]) :
                                       bus_dat_i[7:0];

  /* Read Logic */

  reg [2:0] rd_index;  

  always @(posedge clk) begin
    if (adv_en || rst) begin
      rd_index <= 3'd0;
    end else begin
      if (clk_done) begin
        rd_index <= rd_index + 1;
      end
    end
  end

  reg [7:0] cmd_accum;
  reg [7:0] dat_accum;
  always @(posedge clk) begin
    cmd_accum[7 - rd_index] <= mmc_cmd_i;

    case (data_width)
      DW_1: begin
        dat_accum[7 - rd_index] <= mmc_dat_i[0];
      end
      default: begin
        if (rd_index[0]) begin
          dat_accum[6:3] <= mmc_dat_i[3:0];
        end
      end
    endcase
  end

  assign cmd_rd = {cmd_accum[6:0], mmc_cmd_i};
  assign dat_rd = data_width == DW_1 ? {dat_accum[6:0], mmc_dat_i[0:0]} :
                  data_width == DW_4 ? {dat_accum[6:3], mmc_dat_i[3:0]} :
                                       mmc_dat_i[7:0];


  assign adv_len  = adv_mode == ADV_CMD_WR || adv_mode == ADV_CMD_RD ||
                    adv_mode == ADV_DAT_RD && data_width == DW_1     ||
                    adv_mode == ADV_DAT_WR && data_width == DW_1       ? 3'b111 :
                    adv_mode == ADV_DAT_RD && data_width == DW_4     ||
                    adv_mode == ADV_DAT_WR && data_width == DW_4       ? 3'b001 :
                                                                         3'b0;

  assign adv_done = adv_len == rd_index;
  reg adv_busy;
  always @(posedge clk) begin
    if (adv_en) begin
      adv_busy <= 1'b1;
    end else if (adv_done) begin
      adv_busy <= 1'b0;
    end
  end

  assign adv_tick = adv_en || adv_busy && !adv_done;

endmodule
