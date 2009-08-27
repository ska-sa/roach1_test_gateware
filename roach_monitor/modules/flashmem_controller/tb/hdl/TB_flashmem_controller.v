`timescale 10ns/10ps

`define SIM_LENGTH 1500000
`define CLK_PERIOD 4

`define TEST_LENGTH 1000

module TB_flashmem_controller();
  wire clk;
  reg  reset;

  wire FM_CLK, FM_RESET;
  wire [16:0] FM_ADDR;
  wire [15:0] FM_WD;
  wire FM_REN, FM_WEN, FM_PROGRAM, FM_PAGESTATUS;

  wire [31:0]  FM_RD;
  wire FM_BUSY;
  wire [1:0] FM_STATUS;

  reg [15:0] wb_adr_i;
  reg [15:0] wb_dat_i;
  reg wb_stb_i, wb_cyc_i, wb_we_i;
  wire [15:0] wb_dat_o;
  wire wb_ack_o;

  flashmem_controller flashmem_controller(
    .wb_clk_i(clk), .wb_rst_i(reset),
    .wb_stb_i(wb_stb_i), .wb_cyc_i(wb_cyc_i), .wb_we_i(wb_we_i),
    .wb_adr_i(wb_adr_i), .wb_dat_i(wb_dat_i), .wb_dat_o(wb_dat_o),
    .wb_ack_o(wb_ack_o),
    .FM_CLK(FM_CLK), .FM_RESET(FM_RESET),
    .FM_ADDR(FM_ADDR), .FM_WD(FM_WD), .FM_RD(FM_RD),
    .FM_REN(FM_REN), .FM_WEN(FM_WEN), .FM_PROGRAM(FM_PROGRAM),
    .FM_BUSY(FM_BUSY), .FM_STATUS(FM_STATUS), .FM_PAGESTATUS(FM_PAGESTATUS)
  );

  reg [7:0] clk_counter;
  reg mode_wait;

  initial begin
    reset<=1'b1;
    mode_wait <= 1'b1;
    clk_counter<=8'b0;
`ifdef DEBUG
    $display("sim: Starting Simulation");
`endif
    #512
    reset<=1'b0;
`ifdef DEBUG
    $display("sim: Deasserting Reset");
`endif
    #1000
    mode_wait <= 1'b0;
    #`SIM_LENGTH
    $display("FAILED: simulation timed out");
    $finish;
  end

  assign clk = clk_counter < ((`CLK_PERIOD) >> 1);

  always begin
    #1 clk_counter<=(clk_counter >= (`CLK_PERIOD) - 1 ? 8'b0 : clk_counter + 8'b1);
  end

  /* Flash Memory Block */
`ifdef MODELSIM
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
   .CLK(FM_CLK),              
   .RESET(FM_RESET),            
   .RD(FM_RD),
   .BUSY(FM_BUSY),
   .STATUS(FM_STATUS)
  );
`else

  reg [15:0]  FM_RD_reg;
  reg FM_BUSY_reg;
  reg [1:0] FM_STATUS_reg;
  assign FM_RD = FM_RD_reg;
  assign FM_BUSY = FM_BUSY_reg;
  assign FM_STATUS = FM_STATUS_reg;

`define FM_STATE_IDLE 3'd0
`define FM_STATE_READ 3'd1
`define FM_STATE_WRITE 3'd2
`define FM_STATE_PROGRAM 3'd3
`define FM_WAIT_WRITE 32'd10
`define FM_WAIT_READ 32'd5
`define FM_WAIT_PROGRAM 32'd850

  reg [7:0] memory [65535:0];
  reg [2:0] fm_state;
  reg [31:0] wait_length;
  reg [10:0] dirty_page_index;
  reg dirty_page;
  reg [17:0] fm_addr;
  reg [15:0] fm_data;
  wire [10:0] fm_page_index = fm_addr[17:7];
  
  always @(posedge FM_CLK) begin
    if (~FM_RESET) begin
      fm_state<=`FM_STATE_IDLE;
      dirty_page<=1'b0;
      FM_STATUS_reg<=2'b0;
      FM_BUSY_reg<=1'b0;
    end else begin
      case (fm_state)
        `FM_STATE_IDLE: begin
          fm_addr<={FM_ADDR,1'b0};
          if (FM_REN) begin
            fm_state<=`FM_STATE_READ;
            wait_length<=`FM_WAIT_READ;
            FM_BUSY_reg<=1'b1;
`ifdef DESPERATE_DEBUG
            $display("fm: read command, addr %d",FM_ADDR);
`endif
          end else if (FM_WEN) begin
            fm_state<=`FM_STATE_WRITE;
            wait_length<=`FM_WAIT_WRITE;
            FM_BUSY_reg<=1'b1;
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
            FM_BUSY_reg<=1'b1;
          end
        end
        `FM_STATE_READ: begin
          if (wait_length==32'b0) begin
            FM_BUSY_reg<=1'b0;
            FM_RD_reg<={memory[fm_addr+1],memory[fm_addr]};
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
            FM_BUSY_reg<=1'b0;
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
            FM_BUSY_reg<=1'b0;
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


/********************** Common Signals ****************************/
  reg [1:0] mode;
`define MODE_WAIT  2'd0
`define MODE_WRITE 2'd1
`define MODE_READ  2'd2

  reg mode_done;
  reg [15:0] master_mem [1024 * 64 - 1:0];
/*********************** Mode Control **************************/
 
  integer i;
  always @(posedge clk) begin
    if (reset) begin
      mode <= `MODE_WAIT;
    end else begin
      case (mode)
        `MODE_WAIT: begin
          if (~mode_wait) begin
            mode <= `MODE_WRITE;
          end
        end
        `MODE_WRITE: begin
          if (mode_done) begin
            mode <= `MODE_READ;
`ifdef DEBUG
            $display("mode: WRITE mode passed");
`endif
          end
        end
        `MODE_READ: begin
          if (mode_done) begin
            for (i=0; i < `TEST_LENGTH; i=i+1) begin
              if (master_mem[i] !== i) begin
                $display("FAILED: data invalid - got %d, expected %d", master_mem[i], i);
                $finish;
              end else if (i == `TEST_LENGTH - 1) begin
                $display("PASSED");
                $finish;
              end
            end
          end
        end
      endcase
    end
  end

/******************** WB Master controller *******************/

  reg [1:0] state;
`define STATE_COMMAND 2'd0
`define STATE_COLLECT 2'd1
`define STATE_WAIT    2'd2

  reg [31:0] counter;

  always @(posedge clk) begin
    wb_cyc_i <= 1'b0;
    wb_stb_i <= 1'b0;
    mode_done <= 1'b0;

    if (reset | mode_wait) begin
      state <=`STATE_COMMAND;
      counter <= 32'b0;
    end else begin
      case (state)
        `STATE_COMMAND: begin
          case (mode) 
            `MODE_WRITE: begin
              wb_cyc_i <= 1'b1;
              wb_stb_i <= 1'b1;
              wb_we_i <= 1'b1;
              wb_adr_i <= counter + 16'd64;
              wb_dat_i <= counter;
              state<=`STATE_COLLECT;
`ifdef DESPERATE_DEBUG
              $display("wbm: write, addr %d, data %d", counter + 16'd64, counter);
`endif
            end
            `MODE_READ: begin
              wb_cyc_i <= 1'b1;
              wb_stb_i <= 1'b1;
              wb_we_i <= 1'b0;
              wb_adr_i <= counter + 16'd64;
              state<=`STATE_COLLECT;
`ifdef DESPERATE_DEBUG
              $display("wbm: read, addr %d", counter + 16'd64);
`endif
            end
          endcase
        end
        `STATE_COLLECT: begin
          if (wb_ack_o) begin
            if (counter == `TEST_LENGTH - 1) begin
              counter <= 32'b0;
              mode_done <= 1'b1;
              state<=`STATE_WAIT;
            end else begin
              counter <= counter + 1;
              state<=`STATE_COMMAND;
            end
            if (wb_we_i) begin
`ifdef DESPERATE_DEBUG
              $display("wbm: write_response");
`endif
            end else begin
              master_mem[counter[15:0]] <= wb_dat_o;
`ifdef DESPERATE_DEBUG
              $display("wbm: read response, data %d, counter %d", wb_dat_o, counter);
`endif
            end
          end
        end
        `STATE_WAIT: begin
          state<=`STATE_COMMAND;
        end
      endcase
    end
  end

endmodule
