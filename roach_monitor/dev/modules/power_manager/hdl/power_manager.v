`timescale 1ns/10ps
`include "memlayout.v"
`include "parameters.v"

`define PM_STATE_INITCONFIG 4'b0
`define PM_STATE_WAITCONFIG 4'b1
`define PM_STATE_IDLE 4'd2
`define PM_STATE_POWERUP 4'd3
`define PM_STATE_POWERDOWN 4'd4
`define PM_STATE_POWERDOWN_ANALYSE 4'd5
`define PM_STATE_NO_POWER 4'd6

`ifdef SIMULATION
`define USER_POWERUP_WAIT 32'b1 
`define GLOBAL_ADDRESS_WAIT_SHIFT 1 
`define WATCHDOG_TIMEOUT 32'd160
`else
`define USER_POWERUP_WAIT (`PM_USER_POWERUP_WAIT)
`define GLOBAL_ADDRESS_WAIT_SHIFT `PM_GLOBAL_ADDRESS_WAIT_SHIFT
`define WATCHDOG_TIMEOUT (`PM_WATCHDOG_TIMEOUT)
`endif

module power_manager(
  hard_reset,
  /* Power Control Signals */
  TRACK_2V5,
  SLP_0V9_0,SLP_0V9_1,
  INHIBIT_1V2,INHIBIT_1V8,INHIBIT_2V5,MARGIN_UP_2V5,MARGIN_DOWN_2V5,
  MGT0_1V2_PG,MGT1_1V2_PG,MGT0_1V2_EN,MGT1_1V2_EN,
  ENABLE_1V5,PG_1V5,
  AG_EN,
  /* Back-plane Signals */
  ATX_PS_ON_N,
  XMC_PD_N,
  BP_GA,BP_PERST_N,BP_PWREN_N,BP_ATNLED,BP_MPWRGD,BP_WAKE_N,
  BP_SCLI,BP_SCLO,BP_SDAI,BP_SDAO,BP_ALERT_N,

  /* Chassis Signals */
  CHS_ALERT_N,CHS_NOTIFY,PS_LEDS,
  /* Interaction Signals */
  chassis_irq,power_down,dma_crash,soft_reset,dma_done,no_power,
  /* LBus Signals */
  lb_addr,lb_data_in,lb_data_out,lb_rd,lb_wr,lb_strb,lb_clk
  );
  input hard_reset;
  /* Power Control Signals */
  output ATX_PS_ON_N;
  output TRACK_2V5;
  output [1:0] SLP_0V9_0;
  output [1:0] SLP_0V9_1;
  output INHIBIT_1V2,INHIBIT_1V8,INHIBIT_2V5,MARGIN_UP_2V5,MARGIN_DOWN_2V5;
  input MGT0_1V2_PG,MGT1_1V2_PG,PG_1V5;
  output MGT0_1V2_EN,MGT1_1V2_EN,ENABLE_1V5;
  output [9:0] AG_EN;
  /* Back-plane Signals */
  input [1:0] XMC_PD_N;
  input [4:0] BP_GA;
  input BP_PERST_N,BP_ATNLED;
  output BP_PWREN_N,BP_MPWRGD,BP_WAKE_N;
  input BP_SCLI,BP_SDAI;
  output BP_SCLO,BP_SDAO;
  output BP_ALERT_N;

  /* Chassis Signals */
  input CHS_ALERT_N;
  output CHS_NOTIFY;
  output [2:0] PS_LEDS;
  /* Interaction Signals */
  output chassis_irq,dma_crash,soft_reset;
  input power_down,dma_done;
  /* LBus Signals */
  input [15:0] lb_addr;
  input [15:0] lb_data_in;
  output [15:0] lb_data_out;
  input lb_rd,lb_wr;
  output lb_strb;
  input lb_clk;
  output no_power;

  wire [9:0] AG_EN;
  
  reg CHS_NOTIFY;


  reg BP_ALERT_N;
  reg BP_SCLO,BP_SDAO;
  reg BP_PWREN_N,BP_MPWRGD,BP_WAKE_N;
  
  wire addressed=(lb_addr >= `PC_A && lb_addr < `PC_A + `PC_L);
  reg [15:0] lb_data_out;
  reg lb_strb;

  reg [3:0] state;

  reg soft_reset_reg;
  assign soft_reset=soft_reset_reg | hard_reset;
  
  reg [1:0] user_shutdown;
  reg chassis_shutdown;
  reg chassis_shutdown_ack;
  reg [31:0] chassis_shutdown_timer;
  reg chassis_irq;

  reg crash_shutdown;
  reg crash_shutdown_ack;
  
  reg [4:0] crash_count;
  reg [4:0] watchdog_resets;
  reg [31:0] watchdog_timer;

  reg [31:0] powerup_wait;
  reg dma_crash;


  reg [31:0] beat_counter;
  reg beat;
  
  assign PS_LEDS = 
`ifdef SIMULATION
         state == `PM_STATE_NO_POWER ? 3'b111 : 
`else
         state == `PM_STATE_NO_POWER ? {1'b0,1'b0,1'b1}: 
`endif
         state == `PM_STATE_WAITCONFIG | state == `PM_STATE_POWERUP ? {1'b0,beat,1'b0} :
                                     {3'b110};
  
  reg powered_up;
  assign no_power=~powered_up;
  wire sequence_complete;
  
  power_sequence power_sequence(
    .reset(hard_reset), .clk(lb_clk),
    .power_up(state==`PM_STATE_POWERUP), .power_down(state==`PM_STATE_POWERDOWN),
    .sequence_complete(sequence_complete),
    /* Power Control Signals */
    .ATX_PS_ON_N(ATX_PS_ON_N),
    .TRACK_2V5(TRACK_2V5),
    .SLP_0V9_0(SLP_0V9_0),.SLP_0V9_1(SLP_0V9_1),
    .INHIBIT_1V2(INHIBIT_1V2),.INHIBIT_1V8(INHIBIT_1V8),.INHIBIT_2V5(INHIBIT_2V5),
    .MARGIN_UP_2V5(MARGIN_UP_2V5),.MARGIN_DOWN_2V5(MARGIN_DOWN_2V5),
    .MGT0_1V2_EN(MGT0_1V2_EN),.MGT1_1V2_EN(MGT1_1V2_EN),
    .ENABLE_1V5(ENABLE_1V5),
    .AG_EN(AG_EN)
  );  

  reg byebye;
  reg powerup_strb;

  always @(posedge lb_clk) begin
    if (hard_reset) begin
      BP_PWREN_N <= 1'b1;
      
      BP_ALERT_N <= 1'b1;
      BP_SCLO <= 1'b1; 
      BP_SDAO <= 1'b1;
      BP_MPWRGD <=1'b1;
      BP_WAKE_N <=1'b0;
`ifdef PM_COLD_START
      byebye<=1'b1;
`else
      byebye<=1'b0;
`endif

      
      powered_up<=1'b0;
      watchdog_timer<=32'b0;
      watchdog_resets<=5'b0;
      beat_counter<=32'b0;
      beat<=1'b1;
      `ifdef DEBUG
      $display("pm: got hard reset");
      `endif
      lb_strb<=1'b0;
      lb_data_out<=16'b0;

      soft_reset_reg<=1'b1;
      
      user_shutdown<=2'b0;
      
      crash_shutdown<=1'b0;
      crash_shutdown_ack<=1'b0;
      crash_count<=5'b0;
      
      chassis_shutdown<=1'b0;
      chassis_shutdown_ack<=1'b0;
      chassis_shutdown_timer<=32'b0;
      chassis_irq<=1'b0;
      
      state<=`PM_STATE_INITCONFIG;
      powerup_wait<={BP_GA, `GLOBAL_ADDRESS_WAIT_SHIFT'b0};
      dma_crash<=1'b0;
      CHS_NOTIFY<=1'b0;
      powerup_strb<=1'b0;
    end else begin
      powerup_strb<=1'b0;
      soft_reset_reg<=1'b0;
      if (beat_counter == ((`PM_BEAT_PERIOD) >> 1)) begin
        beat_counter<=32'b0;
        beat<=~beat;
      end else begin
        beat_counter<=beat_counter+32'b1;
      end
      case (state) 
        `PM_STATE_INITCONFIG: begin
`ifdef DEBUG         
          $display("pm: starting power-up sequence");
`endif
          soft_reset_reg<=1'b1;
          state<=`PM_STATE_WAITCONFIG;
          if (powerup_wait != 32'b0)
            powerup_wait<=powerup_wait - 32'b1;
        end
        `PM_STATE_WAITCONFIG: begin
          if (powerup_wait != 32'b0) begin
            powerup_wait<=powerup_wait - 32'b1;
          end else begin
            if (dma_done) begin
	      if (byebye) begin
                state<=`PM_STATE_NO_POWER;
	      end else begin
                state<=`PM_STATE_POWERUP;
`ifdef DEBUG         
          $display("pm: dma tranfer done->waiting for powering up");
`endif
	      end
              dma_crash<=1'b0;
            end
          end
        end
        `PM_STATE_POWERUP: begin
          if (sequence_complete) begin
            state<=`PM_STATE_IDLE;
	    powered_up<=1'b1;
`ifdef DEBUG         
            $display("pm: powered up");
`endif
          end
        end
        `PM_STATE_POWERDOWN: begin
          if (sequence_complete) begin
	    powered_up<=1'b0;
            state<=`PM_STATE_POWERDOWN_ANALYSE;
`ifdef DEBUG         
            $display("pm: powered down");
`endif
          end
        end
        `PM_STATE_POWERDOWN_ANALYSE: begin
          if (crash_shutdown && crash_count >= `PM_MAX_CRASHES - 1) begin
            state<=`PM_STATE_INITCONFIG;
            dma_crash<=1'b1;
	    byebye<=1'b1;
`ifdef DEBUG         
            $display("pm: crash -> no power");
`endif
          end else if (crash_shutdown) begin
            state<=`PM_STATE_INITCONFIG;
            powerup_wait<=`USER_POWERUP_WAIT;
            crash_count<=crash_count + 5'b1;
            crash_shutdown<=1'b0;
            dma_crash<=1'b1;
`ifdef DEBUG         
            $display("pm: crash -> init_config, crash_count=%d",crash_count);
`endif
          end else if (user_shutdown) begin
            powerup_wait<=`USER_POWERUP_WAIT;
            user_shutdown<=2'b0;
            state<=user_shutdown[1] ? `PM_STATE_NO_POWER : `PM_STATE_INITCONFIG;
`ifdef DEBUG         
            $display("pm: user_shutdown -> init_config");
`endif
          end else if (chassis_shutdown & chassis_shutdown_ack) begin
`ifdef DEBUG         
            $display("pm: chassis shutdown -> no power");
`endif
            chassis_irq<=1'b0;
            state<=`PM_STATE_NO_POWER;
          end else if (watchdog_timer >= `WATCHDOG_TIMEOUT - 32'b1) begin
`ifdef DEBUG         
            $display("pm: watchdog overflow, count = %d",watchdog_resets);
`endif
	    if (watchdog_resets >= `PM_WATCHDOG_RESETS_MAX - 5'b1) begin
              state<=`PM_STATE_NO_POWER;
            end else begin
              watchdog_resets<=watchdog_resets + 5'b1;
              watchdog_timer<=32'b0;
              powerup_wait<=`USER_POWERUP_WAIT;
              state<=`PM_STATE_INITCONFIG;
            end
          end else begin
`ifdef DEBUG         
            $display("pm: ??? -> no power");
`endif
            state<=`PM_STATE_NO_POWER;
          end
        end
        `PM_STATE_IDLE: begin
        /* General IO events */
	  
          if (power_down) begin
            crash_shutdown<=1'b1;
            state<=(powered_up ? `PM_STATE_POWERDOWN : `PM_STATE_POWERDOWN_ANALYSE);
`ifdef DEBUG         
            $display("pm: got crash");
`endif
          end else if (chassis_shutdown) begin
	    if (chassis_shutdown_timer >= `PM_SHUTDOWN_WAIT | chassis_shutdown_ack) begin
              state<=(powered_up ? `PM_STATE_POWERDOWN : `PM_STATE_POWERDOWN_ANALYSE);
              chassis_shutdown<=1'b0;
              chassis_shutdown_timer<=32'b0;
              chassis_shutdown_ack<=1'b0;
              CHS_NOTIFY<=1'b1;
`ifdef DEBUG         
              $display("pm: got chassis power down");
`endif
	    end else begin
	      chassis_shutdown_timer<=chassis_shutdown_timer + 32'b1;
	    end
          end else if (user_shutdown) begin
            state<=(powered_up ? `PM_STATE_POWERDOWN : `PM_STATE_POWERDOWN_ANALYSE);
          end else begin
`ifdef PM_WATCHDOG_ENABLE
	    if (watchdog_timer >= `WATCHDOG_TIMEOUT - 1) begin
`ifdef DEBUG         
            $display("pm: watchdog overflow");
`endif
              state<=(powered_up ? `PM_STATE_POWERDOWN : `PM_STATE_POWERDOWN_ANALYSE);
            end else begin
	      watchdog_timer<=watchdog_timer + 32'b1;
            end
`endif
	  end
          if (~CHS_ALERT_N & ~chassis_shutdown) begin
`ifdef DEBUG         
            $display("pm: got chassis alert, %d",$time);
`endif
            chassis_shutdown<=1'b1;
            chassis_irq<=1'b1;
          end 
          if (crash_shutdown_ack) begin
`ifdef DEBUG         
            $display("pm: clearing crash count");
`endif
            crash_shutdown_ack<=1'b0;
            crash_count<=5'b0;
          end
        end
        `PM_STATE_NO_POWER: begin
          if (powerup_strb)
            state<=`PM_STATE_INITCONFIG;
`ifdef DEBUG         
            $display("pm: no power - bye bye");
`endif
          /* no beans -- wait to be remove and blink status LEDs*/
        end
      endcase
      /* LBus stuff */
      if (addressed & (lb_wr | lb_rd)) begin
        lb_strb<=1'b1;
        case (lb_addr)
	  `PC_GA_A: begin
	    if (lb_rd) begin
	      lb_data_out<={11'b0 , BP_GA};
	    end
	  end
	  `PC_PD_A: begin
	    if (lb_rd) begin
	      lb_data_out<={14'b0 , ~XMC_PD_N};
	    end
	  end
          `PC_SHUTDOWN_A: begin
            if (lb_wr && lb_data_in) begin
              if (lb_data_in) begin
                user_shutdown<=2'b11;
              end else begin
                user_shutdown<=2'b01;
              end
`ifdef DEBUG         
            $display("pm_lbus: user_shutdown");
`endif
            end
          end
          `PC_CHASSIS_ALERT_A: begin
            if (lb_wr && lb_data_in && chassis_shutdown) begin
              chassis_shutdown_ack<=1'b1;
`ifdef DEBUG         
            $display("pm_lbus: chassis_ack");
`endif
            end else if (lb_rd) begin
`ifdef DEBUG         
            $display("pm_lbus: chassis read -- %d, %d",chassis_shutdown, $time);
`endif
              if (chassis_shutdown)
                lb_data_out<=16'hffff;
              else
                lb_data_out<=16'h0000;
            end
          end
          `PC_CRASH_A: begin
            if (lb_rd) begin
              if (crash_count != 5'b0)
                lb_data_out<=16'hffff;
              else
                lb_data_out<=16'h0000;
            end else if (lb_wr && lb_data_in) begin
              crash_shutdown_ack<=1'b1;
`ifdef DEBUG         
            $display("pm_lbus: crash_ack");
`endif
            end
          end
	  `PC_WATCHDOG_A: begin
	    if (lb_wr) begin
	      watchdog_timer<=32'b0;
	      watchdog_resets<=5'b0;
	    end else begin
	      lb_data_out<={11'b0,watchdog_resets};
	    end
	  end
	  `PC_POWERUP_A: begin
	    if (lb_wr) begin
              powerup_strb<=1'b1;
              byebye<=1'b0;
	    end 
          end
        endcase
      end else begin
        lb_strb<=1'b0;
        lb_data_out<=16'h0000;
      end
    end
  end
endmodule
