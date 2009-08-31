`timescale 1ns/10ps
`include "flashmem_controller.vh"

module flashmem_controller(
    wb_clk_i, wb_rst_i,
    wb_stb_i, wb_cyc_i, wb_we_i,
    wb_adr_i, wb_dat_i, wb_dat_o,
    wb_ack_o,
    FM_CLK, FM_RESET,
    FM_ADDR, FM_WD, FM_RD,
    FM_REN, FM_WEN, FM_PROGRAM,
    FM_BUSY, FM_STATUS, FM_PAGESTATUS
  );
  input  wb_clk_i, wb_rst_i;
  input  wb_stb_i, wb_cyc_i, wb_we_i;
  input  [15:0] wb_adr_i;
  input  [15:0] wb_dat_i;
  output [15:0] wb_dat_o;
  output wb_ack_o;

  output FM_CLK, FM_RESET;
  output [16:0] FM_ADDR;
  output [15:0] FM_WD;
  output FM_PAGESTATUS;
  output FM_REN, FM_WEN, FM_PROGRAM;
  input  [31:0]  FM_RD;
  input  FM_BUSY;
  input  [1:0] FM_STATUS;

  /****************** Common Signals ***********************/

  wire fm_sel = wb_adr_i > 16'd63; //is the flash selected
  wire [15:0] fm_addr = wb_adr_i - 16'd64; //the flash memory address selected
  wire  [9:0] page_index = fm_addr[15:6]; //the page portion of the flash address

  reg dirty_page; //has the current page been dirtied
  reg  [9:0] dirty_page_index; //which page is the current page

  reg [15:0] status_address; // which page are we going to check the status of
  reg [31:0] status_register;

  reg  [2:0] fm_status; //flash status after transfer

  reg flash_write_trans; //initiate a flash write transfer
  reg flash_read_trans; //initiate a flash read transfer
  reg flash_stat_trans; //initiate a flash status read transfer
  reg flash_sync_trans; //initiate a flash dirty page sync
  reg flash_trans_done; //strobed after transaction is complete

  reg wb_ack_o_int;

  /***************** Wishbone State Machine ***************/

  reg state;
  localparam STATE_IDLE = 1'd0;
  localparam STATE_WAIT = 1'd1;

  wire wb_trans = wb_cyc_i & wb_stb_i & ~(wb_ack_o);

  reg [3:0] wb_dat_o_src;

  reg [15:0] FM_RD_reg;

  assign wb_dat_o = wb_dat_o_src == 4'd0 ? FM_RD_reg :
                    wb_dat_o_src == 4'd1 ? {7'b0, FM_BUSY, 6'b0, fm_status} :
                    wb_dat_o_src == 4'd2 ? (dirty_page ? {6'b0, dirty_page_index} : 16'hffff) :
                    wb_dat_o_src == 4'd3 ? status_register[31:16] :
                    wb_dat_o_src == 4'd4 ? status_register[15:0] :
                    16'b0;
  assign wb_ack_o = wb_ack_o_int | flash_trans_done;


  always @(posedge wb_clk_i) begin
    //strobes
    wb_ack_o_int <= 1'b0;
    flash_write_trans <= 1'b0;
    flash_read_trans <= 1'b0;
    flash_stat_trans <= 1'b0;
    flash_sync_trans <= 1'b0;

    if (wb_rst_i) begin
      state<=STATE_IDLE;
      wb_dat_o_src <= 4'd0;
    end else begin
      case (state)
        STATE_IDLE: begin
           if (wb_trans & fm_sel) begin
           /***** Direct Flash page Read and Write *****/
             if (wb_we_i) begin
               flash_write_trans <= 1'b1;
             end else begin
               flash_read_trans <= 1'b1;
             end
             wb_dat_o_src <= 4'd0;
             state <= STATE_WAIT;
           end else if (wb_trans) begin
             case (wb_adr_i[5:0]) //adr 0 -> 63 is registers
               `REG_FLASH_STATUS: begin
                 if (~wb_we_i) begin
		   wb_dat_o_src <= 4'd1; //status bits
                   wb_ack_o_int <= 1'b1;
                 end
`ifdef DEBUG
               $display("fc: performing op status read");
`endif
               end
               `REG_PAGE_STATUS_1: begin
	             	  wb_ack_o_int <=1'b1;
                  wb_dat_o_src <= 3;
               end
               `REG_PAGE_STATUS_0: begin
	             	  wb_ack_o_int <=1'b1;
                  wb_dat_o_src <= 4;
               end
               `REG_PAGE_STATUS_CTRL: begin
                 if (wb_we_i) begin
                   wb_dat_o_src <= 4'd0;  //FM data out
                   flash_stat_trans <= 1'b1;
		               status_address <= wb_dat_i;
                   state <= STATE_WAIT;
`ifdef DEBUG
                   $display("fc: performing page status fetch");
`endif
                 end else begin
	             	   wb_ack_o_int <=1'b1;
                 end
               end
               `REG_DIRTY_PAGE_STATUS: begin
		 wb_ack_o_int <=1'b1;
                 wb_dat_o_src <= 4'd2;  // dirty page bits
`ifdef DEBUG
                 $display("fc: performing dirty page read");
`endif
               end
               `REG_DIRTY_PAGE_SYNC: begin
                 wb_dat_o_src <= 4'd15;  //zeros
                 if (wb_we_i) begin
                   flash_sync_trans <= 1'b1;
                   state <= STATE_WAIT;
`ifdef DEBUG
                   $display("fc: performing page status read");
`endif
                 end else begin
                   wb_ack_o_int <= 1'b1;
                 end
               end
             endcase
           end
         end
        STATE_WAIT: begin
          if (flash_trans_done) begin
             state <= STATE_IDLE;
          end
        end
      endcase
    end
  end

  /********************* Flash Memory State Machine **********************/

  reg [1:0] fm_state;
  localparam FM_STATE_IDLE    = 2'd0;
  localparam FM_STATE_READ    = 2'd1;
  localparam FM_STATE_WRITE   = 2'd2;
  localparam FM_STATE_PROGRAM = 2'd3;

  assign FM_WD = wb_dat_i;
  assign FM_ADDR = fm_state == FM_STATE_READ && FM_PAGESTATUS ? {1'b0, status_address}   : //the address is latched on the strobe
                   fm_state == FM_STATE_PROGRAM               ? {dirty_page_index, 6'b0} :
                   {1'b0, fm_addr};
  assign FM_CLK = wb_clk_i;
  assign FM_RESET = ~wb_rst_i;

  reg FM_REN,FM_WEN,FM_PROGRAM, FM_PAGESTATUS;

  reg wait_cycle;    // wait one cycle for response
  reg status_read;   // is this a status op?
  reg program_state; // action after program: wr == 1, rd == 0
  reg sync_only;

  reg flash_write_trans_buf; //initiate a flash write transfer
  reg flash_read_trans_buf; //initiate a flash read transfer
  reg flash_stat_trans_buf; //initiate a flash status read transfer
  reg flash_sync_trans_buf; //initiate a flash dirty page sync

  always @(posedge wb_clk_i) begin
    //Single cycle strobes
    wait_cycle <= 1'b0;
    FM_PROGRAM <= 1'b0;
    FM_WEN <= 1'b0;
    FM_REN <= 1'b0;
    FM_PAGESTATUS <= 1'b0;
    flash_trans_done <= 1'b0;

    if (!FM_BUSY) begin
      flash_write_trans_buf <= 1'b0;
      flash_read_trans_buf  <= 1'b0;
      flash_stat_trans_buf  <= 1'b0;
      flash_sync_trans_buf  <= 1'b0;
    end

    if (wb_rst_i) begin
      dirty_page<=1'b0;
      dirty_page_index<=10'b0;
      fm_status<=3'b111;
      fm_state <= FM_STATE_IDLE;
    end else begin
      case (fm_state)
        FM_STATE_IDLE: begin
          if (FM_BUSY) begin
            flash_write_trans_buf <= flash_write_trans_buf | flash_write_trans;
            flash_read_trans_buf  <= flash_read_trans_buf  | flash_read_trans;
            flash_stat_trans_buf  <= flash_stat_trans_buf  | flash_stat_trans;
            flash_sync_trans_buf  <= flash_sync_trans_buf  | flash_sync_trans;
          end else begin
            wait_cycle<=1'b1;
            if (flash_stat_trans | flash_stat_trans_buf) begin
              FM_REN <= 1'b1;
              FM_PAGESTATUS <= 1'b1;
              fm_state<=FM_STATE_READ;
              status_read <= 1'b1;
            end else if (flash_sync_trans | flash_sync_trans_buf) begin
              sync_only <= 1'b1;
              FM_PROGRAM <= 1'b1;
              fm_state <= FM_STATE_PROGRAM;
            end else if (flash_write_trans | flash_write_trans_buf) begin
              if (dirty_page && (dirty_page_index != page_index)) begin
                program_state<=1'b1; // tell the FM state machine that this was a program before write
                sync_only <= 1'b0;
                FM_PROGRAM <= 1'b1;
                fm_state <= FM_STATE_PROGRAM;

                `ifdef DEBUG
                $display("fc: performing write - data = %d, addr = %d", wb_dat_i, {1'b0,fm_addr});
                $display("... buffer page mismatch - program necessary");
                $display("... current buffer index = %d, new buffer index = %d", dirty_page_index, page_index);
                `endif
              end else begin
                FM_WEN<=1'b1;
                fm_state<=FM_STATE_WRITE;
`ifdef DEBUG
                $display("fc: performing write - data = %d, addr = %d",wb_dat_i,{1'b0,fm_addr});
`endif
              end
            end else if (flash_read_trans | flash_read_trans_buf) begin
              status_read <= 1'b0;
              if (dirty_page && (dirty_page_index != page_index)) begin
                program_state <= 1'b0; // tell the FM state machine that this was a program before read
                sync_only <= 1'b0;
                FM_PROGRAM <= 1'b1;
                fm_state <= FM_STATE_PROGRAM;
`ifdef DEBUG
                $display("fc: performing read - addr = %d",{1'b0,fm_addr});
                $display("... buffer page mismatch - program necessary");
                $display("... current buffer index = %d, new buffer index = %d", dirty_page_index,page_index);
`endif
              end else begin
                FM_REN<=1'b1;
                fm_state<=FM_STATE_READ;
`ifdef DEBUG
                $display("fc: performing read - addr = %d",{1'b0,fm_addr});
`endif
             end
           end
          end
        end
        FM_STATE_PROGRAM: begin
          if (~FM_BUSY & ~wait_cycle) begin
            wait_cycle<=1'b1;
            if (sync_only) begin
              fm_state <= FM_STATE_IDLE;
              flash_trans_done <= 1'b1;
            end else if (program_state) begin
              FM_WEN <= 1'b1;
              fm_state <= FM_STATE_WRITE;
            end else begin
              FM_REN <= 1'b1;
              fm_state <= FM_STATE_READ;
            end
            fm_status <= FM_STATUS;
            if (FM_STATUS == 2'b00) begin
              dirty_page <= 1'b0;
              dirty_page_index<={1'b0,fm_addr[15:6]};
`ifdef DEBUG
              $display("fc: program completed - program state = %d", program_state);
`endif
            end else begin
`ifdef SIMULATION
              $display("warning - fc: apparent error during program command - status = %b", FM_STATUS);
`endif
            end
          end
        end
        FM_STATE_READ: begin
          if (~FM_BUSY & ~wait_cycle) begin
            fm_status <= FM_STATUS;
            flash_trans_done <= 1'b1;
            fm_state <= FM_STATE_IDLE;
            FM_RD_reg <= FM_RD[15:0];
            if (status_read)
              status_register <= FM_RD[31:0];

            if (FM_STATUS == 2'b00) begin
              if (~status_read) // only update dirty page index if the read not status
                dirty_page_index <= FM_ADDR[15:6];
`ifdef DEBUG
              $display("fc: read completed, data = %d", FM_RD);
`endif
            end else begin
`ifdef SIMULATION
              $display("warning - fc: apparent error during program - status = %b",FM_STATUS);
`endif
            end
          end
        end
        FM_STATE_WRITE: begin
          if (~FM_BUSY & ~wait_cycle) begin
            fm_status <= FM_STATUS;
            flash_trans_done <= 1'b1;
            fm_state <= FM_STATE_IDLE;

            if (FM_STATUS == 2'b00) begin
              dirty_page <= 1'b1;
              dirty_page_index <= FM_ADDR[15:6];
`ifdef DEBUG
              $display("fc: write completed -- data = %d, addr = %d", FM_WD, FM_ADDR);
`endif
            end else begin
`ifdef SIMULATION
              $display("warning - fc: apparent error during program - status = %b", FM_STATUS);
`endif
            end
          end
        end
      endcase
    end
  end 
endmodule
