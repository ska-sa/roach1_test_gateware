`include "memlayout.v"

`timescale 1ns/10ps
`define SIM_MAX 150000000

`define LB_STATE_IDLE 2'd0
`define LB_STATE_WRITE 2'd1
`define LB_STATE_READ 2'd2

`define MODE_WRITE 2'd0
`define MODE_READ 2'd1
`define MODE_IDLE 2'd2

`ifdef SIMULATION
`define LBUS_TIMEOUT 32'd90
`else
`define LBUS_TIMEOUT 32'd90000
`endif
`define FLASH_START_ADDR 32'd1328
`define FLASH_STOP_ADDR 32'd1512

module TB_flashmem_controller();
  reg reset;

  wire [16:0] FM_ADDR;
  wire [15:0] FM_WD;
  wire FM_REN, FM_WEN, FM_PROGRAM;
  wire FM_RESET;
`ifdef MODELSIM
  wire [15:0]  FM_RD;
  wire FM_BUSY;
  wire [1:0] FM_STATUS;
`else
  reg [15:0]  FM_RD;
  reg FM_BUSY;
  reg [1:0] FM_STATUS;
`endif
  reg [15:0] lb_addr;
  reg [15:0] lb_data_in;
  reg lb_rd,lb_wr;
  reg lb_clk;
  wire [15:0] lb_data_out;
  wire lb_strb;
  
  flashmem_controller flashmem_controller(
  .reset(reset),
  .FM_ADDR(FM_ADDR), .FM_WD(FM_WD), .FM_RD(FM_RD),
  .FM_REN(FM_REN), .FM_WEN(FM_WEN), .FM_PROGRAM(FM_PROGRAM),
  .FM_BUSY(FM_BUSY), .FM_STATUS(FM_STATUS),
  .lb_addr(lb_addr),.lb_data_in(lb_data_in),.lb_data_out(lb_data_out),
  .lb_rd(lb_rd),.lb_wr(lb_wr),.lb_strb(lb_strb),
  .lb_clk(lb_clk)
  );

  reg [1:0] mode;
  reg [7:0] clk_counter;
  reg got_something;

  initial begin
    lb_clk<=1'b1;
    got_something<=1'b0;
    reset<=1'b1;
    clk_counter<=8'b0;
    lb_addr<=16'b0;
    mode<=`MODE_IDLE;
`ifdef DEBUG
    $display("Starting Simulation");
`endif
    #512
    reset<=1'b0;
    #10000
    mode<=`MODE_WRITE;
`ifdef DEBUG
    $display("Deasserting Reset");
`endif
    #`SIM_MAX
    $display("FAILED: simulation timed out");
    $finish;
  end

  always begin
    #1 clk_counter<=(clk_counter == 8'd50 ? 8'b0 : clk_counter + 8'b1);
  end
  always @(clk_counter) begin
    if (clk_counter == 8'd50)
      lb_clk<=~lb_clk;
  end

  /* Flash Memory Block */
`ifdef MODELSIM
  wire [15:0] temp;
  NVM NVM_inst(
   .ADDR({FM_ADDR,1'b0}),//last bit ignored due to 16'bit
   .WD({16'b0,FM_WD}),              
   .DATAWIDTH(2'b01),      
   .REN(FM_REN),            
   .READNEXT(1'b0),       
   .PAGESTATUS(1'b0),     
   .WEN(FM_WEN),     
   .ERASEPAGE(1'b0), 
   .PROGRAM(FM_PROGRAM),  
   .SPAREPAGE(1'b0), 
   .AUXBLOCK(1'b0),   
   .UNPROTECTPAGE(1'b0),    
   .OVERWRITEPAGE(1'b0),    
   .DISCARDPAGE(1'b0),      
   .OVERWRITEPROTECT(1'b0), 
   .PAGELOSSPROTECT(1'b1),  
   .PIPE(1'b0),             
   .LOCKREQUEST(1'b0),      
   .CLK(lb_clk),              
   .RESET(~reset),            
   .RD({temp,FM_RD}),
   .BUSY(FM_BUSY),
   .STATUS(FM_STATUS)
  );
`else

`define FM_STATE_IDLE 3'd0
`define FM_STATE_READ 3'd1
`define FM_STATE_WRITE 3'd2
`define FM_STATE_PROGRAM 3'd3
`define FM_WAIT_WRITE 32'd10
`define FM_WAIT_READ 32'd5
`ifdef SIMULATION
`define FM_WAIT_PROGRAM 32'd850
`else
`define FM_WAIT_PROGRAM 32'd85000
`endif

  reg [7:0] memory [65535:0];
  reg [2:0] fm_state;
  reg [31:0] wait_length;
  reg [10:0] dirty_page_index;
  reg dirty_page;
  reg [17:0] fm_addr;
  reg [15:0] fm_data;
  wire [10:0] fm_page_index = fm_addr[17:7];
  
  always @(posedge lb_clk) begin
    if (reset) begin
      fm_state<=`FM_STATE_IDLE;
      dirty_page<=1'b0;
      FM_STATUS<=2'b0;
      FM_BUSY<=1'b0;
    end else begin
      case (fm_state)
        `FM_STATE_IDLE: begin
          fm_addr<={FM_ADDR,1'b0};
          if (FM_REN) begin
            fm_state<=`FM_STATE_READ;
            wait_length<=`FM_WAIT_READ;
            FM_BUSY<=1'b1;
`ifdef DESPERATE_DEBUG
            $display("fm: read command, addr %d",FM_ADDR);
`endif
          end else if (FM_WEN) begin
            fm_state<=`FM_STATE_WRITE;
            wait_length<=`FM_WAIT_WRITE;
            FM_BUSY<=1'b1;
            fm_data<=FM_WD;
`ifdef DESPERATE_DEBUG
            $display("fm: write command, addr %d, data %d",FM_ADDR,FM_WD);
`endif
          end else if (FM_PROGRAM) begin
`ifdef DESPERATE_DEBUG
            $display("fm: program command, addr %d",FM_ADDR);
`endif
            fm_state<=`FM_STATE_PROGRAM;
            wait_length<=`FM_WAIT_PROGRAM;
            FM_BUSY<=1'b1;
          end
        end
        `FM_STATE_READ: begin
          if (wait_length==32'b0) begin
            FM_BUSY<=1'b0;
            FM_RD<={memory[fm_addr+1],memory[fm_addr]};
            fm_state<=`FM_STATE_IDLE;
`ifdef DEBUG
            $display("fm: read addr %d, read data %d, page_index %d",fm_addr[17:1],
                         {memory[fm_addr+1],memory[fm_addr]},fm_page_index);
`endif
            if (dirty_page == 1'b1 && dirty_page_index != fm_page_index) begin
`ifdef WARNING_MSGS_ON
              $display("fm: warning write to new page when dirty page present");
`endif
            end
          end else begin
            wait_length<=wait_length - 32'b1;
          end
        end
        `FM_STATE_WRITE: begin
          if (wait_length==32'b0) begin
            FM_BUSY<=1'b0;
            dirty_page<=1'b1;
            dirty_page_index<=fm_page_index;
            memory[fm_addr]<=fm_data[7:0];
            memory[fm_addr+1]<=fm_data[15:8];
            fm_state<=`FM_STATE_IDLE;
`ifdef DEBUG
            $display("fm: write addr %d, write data %d, page_index %d",fm_addr[17:1],fm_data,
                 fm_page_index);
`endif
            if (dirty_page == 1'b1 && dirty_page_index != fm_page_index) begin
`ifdef WARNING_MSGS_ON
              $display("fm: warning write to new page when dirty page present");
`endif
            end
          end else begin
            wait_length<=wait_length - 32'b1;
          end
        end
        `FM_STATE_PROGRAM: begin
          if (wait_length==32'b0) begin
            FM_BUSY<=1'b0;
            fm_state<=`FM_STATE_IDLE;
            dirty_page<=1'b0;
`ifdef DEBUG
            $display("fm: page program, dirty index %d, current index %d",
                        dirty_page_index,fm_page_index);
`endif
            if (dirty_page == 1'b0) begin
`ifdef WARNING_MSGS_ON
              $display("fm: warning, unnecessary program");
`endif
            end
            if (fm_page_index != dirty_page_index) begin
`ifdef WARNING_MSGS_ON
              $display("fm: program error, page index mismatch");
`endif
            end
          end else begin
            wait_length<=wait_length - 32'b1;
          end
        end
      endcase
    end
  end
`endif


/* LBus controller */
  reg [1:0] state;
  reg [31:0] fault_countdown;
  always @(posedge lb_clk) begin
    if (reset) begin
      state<=`LB_STATE_IDLE;
      lb_addr<=`FLASH_START_ADDR - 16'b1;
      lb_rd<=1'b0;
      lb_wr<=1'b0;
      fault_countdown<=32'b0;
    end else begin
      case (state)
        `LB_STATE_IDLE: begin
          case (mode) 
            `MODE_READ: begin
              lb_rd<=1'b1;
              if (lb_addr > `FLASH_STOP_ADDR) begin
                lb_addr <= `FLASH_START_ADDR;
              end else begin
                lb_addr<=lb_addr + 16'b1;
              end
              fault_countdown<=32'b0;
              state<=`LB_STATE_READ;
`ifdef DESPERATE_DEBUG
              $display("lb: read, addr %d",lb_addr + 16'b1);
`endif
            end
            `MODE_WRITE: begin
              lb_wr<=1'b1;
              lb_addr<=lb_addr + 16'b1;
              lb_data_in<=lb_addr + 16'b1;
              fault_countdown<=32'b0;
              state<=`LB_STATE_WRITE;
`ifdef DESPERATE_DEBUG
              $display("lb: write, addr %d, data %d",lb_addr + 16'b1,lb_addr + 16'b1);
`endif
            end
          endcase
        end
        `LB_STATE_READ: begin
          if (fault_countdown == `LBUS_TIMEOUT && 
              (lb_addr >= `FLASH_A && lb_addr <= `FLASH_A + (`FLASH_L - 1'b1))) begin
            $display("FAILED: invalid timeout on read: address %d",lb_addr);
            $finish;
          end
          if (fault_countdown == `LBUS_TIMEOUT && 
              (lb_addr < `FLASH_A || lb_addr > `FLASH_A + (`FLASH_L - 1'b1))) begin
            state<=`LB_STATE_IDLE;
`ifdef DEBUG
            $display("LBus read timeout on address = %d",lb_addr);
`endif
          end
          if (lb_strb && (lb_addr < `FLASH_A || lb_addr > `FLASH_A + (`FLASH_L - 1'b1))) begin
            $display("FAILED: invalid reply on read: address %d",lb_addr);
            $finish;
          end
          if (lb_strb && (lb_addr >= `FLASH_A && lb_addr <= `FLASH_A + (`FLASH_L -1'b1))) begin
`ifdef DEBUG
            $display("dv: comparing lb_data out = %d & lb_addr %d",lb_data_out,lb_addr);
`endif
            if (lb_data_out === lb_addr) begin
              state<=`LB_STATE_IDLE;
              got_something<=1'b1;
            end else begin
              $display("FAILED: data error on read: address %d, data %d, expected",
                lb_addr,lb_data_out,lb_addr);
                $finish;
            end
          end
          fault_countdown<=fault_countdown+1'b1;
          lb_rd<=1'b0;
        end
        `LB_STATE_WRITE: begin
          if (fault_countdown == `LBUS_TIMEOUT && 
              (lb_addr >= `FLASH_A && lb_addr <= `FLASH_A + `FLASH_L - 1'b1)) begin
            $display("FAILED: invalid timeout on write: address %d",lb_addr);
            $finish;
          end
          if (fault_countdown == `LBUS_TIMEOUT && 
              (lb_addr < `FLASH_A || lb_addr > `FLASH_A + `FLASH_L - 1'b1)) begin
            state<=`LB_STATE_IDLE;
`ifdef DEBUG
            $display("LBus write timeout on address = %d",lb_addr);
`endif
          end
          if (lb_strb && (lb_addr < `FLASH_A || lb_addr > `FLASH_A + `FLASH_L -1'b1)) begin
            $display("FAILED: invalid reply on write: address %d",lb_addr);
            $finish;
          end
          if (lb_strb && (lb_addr >= `FLASH_A && lb_addr <= `FLASH_A + `FLASH_L - 1'b1)) begin
            state<=`LB_STATE_IDLE;
          end
          fault_countdown<=fault_countdown+1'b1;
          lb_wr<=1'b0;
        end
      endcase
    end
  end
/* Mode Controller */
  always @(posedge lb_clk) begin
    if (!reset && lb_addr == `FLASH_STOP_ADDR && state == `LB_STATE_IDLE) begin
      case (mode)
        `MODE_WRITE: begin
          mode<=`MODE_READ;
`ifdef DEBUG
          $display("mode: entering read mode, lb_addr == %d, state == %d",lb_addr,state);
`endif
        end
        `MODE_READ: begin /*will not check last flash location*/
          if (got_something) begin
            $display("PASSED");
            $finish;
          end else begin
            $display("FAILED: got nothing");
            $finish;
          end
        end
      endcase
    end
  end

endmodule
