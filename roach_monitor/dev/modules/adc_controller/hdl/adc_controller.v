`timescale 1ns/10ps

`define ADCIF_STATE_IDLE 2'b0
`define ADCIF_STATE_CONVERT 2'd1
`define ADCIF_STATE_WAITING 2'd2
`define ADCIF_STATE_DONE 2'd3

module adc_controller(
  reset, clk,
  adc_result,adc_channel,adc_rd,adc_strb,
  ADC_START,ADC_CHNUM,ADC_CALIBRATE,ADC_BUSY,ADC_DATAVALID,ADC_RESULT,ADC_SAMPLE
  );
  input reset,clk;
 
  output adc_strb;
  input adc_rd;
  input [4:0] adc_channel;
  output [11:0] adc_result;

  output ADC_START;
  output [4:0] ADC_CHNUM;
  input ADC_CALIBRATE,ADC_BUSY,ADC_DATAVALID,ADC_SAMPLE;
  input [11:0] ADC_RESULT;

  reg [ 1:0] state;
  reg [11:0] adc_result;
  reg [ 4:0] ADC_CHNUM;
  reg ADC_START;
  reg adc_strb;

  reg got_a_dv;

  always @(posedge clk) begin
    if (reset) begin
      state<=`ADCIF_STATE_IDLE;
      ADC_START<=1'b0;
      ADC_CHNUM<=5'b0;
      adc_strb<=1'b0;
      got_a_dv<=1'b0;
    end else begin
      if (~ADC_DATAVALID) begin
        got_a_dv<=1'b1;
      end
      case (state)
        `ADCIF_STATE_IDLE: begin
          if (adc_rd) begin
            state<=`ADCIF_STATE_CONVERT;
            ADC_CHNUM<=adc_channel;
            `ifdef DESPERATE_DEBUG
              $display("adcif: got rqst, channel = %d",adc_channel);
            `endif
          end
        end
        `ADCIF_STATE_CONVERT: begin
          if (~ADC_CALIBRATE) begin
            state<=`ADCIF_STATE_WAITING;
            ADC_START<=1'b1;
`ifdef DESPERATE_DEBUG
            $display("adcif: waiting for convert: datavalid==%d",ADC_DATAVALID);
`endif
          end
        end
        `ADCIF_STATE_WAITING: begin
          if (ADC_DATAVALID & got_a_dv) begin
`ifdef DEBUG
            $display("adcif: got value %d, channel %d",ADC_RESULT,ADC_CHNUM);
`endif
            state<=`ADCIF_STATE_DONE;
            ADC_START<=1'b0;
	    got_a_dv<=1'b0;
            adc_result<=ADC_RESULT;
            adc_strb<=1'b1;
          end
        end
        `ADCIF_STATE_DONE: begin
	  if (~adc_rd) begin
            adc_strb<=1'b0;
            state<=`ADCIF_STATE_IDLE;
	  end
        end
      endcase
    end
  end

endmodule
