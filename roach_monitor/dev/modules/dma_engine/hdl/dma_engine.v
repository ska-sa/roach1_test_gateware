`timescale 1ns/10ps
`include "memlayout.v"
`include "parameters.v"

`define STATE_START   2'd0
`define STATE_WAITW    2'd1
`define STATE_WAITR    2'd2
`define STATE_DONE    2'd3

`define MODE_FLASH  2'd0
`define MODE_ALC    2'd1
`define MODE_ABCONF 2'd2
`define MODE_DONE 2'd3

`define TIMEOUT_FLASH 17'd100000 /* 9ms*/
`define TIMEOUT_OTHER 17'd256

module dma_engine(
  reset,
  dma_crash,dma_done,
  lb_addr,lb_data_in,lb_data_out,
  lb_rd,lb_wr,lb_strb,
  lb_clk,lb_timeout
  );
  input reset;
  input dma_crash;
  output dma_done;
 
  output [15:0] lb_addr;
  output [15:0] lb_data_out;
  input [15:0] lb_data_in;
  output lb_rd,lb_wr;
  input lb_strb,lb_clk;
  output lb_timeout;
  
  reg lb_rd,lb_wr;
  reg lb_timeout;
  reg [15:0] lb_addr;
  reg [15:0] lb_data_out;
  reg [15:0] lb_data_in_buff;
  reg [31:0] timeout;

  reg dma_done;
  
  reg [1:0] state;
  reg [2:0] mode;
  reg [3:0] progress;
  reg [15:0] index;

  always @(posedge lb_clk) begin
    if (reset) begin
      lb_rd<=1'b0;
      lb_wr<=1'b0;
      lb_data_out<=16'b0;
      lb_addr<=16'b0;
      lb_timeout<=1'b0;

      dma_done<=1'b0;
      
//      state<=`STATE_START;
      state<=`STATE_DONE;
      progress<=3'b0;
      index<=16'b0;
      if (dma_crash)
        mode<=`MODE_FLASH;
      else 
        mode<=`MODE_ALC;

`ifdef DEBUG
      $display("dma: got reset");
`endif
    end else begin
      case (state)
        `STATE_START: begin
          case (mode)
            `MODE_FLASH: begin
              if (progress == 3'd0) begin /* setup ring buffer access */
                lb_addr<=`ALC_RBUFF_A;
                lb_wr<=1'b1;
                lb_data_out<=16'hffff;
                progress<=3'd1;
                state<=`STATE_WAITW;
                index<=16'b0;
`ifdef DESPERATE_DEBUG
                $display("dma:  ring buffer initialize");
`endif
              end else if (progress == 3'd1) begin /* ring buffer read */
                lb_addr<=`ALC_RBUFF_A;
                lb_rd<=1'b1;
                progress<=3'd2;
                state<=`STATE_WAITR;
`ifdef DESPERATE_DEBUG
                $display("dma: flash ring buffer read");
`endif
              end else if (progress == 3'd2) begin /* flash write */
                if (lb_data_in_buff[14] || lb_data_in_buff[15] || index==(`MB_RING_BUFFER_SIZE)-1) begin 
                /* stop on done or error or if index exceeds max [shouldn't happen] */
                  progress<=3'd3;
                  state<=`STATE_WAITW;
		  lb_wr<=1'b1;
		  lb_data_out<={12'hff0 , 1'b0 , lb_data_in_buff[14], lb_data_in_buff[15], index==(`MB_RING_BUFFER_SIZE)-1};
                  lb_addr<=(`FLASH_DATA_A) + index + (`FLASH_CRASH_OFFSET);
`ifdef DESPERATE_DEBUG
                $display("dma: ring buffer finished");
`endif
                end else begin 
                  lb_wr<=1'b1;
                  lb_data_out<=lb_data_in_buff;
                  progress<=3'd1;
                  state<=`STATE_WAITW;
                  lb_addr<=(`FLASH_DATA_A) + index + (`FLASH_CRASH_OFFSET);
                  index<=index + 16'b1;
`ifdef DESPERATE_DEBUG
                $display("dma: flash write, addr = %d",`FLASH_DATA_A + index);
`endif
                end
              end else if (progress==3'd3) begin /* stop ring buffer read */
                lb_addr<=`ALC_RBUFF_A;
                lb_wr<=1'b1;
                lb_data_out<=16'h0;
                progress<=3'd0;
                index<=16'b0;
                mode<=`MODE_ALC;
                state<=`STATE_WAITW;
`ifdef DESPERATE_DEBUG
                $display("dma: ring buffer closed");
`endif
              end
            end
            `MODE_ALC: begin
              if (progress == 3'b0) begin
                lb_rd<=1'b1;
                lb_addr<=`FROM_LEVELS_A + index;
                progress<=3'd1;
                state<=`STATE_WAITR;
`ifdef DESPERATE_DEBUG
                $display("dma: from levels read, addr = %d",`FROM_LEVELS_A + index);
`endif
              end else if (progress == 3'd1) begin
                lb_wr<=1'b1;
                lb_addr<=`ALC_HARDLEVEL_A + index;
                lb_data_out<=(lb_data_in_buff << 4); /*12 bits for comp vals*/
                progress<=3'd0;
                if (index >= `FROM_LEVELS_L - 10'b1) begin
                  index<=16'd0;
                  mode<=`MODE_ABCONF;
                end else begin
                  index<=index+16'b1;
                end
                state<=`STATE_WAITW;
`ifdef DESPERATE_DEBUG
                $display("dma: alc levels write, addr = %d",`ALC_HARDLEVEL_A + index);
`endif
              end 
            end
            `MODE_ABCONF: begin
              if (progress == 3'b0) begin
                lb_rd<=1'b1;
                lb_addr<=`FROM_ACMDATA_A + index;
                progress<=3'd1;
                state<=`STATE_WAITR;
`ifdef DESPERATE_DEBUG
                $display("dma: from abconf read, addr = %d",`FROM_ACMDATA_A + index);
`endif
              end else if (progress == 3'd1) begin
                lb_wr<=1'b1;
                lb_addr<=`ACM_AQUADS_A + index;
                lb_data_out<=lb_data_in_buff;
                progress<=3'd0;
                if (index >= `FROM_ACMDATA_L - 10'b1) begin
                  index<=16'd0;
                  mode<=`MODE_DONE;
                end else begin
                  index<=index+16'b1;
                end
                state<=`STATE_WAITW;
`ifdef DESPERATE_DEBUG
                $display("dma: abconf write, addr = %d",`ACM_AQUADS_A + index);
`endif
              end
            end
            `MODE_DONE: begin
              state<=`STATE_DONE;
            end
          endcase
          timeout<=32'b0; /*reset timeout*/
          lb_timeout<=1'b0;
        end
        `STATE_WAITW: begin
          lb_wr<=1'b0;
          if (lb_strb) begin
            state<=`STATE_START;
          end else if (timeout >= `TIMEOUT_FLASH) begin
            lb_timeout<=1'b1;
            state<=`STATE_START;
          end else begin
            timeout<=timeout + 17'b1;
          end
        end
        `STATE_WAITR: begin
          lb_rd<=1'b0;
          if (lb_strb) begin
            lb_data_in_buff<=lb_data_in;
            state<=`STATE_START;
          end else if (timeout >= `TIMEOUT_OTHER) begin
            lb_timeout<=1'b1;
            state<=`STATE_START;
          end else begin
            timeout<=timeout + 17'b1;
          end
        end
        `STATE_DONE: begin
          dma_done<=1'b1;
          lb_wr<=1'b0;
          lb_rd<=1'b0;
          lb_addr<=16'b0;
          lb_data_out<=16'b0;
          lb_timeout<=1'b0;
        end
      endcase
    end 
  end
endmodule
