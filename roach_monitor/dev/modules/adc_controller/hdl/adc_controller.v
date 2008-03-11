`timescale 1ns/10ps

`include "adc_controller.vh"

module adc_controller(
    wb_clk_i, wb_rst_i,
    wb_stb_i, wb_cyc_i, wb_we_i,
    wb_adr_i, wb_dat_i, wb_dat_o,
    wb_ack_o,
    adc_result, adc_channel, adc_strb,
    ADC_START, ADC_CHNUM, ADC_CALIBRATE, ADC_BUSY, ADC_DATAVALID, ADC_RESULT,
    current_stb, temp_stb
  );
  input  wb_clk_i, wb_rst_i;
  input  wb_stb_i, wb_cyc_i, wb_we_i;
  input  [15:0] wb_adr_i;
  input  [15:0] wb_dat_i;
  output [15:0] wb_dat_o;
  output wb_ack_o;
 
  output adc_strb;
  output  [4:0] adc_channel;
  output [11:0] adc_result;
  output  [9:0] current_stb;
  output [10:0] temp_stb;

  output ADC_START;
  output  [4:0] ADC_CHNUM;
  input  ADC_CALIBRATE, ADC_BUSY, ADC_DATAVALID;
  input  [11:0] ADC_RESULT;

  /********************* Common Registers ***********************/
  reg [31:0] channel_bypass;
  reg  [9:0] cmon_en;
  reg [10:0] tmon_en;
  reg adc_en;

  /*********************** ADC Control *************************/
  reg  [2:0] state;
  localparam STATE_IDLE    = 3'd0;
  localparam STATE_STROBE  = 3'd1;
  localparam STATE_CONVERT = 3'd2;
  localparam STATE_WAITING = 3'd3;
  localparam STATE_DONE    = 3'd4;

  reg  [9:0] current_stb;
  reg [10:0] temp_stb;

  reg adc_strb;
  reg [11:0] adc_result;
  assign adc_channel = ADC_CHNUM;

  reg  [4:0] ADC_CHNUM;
  reg ADC_START;

  reg prev_dv;

  localparam STB_WIDTH = 400; //400 * 25ns = 10us

  wire [31:0] adc_chnum_decoded = (1 << ADC_CHNUM); //this might be a timing liability

  wire [9:0] current_sel = {adc_chnum_decoded[29], adc_chnum_decoded[26],
                            adc_chnum_decoded[23], adc_chnum_decoded[20],
                            adc_chnum_decoded[17], adc_chnum_decoded[14],
                            adc_chnum_decoded[11], adc_chnum_decoded[8],
                            adc_chnum_decoded[5],  adc_chnum_decoded[2]};
  wire [10:0] temp_sel = {adc_chnum_decoded[31], adc_chnum_decoded[30], adc_chnum_decoded[27], adc_chnum_decoded[24],
                          adc_chnum_decoded[21], adc_chnum_decoded[18], adc_chnum_decoded[15], adc_chnum_decoded[12],
                          adc_chnum_decoded[9],  adc_chnum_decoded[6],  adc_chnum_decoded[3]};

  reg [8:0] stb_counter;

  always @(posedge wb_clk_i) begin
    //strobes
    adc_strb<=1'b0;
    prev_dv<=ADC_DATAVALID;

    if (wb_rst_i) begin
      state<=STATE_IDLE;
      ADC_START<=1'b0;
      ADC_CHNUM<=5'b0;
    end else begin
      case (state)
        STATE_IDLE: begin
          if (adc_en & ~ADC_CALIBRATE) begin
            if (channel_bypass[ADC_CHNUM]) begin
              state<=STATE_DONE;
            end else if (current_sel & cmon_en || temp_sel & tmon_en)  begin
              state<=STATE_STROBE;
              stb_counter <= STB_WIDTH;
              current_stb <= current_sel & cmon_en;
              temp_stb <= temp_sel & tmon_en;
            end else begin
              state<=STATE_CONVERT;
            end
`ifdef DESPERATE_DEBUG
            $display("adc_c: got rqst, channel = %d",adc_channel);
`endif
          end
        end 
        STATE_STROBE: begin
          if (stb_counter) begin
            stb_counter <= stb_counter - 1;
          end else begin
            state <= STATE_CONVERT;
          end
        end
        STATE_CONVERT: begin
          ADC_START<=1'b1;
          state<=STATE_WAITING;
`ifdef DESPERATE_DEBUG
          $display("adc_c: waiting for convert: datavalid==%d",ADC_DATAVALID);
`endif
        end
        STATE_WAITING: begin
          ADC_START<=1'b0;
          if (ADC_DATAVALID && ADC_DATAVALID != prev_dv) begin //when DV goes high
            current_stb <= 10'b0;
            temp_stb <= 11'b0;
            adc_result<=ADC_RESULT;
            adc_strb<=1'b1;
            state<=STATE_DONE;
`ifdef DEBUG
            $display("adc_c: got value %d, channel %d",ADC_RESULT,ADC_CHNUM);
`endif
          end
        end
        STATE_DONE: begin
          ADC_CHNUM <= ADC_CHNUM + 1;
          state<=STATE_IDLE;
        end
      endcase
    end
  end

  /*********************** WishBone Interface *************************/
  reg wb_ack_o;
  reg [2:0] wb_dat_o_src;

  assign wb_dat_o = wb_dat_o_src == 3'd0 ? channel_bypass[15:0] :
                    wb_dat_o_src == 3'd1 ? channel_bypass[31:16] :
                    wb_dat_o_src == 3'd2 ? {6'b0, cmon_en} :
                    wb_dat_o_src == 3'd3 ? {5'b0, tmon_en} :
                    wb_dat_o_src == 3'd4 ? {15'b0, adc_en} :
                    16'b0;

  always @(posedge wb_clk_i) begin
    //strobes
    wb_ack_o <= 1'b0;
    if (wb_rst_i) begin
      channel_bypass <= {32{1'b0}};
      cmon_en <= {10{1'b0}};
      tmon_en <= {11{1'b0}};
      adc_en <= 1'b0;
    end else begin
      if (wb_cyc_i & wb_stb_i & ~wb_ack_o) begin
        wb_ack_o <= 1'b1;
        case (wb_adr_i)
          `REG_ADC_CHANNEL_BYPASS_0: begin
            if (wb_we_i) begin
              channel_bypass[15:0] <= wb_dat_i;
`ifdef DEBUG
              $display("adc_c: chan bypass 0 set to %b", wb_dat_i);
`endif
            end else begin
              wb_dat_o_src <= 3'd0;
            end
          end
          `REG_ADC_CHANNEL_BYPASS_1: begin
            if (wb_we_i) begin
              channel_bypass[31:16] <= wb_dat_i;
`ifdef DEBUG
              $display("adc_c: chan bypass 1 set to %b", wb_dat_i);
`endif
            end else begin
              wb_dat_o_src <= 3'd1;
            end
          end
          `REG_ADC_CMON_EN: begin
            if (wb_we_i) begin
              cmon_en <= wb_dat_i[9:0];
`ifdef DEBUG
              $display("adc_c: cmon set tp %b", wb_dat_i[9:0]);
`endif
            end else begin
              wb_dat_o_src <= 3'd2;
            end
          end
          `REG_ADC_TMON_EN: begin
            if (wb_we_i) begin
              tmon_en <= wb_dat_i[10:0];
`ifdef DEBUG
              $display("adc_c: tmon set to %b", wb_dat_i[10:0]);
`endif
            end else begin
              wb_dat_o_src <= 3'd3;
            end
          end
          `REG_ADC_EN: begin
            if (wb_we_i) begin
              adc_en <= wb_dat_i[0];
`ifdef DEBUG
              if (wb_dat_i[0])
                $display("adc_c: adc enabled");
`endif
            end else begin
              wb_dat_o_src <= 3'd4;
            end
          end
        endcase
      end
    end
  end

endmodule
