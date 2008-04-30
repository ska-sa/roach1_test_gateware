`include "sys_block.vh"
module sys_block(
    //wb slave
    wb_clk_i, wb_rst_i,
    wb_we_i, wb_cyc_i, wb_stb_i, wb_sel_i,
    wb_adr_i, wb_dat_i, wb_dat_o,
    wb_ack_o, wb_toutsup_o
    , debug_clk, debug_we , debug
  );
  input debug_clk, debug_we;
  input [63:0] debug;
  parameter BOARD_ID  = 16'hdead;
  parameter REV_MAJOR = 16'haaaa;
  parameter REV_MINOR = 16'hbbbb;
  parameter REV_RCS   = 16'hcccc;

  input  wb_clk_i;
  input  wb_rst_i;
  input  wb_we_i;
  input  wb_cyc_i;
  input  wb_stb_i;
  input   [1:0] wb_sel_i;
  input  [31:0] wb_adr_i;
  input  [15:0] wb_dat_i;
  output [15:0] wb_dat_o;
  output wb_ack_o, wb_toutsup_o;
  assign wb_toutsup_o=1'b0;

  reg wb_ack_o;
  reg  [3:0] wb_dat_o_sel;
  reg [15:0] scratch_pad;

  wire [63:0] fifo_data;

  assign wb_dat_o = wb_dat_o_sel == `REG_BOARD_ID   ? BOARD_ID    :
                    wb_dat_o_sel == `REG_REV_MAJOR  ? REV_MAJOR   :
                    wb_dat_o_sel == `REG_REV_MINOR  ? REV_MINOR   :
                    wb_dat_o_sel == `REG_REV_RCS    ? REV_RCS     :
                    wb_dat_o_sel == `REG_SCRATCHPAD ? scratch_pad :
                    wb_dat_o_sel == `REG_SCRATCHPAD + 1 ? fifo_data[63:48] :
                    wb_dat_o_sel == `REG_SCRATCHPAD + 2 ? fifo_data[47:32] :
                    wb_dat_o_sel == `REG_SCRATCHPAD + 3 ? fifo_data[31:16] :
                    wb_dat_o_sel == `REG_SCRATCHPAD + 4 ? fifo_data[15:0] :
                    16'b0;
  reg fifo_rd_en;
  always @(posedge wb_clk_i) begin
    fifo_rd_en <= 1'b0;
    if (wb_rst_i) begin
      wb_ack_o<=1'b0;
    end else begin
      wb_ack_o<=1'b0;
      if (wb_cyc_i & wb_stb_i & ~wb_ack_o) begin
        wb_ack_o<=1'b1;
        wb_dat_o_sel <= wb_adr_i[4:1];

        case (wb_adr_i[4:1])
          `REG_BOARD_ID: begin
          end
          `REG_REV_MAJOR: begin
          end
          `REG_REV_MINOR: begin
          end
          `REG_REV_RCS: begin
          end
          `REG_SCRATCHPAD: begin
            if (wb_we_i) begin
              if (wb_sel_i[0])
                scratch_pad[7:0] <= wb_dat_i[7:0];
              if (wb_sel_i[1])
                scratch_pad[15:8] <= wb_dat_i[15:8];
            end
          end
          `REG_SCRATCHPAD + 1: begin
          end
          `REG_SCRATCHPAD + 2: begin
          end
          `REG_SCRATCHPAD + 3: begin
          end
          `REG_SCRATCHPAD + 4: begin
          end
          `REG_SCRATCHPAD + 5: begin
            fifo_rd_en <= 1'b1;
          end
        endcase
      end
    end
  end

  xaui_fifo xaui_fifo_fu(
    .rst(wb_rst_i), 
    .rd_clk(wb_clk_i),
    .dout(fifo_data),
    .rd_en(fifo_rd_en),
    .wr_clk(debug_clk),
    .din(debug),
    .wr_en(debug_we),
    .overflow(), .underflow(),
    .almost_full(), .almost_empty(),
    .full(), .empty()
  );




endmodule
