`timescale 1ns/1ps
`define SIM_LENGTH 10000000
`define CLK_PERIOD 25

`define DEFAULT_VAL 12'h50

`define HARD_TH_L 12'hf
`define HARD_TH_H 12'hff

`define SOFT_TH_L 12'h1
`define SOFT_TH_H 12'h1ff

module TB_level_checker();
  wire clk;
  reg  reset;

  reg  wb_stb_i, wb_cyc_i, wb_we_i;
  reg  [15:0] wb_adr_i;
  reg  [15:0] wb_dat_i;
  wire [15:0] wb_dat_o;
  wire wb_ack_o;
 
  reg  adc_strb;
  reg   [4:0] adc_channel;
  reg  [11:0] adc_result;

  wire soft_viol, hard_viol;
  wire [31:0] v_in_range;

  wire  [6:0] ram_raddr;
  wire  [6:0] ram_waddr;
  wire [11:0] ram_rdata;
  wire [11:0] ram_wdata;
  wire ram_wen;

  level_checker level_checker(
    .wb_clk_i(clk), .wb_rst_i(reset),
    .wb_stb_i(wb_stb_i), .wb_cyc_i(wb_cyc_i), .wb_we_i(wb_we_i),
    .wb_adr_i(wb_adr_i), .wb_dat_i(wb_dat_i), .wb_dat_o(wb_dat_o),
    .wb_ack_o(wb_ack_o),
    .adc_result(adc_result), .adc_channel(adc_channel), .adc_strb(adc_strb),
    .soft_reset(1'b0),
    .hard_en(1'b1), .soft_en(1'b1),
    .soft_viol(soft_viol), .hard_viol(hard_viol),
    .v_in_range(v_in_range),
    .ram_raddr(ram_raddr), .ram_waddr(ram_waddr),
    .ram_rdata(ram_rdata), .ram_wdata(ram_wdata),
    .ram_wen(ram_wen)
  );

  reg [7:0] clk_counter;

  initial begin
    clk_counter<=8'b0;
    reset<=1'b1;
`ifdef DEBUG
    $display("sim: starting sim");
`endif
    #5
    reset<=1'b0;
`ifdef DEBUG
    $display("sim: clearing reset");
`endif
    #`SIM_LENGTH 
    $display("FAILED: simulation timed out");
    $finish;
  end

  assign clk = clk_counter < ((`CLK_PERIOD) / 2);

  always begin
    #1 clk_counter <= (clk_counter == `CLK_PERIOD - 1 ? 32'b0 : clk_counter + 1);
  end
  /*************** SRAM Block *************/
  /* A single port ram is unfortunate as sharing is required, but is unwasteful
   * fusion archicture supports only 8 bit dual ports */

  wire [5:0] ram_rdata_nc;
  RAM512X18 RAM512X18_inst (
    .RESET(~reset),
    /* Read Port */
    .RCLK(clk), .REN(1'b0),
    .PIPE(1'b0), .RW1(1'b1), .RW0(1'b0), //non-pipelined, 256x18 mode
    .RADDR8(1'b0), .RADDR7(1'b0), .RADDR6(ram_raddr[6]), .RADDR5(ram_raddr[5]),
    .RADDR4(ram_raddr[4]), .RADDR3(ram_raddr[3]), .RADDR2(ram_raddr[2]), .RADDR1(ram_raddr[1]), .RADDR0(ram_raddr[0]),
    .RD17(ram_rdata_nc[5]), .RD16(ram_rdata_nc[4]), .RD15(ram_rdata_nc[3]),
    .RD14(ram_rdata_nc[2]), .RD13(ram_rdata_nc[1]), .RD12(ram_rdata_nc[0]),
    .RD11(ram_rdata[11]), .RD10(ram_rdata[10]), .RD9(ram_rdata[9]), .RD8(ram_rdata[8]), .RD7(ram_rdata[7]),.RD6(ram_rdata[6]),
    .RD5(ram_rdata[5]), .RD4(ram_rdata[4]), .RD3(ram_rdata[3]), .RD2(ram_rdata[2]), .RD1(ram_rdata[1]), .RD0(ram_rdata[0]),
    /* Write Port */
    .WCLK(clk), .WEN(~ram_wen),
    .WW1(1'b1), .WW0(1'b0), // 256x18 mode
    .WADDR8(1'b0),.WADDR7(1'b0),.WADDR6(ram_waddr[6]),.WADDR5(ram_waddr[5]),
    .WADDR4(ram_waddr[4]),.WADDR3(ram_waddr[3]),.WADDR2(ram_waddr[2]),.WADDR1(ram_waddr[1]),.WADDR0(ram_waddr[0]),
    .WD17(1'b0), .WD16(1'b0), .WD15(1'b0), .WD14(1'b0), .WD13(1'b0), .WD12(1'b0),
    .WD11(ram_wdata[11]), .WD10(ram_wdata[10]), .WD9(ram_wdata[9]), .WD8(ram_wdata[8]), .WD7(ram_wdata[7]),.WD6(ram_wdata[6]),
    .WD5(ram_wdata[5]), .WD4(ram_wdata[4]), .WD3(ram_wdata[3]), .WD2(ram_wdata[2]), .WD1(ram_wdata[1]), .WD0(ram_wdata[0])
  );

  /***************** Mode Control *****************/
  reg [2:0] mode;
  `define MODE_SETUP          3'd0
  `define MODE_SOFT_VIOL_HIGH 3'd1
  `define MODE_SOFT_VIOL_LOW  3'd2
  `define MODE_HARD_VIOL_HIGH 3'd3
  `define MODE_HARD_VIOL_LOW  3'd4
  `define MODE_CHECK          3'd5
  `define MODE_PROCESS        3'd6
  `define MODE_WBCHECK        3'd7

  reg [4:0] mode_chan;

  reg [3:0] mode_advance;

  reg expect_hard, expect_soft;

  reg [31:0] mode_timer;
  reg [31:0] mode_progress;

  reg [15:0] wbm_mem [15:0];

  always @(posedge clk) begin
    if (reset) begin
    end else begin
      if ((hard_viol | soft_viol) & mode != `MODE_CHECK) begin
        $display("FAILED: unexpected viol strb");
        $finish;
      end
    end
  end

  always @(posedge clk) begin
    if (reset) begin
      mode <= `MODE_SETUP;
      mode_progress <= 32'b0;
    end else begin
      case (mode)
        `MODE_SETUP: begin
          if (mode_advance[1]) begin
            mode <= `MODE_PROCESS;
`ifdef DEBUG
          $display("mode: mode setup done");
`endif
          end
        end
        `MODE_SOFT_VIOL_HIGH: begin
          if (mode_advance[0]) begin
            expect_soft <= 1'b1;
            mode_timer <= 32'd20;
            mode <= `MODE_CHECK;
          end
        end
        `MODE_HARD_VIOL_HIGH: begin
          if (mode_advance[0]) begin
            expect_hard <= 1'b1;
            mode_timer <= 32'd20;
            mode <= `MODE_CHECK;
          end
        end
        `MODE_SOFT_VIOL_LOW: begin
          if (mode_advance[0]) begin
            expect_soft <= 1'b1;
            mode_timer <= 32'd20;
            mode <= `MODE_CHECK;
          end
        end
        `MODE_HARD_VIOL_LOW: begin
          if (mode_advance[0]) begin
            expect_hard <= 1'b1;
            mode_timer <= 32'd20;
            mode <= `MODE_CHECK;
          end
        end
        `MODE_CHECK: begin
          if (mode_timer == 0) begin
            $display("FAILED: mode timeout");
            $finish;
          end else begin
            mode_timer <= mode_timer - 1;
          end

          if (soft_viol) begin
            if (expect_soft) begin
              mode <= `MODE_PROCESS;
            end
          end
          if (hard_viol) begin
            if (expect_hard) begin
              mode <= `MODE_PROCESS;
            end
          end
        end
        `MODE_PROCESS: begin
          expect_hard <= 1'b0;
          expect_soft <= 1'b0;
          case (mode_progress[1:0])
            2'd0: begin
              mode<=`MODE_HARD_VIOL_LOW;
            end
            2'd1: begin
              mode<=`MODE_SOFT_VIOL_LOW;
            end
            2'd2: begin
              mode<=`MODE_HARD_VIOL_HIGH;
            end
            2'd3: begin
              mode<=`MODE_SOFT_VIOL_HIGH;
            end
          endcase
          mode_chan <= mode_progress[6:2];
          mode_progress <= mode_progress + 1;
          if (mode_progress >= 127) begin
            mode <= `MODE_WBCHECK;
          end
        end
        `MODE_WBCHECK: begin
          if (mode_advance[1]) begin
            if (wbm_mem[0] === `SOFT_TH_L && wbm_mem[1] === `SOFT_TH_H &&
                wbm_mem[2] === `HARD_TH_L && wbm_mem[3] === `HARD_TH_H) begin
              $display("PASSED");
              $finish;
            end else begin
              $display("FAILED: invalid data on wbm readback");
              $finish;
            end
          end
        end
      endcase
    end
  end

  /***************** Simulated ADC ******************/
  reg [31:0] adc_timer;

  reg send_once;
  always @(posedge clk) begin
    mode_advance[0] <= 1'b0;
    adc_strb <= 1'b0;
    if (reset) begin
      adc_channel <= 5'b0;
      adc_timer <= 32'b0;
    end else begin
      if (adc_timer == 32'b0) begin
        if (mode_chan != (adc_channel +1)%32) begin
          adc_result <= `DEFAULT_VAL;
        end else begin
          case (mode)
            `MODE_SOFT_VIOL_LOW: begin
              adc_result <= `SOFT_TH_L - 1;
              mode_advance[0] <= 1'b1;
`ifdef DEBUG
              $display("adc: soft viol l");
`endif
            end
            `MODE_SOFT_VIOL_HIGH: begin
              adc_result <= `SOFT_TH_H + 1;
              mode_advance[0] <= 1'b1;
`ifdef DEBUG
              $display("adc: soft viol h");
`endif
            end
            `MODE_HARD_VIOL_LOW: begin
              adc_result <= `HARD_TH_L - 1;
              mode_advance[0] <= 1'b1;
`ifdef DEBUG
              $display("adc: hard viol l");
`endif
            end
            `MODE_HARD_VIOL_HIGH: begin
              adc_result <= `HARD_TH_H + 1;
              mode_advance[0] <= 1'b1;
`ifdef DEBUG
              $display("adc: hard viol h");
`endif
            end
            default: begin
              adc_result <= `DEFAULT_VAL;
            end
          endcase
        end
        adc_channel <= adc_channel + 1;
        adc_strb <= 1'b1;
        adc_timer <= 32'd50; // the real value would be larger
      end else begin
        adc_timer <= adc_timer - 1;
      end
    end
  end

  /***************** Simulated WBM ******************/

  reg [1:0] wbm_state;
`define STATE_COMMAND 2'd0
`define STATE_COLLECT 2'd1
`define STATE_WAIT    2'd2

  reg [31:0] wbm_progress;

  always @(posedge clk) begin
    wb_cyc_i <= 1'b0;
    wb_stb_i <= 1'b0;
    mode_advance[1] <= 1'b0;

    if (reset) begin
      wbm_state <= `STATE_COMMAND;
      wbm_progress <= 32'b0;
    end else begin
      case (wbm_state)
        `STATE_COMMAND: begin
          case (mode)
            `MODE_SETUP: begin
              wb_cyc_i <= 1'b1;
              wb_stb_i <= 1'b1;
              wb_we_i  <= 1'b1;
              wb_adr_i <= wbm_progress[15:0];
              wbm_state <= `STATE_COLLECT;
              if (wbm_progress < 128) begin
                wb_dat_i <= wbm_progress[6] ? (wbm_progress[0] ? `HARD_TH_H : `HARD_TH_L) : (wbm_progress[0] ? `SOFT_TH_H : `SOFT_TH_L);
`ifdef DEBUG
              $display("wbm: write addr = %h, data = %h", wbm_progress, wbm_progress[6] ? (wbm_progress[0] ? `HARD_TH_H : `HARD_TH_L) : (wbm_progress[0] ? `SOFT_TH_H : `SOFT_TH_L));
`endif
              end else if (wbm_progress == 128) begin
                wb_dat_i <= 16'b1;
`ifdef DEBUG
              $display("wbm: write addr = %h, data = %h", wbm_progress, 1'b1);
`endif
              end else if (wbm_progress == 129) begin
                wb_dat_i <= 16'b1;
`ifdef DEBUG
              $display("wbm: write addr = %h, data = %h", wbm_progress, 1'b1);
`endif
              end else begin
                $display("FAILED: this should not happen");
                $finish;
              end
            end
            `MODE_WBCHECK: begin
              wb_cyc_i <= 1'b1;
              wb_stb_i <= 1'b1;
              wb_we_i  <= 1'b0;
              case (wbm_progress)
                0: wb_adr_i <= 16'h0;
                1: wb_adr_i <= 16'h1;
                2: wb_adr_i <= 16'h40;
                3: wb_adr_i <= 16'h41;
              endcase
              wbm_state <= `STATE_COLLECT;
`ifdef DEBUG
              $display("wbm: read");
`endif
            end
          endcase
        end
        `STATE_COLLECT: begin
          if (wb_ack_o) begin
            case (mode)
              `MODE_SETUP: begin
                if (wbm_progress == 129) begin
                  wbm_progress <= 32'b0;
                  mode_advance[1] <= 1'b1;
                  wbm_state <= `STATE_WAIT;
                end else begin
                  wbm_progress <= wbm_progress + 1;
                  wbm_state <= `STATE_COMMAND;
                end
`ifdef DEBUG
            $display("wbm: got ack");
`endif
              end
              `MODE_WBCHECK: begin
                wbm_mem[wbm_progress[3:0]] <= wb_dat_o;
                if (wbm_progress == 3) begin
                  wbm_progress <= 32'b0;
                  mode_advance[1] <= 1'b1;
                  wbm_state <= `STATE_WAIT;
                end else begin
                  wbm_progress <= wbm_progress + 1;
                  wbm_state <= `STATE_COMMAND;
                end
`ifdef DEBUG
            $display("wbm: got ack, adr = %x, data = %x", wb_adr_i, wb_dat_o);
`endif
              end
              default: begin
                $display("FAILED: invalid state");
                $finish;
              end
            endcase

          end
        end
        `STATE_WAIT: begin
           wbm_state <= `STATE_COMMAND;
        end
      endcase
    end
  end 
   
endmodule
