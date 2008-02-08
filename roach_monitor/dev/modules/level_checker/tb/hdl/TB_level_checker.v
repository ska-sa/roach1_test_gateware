`timescale 1ns/10ps
`include "memlayout.v"
`include "parameters.v"

`define SOFT_THRESH_LOW 12'd10
`define SOFT_THRESH_HIGH 12'd400

`define HARD_THRESH_LOW 12'd5
`define HARD_THRESH_HIGH 12'd450

`define MIDDLE_VALUE 16'd200
/* This testbench first writes high and low thresholds as well as ADC data.
 * It triggers soft and critical alert conditions and tests the responces
 * it then reads back the contents of the local bus to validate the state of
 * the system */
`ifndef ALC_POWER_DOWN_ENABLE
`define ALC_POWER_DOWN_ENABLE
`endif

module TB_level_checker();
  
  reg clk,hard_reset,soft_reset;
     
  reg adc_strb; 
  wire adc_rd; 
  wire [4:0] adc_channel;
  reg [11:0] adc_result;

  reg [15:0] lb_addr;
  reg lb_rd,lb_wr;
  wire [15:0] lb_data_out;
  reg [15:0] lb_data_in;
  wire lb_strb;
  
  wire irq;
  wire power_down;

  wire [12:0] RB_ADDR;

  wire [11:0] RB_RDATA;
  wire [11:0] RB_WDATA;
  wire RB_WRB;
  
  analogue_level_checker analogue_level_checker(
    .soft_reset(soft_reset), .hard_reset(hard_reset),
    
    .adc_result(adc_result),.adc_rd(adc_rd),.adc_channel(adc_channel),.adc_strb(adc_strb),
    
    .lb_addr(lb_addr),.lb_data_in(lb_data_in),.lb_data_out(lb_data_out),
    .lb_rd(lb_rd),.lb_wr(lb_wr),.lb_strb(lb_strb),.lb_clk(clk),

    .irq(irq),.power_down(power_down),.no_power(1'b0),

    .RB_ADDR(RB_ADDR),.RB_WDATA(RB_WDATA),.RB_RDATA(RB_RDATA),.RB_WRB(RB_WRB)
    
  );
  reg [4:0] hard_chan; 
  reg [4:0] soft_chan; 
  reg [2:0] checks;
  reg force_hard_crash;
  reg force_soft_crash;
  reg readback_mode;
  reg [1:0] ring_buff_mode;
  reg [31:0] rb_counter;
  
  initial begin
    clk<=1'b0;
    checks<=3'b000;
    hard_reset<=1'b1;
    force_soft_crash<=1'b0;
    force_hard_crash<=1'b0;
    readback_mode<=1'b0;
    ring_buff_mode<=2'b0;
`ifdef DEBUG
    $display("starting sim");
`endif
    #5 hard_reset<=1'b0;
`ifdef DEBUG
    $display("clearing reset");
`endif
    #8000
    force_hard_crash<=1'b1;
`ifdef DEBUG
    $display("adc: forcing hard crash condition");
`endif
    #800 
    force_hard_crash<=1'b0;
`ifdef DEBUG
    $display("releasing crash condition");
`endif

    #8000 force_soft_crash<=1'b1;
`ifdef DEBUG
    $display("forcing soft crash condition");
`endif
    #800 force_soft_crash<=1'b0;
`ifdef DEBUG
    $display("releasing crash condition");
`endif
    #80000 
`ifdef DEBUG
    $display("entering readback mode");
`endif
    readback_mode<=1'b1;


    #8000
    ring_buff_mode<=2'b11; /*PAUSE*/
    #80
    ring_buff_mode<=2'b10; /*READBACK*/
    #8000
    ring_buff_mode<=2'b01; /*RESUME*/
    $display("PASSED");
    $finish;

  end

  always begin
    #1 clk <=~clk;
  end
  /*memory interface*/

`ifdef MODELSIM
`else
  reg [11:0] memory [8192 - 1:0];
  assign RB_RDATA = memory[RB_ADDR - 1];
  
  always @(posedge clk) begin
    if (soft_reset) begin
    end else begin
      if (~RB_WRB) begin
        memory[RB_ADDR - 1] <= RB_WDATA;
`ifdef DESPERATE_DEBUG
        $display("rb: got write, addr = %d, send data = %d",RB_ADDR,RB_WDATA);
`endif
      end
    end
  end

`endif

  reg [4:0] adc_channel_buff;
`define SAMPLE_WAIT 16'd10
  reg [15:0] sample_wait;
    /*ADC iface fake*/
  always @(posedge clk) begin
    if (soft_reset) begin
      adc_strb<=1'b0;
      sample_wait<=16'b0;
    end else begin
      if (adc_strb & adc_rd) begin //wait for adc_rd to go low while adc_strb is up
      end else if (sample_wait == 16'b0) begin
        adc_strb<=1'b0;
        if (adc_rd) begin
          adc_channel_buff<=adc_channel;
          sample_wait<=16'b1;
`ifdef DESPERATE_DEBUG
    $display("adc: got request for channel = %d , waiting...",adc_channel);
`endif
        end
      end else begin
        if (sample_wait==`SAMPLE_WAIT) begin
`ifdef DESPERATE_DEBUG
    //$display("adc: sample_ready");
`endif
          sample_wait<=16'b0;
          adc_strb<=1'b1;
          if (force_soft_crash) begin
            soft_chan<= adc_channel_buff;
            adc_result<=`SOFT_THRESH_HIGH+adc_channel_buff + 16;
`ifdef DESPERATE_DEBUG
    //$display("adc: value=%d",`SOFT_THRESH_HIGH+adc_channel_buff);
`endif
          end else if (force_hard_crash) begin
            hard_chan<= adc_channel_buff;
            adc_result<=`HARD_THRESH_HIGH +adc_channel_buff +16;
`ifdef DEBUG
            $display("adc: force hard crash: value == %d, channel == %d",`HARD_THRESH_HIGH + 1'b1 + adc_channel_buff,adc_channel_buff);
`endif
`ifdef DESPERATE_DEBUG
           // $display("adc: value=%d",`HARD_THRESH_HIGH+adc_channel_buff);
`endif
          end else begin
            adc_result<=`MIDDLE_VALUE + adc_channel_buff;
`ifdef DESPERATE_DEBUG
    //$display("adc: value=%d",`MIDDLE_VALUE+adc_channel_buff);
`endif
          end
        end else begin
          sample_wait<=sample_wait+16'b1;
        end
      end
    end
  end

    /*interrupt controller fake*/
  reg [7:0] irq_countdown;
  always @(posedge clk) begin
    if (soft_reset) begin
      irq_countdown<=7'b0;
    end else begin
      if (irq) begin
        irq_countdown<=7'b0;
      end else begin 
        if (force_soft_crash) begin
          irq_countdown<=irq_countdown + 7'b1;
        end
      end
      
      if (irq_countdown == 7'd100) begin
          $display("FAILED: no irq when forced");
          $finish;
      end
    end
  end
    /*power controller fake*/
  reg [6:0] crash_counter;
  always @(posedge clk) begin
    if (hard_reset) begin
      soft_reset<=1'b1;
      crash_counter<=7'b0;
`ifdef DEBUG
              $display("pc: reset");
`endif
    end else begin
      if (power_down /*or powering_down*/) begin
        /*perform all the power down goodies after which hit reset*/
        soft_reset<=1'b1;
        crash_counter<=7'b0;
`ifdef DEBUG
              $display("pc: got powerdown");
`endif
      end else begin
        soft_reset<=1'b0;
        if (force_hard_crash) begin
          crash_counter<=crash_counter + 7'b1;
        end
        if (crash_counter == 7'd100) begin
          $display("FAILED: no crash when forced");
          $finish;
        end
      end
    end
  end

`define STATE_IDLE 3'd0
`define STATE_WRITE 3'd1
`define STATE_READ 3'd2
`define STATE_WAITR 3'd3
`define STATE_WAITW 3'd4
  reg [2:0] state;

  reg [3:0] fault_countdown;

  reg [6:0] threshold_index;

  always @ (posedge clk) begin
    if (soft_reset) begin
      lb_rd<=1'b0;
      lb_wr<=1'b0;
      state<=`STATE_IDLE;
      fault_countdown<=4'b0;
      threshold_index<=7'b0;
`ifdef DEBUG
      $display("lb: reset");
`endif
    end else begin
`ifdef DESPERATE_DEBUG
              $display("lb: state = %d",state);
`endif
      case (state)
        `STATE_IDLE: begin
`ifdef DESPERATE_DEBUG
              $display("lb: idle, threshold_index=%d",threshold_index);
`endif
          threshold_index<=threshold_index + 7'b1;
          if (ring_buff_mode == 2'b11) begin
            lb_wr<=1'b1;
            state<=`STATE_WAITW;
            lb_data_in<=16'hffff;
            lb_addr<=`ALC_RBUFF_A;
            rb_counter<=10'b0 - 10'b1;
          end else if (ring_buff_mode == 2'b10) begin
            lb_addr<=`ALC_RBUFF_A;
            lb_rd<=1'b1;
            state<=`STATE_WAITR;
            rb_counter<=rb_counter + 32'b1;
          end else if (ring_buff_mode == 2'b01) begin
            lb_wr<=1'b1;
            state<=`STATE_WAITW;
            lb_data_in<=16'h0;
            lb_addr<=`ALC_RBUFF_A;
          end else if (~readback_mode) begin
`ifdef DESPERATE_DEBUG
              $display("lb: write address - %d, write data - %d", lb_addr,lb_data_in);
`endif
            lb_wr<=1'b1;
            state<=`STATE_WAITW;
	    lb_addr<=(threshold_index[6] ? `ALC_SOFTLEVEL_A : `ALC_HARDLEVEL_A)+threshold_index[5:0];
            lb_data_in<=(threshold_index[6] ? (threshold_index[0] ?`SOFT_THRESH_LOW : `SOFT_THRESH_HIGH)
	              : (threshold_index[0] ? `HARD_THRESH_LOW : `HARD_THRESH_HIGH)); 
          end else begin
            if (lb_addr < `ALC_A)
               lb_addr<=`ALC_A;
            else if(lb_addr >= `ALC_A && lb_addr < `ALC_A + `ALC_L - 16'b1) 
               lb_addr<=lb_addr+16'b1;
            else
               lb_addr<=`ALC_A;
            
            lb_rd<=1'b1;
            state<=`STATE_WAITR;
`ifdef DESPERATE_DEBUG
              $display("lb: read address - %d", lb_addr);
`endif
          end
	end
        `STATE_WAITR:
          begin
            if (fault_countdown == 4'b1111) begin
              state<=`STATE_IDLE;
              fault_countdown<=4'b0;
              if (lb_addr >= `ALC_A && lb_addr < `ALC_A + `ALC_L) begin
                  $display("FAILED: invalid timeout on write: address %d",lb_addr);
                  $finish;
              end
`ifdef DEBUG
              $display("bus timeout at address: %x", lb_addr);
`endif
            end else begin
              fault_countdown<=fault_countdown + 4'b1;
              if (lb_rd)
                lb_rd<=1'b0;

              if (lb_strb) begin
                if (lb_addr < `ALC_A || lb_addr >= `ALC_A + `ALC_L) begin
                  $display("FAILED: invalid reply on write: address %d",lb_addr);
                  $finish;
                end else begin
`ifdef DESPERATE_DEBUG
              $display("lb: got read reply - %d   data = %d", lb_addr,lb_data_out);
`endif
                end
                state<=`STATE_IDLE;
                fault_countdown<=4'b0;
                if (ring_buff_mode == 2'b10) begin
                  if (lb_data_out[15] === 1'b1) begin
                    $display("FAILED: ring buffer error -- data == %d",lb_data_in);
                    $finish;
                  end else if (lb_data_out[14] === 1'b1) begin
                    if (rb_counter < 10'd1023 - 16'd32) begin
                      $display("FAILED: ring buffer short fall - got %d value",rb_counter);
                      $finish;
                    end
                  end else if (!(lb_data_out[11:0] === (5'd31-(rb_counter % 6'd32) + `MIDDLE_VALUE))) begin
                      $display("FAILED: ring buffer value failure, rbcounter == %d, data == %d, expected %d",rb_counter, lb_data_out, (5'd31-(rb_counter % 6'd32) + `MIDDLE_VALUE));
                      $finish;
                  end
                end else begin
                  if (lb_addr >= `ALC_HARDLEVEL_A && lb_addr < `ALC_HARDLEVEL_A + `ALC_HARDLEVEL_L) begin
                    if ((lb_addr - (`ALC_HARDLEVEL_A))  % 2 == 16'b0) begin
                      if (!(lb_data_out === `HARD_THRESH_HIGH)) begin
                        $display("FAILED: hard thresh high readback failed");
                        $finish;
                      end
                      `ifdef DESPERATE_DEBUG 
                      else 
                        $display("hard level high valid: %d ",lb_data_out);
                      `endif
                    end
                    if ((lb_addr - (`ALC_HARDLEVEL_A)) % 2 == 16'b1) begin
                      if (!(lb_data_out === `HARD_THRESH_LOW)) begin
                        $display("FAILED: hard thresh low readback failed");
                        $finish;
                      end
                      `ifdef DESPERATE_DEBUG 
                      else 
                        $display("hard level low valid: %d ",lb_data_out);
                      `endif
                    end
                  end else if 
                    (lb_addr >= `ALC_SOFTLEVEL_A && lb_addr < `ALC_SOFTLEVEL_A + `ALC_SOFTLEVEL_L) begin
                    if ((lb_addr - (`ALC_SOFTLEVEL_A) ) % 2 == 16'b0) begin
                      if (!(lb_data_out === `SOFT_THRESH_HIGH)) begin
                        $display("FAILED: soft thresh high readback failed");
                        $finish;
                      end 
                      `ifdef DESPERATE_DEBUG 
                      else 
                        $display("soft level high valid: %d ",lb_data_out);
                      `endif
                    end
                    if ((lb_addr - (`ALC_SOFTLEVEL_A) ) % 2 == 16'b1) begin
                      if (!(lb_data_out === `SOFT_THRESH_LOW)) begin
                        $display("FAILED: soft thresh low readback failed");
                        $finish;
                      end
                      `ifdef DESPERATE_DEBUG 
                      else 
                        $display("soft level low valid: %d ",lb_data_out);
                      `endif
                    end
                  end else if
                    (lb_addr >= `ALC_FAULTVAL_A && lb_addr < `ALC_FAULTVAL_A + `ALC_FAULTVAL_L) begin
                    if ((lb_addr - (`ALC_FAULTVAL_A) ) % 2 == 16'b0) begin
                      if (!(lb_data_out === {11'b0,hard_chan})) begin
                        $display("FAILED: hard faultval readback failed, got %d, expected %d",
                                          lb_data_out,{11'b0,hard_chan});
                        $finish;
                      end
                      `ifdef DEBUG 
                      else 
                        $display("hard faultval valid: %d == %d",lb_data_out,{11'b0,hard_chan});
                      `endif
                    end
                    if ((lb_addr - (`ALC_FAULTVAL_A) ) % 2 == 16'b1) begin
                      if (lb_data_out != {11'b0,soft_chan}) begin
                        $display("FAILED: soft fault val readback failed");
                        $finish;
                      end
                      `ifdef DEBUG 
                      else 
                        $display("soft faultval valid: %d == %d",lb_data_out,{11'b0,soft_chan});
                      `endif
                    end
                  end else if (lb_addr >= `ALC_ADC_VALUE_A && 
                               lb_addr < `ALC_ADC_VALUE_A + `ALC_ADC_VALUE_L) begin
		  if (!(lb_data_out === ((lb_addr - (`ALC_ADC_VALUE_A) + `MIDDLE_VALUE )))) begin
                      $display("FAILED: invalid analogue value, channel %d, value %d, expected %d",
                                          lb_addr - (`ALC_ADC_VALUE_A), lb_data_out >> 3, (lb_addr - (`ALC_ADC_VALUE_A) + `MIDDLE_VALUE));
                      $finish;
                    end
                  end
                end
              end
            end
          end
        `STATE_WAITW:
          begin
            if (fault_countdown == 4'b1111) begin
              state<=`STATE_IDLE;
              fault_countdown<=4'b0;
              if (lb_addr >= `ALC_A && lb_addr < `ALC_A + `ALC_L) begin
                  $display("FAILED: invalid timeout on write: address %d",lb_addr);
                  $finish;
              end
`ifdef DEBUG
              $display("bus timeout at address: %x", lb_addr);
`endif
            end else begin
              fault_countdown<=fault_countdown + 4'b1;
              if (lb_wr)
                lb_wr<=1'b0;

              if (lb_strb) begin
                if (lb_addr < `ALC_A || lb_addr >= `ALC_A + `ALC_L) begin
                  $display("FAILED: invalid reply on write: address %d",lb_addr);
                  $finish;
                end else begin
`ifdef DESPERATE_DEBUG
              $display("lb: got write reply - %d", lb_addr);
`endif
                end
                state<=`STATE_IDLE;
                fault_countdown<=4'b0;
              end
            end
          end
      endcase
    end
  end

endmodule
