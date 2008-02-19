`timescale 100ps/10ps
`include "level_checker.vh"

module level_checker(
    wb_clk_i, wb_rst_i,
    wb_stb_i, wb_cyc_i, wb_we_i,
    wb_adr_i, wb_dat_i, wb_dat_o,
    wb_ack_o,
    adc_result, adc_channel, adc_strb,
    soft_reset,
    soft_viol, hard_viol,
    v_in_range
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
  output [31:0] v_in_range;

  /************** Common Signals *****************/
  reg  hard_thresh_valid, soft_thresh_valid;
  wire thresh_sel_type; //level checker is checking hard or soft
  wire thresh_sel_pol;  //level checker is checking high or low
  wire wb_trans = wb_cyc_i & wb_stb_i & ~wb_ack_o;
  wire wb_ram   = wb_adr_i < 16'd128;

  wire  [6:0] ram_raddr;
  wire  [6:0] ram_waddr;
  wire [11:0] ram_rdata;
  wire [11:0] ram_wdata;
  wire ram_wen;

  assign ram_wen = wb_trans & wb_ram & wb_we_i;
  assign ram_waddr = wb_adr_i[6:0];
  assign ram_wdata = wb_dat_i[11:0];

  assign ram_wb_r = wb_trans & wb_ram & ~wb_we_i ; //the wishbone slave `takes` the ram read interface
  assign ram_raddr = ram_wb_r ? wb_adr_i[6:0] : {thresh_sel_type, adc_channel, thresh_sel_pol};

  /******************** WB Slave ********************/
  reg wb_ack_o;
  reg [3:0] wb_dat_o_src;

  reg  [5:0] soft_viol_source;
  reg [11:0] soft_viol_value;

  reg  [5:0] hard_viol_source;
  reg [11:0] hard_viol_value;

  assign wb_dat_o = wb_dat_o_src == 4'd0 ? ram_rdata :
                    wb_dat_o_src == 4'd1 ? {15'b0, soft_thresh_valid} :
                    wb_dat_o_src == 4'd2 ? {15'b0, hard_thresh_valid} :
                    wb_dat_o_src == 4'd3 ? {10'b0, soft_viol_source} :
                    wb_dat_o_src == 4'd4 ?  {4'b0, soft_viol_value} :
                    wb_dat_o_src == 4'd5 ? {10'b0, hard_viol_source} :
                    wb_dat_o_src == 4'd6 ?  {4'b0, hard_viol_value} :
                    wb_dat_o_src == 4'd7 ? v_in_range[15:0] :
                    wb_dat_o_src == 4'd8 ? v_in_range[31:16] :
                    16'b0;

  reg clear_soft_viol, clear_hard_viol;

  always @(posedge wb_clk_i) begin
    wb_ack_o <= 1'b0;
    clear_soft_viol <= 1'b0;
    clear_hard_viol <= 1'b0;

    if (soft_reset) begin
      soft_thresh_valid <= 1'b0;
    end

    if (wb_rst_i) begin
      soft_thresh_valid <= 1'b0;
      hard_thresh_valid <= 1'b0;
      soft_viol_source <= 6'b0;
      hard_viol_source <= 6'b0;
    end else if (wb_trans) begin
      wb_ack_o <= 1'b1;
      if (wb_ram) begin
        wb_dat_o_src <= 4'b0;
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
            clear_soft_viol <= 1'b0;
          end
          `REG_SOFT_VIOL_VALUE: begin
            wb_dat_o_src <= 4'd4;
          end
          `REG_HARD_VIOL_SOURCE: begin
            wb_dat_o_src <= 4'd5;
            clear_hard_viol <= 1'b0;
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

  always @(posedge wb_clk_i) begin
    soft_viol <= 1'b0;
    hard_viol <= 1'b0;
    if (clear_soft_viol)
      soft_viol_source <= 6'b0;
    if (clear_hard_viol)
      hard_viol_source <= 6'b0;
    wait_cycle <= 1'b0;

    if (wb_rst_i) begin
      v_in_range <= 32'b0;
      state <= STATE_IDLE;
      check_type <= 2'b00;
    end else begin
      case (state)
        STATE_IDLE: begin
          if (adc_strb) begin
            state <= STATE_CHECK;
            hard_viol_int <= 1'b0;
            soft_viol_int <= 1'b0;
            check_type <= 2'b0;
            wait_cycle <= 1'b1;
          end
        end
        STATE_CHECK: begin
          if (~ram_wb_r & ~wait_cycle) begin
            if (soft_thresh_valid & ~check_type[1]) begin
              soft_viol_int <= soft_viol_int | (check_type[0] ? ram_rdata < adc_result : ram_rdata > adc_result);
`ifdef DEBUG
              //$display("lc: chan = %b, check_type = %b, ram_raddr = %h, ram_rdata = %h, adc_result = %h", adc_channel, check_type, ram_raddr, ram_rdata, adc_result);
`endif
            end
            if (hard_thresh_valid & check_type[1]) begin
              hard_viol_int <= hard_viol_int |  (check_type[0] ? ram_rdata < adc_result : ram_rdata > adc_result);
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
            v_in_range[adc_channel] <= ~hard_viol_int;

          if (hard_viol_int) begin
`ifdef DEBUG
            //$display("lc: hard viol");
`endif
            if (~hard_viol_source[5]) begin
              hard_viol_source <= {1'b1, adc_channel};
              hard_viol_value <= adc_result;
            end
          end
          if (soft_viol_int) begin
`ifdef DEBUG
            //$display("lc: soft viol");
`endif
            if (~soft_viol_source[5]) begin
              soft_viol_source <= {1'b1, adc_channel};
              soft_viol_value <= adc_result;
            end
          end
          state <= STATE_IDLE;
        end
      endcase
    end
  end


  /* A single port ram is unfortunate as sharing is required, but is unwasteful
   * fusion archicture supports only 8 bit dual ports */

  wire [5:0] ram_rdata_nc;
  RAM512X18 RAM512X18_inst (
    .RESET(~wb_rst_i),
    /* Read Port */
    .RCLK(wb_clk_i), .REN(1'b0),
    .PIPE(1'b0), .RW1(1'b1), .RW0(1'b0), //non-pipelined, 256x18 mode
    .RADDR8(1'b0), .RADDR7(1'b0), .RADDR6(ram_raddr[6]), .RADDR5(ram_raddr[5]),
    .RADDR4(ram_raddr[4]), .RADDR3(ram_raddr[3]), .RADDR2(ram_raddr[2]), .RADDR1(ram_raddr[1]), .RADDR0(ram_raddr[0]),
    .RD17(ram_rdata_nc[5]), .RD16(ram_rdata_nc[4]), .RD15(ram_rdata_nc[3]),
    .RD14(ram_rdata_nc[2]), .RD13(ram_rdata_nc[1]), .RD12(ram_rdata_nc[0]),
    .RD11(ram_rdata[11]), .RD10(ram_rdata[10]), .RD9(ram_rdata[9]), .RD8(ram_rdata[8]), .RD7(ram_rdata[7]),.RD6(ram_rdata[6]),
    .RD5(ram_rdata[5]), .RD4(ram_rdata[4]), .RD3(ram_rdata[3]), .RD2(ram_rdata[2]), .RD1(ram_rdata[1]), .RD0(ram_rdata[0]),
    /* Write Port */
    .WCLK(wb_clk_i), .WEN(~ram_wen),
    .WW1(1'b1), .WW0(1'b0), // 256x18 mode
    .WADDR8(1'b0),.WADDR7(1'b0),.WADDR6(ram_waddr[6]),.WADDR5(ram_waddr[5]),
    .WADDR4(ram_waddr[4]),.WADDR3(ram_waddr[3]),.WADDR2(ram_waddr[2]),.WADDR1(ram_waddr[1]),.WADDR0(ram_waddr[0]),
    .WD17(1'b0), .WD16(1'b0), .WD15(1'b0), .WD14(1'b0), .WD13(1'b0), .WD12(1'b0),
    .WD11(ram_wdata[11]), .WD10(ram_wdata[10]), .WD9(ram_wdata[9]), .WD8(ram_wdata[8]), .WD7(ram_wdata[7]),.WD6(ram_wdata[6]),
    .WD5(ram_wdata[5]), .WD4(ram_wdata[4]), .WD3(ram_wdata[3]), .WD2(ram_wdata[2]), .WD1(ram_wdata[1]), .WD0(ram_wdata[0])
  );

endmodule
