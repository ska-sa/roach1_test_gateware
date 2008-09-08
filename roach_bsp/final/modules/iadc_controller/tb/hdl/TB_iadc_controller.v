`include "iadc_controller.vh"

`timescale 1ns/10ps

`define SIMLENGTH 80000
`define CLK_PERIOD 10

`define TEST_CTRL_ADDRESS  3'b110
`define TEST_CTRL_DATA    16'hdead

module TB_iadc_controller();


  /*********************** DUT ********************/
  reg reset;
  wire clk;

  reg  wb_cyc_i, wb_stb_i, wb_we_i;
  reg  [31:0] wb_adr_i;
  reg  [15:0] wb_dat_i;
  wire [15:0] wb_dat_o;
  wire wb_ack_o;

  wire adc_clk_0, adc_clk_90;
  wire [63:0] adc_data;
  wire adc_sync;
  wire [3:0] adc_outofrange;
  wire adc_ctrl_clk, adc_ctrl_data, adc_ctrl_strobe_n;
  wire adc_mode, adc_ddrb;

  iadc_controller iadc_controller_inst(
    .wb_clk_i(clk), .wb_rst_i(reset),
    .wb_cyc_i(wb_cyc_i), .wb_stb_i(wb_stb_i), .wb_we_i(wb_we_i), .wb_sel_i(2'b11),
    .wb_adr_i(wb_adr_i), .wb_dat_i(wb_dat_i), .wb_dat_o(wb_dat_o),
    .wb_ack_o(wb_ack_o),

    .adc_clk_0(adc_clk_0), .adc_clk_90(adc_clk_90),
    .adc_data(adc_data),
    .adc_sync(adc_sync),
    .adc_outofrange(adc_outofrange),
    .adc_ctrl_clk(adc_ctrl_clk),
    .adc_ctrl_data(adc_ctrl_data),
    .adc_ctrl_strobe_n(adc_ctrl_strobe_n),
    .adc_mode(adc_mode),
    .adc_ddrb(adc_ddrb)
  );

  /*************** Simulation Control ***************/

  reg [31:0] clk_counter;

  initial begin
    $dumpvars();
    reset<=1'b1;
    clk_counter<=32'b0;
    #50
    reset<=1'b0;
`ifdef DEBUG
    $display("sim: reset cleared");
`endif
    #`SIMLENGTH
    $display("FAILED: simulation timed out");
    $finish;
  end

  assign clk = clk_counter < ((`CLK_PERIOD) / 2);

  always begin
    #1 clk_counter <= (clk_counter == `CLK_PERIOD - 1 ? 32'b0 : clk_counter + 1);
  end

  /***************** Mode Control ******************/

  reg  [2:0] ctrl_address;
  reg [15:0] ctrl_data;

  reg [2:0] mode;
  localparam MODE_CTRL_ADDR = 3'd0;
  localparam MODE_CTRL_DATA = 3'd1;
  localparam MODE_CTRL_TX   = 3'd2;
  localparam MODE_CTRL_WAIT = 3'd3;

  reg [3:0] mode_done;

  reg runtwice;

  always @(posedge clk) begin
    if (reset) begin
      mode <= MODE_CTRL_ADDR;
      runtwice <= 0;
    end else begin
      case (mode)
        MODE_CTRL_ADDR: begin
          if (mode_done[MODE_CTRL_ADDR]) begin
            mode <= MODE_CTRL_DATA;
`ifdef DEBUG
            $display("mode: MODE_CTRL_ADDR done");
`endif
          end
        end
        MODE_CTRL_DATA: begin
          if (mode_done[MODE_CTRL_DATA]) begin
            mode <= MODE_CTRL_TX;
`ifdef DEBUG
            $display("mode: MODE_CTRL_DATA done");
`endif
          end
        end
        MODE_CTRL_TX:   begin
          if (mode_done[MODE_CTRL_TX]) begin
            mode <= MODE_CTRL_WAIT;
`ifdef DEBUG
            $display("mode: MODE_CTRL_TX done");
`endif
          end
        end
        MODE_CTRL_WAIT: begin
          if (mode_done[MODE_CTRL_WAIT]) begin
            if (ctrl_address !== `TEST_CTRL_ADDRESS || ctrl_data !== `TEST_CTRL_DATA) begin
              $display("FAILED: data validation failed - expected %x, got %x", {`TEST_CTRL_ADDRESS, `TEST_CTRL_DATA}, {ctrl_address, ctrl_data});
              $finish;
            end
              if (!runtwice) begin
                runtwice <= 1;
                mode <= MODE_CTRL_ADDR;
              end else begin
                $display("PASSED");
                $finish;
              end
          end
        end
      endcase
    end
  end

  /**************** ADC Controller *****************/
  reg  [2:0] ctrl_address_buf;
  reg [15:0] ctrl_data_buf;


  reg adc_ctrl_state;
  localparam ADC_CTRL_STATE_IDLE = 1'd0;
  localparam ADC_CTRL_STATE_BUSY = 1'd1;

  reg [4:0] adc_progress;

  reg prev_clk;

  always @(posedge clk) begin
    prev_clk <= adc_ctrl_clk;
    if (reset) begin
      adc_ctrl_state <= ADC_CTRL_STATE_IDLE;
      mode_done[MODE_CTRL_WAIT] <= 1'b0;
    end else if (prev_clk != adc_ctrl_clk && adc_ctrl_clk) begin //posedge clk
      case (adc_ctrl_state)
        ADC_CTRL_STATE_IDLE: begin
          if (!adc_ctrl_strobe_n) begin
            adc_ctrl_state <= ADC_CTRL_STATE_BUSY;
            adc_progress <= 5'd0;
            ctrl_address_buf[2] <= adc_ctrl_data;
`ifdef DEBUG
            $display("adc_ctrl: got strobe + addr[2]");
`endif
          end
        end
        ADC_CTRL_STATE_BUSY: begin
          if (adc_progress < 2) begin
            ctrl_address_buf[1 - adc_progress] <= adc_ctrl_data;
            adc_progress <= adc_progress + 1;
`ifdef DEBUG
            $display("adc_ctrl: got addr[%d]", 1 - adc_progress);
`endif
          end else if (adc_progress < 18) begin
            ctrl_data_buf[16 - (adc_progress - 2) - 1] <= adc_ctrl_data;
            adc_progress <= adc_progress + 1;
`ifdef DEBUG
            $display("adc_ctrl: got data[%d]", 16 - (adc_progress - 2) - 1);
`endif
          end else if (!adc_ctrl_strobe_n) begin
            ctrl_address <= ctrl_address_buf;
            ctrl_data    <= ctrl_data_buf;
`ifdef DEBUG
            $display("adc_ctrl: got commit strb");
`endif
          end else if (adc_ctrl_strobe_n) begin
`ifdef DEBUG
            $display("adc_ctrl: strb cleared");
`endif
            adc_ctrl_state <= ADC_CTRL_STATE_IDLE;
            mode_done[MODE_CTRL_WAIT] <= 1'b1;
          end
        end
      endcase
    end
  end

  /**************** WishBone Master ****************/
  reg [1:0] wbm_state;
  localparam WBM_STATE_COMMAND = 2'd0;
  localparam WBM_STATE_COLLECT = 2'd1;
  localparam WBM_STATE_WAIT    = 2'd2;

  always @(posedge clk) begin
    wb_cyc_i <= 1'b0;
    wb_stb_i <= 1'b0;

    if (reset) begin
      wbm_state <= WBM_STATE_COMMAND;

      mode_done[MODE_CTRL_ADDR] <= 1'b0;
      mode_done[MODE_CTRL_DATA] <= 1'b0;
      mode_done[MODE_CTRL_TX]   <= 1'b0;
    end else begin
      case (wbm_state)
        WBM_STATE_COMMAND: begin
          case (mode)
            MODE_CTRL_ADDR: begin
              wb_adr_i <= {27'b0, `REG_IADC_TWI_ADDR, 1'b0};
              wb_dat_i <= {13'b0, `TEST_CTRL_ADDRESS};
              wb_cyc_i <= 1'b1;
              wb_stb_i <= 1'b1;
              wb_we_i  <= 1'b1;
              wbm_state <= WBM_STATE_COLLECT;
            end
            MODE_CTRL_DATA: begin
              wb_adr_i <= {27'b0, `REG_IADC_TWI_DATA, 1'b0};
              wb_dat_i <= {13'b0, `TEST_CTRL_DATA};
              wb_cyc_i <= 1'b1;
              wb_stb_i <= 1'b1;
              wb_we_i  <= 1'b1;
              wbm_state <= WBM_STATE_COLLECT;
            end
            MODE_CTRL_TX:   begin
              wb_adr_i <= {27'b0, `REG_IADC_TWI_TX, 1'b0};
              wb_dat_i <= 16'b1;
              wb_cyc_i <= 1'b1;
              wb_stb_i <= 1'b1;
              wb_we_i  <= 1'b1;
              wbm_state <= WBM_STATE_COLLECT;
            end
          endcase
        end
        WBM_STATE_COLLECT: begin
          if (wb_ack_o) begin
            case (mode)
              MODE_CTRL_ADDR: begin
                mode_done[MODE_CTRL_ADDR] <= 1'b1;
              end
              MODE_CTRL_DATA: begin
                mode_done[MODE_CTRL_DATA] <= 1'b1;
              end
              MODE_CTRL_TX: begin
                mode_done[MODE_CTRL_TX] <= 1'b1;
              end
            endcase
            wbm_state <= WBM_STATE_WAIT;
          end
        end
        WBM_STATE_WAIT: begin
          wbm_state <= WBM_STATE_COMMAND;
        end
      endcase
    end
  end
endmodule
