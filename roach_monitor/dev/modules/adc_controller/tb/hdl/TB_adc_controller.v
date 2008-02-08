`timescale 1ns/10ps
module TB_adc_controller();
  reg reset,clk;
  wire [11:0] adc_result;
  reg [4:0] adc_channel; 
  reg adc_rd;
  wire adc_strb;
  wire ADC_START;
  wire [4:0] ADC_CHNUM;
  reg [11:0] ADC_RESULT;
  reg ADC_BUSY,ADC_CALIBRATE,ADC_DATAVALID,ADC_SAMPLE;
  adc_iface adc_iface(
    .reset(reset), .clk(clk),
    .adc_result(adc_result),.adc_channel(adc_channel),.adc_rd(adc_rd),.adc_strb(adc_strb),
    .ADC_START(ADC_START),.ADC_CHNUM(ADC_CHNUM),.ADC_CALIBRATE(ADC_CALIBRATE),.ADC_BUSY(ADC_BUSY),.ADC_DATAVALID(ADC_DATAVALID),.ADC_RESULT(ADC_RESULT),.ADC_SAMPLE(ADC_SAMPLE)
    );
    reg gotsomething;
    initial begin
      clk<=1'b1;
      reset<=1'b1;
      gotsomething<=1'b0;
`ifdef DEBUG
      $display("simulation start:");
`endif
      #8
      reset<=1'b0;
`ifdef DEBUG
      $display("deasserted reset");
`endif
      #80000
      if (~gotsomething) begin
        $display("FAILED: got no response");
      end else
        $display("PASSED");
      $finish;
    end

    always begin
      #1 clk<=~clk;
    end
`define CALIBRATE_TIME 10'd1000
`define CONVERT_TIME 8'd100
    reg [2:0] adc_state;
`define ADC_STATE_CALIBRATE 3'd0 
`define ADC_STATE_WAIT 3'd1 
`define ADC_STATE_CONVERT 3'd2 
   reg [9:0] calibrate_timer; 
   reg [7:0] adc_timer; 
   reg [4:0] adc_chnum;
    
    always @(posedge clk) begin
      if (reset) begin
        calibrate_timer<=10'b0;
        adc_timer<=8'b0;
        adc_state<=`ADC_STATE_CALIBRATE;
        ADC_CALIBRATE<=1'b1;
        ADC_BUSY<=1'b0;
        ADC_DATAVALID<=1'b0;
        ADC_SAMPLE<=1'b0;
      end begin
        case (adc_state) 
          `ADC_STATE_CALIBRATE: begin
            if (calibrate_timer==`CALIBRATE_TIME) begin
              adc_state<=`ADC_STATE_WAIT;
              ADC_CALIBRATE<=1'b0;
              ADC_BUSY<=1'b0;
              `ifdef DEBUG
                $display("adc: calibrated");
              `endif
            end else
              calibrate_timer<=calibrate_timer+10'b1;
          end
          `ADC_STATE_WAIT: begin
            if (ADC_START) begin
              adc_chnum<=ADC_CHNUM;
              ADC_DATAVALID<=1'b0;
              `ifdef DEBUG
                $display("adc: got channel %d -- converting",ADC_CHNUM);
              `endif
              adc_timer<=8'b0;              
              adc_state<=`ADC_STATE_CONVERT;
              ADC_BUSY<=1'b1;
              ADC_SAMPLE<=1'b1; //not true sample should be trigger before busy
              ADC_DATAVALID<=1'b0;
            end
          end
          `ADC_STATE_CONVERT: begin
            if (adc_timer == `CONVERT_TIME - 1) begin
              adc_state<=`ADC_STATE_CALIBRATE;
              ADC_CALIBRATE<=1'b1;
              calibrate_timer<=10'b0;
              ADC_BUSY<=1'b0;
              ADC_SAMPLE<=1'b0;
              ADC_DATAVALID<=1'b1;
              ADC_RESULT<={7'b0,adc_chnum};
              `ifdef DEBUG
                $display("adc: converted, val = %d",{7'b0,adc_chnum});
              `endif
            end else begin
              adc_timer<=adc_timer + 8'b1;
            end
          end
        endcase
      end
    end
   
    reg [1:0] alc_state; 
`define ALC_STATE_START 2'd0
`define ALC_STATE_WAIT  2'd1
`define ALC_STATE_FINISH 2'd2

    always @(posedge clk) begin
      if (reset) begin
        adc_channel<=5'b11111;
        alc_state<=`ALC_STATE_START;
        adc_rd<=1'b0;
      end else begin
        case (alc_state)
          `ALC_STATE_START: begin
            adc_channel<=adc_channel + 5'b1; 
            adc_rd<=1'b1;
            alc_state<=`ALC_STATE_WAIT;
              `ifdef DEBUG
                $display("alc: rqst value, channel ==  %d",adc_channel + 5'b1);
              `endif
          end
          `ALC_STATE_WAIT: begin
            adc_rd<=1'b0;
            if (adc_strb) begin
              alc_state<=`ALC_STATE_FINISH;
              `ifdef DEBUG
                $display("alc: got value - %d",adc_result);
              `endif
              if (adc_result[4:0] == adc_channel) begin
                gotsomething<=1'b1;
              end else begin
                $display("FAILED: adc result != adc_channel : %d , %d ",adc_result[4:0],adc_channel);
                $finish;
              end
            end
          end
          `ALC_STATE_FINISH: begin
            if (~adc_strb) begin
              alc_state<=`ALC_STATE_START;
            end
          end
        endcase
      end
    end
endmodule
