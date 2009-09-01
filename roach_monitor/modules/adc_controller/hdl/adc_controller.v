`timescale 1ns/10ps

`include "adc_controller.vh"
`include "log2_up.v"

module adc_controller(
    wb_clk_i, wb_rst_i,
    wb_stb_i, wb_cyc_i, wb_we_i,
    wb_adr_i, wb_dat_i, wb_dat_o,
    wb_ack_o,
    adc_result, adc_channel, adc_strb,
    ADC_START, ADC_CHNUM, ADC_CALIBRATE, ADC_DATAVALID, ADC_RESULT, ADC_BUSY, ADC_SAMPLE,
    current_stb, temp_stb, fast_mode
  );
  parameter DEFAULT_SAMPLE_AVERAGING = 3'b010;

  reg WTF_local, WTF_auto;
  wire WTF = WTF_local || WTF_auto;

  /* Wishbone interface */
  input  wb_clk_i, wb_rst_i;
  input  wb_stb_i, wb_cyc_i, wb_we_i;
  input  [15:0] wb_adr_i;
  input  [15:0] wb_dat_i;
  output [15:0] wb_dat_o;
  output wb_ack_o;
 
  /* Signals to fabric */
  output adc_strb;
  output  [4:0] adc_channel;
  output [11:0] adc_result;

  /* Signals to AB */
  output ADC_START;
  output  [4:0] ADC_CHNUM;
  input  ADC_CALIBRATE, ADC_DATAVALID, ADC_BUSY, ADC_SAMPLE;
  input  [11:0] ADC_RESULT;
  output  [9:0] current_stb;
  output [10:0] temp_stb;
  output fast_mode;

  /********************* Common Registers ***********************/

  /* registers from wishbone interface */
  reg  [9:0] cmon_en;
  reg [10:0] tmon_en;
  reg [31:0] channel_bypass;
  reg  [2:0] sample_averaging;
  reg adc_en;

  wire acquire_start;
  wire  [4:0] current_channel;

  wire acquire_done;
  wire [11:0] acquire_result;

  /*********************** ADC Acquire Logic *************************/

  reg [2:0] acquire_state;
  localparam ACQ_STATE_IDLE      = 3'd0;
  localparam ACQ_STATE_CALWAIT   = 3'd1;
  localparam ACQ_STATE_STRB_LOW  = 3'd2;
  localparam ACQ_STATE_STRB_SET  = 3'd3;
  localparam ACQ_STATE_START     = 3'd4;
  localparam ACQ_STATE_SAMPLE    = 3'd5;

  reg [8:0] stb_counter;
  localparam STB_LOW_WIDTH = 300;
  /* cmstrb / tmstrb needs to go low for 5us before starting a sample */
  localparam STB_SET_WIDTH = 300;
  /* cmstrb / tmstrb needs to go high for 5us before starting a sample */

  wire strb_channel; /* is the channel a strobed channel (current or temp monitoring) */

  reg ADC_START;

  always @(posedge wb_clk_i) begin
    ADC_START <= 1'b0;
    if (wb_rst_i || WTF) begin
      acquire_state  <= ACQ_STATE_IDLE;
      stb_counter    <= 9'd0;
    end else begin
      case (acquire_state)
        ACQ_STATE_IDLE: begin
          if (acquire_start) begin
            if (strb_channel) begin
              stb_counter   <= STB_LOW_WIDTH;
              acquire_state <= ACQ_STATE_STRB_LOW;
            end else begin
              acquire_state <= ACQ_STATE_START;
              ADC_START <= 1'b1;
            end
`ifdef DESPERATE_DEBUG
            $display("adc_acq: got rqst, channel = %d",adc_channel);
`endif
          end
        end
        ACQ_STATE_CALWAIT: begin
          if (!ADC_CALIBRATE) begin
            if (strb_channel) begin
              stb_counter   <= STB_LOW_WIDTH;
              acquire_state <= ACQ_STATE_STRB_LOW;
            end else begin
              acquire_state <= ACQ_STATE_START;
              ADC_START <= 1'b1;
            end
          end
        end
        ACQ_STATE_STRB_LOW: begin
          if (stb_counter) begin
            stb_counter <= stb_counter - 1;
          end else begin
            acquire_state <= ACQ_STATE_STRB_SET;
            stb_counter   <= STB_SET_WIDTH;
          end
        end
        ACQ_STATE_STRB_SET: begin
          if (stb_counter) begin
            stb_counter <= stb_counter - 1;
          end else begin
            acquire_state <= ACQ_STATE_START;
              ADC_START <= 1'b1;
          end
        end
        ACQ_STATE_START: begin
          if (ADC_BUSY) begin
            /* When ADC_BUSY goes high we know the sample has taken.
            */
               
            acquire_state <= ACQ_STATE_SAMPLE;
`ifdef DESPERATE_DEBUG
            $display("adc_acq: waiting for convert");
`endif
          end
        end
        ACQ_STATE_SAMPLE: begin
          /* The logic above breaks the simulation */
          if (ADC_DATAVALID) begin
            acquire_state     <= ACQ_STATE_IDLE;
`ifdef DEBUG
            $display("adc_acq: got value %d, channel %d", ADC_RESULT, ADC_CHNUM);
`endif
          end
        end
      endcase
    end
  end

  /* decode channel to get current strobe source */
  reg  [9:0] cstrb_decoded;
  always @(*) begin
    case (current_channel)
      5'd2:    cstrb_decoded <= 10'b1 << 0;
      5'd5:    cstrb_decoded <= 10'b1 << 1;
      5'd8:    cstrb_decoded <= 10'b1 << 2;
      5'd11:   cstrb_decoded <= 10'b1 << 3;
      5'd14:   cstrb_decoded <= 10'b1 << 4;
      5'd17:   cstrb_decoded <= 10'b1 << 5;
      5'd20:   cstrb_decoded <= 10'b1 << 6;
      5'd23:   cstrb_decoded <= 10'b1 << 7;
      5'd26:   cstrb_decoded <= 10'b1 << 8;
      5'd29:   cstrb_decoded <= 10'b1 << 9;
      default: cstrb_decoded <= 10'b0;
    endcase
  end

  reg  [10:0] tstrb_decoded;
  always @(*) begin
    case (current_channel)
      5'd3:    tstrb_decoded <= 11'b1 << 0;
      5'd6:    tstrb_decoded <= 11'b1 << 1;
      5'd9:    tstrb_decoded <= 11'b1 << 2;
      5'd12:   tstrb_decoded <= 11'b1 << 3;
      5'd15:   tstrb_decoded <= 11'b1 << 4;
      5'd18:   tstrb_decoded <= 11'b1 << 5;
      5'd21:   tstrb_decoded <= 11'b1 << 6;
      5'd24:   tstrb_decoded <= 11'b1 << 7;
      5'd27:   tstrb_decoded <= 11'b1 << 8;
      5'd30:   tstrb_decoded <= 11'b1 << 9;
      5'd31:   tstrb_decoded <= 11'b1 << 10;
      default: tstrb_decoded <= 11'b0;
    endcase
  end

  assign strb_channel = (|(tstrb_decoded & tmon_en)) || (|(cstrb_decoded & cmon_en));
  /* likely timing hazard */

  /* ADC acquire assignments */

  //assign ADC_START = acquire_state == ACQ_STATE_START;
  assign ADC_CHNUM = current_channel;

  assign acquire_done   = (acquire_state == ACQ_STATE_SAMPLE) && ADC_DATAVALID;
  assign acquire_result = ADC_RESULT;

  assign fast_mode = !strb_channel;
  /* use fast mode if the channel is not a strb channel */

  assign temp_stb    = (tstrb_decoded & tmon_en) & {11{acquire_state == ACQ_STATE_STRB_SET || acquire_state == ACQ_STATE_START || acquire_state == ACQ_STATE_SAMPLE}};
  assign current_stb = (cstrb_decoded & cmon_en) & {10{acquire_state == ACQ_STATE_STRB_SET || acquire_state == ACQ_STATE_START || acquire_state == ACQ_STATE_SAMPLE}};

  /************************ Sample Processing ***************************/

  reg [2:0] process_state;
  localparam PROC_STATE_START = 3'd0;
  localparam PROC_STATE_WAIT  = 3'd1;
  localparam PROC_STATE_CAL   = 3'd2;
  localparam PROC_STATE_ACC   = 3'd3;
  localparam PROC_STATE_TICK  = 3'd4;

  reg  [4:0] channel;

  reg [18:0] sample_accum_reg;
  reg [11:0] cal_value;
  reg  [6:0] avrg_count;
  wire [6:0] avrg_target;

  reg acquire_start_strb;
  reg [6:0] meh;

  reg [17:0] wtf_counter;

  always @(posedge wb_clk_i) begin
    acquire_start_strb <= 1'b0;
    WTF_auto <= 1'b0;

    if (wb_rst_i || WTF_local) begin
      process_state    <= PROC_STATE_START;
      channel          <= 5'd0;
      sample_accum_reg <= 15'd0;
      avrg_count       <=  6'd0;
      meh <= 0;
    end else begin 
      case (process_state)
        PROC_STATE_START: begin
          if (adc_en) begin
            if ( |((32'b1 << channel) & channel_bypass) ) begin
              channel <= channel + 1;
`ifdef DESPERATE_DEBUG
              $display("adc_ctrl: bypassing channel %d", channel);
`endif
            end else begin
              process_state      <= PROC_STATE_WAIT;
              wtf_counter        <= 18'd0;
              acquire_start_strb <= 1'b1;
`ifdef DESPERATE_DEBUG
              $display("adc_ctrl: asked for sample");
`endif
            end
          end
        end
        PROC_STATE_WAIT: begin
          if (acquire_done) begin
            process_state <= PROC_STATE_CAL;
`ifdef DESPERATE_DEBUG
            $display("adc_ctrl: got data = %d", acquire_result);
`endif
          end
          wtf_counter <= wtf_counter + 1;
          if (wtf_counter == {18{1'b1}}) begin
            wtf_counter <= 0;
            WTF_auto <= 1'b1;
            process_state    <= PROC_STATE_START;
          end  
        end
        PROC_STATE_CAL: begin
          cal_value     <= acquire_result;
          process_state <= PROC_STATE_ACC;
/* 
    TODO: implement calibration with stuff stored in SPARE flash memory pages 
*/
        end
        PROC_STATE_ACC: begin
          sample_accum_reg <= sample_accum_reg + cal_value;
          process_state    <= PROC_STATE_TICK;
        end
        PROC_STATE_TICK: begin
          if (avrg_count >= avrg_target) begin
            channel          <= channel + 1;
            avrg_count       <= 6'b0;
            sample_accum_reg <= 0;
            if (channel == 31)
              meh <= meh + 1;
          end else begin
            avrg_count <= avrg_count + 1;
          end
          process_state <= PROC_STATE_START;
        end
      endcase
    end
  end

  assign avrg_target = (1 << sample_averaging) - 1;

  assign acquire_start   = acquire_start_strb;
  assign current_channel = channel;

  assign adc_strb    = process_state == PROC_STATE_TICK && avrg_count >= avrg_target;
  assign adc_channel = channel;
  assign adc_result  = sample_accum_reg >> sample_averaging;

  /*********************** WishBone Interface *************************/
  reg wb_ack_o;
  reg [2:0] wb_dat_o_src;

  assign wb_dat_o = wb_dat_o_src == 3'd0 ? channel_bypass[31:16] :
                    wb_dat_o_src == 3'd1 ? channel_bypass[15:0] :
                    wb_dat_o_src == 3'd2 ? {6'b0, cmon_en} :
                    wb_dat_o_src == 3'd3 ? {5'b0, tmon_en} :
                    wb_dat_o_src == 3'd4 ? {15'b0, adc_en} :
                    wb_dat_o_src == 3'd5 ? {13'b0, sample_averaging} :
                    wb_dat_o_src == 3'd6 ? {8'b0, 1'b0, process_state, 1'b0, acquire_state} :
                    16'd0;

  always @(posedge wb_clk_i) begin
    //strobes
    wb_ack_o <= 1'b0;
    WTF_local <= 1'b0;
    if (wb_rst_i) begin
      channel_bypass <= {32{1'b0}};
      cmon_en <= {10{1'b1}};
      tmon_en <= {11{1'b1}};
      adc_en <= 1'b1;
      sample_averaging <= DEFAULT_SAMPLE_AVERAGING;
    end else begin
      if (wb_cyc_i & wb_stb_i & ~wb_ack_o) begin
        wb_ack_o <= 1'b1;
        case (wb_adr_i)
          `REG_ADC_CHANNEL_BYPASS_0: begin
            if (wb_we_i) begin
              channel_bypass[31:16] <= wb_dat_i;
`ifdef DEBUG
              $display("adc_c: chan bypass 0 set to %b", wb_dat_i);
`endif
            end else begin
              wb_dat_o_src <= 3'd0;
            end
          end
          `REG_ADC_CHANNEL_BYPASS_1: begin
            if (wb_we_i) begin
              channel_bypass[15:0] <= wb_dat_i;
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
          `REG_AVG_CONF: begin
            wb_dat_o_src <= 3'd5;
            if (wb_we_i) begin
              sample_averaging <= wb_dat_i[2:0];
            end
          end
          `REG_ADC_STATUS: begin
            wb_dat_o_src <= 3'd6;
            if (wb_we_i)
              WTF_local <= 1'b1;
          end
        endcase
      end
    end
  end

endmodule

