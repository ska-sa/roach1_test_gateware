`timescale 100ps/10ps
`include "level_checker.vh"

module level_checker(
    wb_clk_i, wb_rst_i,
    wb_stb_i, wb_cyc_i, wb_we_i,
    wb_adr_i, wb_dat_i, wb_dat_o,
    wb_ack_o,
    adc_result, adc_channel, adc_strb,
    soft_reset,
    soft_en, hard_en,
    soft_viol, hard_viol,
    v_in_range,
    ram_raddr, ram_waddr,
    ram_rdata, ram_wdata,
    ram_wen
  );
  input  wb_clk_i, wb_rst_i;
  input  wb_stb_i, wb_cyc_i, wb_we_i;
  input  [15:0] wb_adr_i;
  input  [15:0] wb_dat_i;
  output [15:0] wb_dat_o;
  output wb_ack_o;
 
  input  adc_strb;
  input   [4:0] adc_channel;
  input  [11:0] adc_result;

  input  soft_reset;
  output soft_viol, hard_viol;
  input  soft_en, hard_en;
  output [31:0] v_in_range;

  output  [6:0] ram_raddr;
  output  [6:0] ram_waddr;
  input  [11:0] ram_rdata;
  output [11:0] ram_wdata;
  output ram_wen;

  /************** Common Signals *****************/
  reg  hard_thresh_valid, soft_thresh_valid;
  wire [4:0] adc_channel_src;
  wire thresh_sel_type; //level checker is checking hard or soft
  wire thresh_sel_pol;  //level checker is checking high or low
  wire wb_trans = wb_cyc_i & wb_stb_i & ~wb_ack_o;
  wire wb_ram   = wb_adr_i < 16'd128;

  assign ram_wen = wb_trans & wb_ram & wb_we_i;
  assign ram_waddr = wb_adr_i[6:0];
  assign ram_wdata = wb_dat_i[11:0];

  reg bus_wait;

  assign ram_wb_r = wb_trans & wb_ram & ~wb_we_i | bus_wait; //the wishbone slave `takes` the ram read interface
  assign ram_raddr = ram_wb_r ? wb_adr_i[6:0] : {thresh_sel_type, adc_channel_src, thresh_sel_pol};

  /******************** WB Slave ********************/
  reg wb_ack_o;
  reg [3:0] wb_dat_o_src;

  reg  [4:0] soft_viol_source;
  reg [11:0] soft_viol_value;

  reg  [4:0] hard_viol_source;
  reg [11:0] hard_viol_value;

  reg [15:0] crash_counter;

  reg soft_ack;
  reg hard_ack;

  assign wb_dat_o = wb_dat_o_src == 4'd0 ? ram_rdata :
                    wb_dat_o_src == 4'd1 ? {15'b0, soft_thresh_valid} :
                    wb_dat_o_src == 4'd2 ? {15'b0, hard_thresh_valid} :
                    wb_dat_o_src == 4'd3 ? {11'b0, soft_viol_source} :
                    wb_dat_o_src == 4'd4 ?  {4'b0, soft_viol_value} :
                    wb_dat_o_src == 4'd5 ? {11'b0, hard_viol_source} :
                    wb_dat_o_src == 4'd6 ?  {4'b0, hard_viol_value} :
                    wb_dat_o_src == 4'd7 ? v_in_range[15:0] :
                    wb_dat_o_src == 4'd8 ? v_in_range[31:16] :
                    wb_dat_o_src == 4'd9 ? crash_counter :
                    16'b0;

  always @(posedge wb_clk_i) begin
    bus_wait <= 1'b0;
    wb_ack_o <= 1'b0;
    hard_ack <= 1'b0;
    soft_ack <= 1'b0;

    if (soft_reset) begin
      soft_thresh_valid <= 1'b0;
      soft_ack <= 1'b1;
    end

    if (wb_rst_i) begin
      soft_thresh_valid <= 1'b0;
      hard_thresh_valid <= 1'b0;
    end else if (wb_trans) begin
      wb_ack_o <= 1'b1;
      if (wb_ram) begin
        wb_dat_o_src <= 4'b0;
        bus_wait <= 1'b1;
      end else begin
        case (wb_adr_i)
          `REG_SOFT_THRESH_VALID: begin
            wb_dat_o_src <= 4'd1;
            if (wb_we_i) begin
              soft_thresh_valid <= wb_dat_i[0];
            end
          end
          `REG_HARD_THRESH_VALID: begin
            wb_dat_o_src <= 4'd2;
            if (wb_we_i) begin
              hard_thresh_valid <= wb_dat_i[0];
            end
          end
          `REG_SOFT_VIOL_SOURCE: begin
            wb_dat_o_src <= 4'd3;
            soft_ack <= 1'b1;
          end
          `REG_SOFT_VIOL_VALUE: begin
            wb_dat_o_src <= 4'd4;
          end
          `REG_HARD_VIOL_SOURCE: begin
            wb_dat_o_src <= 4'd5;
            hard_ack <= 1'b1;
          end
          `REG_HARD_VIOL_VALUE: begin
            wb_dat_o_src <= 4'd6;
          end
          `REG_VINRANGE_0: begin
            wb_dat_o_src <= 4'd7;
          end
          `REG_VINRANGE_1: begin
            wb_dat_o_src <= 4'd8;
          end
          default : begin
            wb_dat_o_src <= 4'd9;
          end
        endcase
      end
    end
  end

  /******************** Level Checker *********************/

  reg [1:0] state;
  localparam STATE_IDLE  = 0;
  localparam STATE_CHECK = 1;
  localparam STATE_SEND  = 2;

  reg [1:0] check_type;

  reg soft_viol_int;
  reg hard_viol_int;
  reg soft_viol, hard_viol;

  reg [31:0] v_in_range;

  assign thresh_sel_type = check_type[1];
  assign thresh_sel_pol  = check_type[0];

  reg wait_cycle;
  reg [11:0] adc_result_reg;
  reg  [4:0] adc_channel_reg;
  assign adc_channel_src = adc_channel_reg;

  reg hard_lock, soft_lock;

  always @(posedge wb_clk_i) begin
    soft_viol <= 1'b0;
    hard_viol <= 1'b0;
    wait_cycle <= 1'b0;
    if (soft_reset)
      soft_lock <= 1'b0;

    if (wb_rst_i) begin
      v_in_range <= 32'b0;
      state <= STATE_IDLE;
      check_type <= 2'b00;
      adc_result_reg  <= 12'b0;
      adc_channel_reg <= 5'b0;
      hard_lock <= 1'b0;
      soft_lock <= 1'b0;
    end else begin
      case (state)
        STATE_IDLE: begin
          if (adc_strb) begin
            state <= STATE_CHECK;
            hard_viol_int <= 1'b0;
            soft_viol_int <= 1'b0;
            check_type <= 2'b0;
            wait_cycle <= 1'b1;
            adc_result_reg  <= adc_result;
            adc_channel_reg <= adc_channel;
          end
        end
        STATE_CHECK: begin
          if (!ram_wb_r && !wait_cycle) begin
            if (soft_thresh_valid && !check_type[1]) begin
              soft_viol_int <= soft_viol_int | (check_type[0] ? ram_rdata < adc_result_reg : ram_rdata > adc_result_reg);
`ifdef DEBUG
              //$display("lc: chan = %b, check_type = %b, ram_raddr = %h, ram_rdata = %h, adc_result_reg = %h", adc_channel, check_type, ram_raddr, ram_rdata, adc_result_reg);
`endif
            end
            if (hard_thresh_valid && check_type[1]) begin
              hard_viol_int <= hard_viol_int |  (check_type[0] ? ram_rdata < adc_result_reg : ram_rdata > adc_result_reg);
`ifdef DEBUG
              //$display("lc: chan = %b, check_type = %b, ram_raddr = %h, ram_rdata = %h, adc_result = %h", adc_channel, check_type, ram_raddr, ram_rdata, adc_result);
`endif
            end
            if (check_type == 2'b11) begin
              state <= STATE_SEND;
            end else begin
              check_type <= check_type + 1;
              wait_cycle <= 1'b1;
            end
          end
        end
        STATE_SEND: begin
          soft_viol <= soft_viol_int;
          hard_viol <= hard_viol_int;
          if (hard_thresh_valid)
            v_in_range[adc_channel_reg] <= ~hard_viol_int;

          if (hard_viol_int && !hard_lock && hard_en) begin
`ifdef DEBUG
            //$display("lc: hard viol");
`endif
            hard_viol_source <= adc_channel_reg;
            hard_viol_value <= adc_result_reg;
            crash_counter <= crash_counter + 1;
            hard_lock <= 1'b1;
          end
          if (soft_viol_int && !soft_lock && soft_en) begin
`ifdef DEBUG
            //$display("lc: soft viol");
`endif
            soft_viol_source <= adc_channel_reg;
            soft_viol_value <= adc_result_reg;
          end
          state <= STATE_IDLE;
        end
      endcase
      if (hard_ack)
        hard_lock <= 1'b0;
      if (soft_ack)
        soft_lock <= 1'b0;
    end
  end



endmodule
