`timescale 1ns/10ps

`include "memlayout.v"

`define CLK_PERIOD      32'd100

`define STATE_START 2'd0
`define STATE_WAITR 2'd1
`define STATE_WAITW 2'd2
`define STATE_CHECK 2'd3

`define MODE_FAIL0 3'd0
`define MODE_CMND0 3'd1
`define MODE_ADDR0 3'd2
`define MODE_FAIL1 3'd3
`define MODE_CMND1 3'd4
`define MODE_ADDR1 3'd5
`define MODE_CMND2 3'd6

module TB_bus_monitor();
 
  reg reset;
  reg timeout;
  reg [15:0] lb_addr;
  reg [15:0] lb_data_in;
  wire [15:0] lb_data_out;
  reg lb_rd,lb_wr;
  wire lb_strb;
  wire clk; 

  bus_monitor bus_monitor(
    .reset(reset),
    .timeout(timeout),
    .lb_addr(lb_addr),.lb_data_in(lb_data_in),.lb_data_out(lb_data_out),
    .lb_rd(lb_rd),.lb_wr(lb_wr),.lb_strb(lb_strb),.lb_clk(clk)
  ); 

  
  reg [31:0] clk_counter;

  initial begin
`ifdef DEBUG
    $display("starting simulation");
`endif
    reset<=1'b1;
    clk_counter<=32'b0;
    #512
`ifdef DEBUG
    $display("clearing reset");
`endif
    reset<=1'b0;
    #999999
    $display("FAILED: simulation timed out");
    $finish;
  end

  assign clk = (clk_counter > (`CLK_PERIOD >> 1));
  always begin
    #1 clk_counter<=(clk_counter < `CLK_PERIOD ? clk_counter + 32'b1 : 32'b0);
  end

  reg [1:0] state;
  reg [2:0] mode;
  reg [3:0] fault_countdown;
  reg [15:0] lb_data_out_buff;
  
  always @(posedge clk) begin
    if (reset) begin
      state<=`STATE_START;
      fault_countdown<=4'b0;
      mode<=`MODE_FAIL0;
      lb_wr<=1'b0;
      lb_rd<=1'b0;
      lb_addr<=16'b0;
      lb_data_in<=16'b0;
    end else begin
`ifdef DESPERATE_DEBUG
      $display("state = %d , mode = %d, lb_strb = %d",state,mode,lb_strb, lb_rd, lb_wr);
`endif
      case (state) 
        `STATE_START: begin
          timeout<=1'b0;
          case (mode)
            `MODE_FAIL0: begin
              lb_addr<=`BUSMON_A + `BUSMON_L;
              lb_rd<=1'b1;
              state<=`STATE_WAITR;
            end
            `MODE_CMND0: begin
              lb_addr<=`BUSMON_CMND_A;
              lb_rd<=1'b1;
              state<=`STATE_WAITR;
            end
            `MODE_ADDR0: begin
              lb_addr<=`BUSMON_ADDR_A;
              lb_rd<=1'b1;
              state<=`STATE_WAITR;
            end
            `MODE_FAIL1: begin
              lb_addr<=`BUSMON_A + `BUSMON_L;
              lb_wr<=1'b1;
              state<=`STATE_WAITW;
            end
            `MODE_CMND1: begin
              lb_addr<=`BUSMON_CMND_A;
              lb_rd<=1'b1;
              state<=`STATE_WAITR;
            end
            `MODE_ADDR1: begin
              lb_addr<=`BUSMON_ADDR_A;
              lb_rd<=1'b1;
              state<=`STATE_WAITR;
            end
            `MODE_CMND2: begin
              lb_addr<=`BUSMON_CMND_A;
              lb_rd<=1'b1;
              state<=`STATE_WAITR;
            end
            default: begin
              $display("FAILED: invalid MODE");
              $finish;
            end
          endcase
        end
        `STATE_WAITW: begin
            if (fault_countdown == 4'b1111) begin
              state<=`STATE_CHECK;
              fault_countdown<=4'b0;
              if (lb_addr >= `BUSMON_A && lb_addr < `BUSMON_A + `BUSMON_L) begin
                $display("FAILED: invalid timeout on read: address %x",lb_addr);
                $finish;
              end else begin
                timeout<=1'b1;
`ifdef DEBUG
                $display("lb: bus timeout on address: %d", lb_addr);
`endif
              end
            end else begin
              fault_countdown<=fault_countdown + 4'b1;
              if (lb_wr)
                lb_wr<=1'b0;

              if (lb_strb) begin
                if (lb_addr < `BUSMON_A || lb_addr >= `BUSMON_A + `BUSMON_L) begin
                  $display("FAILED: invalid reply on read: address %x",lb_addr);
                  $finish;
                end
                state<=`STATE_CHECK;
              end
          end
        end
        `STATE_WAITR: begin
          if (fault_countdown == 4'b1111) begin
            state<=`STATE_CHECK;
            fault_countdown<=4'b0;
            if (lb_addr >= `BUSMON_A && lb_addr < `BUSMON_A + `BUSMON_L) begin
              $display("FAILED: invalid timeout on read: address %x",lb_addr);
              $finish;
            end else begin
              timeout<=1'b1;
`ifdef DEBUG
              $display("lb: bus timeout on address: %d", lb_addr);
`endif
            end
          end else begin
            fault_countdown<=fault_countdown + 4'b1;
            if (lb_rd)
              lb_rd<=1'b0;

            if (lb_strb) begin
              if (lb_addr < `BUSMON_A || lb_addr >= `BUSMON_A + `BUSMON_L) begin
                $display("FAILED: invalid reply on read: address %x",lb_addr);
                $finish;
              end
              state<=`STATE_CHECK;
              fault_countdown<=4'b0;
              lb_data_out_buff<=lb_data_out;
`ifdef DESPERATE_DEBUG
              $display("lbus: got data %d",lb_data_out); 
`endif
            end
          end

        end
        `STATE_CHECK: begin
          state<=`STATE_START;
          case (mode)
            `MODE_FAIL0: begin
              if (!(timeout === 1'b1)) begin
                $display("FAILED: no timeout 0");
                $finish;
              end
              mode<=`MODE_CMND0;
            end
            `MODE_FAIL1: begin
              if (!(timeout === 1'b1)) begin
                $display("FAILED: no timeout 1");
                $finish;
              end
              mode<=`MODE_CMND1;
            end
            `MODE_CMND0: begin
              if (!(lb_data_out_buff === 16'h8002)) begin
                $display("FAILED: incorrect cmnd 0, data == %b",lb_data_out_buff);
                $finish;
              end
              mode<=`MODE_ADDR0;
            end
            `MODE_CMND1: begin
              if (!(lb_data_out_buff === 16'h8001)) begin
                $display("FAILED: incorrect cmnd 1",lb_data_out_buff);
                $finish;
              end
              mode<=`MODE_ADDR1;
            end
            `MODE_ADDR0: begin
              if (!(lb_data_out_buff === `BUSMON_A + `BUSMON_L)) begin
                $display("FAILED: incorrect addr 0");
                $finish;
              end
              mode<=`MODE_FAIL1;
            end
            `MODE_ADDR1: begin
              if (!(lb_data_out_buff === `BUSMON_A + `BUSMON_L)) begin
                $display("FAILED: incorrect addr 1 -- addr = %d",lb_data_out_buff);
                $finish;
              end
              mode<=`MODE_CMND2;
            end
            `MODE_CMND2: begin
              if (!(lb_data_out_buff === 16'h0001)) begin
                $display("FAILED: incorrect cmnd 2");
                $finish;
              end
              $display("PASSED");
              $finish;
            end
          endcase
        end
      endcase
    end
  end
endmodule
