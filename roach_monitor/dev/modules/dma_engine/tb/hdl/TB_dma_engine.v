`timescale 1ns/10ps

`include "memlayout.v"

`define WAIT_FLASHMEM_WRITE 17'd20
`define WAIT_FLASHMEM_MISS  17'd900
`define WAIT_FLASHMEM_READ  17'd20
`define WAIT_FLASHROM       17'd3
`define WAIT_ALC            17'd3
`define WAIT_ABCONF         17'd3

`define CLK_PERIOD           32'd100 /*100ns*/

module TB_dma_engine();
  reg dma_crash;
  reg soft_reset,hard_reset;
  reg [15:0] lb_data_in;
  wire [15:0] lb_data_out;
  wire [15:0] lb_addr;
  wire lb_rd,lb_wr,lb_timeout;
  reg lb_strb; 
  wire dma_done;
  wire clk;
  
  dma_engine dma_engine0(
  .reset(soft_reset),
  .dma_crash(dma_crash),.dma_done(dma_done),
  .lb_addr(lb_addr),.lb_data_in(lb_data_in),.lb_data_out(lb_data_out),
  .lb_rd(lb_rd),.lb_wr(lb_wr), .lb_strb(lb_strb),
  .lb_clk(clk),
  .lb_timeout(lb_timeout)
  );

  reg [31:0] clk_counter;

  reg task_done_from,task_done_flash,task_done_abconf,task_done_alc,task_done_rbuff;
  reg crash_condition;
  reg timeout_expected;
  
  initial begin
`ifdef DEBUG
    $display("starting simulation");
`endif
    crash_condition<=1'b0;
    task_done_from<=1'b0;
    task_done_rbuff<=1'b0;
    task_done_flash<=1'b0;
    task_done_abconf<=1'b0;
    task_done_alc<=1'b0;
    timeout_expected<=1'b0;

    hard_reset<=1'b1;
    soft_reset<=1'b0;
    clk_counter<=32'b0;
    #512
    hard_reset<=1'b0;
`ifdef DEBUG
    $display("deasserting reset");
`endif
    #9999999
    $display("FAILED: simulation timed out");
    $finish;
  end

  assign clk = (clk_counter > (`CLK_PERIOD >> 1));
  always begin
    #1 clk_counter<=(clk_counter < `CLK_PERIOD ? clk_counter + 32'b1 : 32'b0);
  end

  reg dma_deasserted;
  always @(posedge clk) begin
    if (hard_reset) begin
      dma_deasserted<=1'b1;
    end else begin
      if (dma_done === 1'b1 && dma_deasserted) begin
        dma_deasserted<=1'b0;
        if (~task_done_from) begin
          $display("FAILED: from task not completed");
          $finish;
        end else if (crash_condition && ~task_done_rbuff) begin
          $display("FAILED: ring_buffer task not completed");
          $finish;
        end else if (crash_condition && ~task_done_flash) begin
          $display("FAILED: flash task not completed");
          $finish;
        end else if (~task_done_abconf) begin
          $display("FAILED: from abconf not completed");
          $finish;
        end else if (~task_done_alc) begin
          $display("FAILED: from alc not completed");
          $finish;
        end else begin
          task_done_from<=1'b0;
          task_done_rbuff<=1'b0;
          task_done_flash<=1'b0;
          task_done_abconf<=1'b0;
          task_done_alc<=1'b0;
          if (crash_condition)  begin
`ifdef DEBUG
            $display("sim: crash dma operation completed");
`endif
            $display("PASSED");
            $finish;
          end else begin
            crash_condition<=1'b1;
`ifdef DEBUG
            $display("sim: normal dma operation completed");
`endif
          end
        end
      end else if (~dma_done) begin
        dma_deasserted<=1'b1;
      end
    end
  end

  always @(posedge clk) begin
    if (soft_reset) begin
    end else begin
      if (lb_timeout & ~timeout_expected) begin
            $display("FAILED: invalid timeout");
            $finish;
      end
    end
  end
   
   /*fake power manager*/ 
  always @(posedge clk)begin
    if (hard_reset) begin
      soft_reset<=1'b1;
      dma_crash<=1'b0;
    end else begin
      soft_reset<=1'b0;
      if (crash_condition && !dma_crash) begin
        dma_crash<=1'b1;
        soft_reset<=1'b1;
      end
    end
  end
   /*fake flashrom*/ 
  reg [31:0] from_wait;
  reg [6:0] from_index;
  always @(posedge clk)begin
    if (soft_reset) begin
      from_wait<=32'b0;
      from_index<=7'b0;
    end else begin
      if (from_wait == 32'b0) begin
       if (lb_strb == 1'b1)
         lb_strb<=1'b0;
      end else if (from_wait == 32'b1) begin
       lb_strb<=1'b1;
       from_wait<=from_wait - 32'b1;
      end else begin
       from_wait<=from_wait - 32'b1;
      end

      if (lb_addr >= `FROM_A && lb_addr < `FROM_A + `FROM_L) begin
        if (lb_rd) begin
          from_index<=from_index + 7'b1;
`ifdef DESPERATE_DEBUG
          $display("from: read on addr = %d, count = %d",lb_addr,from_index); 
`endif
          if (from_index == 7'd40 + 7'd64 - 7'd1) begin
            task_done_from<=1'b1;
          end else if (from_index > 7'd40 + 7'd64 - 7'd1) begin
            $display("FAILED: flash index exceeded allowable value");
            $finish;
          end
          lb_data_in<=16'b0;
          from_wait<=`WAIT_FLASHROM;
        end
      end 
    end
  end
  
   /*fake flashmem*/ 
  reg [31:0] fm_wait;
  reg [9:0] fm_index;
  always @(posedge clk)begin
    if (soft_reset) begin
      fm_wait<=32'b0;
      fm_index<=11'b0;
    end else begin
      if (fm_wait == 32'b0) begin
       if (lb_strb == 1'b1)
         lb_strb<=1'b0;
      end else if (fm_wait == 32'b1) begin
       lb_strb<=1'b1;
       fm_wait<=fm_wait - 32'b1;
      end else begin
       fm_wait<=fm_wait - 32'b1;
      end
      if (lb_addr >= `FLASH_DATA_A && lb_addr <= `FLASH_DATA_A + (`FLASH_DATA_L - 16'b1)) begin
        if (lb_rd) begin
          lb_data_in<=16'b0;
          fm_wait<=`WAIT_FLASHMEM_READ;
        end else if (lb_wr) begin
`ifdef DESPERATE_DEBUG
            $display("fm: write on addr = %d, count = %d",lb_addr,fm_index); 
`endif
          fm_index<=fm_index + 1'b1;
          if (fm_index > 1024) begin
            $display("FAILED: flash memory index exceeded allowable value");
            $finish;
          end else if (fm_index >= 911) begin
            task_done_flash<=1'b1;
          end
          if (lb_addr[5:0] == 6'h3f) begin
            fm_wait<=`WAIT_FLASHMEM_WRITE;
          end else begin
            fm_wait<=`WAIT_FLASHMEM_WRITE;
          end
        end
      end 
    end
  end
   /*fake abconf*/ 
  reg [31:0] abconf_wait;
  reg [5:0] abconf_index;
  always @(posedge clk)begin
    if (soft_reset) begin
      abconf_wait<=32'b0;
      abconf_index<=6'b0;
    end else begin
      if (abconf_wait == 32'b0) begin
       if (lb_strb == 1'b1)
         lb_strb<=1'b0;
      end else if (abconf_wait == 32'b1) begin
       lb_strb<=1'b1;
       abconf_wait<=abconf_wait - 32'b1;
      end else begin
       abconf_wait<=abconf_wait - 32'b1;
      end
      if (lb_addr >= `ACM_A && lb_addr < `ACM_A + `ACM_L) begin
        if (lb_wr) begin
`ifdef DESPERATE_DEBUG
            $display("abconf: write on addr = %d, count = %d",lb_addr,abconf_index); 
`endif
          if (abconf_index < 6'd39) begin
            abconf_index<=abconf_index + 1'b1;
          end else begin
            task_done_abconf<=1'b1;
          end
          abconf_wait<=`WAIT_ABCONF;
          if (lb_addr - `ACM_A == 16'd41)
            task_done_abconf<=1'b1;
        end
      end 
    end
  end

   /*fake alc*/ 
  reg [31:0] alc_wait;
  reg [15:0] buffer_index;
  reg [9:0] alc_index;
  reg ring_buffer_started;
  always @(posedge clk)begin
    if (soft_reset) begin
      alc_wait<=32'b0;
      ring_buffer_started<=1'b0;
      alc_index<=10'b0;
    end else begin
      if (alc_wait == 32'b0) begin
       if (lb_strb == 1'b1)
         lb_strb<=1'b0;
      end else if (alc_wait == 32'b1) begin
       lb_strb<=1'b1;
       alc_wait<=alc_wait - 32'b1;
      end else begin
       alc_wait<=alc_wait - 32'b1;
      end
      if (lb_addr >= `ALC_A && lb_addr < `ALC_A + `ALC_L) begin
        if (lb_addr == `ALC_RBUFF_A) begin
          if (lb_wr) begin
            if (lb_data_out) begin
              if (ring_buffer_started) begin
                $display("FAILED: spurious buffer operation start command");
                $finish;
              end
`ifdef DESPERATE_DEBUG
              $display("alc: ring buffer start");
`endif
              ring_buffer_started<=1'b1;
              buffer_index<=1'b0;
              alc_wait<=`WAIT_ALC;
            end else begin
              if (~ring_buffer_started) begin
                $display("FAILED: spurious buffer operation stop command");
                $finish;
              end
`ifdef DESPERATE_DEBUG
              $display("alc: ring buffer stop");
`endif
              ring_buffer_started<=1'b0;
              task_done_rbuff<=1'b1;
              alc_wait<=`WAIT_ALC;
            end
          end else if (lb_rd) begin
            if (~ring_buffer_started) begin
              $display("FAILED: spurious buffer operation stop command");
              $finish;
            end
`ifdef DESPERATE_DEBUG
            $display("alc: ring buffer read, count = %d",buffer_index);
`endif
            alc_wait<=`WAIT_ALC;
            if (buffer_index >= 13'd1000) begin
              lb_data_in<=16'h4000;
            end else begin
              lb_data_in<=16'b0;
              buffer_index<=buffer_index + 1'b1;
            end
          end
        end else begin
          if (lb_wr) begin
            alc_wait<=`WAIT_ALC;
            alc_index<=alc_index + 1'b1;
            if (alc_index >= 7'd64) begin
              $display("FAILED: alc index max exceeded");
              $finish;
            end else if (alc_index == 7'd63) begin
              task_done_alc<=1'b1;
            end
`ifdef DESPERATE_DEBUG
            $display("alc: write on addr = %d, count = %d",lb_addr,alc_index); 
`endif
          /*check addresses match dma range*/
          end
        end
      end 
    end
  end
endmodule
