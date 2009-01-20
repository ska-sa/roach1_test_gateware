`timescale 1ns/1ns
`define SIM_LENGTH 10000000
`define CLK_PERIOD 25

`ifdef MODELSIM
`include "fusion.v"
`endif

`define ADC_CLKDIVIDE  8'd0  //SYSCLK = 40 MHZ, ADCCLK/4 = 10MHz
`define ADC_SAMPLETIME 8'd6 //(6+2) clock cycles sample time 
`define ADC_MODE       4'b0001    //12bit + nopowerdown 
//`define ADC_MODE       4'b0001    //12bit
//


`define PRESCALE_FACTOR 4.095

//test current in AMPs sense resistor is one ohm
`define TESTV_0 0.4
`define TESTV_1 0.8
`define TESTV_2 1.2
`define TESTV_3 1.6
`define TESTV_4 2.0
`define TESTV_5 2.4
`define TESTV_6 2.8
`define TESTV_7 3.2
`define TESTV_8 3.6
`define TESTV_9 4.0

//test current in amps
`define TESTC_0 0.0
`define TESTC_1 0.1
`define TESTC_2 0.2
`define TESTC_3 0.3
`define TESTC_4 0.4
`define TESTC_5 0.5
`define TESTC_6 0.6
`define TESTC_7 0.7
`define TESTC_8 0.8
`define TESTC_9 0.9

//test resistance in ohms
`define TESTR_0 0.1
`define TESTR_1 0.1
`define TESTR_2 0.1
`define TESTR_3 0.1
`define TESTR_4 0.1
`define TESTR_5 0.1
`define TESTR_6 0.1
`define TESTR_7 0.1
`define TESTR_8 0.1
`define TESTR_9 0.1

//test temperatures
`define TESTT_0 0.0
`define TESTT_1 100.0
`define TESTT_2 200.0
`define TESTT_3 35.0
`define TESTT_4 40.0
`define TESTT_5 45.0
`define TESTT_6 50.0
`define TESTT_7 55.0
`define TESTT_8 60.0
`define TESTT_9 100.0

//Expected Results 
`define RES_00 2400
`define RES_01 ((`TESTV_0/`PRESCALE_FACTOR) * 4095) 
`define RES_02 ((`TESTC_0 * `TESTR_0 * 10)/2.56 * 4095) 
`define RES_03 (`TESTT_0 * 19.53)
`define RES_04 ((`TESTV_1/`PRESCALE_FACTOR) * 4095) 
`define RES_05 ((`TESTC_1 * `TESTR_1 * 10)/2.56 * 4095) 
`define RES_06 (`TESTT_1 * 19.53)
`define RES_07 ((`TESTV_2/`PRESCALE_FACTOR) * 4095) 
`define RES_08 ((`TESTC_2 * `TESTR_2 * 10))/2.56 * 4095  
`define RES_09 (`TESTT_2 * 19.53)
`define RES_10 ((`TESTV_3/`PRESCALE_FACTOR) * 4095) 
`define RES_11 ((`TESTC_3 * `TESTR_3 * 10))/2.56 * 4095  
`define RES_12 (`TESTT_3 * 19.53)
`define RES_13 ((`TESTV_4/`PRESCALE_FACTOR) * 4095) 
`define RES_14 ((`TESTC_4 * `TESTR_4 * 10))/2.56 * 4095  
`define RES_15 (`TESTT_4 * 19.53)
`define RES_16 ((`TESTV_5/`PRESCALE_FACTOR) * 4095) 
`define RES_17 ((`TESTC_5 * `TESTR_0 * 10))/2.56 * 4095  
`define RES_18 (`TESTT_5 * 19.53)
`define RES_19 ((`TESTV_6/`PRESCALE_FACTOR) * 4095) 
`define RES_20 ((`TESTC_6 * `TESTR_6 * 10))/2.56 * 4095  
`define RES_21 (`TESTT_6 * 19.53)
`define RES_22 ((`TESTV_7/`PRESCALE_FACTOR) * 4095) 
`define RES_23 ((`TESTC_7 * `TESTR_7 * 10))/2.56 * 4095  
`define RES_24 (`TESTT_7 * 19.53)
`define RES_25 ((`TESTV_8/`PRESCALE_FACTOR) * 4095) 
`define RES_26 ((`TESTC_8 * `TESTR_8 * 10))/2.56 * 4095  
`define RES_27 (`TESTT_8 * 19.53)
`define RES_28 ((`TESTV_9/`PRESCALE_FACTOR) * 4095) 
`define RES_29 ((`TESTC_9 * `TESTR_0 * 10))/2.56 * 4095  
`define RES_30 (`TESTT_9 * 19.53)
`define RES_31 0


module TB_adc_controller();
  wire clk;
  reg  reset;

  wire adc_strb;
  wire [11:0] adc_result;
  wire  [4:0] adc_channel; 

  wire ADC_START;
  wire  [4:0] ADC_CHNUM;
  wire [11:0] ADC_RESULT;
  wire ADC_BUSY, ADC_CALIBRATE, ADC_DATAVALID, ADC_SAMPLE;

  wire  [9:0] current_stb;
  wire [10:0] temp_stb;

  reg  wb_cyc_i, wb_stb_i, wb_we_i;
  reg  [15:0] wb_adr_i;
  reg  [15:0] wb_dat_i;
  wire [15:0] wb_dat_o;
  wire wb_ack_o;

  reg [1:0] mode;
  `define MODE_ACM_CONF   2'd0
  `define MODE_ADC_CONF   2'd1
  `define MODE_VALUE_LOAD 2'd2
  `define MODE_ADC_RUN    2'd3
  adc_controller #(
    .DEFAULT_SAMPLE_AVERAGING(1)
  ) adc_controller_inst (
    .wb_clk_i(clk), .wb_rst_i(reset || mode == `MODE_ACM_CONF),
    .wb_stb_i(wb_stb_i), .wb_cyc_i(wb_cyc_i), .wb_we_i(wb_we_i),
    .wb_adr_i(wb_adr_i), .wb_dat_i(wb_dat_i), .wb_dat_o(wb_dat_o),
    .wb_ack_o(wb_ack_o),
    .adc_strb(adc_strb), .adc_result(adc_result), .adc_channel(adc_channel),
    .ADC_START(ADC_START), .ADC_CHNUM(ADC_CHNUM),
    .ADC_CALIBRATE(ADC_CALIBRATE), .ADC_DATAVALID(ADC_DATAVALID),
    .ADC_RESULT(ADC_RESULT), .ADC_BUSY(ADC_BUSY), .ADC_SAMPLE(ADC_SAMPLE),
    .current_stb(current_stb), .temp_stb(temp_stb), .fast_mode()
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

/*************************** Mode Control *********************************/
  reg [11:0] adc_mem [31:0];


  reg mode_done [3:0];

  integer k;

  reg [11:0] expected_val;

  always @(posedge clk) begin
    if (reset) begin
      mode <= `MODE_ACM_CONF;
    end else begin
      case (mode)
        `MODE_ACM_CONF: begin
          if (mode_done[0]) begin
            mode <= `MODE_ADC_CONF;
`ifdef DEBUG
            $display("mode: MODE_ACM_CONF passed");
`endif
          end
        end
        `MODE_ADC_CONF: begin
          if (mode_done[1]) begin
            mode <= `MODE_VALUE_LOAD;
`ifdef DEBUG
            $display("mode: MODE_ADC_CONF passed");
`endif
          end
        end
        `MODE_VALUE_LOAD: begin
          if (mode_done[2]) begin
            mode <= `MODE_ADC_RUN;
`ifdef DEBUG
            $display("mode: MODE_VALUE_LOAD passed");
`endif
          end
        end
        `MODE_ADC_RUN: begin
          if (mode_done[3]) begin
`ifdef MODELSIM
            for (k=0; k < 32; k=k+1) begin
              case (k)
                0: expected_val = `RES_00;
                1: expected_val = `RES_01;
                2: expected_val = `RES_02;
                3: expected_val = `RES_03;
                4: expected_val = `RES_04;
                5: expected_val = `RES_05;
                6: expected_val = `RES_06;
                7: expected_val = `RES_07;
                8: expected_val = `RES_08;
                9: expected_val = `RES_09;
                10: expected_val = `RES_10;
                11: expected_val = `RES_11;
                12: expected_val = `RES_12;
                13: expected_val = `RES_13;
                14: expected_val = `RES_14;
                15: expected_val = `RES_15;
                16: expected_val = `RES_16;
                17: expected_val = `RES_17;
                18: expected_val = `RES_18;
                19: expected_val = `RES_19;
                20: expected_val = `RES_20;
                21: expected_val = `RES_21;
                22: expected_val = `RES_22;
                23: expected_val = `RES_23;
                24: expected_val = `RES_24;
                25: expected_val = `RES_25;
                26: expected_val = `RES_26;
                27: expected_val = `RES_27;
                28: expected_val = `RES_28;
                29: expected_val = `RES_29;
                30: expected_val = `RES_30;
                31: expected_val = `RES_31;
              endcase
              if (adc_mem[k] === (expected_val)) begin
                if (k == 31) begin 
                  $display("PASSED");
                  $finish;
                end
              end else begin
                $display("FAILED: invalid value on val %d - got %d, expected %d", k, adc_mem[k], (expected_val));
                $finish;
              end
            end
            $finish;
`else
            for (k=0; k < 32; k=k+1) begin
              if (adc_mem[k] !== k) begin
                $display("FAILED: invalid value - got %d, expected %d", adc_mem[k], k);
                $finish;
              end else if (k == 31) begin
                $display("PASSED");
                $finish;
              end
            end
`endif
`ifdef DEBUG
            $display("mode: MODE_VALUE_LOAD passed");
`endif
          end
        end
      endcase
    end
  end

  wire [10*64 - 1: 0] AV_val = {$realtobits(`TESTV_9), 
                                $realtobits(`TESTV_8), 
                                $realtobits(`TESTV_7), 
                                $realtobits(`TESTV_6), 
                                $realtobits(`TESTV_5), 
                                $realtobits(`TESTV_4), 
                                $realtobits(`TESTV_3), 
                                $realtobits(`TESTV_2), 
                                $realtobits(`TESTV_1), 
                                $realtobits(`TESTV_0)};
  wire [10*64 - 1: 0] AC_val = {$realtobits(`TESTV_9 - `TESTC_9*`TESTR_9), 
                                $realtobits(`TESTV_8 - `TESTC_8*`TESTR_8), 
                                $realtobits(`TESTV_7 - `TESTC_7*`TESTR_7), 
                                $realtobits(`TESTV_6 - `TESTC_6*`TESTR_6), 
                                $realtobits(`TESTV_5 - `TESTC_5*`TESTR_5), 
                                $realtobits(`TESTV_4 - `TESTC_4*`TESTR_4), 
                                $realtobits(`TESTV_3 - `TESTC_3*`TESTR_3), 
                                $realtobits(`TESTV_2 - `TESTC_2*`TESTR_2), 
                                $realtobits(`TESTV_1 - `TESTC_1*`TESTR_1), 
                                $realtobits(`TESTV_0 - `TESTC_0*`TESTR_0)};
  wire [10*64 - 1: 0] AT_val = {$realtobits(`TESTT_9/1024), 
                                $realtobits(`TESTT_8/1024), 
                                $realtobits(`TESTT_7/1024), 
                                $realtobits(`TESTT_6/1024), 
                                $realtobits(`TESTT_5/1024), 
                                $realtobits(`TESTT_4/1024), 
                                $realtobits(`TESTT_3/1024), 
                                $realtobits(`TESTT_2/1024), 
                                $realtobits(`TESTT_1/1024), 
                                $realtobits(`TESTT_0/1024)};


/******************** Simulated ADC/Analogue Block *****************************/

`ifdef MODELSIM
  /* TODO: implement AB conf + crap to get real AB to work */
  reg ACM_WEN;
  reg ACM_CLK;
  reg [7:0] ACM_ADDR;
  reg [7:0] ACM_DATAW;

  reg [9:0] AV;
  reg [9:0] AC;
  reg [9:0] AT;


  /* Analogue Value Generation */

  reg [3:0] load_progress;
  reg [5:0] bit_prog;

  reg alt;

  always @(posedge clk) begin
    if (reset) begin
      bit_prog <= 6'b0;
      mode_done[2] <= 1'b0;
      load_progress <= 4'd0;
      alt <= 1'b1;
    end else if (alt) begin
      AV <= 10'bzzzzz_zzzzz;
      AC <= 10'bzzzzz_zzzzz;
      AT <= 10'bzzzzz_zzzzz;
      alt <= 1'b0;
    end else if (~mode_done[2] && mode == `MODE_VALUE_LOAD) begin
      alt <= 1'b1;
     
      AV[load_progress] <= AV_val[load_progress * 64 + bit_prog]; 
      AC[load_progress] <= AC_val[load_progress * 64 + bit_prog]; 
      AT[load_progress] <= AT_val[load_progress * 64 + bit_prog]; 
      if (bit_prog == 6'd63) begin
        load_progress <= load_progress + 1;
        if (load_progress == 9 && bit_prog == 6'd63) begin
          mode_done[2] <= 1'b1;
`ifdef DEBUG
          $display("val_load: loaded analogue values");
`endif
        end
      end
      bit_prog <= bit_prog + 1;
    end
  end

  AB AB_INST (
    // digital outputs 
    .DAVOUT0(), .DACOUT0(), .DATOUT0(),
    .DAVOUT1(), .DACOUT1(), .DATOUT1(),
    .DAVOUT2(), .DACOUT2(), .DATOUT2(),
    .DAVOUT3(), .DACOUT3(), .DATOUT3(),
    .DAVOUT4(), .DACOUT4(), .DATOUT4(),
    .DAVOUT5(), .DACOUT5(), .DATOUT5(),
    .DAVOUT6(), .DACOUT6(), .DATOUT6(),
    .DAVOUT7(), .DACOUT7(), .DATOUT7(),
    .DAVOUT8(), .DACOUT8(), .DATOUT8(),
    .DAVOUT9(), .DACOUT9(), .DATOUT9(),
    //digital input enables
    .DENAV0(1'b0), .DENAC0(1'b0), .DENAT0(1'b0),
    .DENAV1(1'b0), .DENAC1(1'b0), .DENAT1(1'b0),
    .DENAV2(1'b0), .DENAC2(1'b0), .DENAT2(1'b0),
    .DENAV3(1'b0), .DENAC3(1'b0), .DENAT3(1'b0),
    .DENAV4(1'b0), .DENAC4(1'b0), .DENAT4(1'b0),
    .DENAV5(1'b0), .DENAC5(1'b0), .DENAT5(1'b0),
    .DENAV6(1'b0), .DENAC6(1'b0), .DENAT6(1'b0),
    .DENAV7(1'b0), .DENAC7(1'b0), .DENAT7(1'b0),
    .DENAV8(1'b0), .DENAC8(1'b0), .DENAT8(1'b0),
    .DENAV9(1'b0), .DENAC9(1'b0), .DENAT9(1'b0),
    //analog block pads
    .AV0(AV[0]), .AC0(AC[0]), .AT0(AT[0]), .AG0(),
    .AV1(AV[1]), .AC1(AC[1]), .AT1(AT[1]), .AG1(),
    .AV2(AV[2]), .AC2(AC[2]), .AT2(AT[2]), .AG2(),
    .AV3(AV[3]), .AC3(AC[3]), .AT3(AT[3]), .AG3(),
    .AV4(AV[4]), .AC4(AC[4]), .AT4(AT[4]), .AG4(),
    .AV5(AV[5]), .AC5(AC[5]), .AT5(AT[5]), .AG5(),
    .AV6(AV[6]), .AC6(AC[6]), .AT6(AT[6]), .AG6(),
    .AV7(AV[7]), .AC7(AC[7]), .AT7(AT[7]), .AG7(),
    .AV8(AV[8]), .AC8(AC[8]), .AT8(AT[8]), .AG8(),
    .AV9(AV[9]), .AC9(AC[9]), .AT9(AT[9]), .AG9(),
    .ATRETURN01(1'b0), .ATRETURN23(1'b0),
    .ATRETURN45(1'b0), .ATRETURN67(1'b0), .ATRETURN89(1'b0),
    //gate driver enable
    .GDON0(1'b1), .GDON1(1'b1), .GDON2(1'b1), .GDON3(1'b1), .GDON4(1'b1),
    .GDON5(1'b1), .GDON6(1'b1), .GDON7(1'b1), .GDON8(1'b1), .GDON9(1'b1),
    //current monitor strobes
    .CMSTB0(current_stb[0]), .CMSTB1(current_stb[1]), .CMSTB2(current_stb[2]), .CMSTB3(current_stb[3]), .CMSTB4(current_stb[4]),
    .CMSTB5(current_stb[5]), .CMSTB6(current_stb[6]), .CMSTB7(current_stb[7]), .CMSTB8(current_stb[8]), .CMSTB9(current_stb[9]),
    //temperature monitor strobes
    .TMSTB0(temp_stb[0]), .TMSTB1(temp_stb[1]), .TMSTB2(temp_stb[2]), .TMSTB3(temp_stb[3]), .TMSTB4(temp_stb[4]),
    .TMSTB5(temp_stb[5]), .TMSTB6(temp_stb[6]), .TMSTB7(temp_stb[7]), .TMSTB8(temp_stb[8]), .TMSTB9(temp_stb[9]),
    .TMSTBINT(temp_stb[10]),
    //ADC CONTROL
    .ADCRESET(reset), .ADCSTART(ADC_START), .CHNUMBER(ADC_CHNUM),
    .CALIBRATE(ADC_CALIBRATE), .SAMPLE(ADC_SAMPLE), .BUSY(ADC_BUSY),
    .DATAVALID(ADC_DATAVALID), .RESULT(ADC_RESULT),
    //Clock Divide control, Sample Time Control, Sample Mode
    .TVC(`ADC_CLKDIVIDE), .STC(`ADC_SAMPLETIME), .MODE(`ADC_MODE),
    //Analog Configuration MUX [ACM] interface 
    .ACMRDATA(), .ACMWDATA(ACM_DATAW), .ACMADDR(ACM_ADDR), .ACMCLK(ACM_CLK), .ACMWEN(ACM_WEN), .ACMRESET(~reset),        
    //Real time clock pins
    .RTCCLK(), .RTCMATCH(), .RTCPSMMATCH(), .RTCXTLSEL(), .RTCXTLMODE(),
    //reference pins
    .VAREFSEL(1'b0), .VAREF(), .GNDREF(1'b0),
    //System signals
    .SYSCLK(clk), .PWRDWN(1'b0)
  );

  /* Analogue Block instansation */
`else


`define POSTCALIBRATE_TIME 10'd10
`define PRECALIBRATE_TIME 10'd1000
`define CONVERT_TIME   10'd100

  reg [2:0] adc_state;
`define ADC_STATE_CALIBRATE 3'd0 
`define ADC_STATE_CALIBRATE 3'd0 
`define ADC_STATE_WAIT 3'd1 
`define ADC_STATE_CONVERT 3'd2 

  reg [9:0] calibrate_timer; 
  reg [9:0] adc_timer; 
  reg [4:0] adc_chnum;

  reg ADC_CALIBRATE_reg, ADC_BUSY_reg, ADC_DATAVALID_reg, ADC_SAMPLE_reg;
  reg [11:0] ADC_RESULT_reg;

  assign ADC_CALIBRATE = ADC_CALIBRATE_reg;
  assign ADC_BUSY = ADC_BUSY_reg;
  assign ADC_DATAVALID = ADC_DATAVALID_reg;
  assign ADC_RESULT = ADC_RESULT_reg;
    
  always @(posedge clk) begin
    if (reset) begin
      calibrate_timer<=`PRECALIBRATE_TIME;
      adc_timer<=10'b0;
      adc_state<=`ADC_STATE_CALIBRATE;
      ADC_CALIBRATE_reg<=1'b1;
      ADC_BUSY_reg<=1'b0;
      ADC_DATAVALID_reg<=1'b0;
    end begin
      case (adc_state) 
        `ADC_STATE_CALIBRATE: begin
          if (calibrate_timer) begin
            calibrate_timer<=calibrate_timer-10'b1;
          end else begin
            ADC_CALIBRATE_reg<=1'b0;
            ADC_BUSY_reg<=1'b0;
            adc_state<=`ADC_STATE_WAIT;
`ifdef DEBUG
              $display("adc: calibrated");
`endif
          end
        end
        `ADC_STATE_WAIT: begin
          if (ADC_START) begin
            adc_chnum<=ADC_CHNUM;
            ADC_DATAVALID_reg<=1'b0;
            adc_timer<=8'b0;              
            adc_state<=`ADC_STATE_CONVERT;
            ADC_BUSY_reg<=1'b1;
            ADC_DATAVALID_reg<=1'b0;
`ifdef DEBUG
            $display("adc: got channel %d -- converting", ADC_CHNUM);
`endif
          end
        end
        `ADC_STATE_CONVERT: begin
          if (adc_timer == `CONVERT_TIME - 1) begin
            adc_state<=`ADC_STATE_CALIBRATE;
            ADC_CALIBRATE_reg<=1'b1;
            calibrate_timer<=`POSTCALIBRATE_TIME;
            ADC_BUSY_reg<=1'b0;
            ADC_DATAVALID_reg<=1'b1;
            ADC_RESULT_reg<={7'b0,adc_chnum}; /* TODO: use real values + AB conf to calc what ADC_RESULT should be */
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
`endif

/*************************** Simulated ADC slave ****************************/

  reg [31:0] adc_sampled;

  always @(posedge clk) begin
    if (reset) begin
      mode_done[3] <= 1'b0;
      adc_sampled <= 32'b0;
    end else if (~mode_done[3] && mode == `MODE_ADC_RUN) begin
      if (adc_sampled == {32{1'b1}}) begin
        mode_done[3] <= 1'b1;
`ifdef DEBUG 
        $display("adc_slave: got all samples");
`endif
      end
      if (adc_strb) begin
        adc_mem[adc_channel] <= adc_result;
        adc_sampled[adc_channel] <= 1'b1;
`ifdef DEBUG 
        $display("adc_slave: got sample, chan = %d, val = %d", adc_channel, adc_result);
`endif
      end
    end
  end

/*************************** Simulated ADC Config ****************************/

  reg [1:0] wbm_state;
  `define WBM_STATE_COMMAND 2'd0
  `define WBM_STATE_COLLECT 2'd1
  `define WBM_STATE_DONE    2'd2

  reg [2:0] wbm_progress;

  always @(posedge clk) begin
    wb_cyc_i <= 1'b0;
    wb_stb_i <= 1'b0;
    wb_we_i <= 1'b1;
    if (reset) begin
      mode_done[1] <= 1'b0;
      wbm_state <= `WBM_STATE_COMMAND;
      wbm_progress <= 3'b0;
    end else if (mode == `MODE_ADC_CONF) begin
      case (wbm_state)
        `WBM_STATE_COMMAND: begin
          wb_cyc_i <= 1'b1;
          wb_stb_i <= 1'b1;
          wb_adr_i <= {13'b0, wbm_progress};
          case (wbm_progress)
            3'd0: begin //enable all channels 0
              wb_dat_i <= {16{1'b0}};
            end
            3'd1: begin //enable all channels 1
              wb_dat_i <= {16{1'b0}};
            end
            3'd2: begin //enable all current mons
              wb_dat_i <= {16{1'b1}};
            end
            3'd3: begin //enable all temp mons
              wb_dat_i <= {16{1'b1}};
            end
            3'd4: begin //enable adc
              wb_dat_i <= {16{1'b1}};
            end
          endcase
          wbm_state <= `WBM_STATE_COLLECT;
`ifdef DEBUG
          $display("wbm: config adc %d", wbm_progress);
`endif
        end
        `WBM_STATE_COLLECT: begin
          if (wb_ack_o) begin
            if (wbm_progress == 3'd4) begin
              wbm_state <= `WBM_STATE_DONE;
`ifdef DEBUG
              $display("wbm: config adc done");
`endif
            end else begin
              wbm_progress <= wbm_progress + 1;
              wbm_state <= `WBM_STATE_COMMAND;
`ifdef DEBUG
              $display("wbm: config adc %d done", wbm_progress);
`endif
            end
          end
        end
        `WBM_STATE_DONE: begin
          mode_done[1] <= 1'b1;
        end
      endcase
    end
  end

/*************************** Simulated ACM Config ****************************/

`ifdef MODELSIM
  reg [2:0] acm_clk_counter;
  reg [7:0] acm_progress;
  reg twice;
  always @(posedge clk) begin
    if (reset) begin
      mode_done[0] <= 1'b0;
      acm_clk_counter <= 3'b0;
      acm_progress <= 8'b0;
      ACM_WEN <= 1'b0;
      ACM_CLK <= 1'b0;
      twice <= 1'b0;
    end else if (mode == `MODE_ACM_CONF && !mode_done[0]) begin
      acm_clk_counter <= acm_clk_counter + 1;
      if (acm_clk_counter <= 3'b011) begin
        ACM_CLK <= 1'b0;
        ACM_ADDR <= acm_progress + 1; //ACM quads start at 1
        ACM_WEN <= 1'b1;
        case (acm_progress[1:0])
          2'b00: ACM_DATAW <= 8'h92; //volt
          2'b01: ACM_DATAW <= 8'h10; //curr
          2'b10: ACM_DATAW <= 8'h81; //gate
          2'b11: ACM_DATAW <= 8'h10; //temp
        endcase
      end else begin
        ACM_CLK <= 1'b1;
        if (acm_clk_counter == 3'b111) begin
          if (acm_progress == 8'd39) begin
            if (twice) begin
              mode_done[0] <= 1'b1;
            end else begin
              twice <= 1'b1;
              acm_progress <= 8'b0;
`ifdef DEBUG
              $display("acm: second time");
`endif
            end
          end else begin
            acm_progress <= acm_progress + 1;
          end
        end
      end
    end
  end
`else
  always @(posedge clk) begin
    mode_done[0] <= 1'b1; // no configuration necessary
    mode_done[2] <= 1'b1; // no valud loading
  end
`endif


   
endmodule
