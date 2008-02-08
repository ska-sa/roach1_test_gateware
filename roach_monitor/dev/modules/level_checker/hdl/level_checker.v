`timescale 1ns/10ps
`include "memlayout.v"
`include "parameters.v"
  
 /* ADC interface Variables */
`define ADC_STATE_RQST 2'd0
`define ADC_STATE_WAIT 2'd1
`define ADC_STATE_COMPARE 2'd2

/*FIXME: this SUCKS!*/

module level_checker(
  soft_reset,hard_reset,
  adc_result,adc_channel,adc_rd,adc_strb,
  irq,power_down,no_power, stall_buffer,
  lb_addr,lb_data_in,lb_data_out,lb_rd,lb_wr,lb_strb,lb_clk,
  RB_ADDR,RB_WDATA,RB_RDATA,RB_WRB
  );
  input soft_reset,hard_reset;
 
  input adc_strb;
  output adc_rd;
  output [4:0] adc_channel;
  input [11:0] adc_result;

  input [15:0] lb_addr;
  input [15:0] lb_data_in;
  output [15:0] lb_data_out;
  input lb_rd,lb_wr,lb_clk;
  input stall_buffer;
  output lb_strb;

  output irq,power_down;
  input no_power;

  output [11:0] RB_WDATA;
  input  [11:0] RB_RDATA;
  output [12:0]  RB_ADDR;
  output RB_WRB;
  
  wire addressed=(lb_addr >= `ALC_A && lb_addr < `ALC_A + `ALC_L);
  wire [7:0] temp_addr=(lb_addr - (`ALC_A));
  
  wire value_addressed=(lb_addr >= (`ALC_ADC_VALUE_A) && 
                       lb_addr < (`ALC_ADC_VALUE_A + `ALC_ADC_VALUE_L));
  wire faultval_addressed=(lb_addr >= (`ALC_FAULTVAL_A) && 
                          lb_addr < (`ALC_FAULTVAL_A + `ALC_FAULTVAL_L));
  wire hardlevel_addressed=(lb_addr >= `ALC_HARDLEVEL_A && 
                           lb_addr < (`ALC_HARDLEVEL_A + `ALC_HARDLEVEL_L));
  wire softlevel_addressed=(lb_addr >= (`ALC_SOFTLEVEL_A) && 
                           lb_addr < (`ALC_SOFTLEVEL_A + `ALC_SOFTLEVEL_L));
  wire rbuff_addressed=(lb_addr >= `ALC_RBUFF_A && 
                           lb_addr < (`ALC_RBUFF_A + `ALC_RBUFF_L));
  
  wire [15:0] hardlevel_addr=(lb_addr-(`ALC_HARDLEVEL_A));
  wire [15:0] softlevel_addr=(lb_addr-(`ALC_SOFTLEVEL_A));
  wire [15:0] value_addr=(lb_addr-(`ALC_ADC_VALUE_A));
  wire [15:0] faultval_addr=(lb_addr-(`ALC_FAULTVAL_A));

 
  reg [15:0] lb_data_out;
  reg lb_strb;

  reg irq;
  reg power_down;
  
  reg [5:0] fault_val_hard;
  reg [5:0] fault_val_soft;

  reg [11:0] hard_level [63:0];
  reg [11:0] soft_level [63:0];
  
  reg [16:0] rbuffer_head;
  reg [16:0] frame_head;
  reg [16:0] user_access_index;
  reg rbuffer_pause;

  reg [1:0] adc_state; 
  reg adc_rd; 
  reg [4:0] adc_channel; 

  reg [127:0] value_set; /* threshold has been set? */

  reg [11:0] adc_values [31:0];

  reg RB_WRB;
  reg [12:0] RB_ADDR_buff;
  assign RB_ADDR = (RB_WRB ? user_access_index[12:0] : RB_ADDR_buff);
  assign RB_WDATA = adc_result;


  always @(posedge lb_clk) begin
    if (hard_reset) begin 
      /*need hard reset to maintain contents of history buffer after crash*/
      rbuffer_head<=10'b0;
      frame_head<=10'b0;
      fault_val_hard<=6'b100000;
      fault_val_soft<=6'b100000;
      value_set<=128'b0;
    end else if (soft_reset) begin
      RB_WRB<=1'b1;
      /*OR bus compatibility*/
      lb_data_out<=16'b0;
      lb_strb<=1'b0;
      rbuffer_pause<=1'b0;
      lb_strb<=1'b0;
      /*local goodies*/
      adc_state<=`ADC_STATE_RQST;
      adc_rd<=1'b0; 
      adc_channel<=5'b11111; 
      power_down<=1'b0;             
      irq<=1'b0;
      value_set<=128'b0;
`ifdef DEBUG 
      $display("ALC reset");
`endif
    end else begin
      /*LB Interface*/
      if (addressed & (lb_rd | lb_wr)) begin
        lb_strb<=1'b1; /*default action is to complete operation in 1 cycle*/
        if (hardlevel_addressed) begin
           if (lb_wr) begin
             hard_level[hardlevel_addr[5:0]] <=lb_data_in[11:0];
             value_set[{1'b0,hardlevel_addr[5:0]}] <=1'b1;
`ifdef DEBUG
        $display("alc: hard write -- index=%d, data=%x, high=%b",hardlevel_addr[5:0],lb_data_in[11:0],~hardlevel_addr[0]);
`endif
           end else begin
             lb_data_out<={4'b0,hard_level[hardlevel_addr[5:0]]};
`ifdef DEBUG
        $display("alc: hard read -- index=%d data=%d",hardlevel_addr[5:0],hard_level[hardlevel_addr[5:0]]);
`endif
           end
	end else if (softlevel_addressed) begin
           if (lb_wr) begin
             soft_level[softlevel_addr[5:0]] <=lb_data_in[11:0];
             value_set[{1'b1,softlevel_addr[5:0]}] <=1'b1;
`ifdef DEBUG
        $display("alc: soft write -- index=%d, data=%d, high=%b",softlevel_addr[5:0],lb_data_in[11:0], ~softlevel_addr[0]);
`endif
           end else begin
             lb_data_out<={4'b0,soft_level[softlevel_addr[5:0]]};
`ifdef DEBUG
        $display("alc: soft read -- index=%d data=%d",softlevel_addr[5:0],soft_level[softlevel_addr[5:0]]);
`endif
           end
	end else if (value_addressed) begin
	   if (lb_wr) begin
	   end else begin
             lb_data_out<={4'b0,adc_values[value_addr[4:0]]};
`ifdef DEBUG
	     $display("alc: value read -- channel == %d, data == %d",value_addr[4:0],adc_values[value_addr[4:0]]);
`endif
	   end
        end else if (faultval_addressed) begin
           if (lb_wr) begin
           end else begin
             if (faultval_addr[0] == 1'b0) begin 
               lb_data_out<={10'b0,fault_val_hard};
             end else begin
               lb_data_out<={10'b0,fault_val_soft};
             end
`ifdef DESPERATE_DEBUG
        $display("alc: fault value");
`endif
           end
	end else if (rbuff_addressed) begin
          if (lb_wr && ~lb_data_in) begin
            rbuffer_pause<=1'b0;
`ifdef DEBUG
        $display("alc: stopping ring buffer pause");
`endif
          end else if (lb_wr && lb_data_in) begin
            rbuffer_pause<=1'b1;
            user_access_index<=frame_head - 1'b1;
`ifdef DEBUG
        $display("alc: starting ring buffer pause");
`endif
          end else if (lb_rd && rbuffer_pause) begin
            if (user_access_index == rbuffer_head) begin
              lb_data_out<=16'h4000; /*end of buffer bit 14 asserted*/
`ifdef DEBUG
        $display("alc: ring buffer finished"); 
`endif
            end else begin
	      /*ring buffer read here*/
	      lb_data_out<={4'b0,RB_RDATA};
	      if (user_access_index == 17'b0) begin
                user_access_index<=`MB_RING_BUFFER_SIZE - 1'b1;
	      end else begin
                user_access_index<=user_access_index - 1'b1;
	      end
`ifdef DEBUG
        $display("alc: ring buffer read -- index == %d",user_access_index); 
`endif
            end
          end else if (lb_rd && ~rbuffer_pause) begin
            lb_data_out<=16'h8000; /*error: bit 15 asserted*/
          end
	end else begin
`ifdef DEBUG 
	  $display("warning: apparent error in memlayout");
`endif
	end
      end else begin
      /*OR bus compatibility*/
        lb_data_out<=16'b0;
        lb_strb<=1'b0;
      end

      /*Analogue Interface*/
      case (adc_state) 
        `ADC_STATE_RQST: begin
          if (~adc_strb) begin
	    adc_rd<=1'b1;
	    adc_channel<=adc_channel+5'b1;
	    adc_state<=`ADC_STATE_WAIT;
`ifdef DESPERATE_DEBUG 
	    $display("alc_adc: requesting sample from channel %d",adc_channel+5'b1);
`endif
          end
	end
	`ADC_STATE_WAIT: begin
	  if (adc_strb) begin
	    adc_rd<=1'b0;
            adc_values[adc_channel] <= adc_result[11:0];
`ifdef DESPERATE_DEBUG 
	    $display("alc_adc: got reply and value %d",{4'b0000,adc_result});
`endif
`ifdef DESPERATE_DEBUG
            $display("alc_adc: rbuff head = %d, frame_head = %d",frame_head+adc_channel,frame_head);
            $display("alc_adc: channel = %d, result = %d",adc_channel,adc_result[11:3]);
`endif
	    adc_state<=`ADC_STATE_COMPARE;
            /* ring buffer update */
            if (~rbuffer_pause | stall_buffer) begin
	      RB_WRB<=1'b0;
              RB_ADDR_buff <= frame_head+adc_channel;
	      if (frame_head + adc_channel < `MB_RING_BUFFER_SIZE) begin
                rbuffer_head<=(frame_head + adc_channel); 
	      end else begin
                rbuffer_head<=(frame_head + adc_channel) - `MB_RING_BUFFER_SIZE; 
	      end
              if (adc_channel == 5'd31) begin
	        if (rbuffer_head + 10'd2 < `MB_RING_BUFFER_SIZE) begin
                  frame_head<=rbuffer_head + 10'd2; 
		  //frame head sneaks ahead by 2
		end else begin
                  frame_head<=rbuffer_head + 10'd2 - `MB_RING_BUFFER_SIZE;
		end
              end
            end
	  end
	end
	`ADC_STATE_COMPARE: begin
	  adc_state<=`ADC_STATE_RQST;
	  RB_WRB<=1'b1;
	  if (value_set[{1'b0,adc_channel,1'b0}] && adc_result > hard_level[{adc_channel,1'b0}] || 
              value_set[{1'b0,adc_channel,1'b1}] && adc_result < hard_level[{adc_channel,1'b1}]) begin
             if (!no_power || (adc_channel == 32'b1 ||  adc_channel == 32'd4 || adc_channel == 32'd15)) begin
`ifdef ALC_POWER_DOWN_ENABLE
               power_down<=1'b1; /*only gets cleared with reset*/
`endif
               fault_val_hard<={1'b0,adc_channel};
`ifdef DEBUG 
	  $display("CRITICAL ALERT: channel==%d",adc_channel);
`endif
             end
          end else if (value_set[{1'b1,adc_channel,1'b0}] && adc_result > soft_level[{adc_channel,1'b0}] || 
              value_set[{1'b1,adc_channel,1'b1}] && adc_result < soft_level[{adc_channel,1'b1}]) begin
              /*TODO: remove this check*/
            if (!no_power || (adc_channel == 32'b1 ||  adc_channel == 32'd4 || adc_channel == 32'd15)) begin
`ifdef ALC_IRQ_ENABLE
	      irq<=1'b1;
`endif
              fault_val_soft<={1'b0,adc_channel};
`ifdef DEBUG 
	  $display("SOFT ALERT: channel == %d",adc_channel);
`endif
            end
          end

`ifdef DESPERATE_DEBUG 
	  $display("alc_adc: adc_channel %d ---adc value %d --- soft thresh %d ---- hard thresh %d",adc_channel,adc_result,soft_level[{adc_channel,1'b0}], hard_level[{adc_channel,1'b0}]);
	  $display("alc_adc: value set softh %d: softl %d: hardh %d : hardl %d ",
            value_set[{1'b1,adc_channel,1'b0}],value_set[{1'b1,adc_channel,1'b1}],
            value_set[{1'b0,adc_channel,1'b0}],value_set[{1'b0,adc_channel,1'b1}]);
`endif
	end
      endcase
      if (irq)begin /*assert irq for one cycle*/
`ifdef DEBUG
        $display("alc_irq: got ack");
`endif
        irq<=1'b0;
      end
    end
  end

endmodule
