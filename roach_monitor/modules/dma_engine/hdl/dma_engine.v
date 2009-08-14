`timescale 1ns/10ps

module dma_engine(
    wb_clk_i, wb_rst_i,
    wb_cyc_o, wb_stb_o, wb_we_o,
    wb_adr_o, wb_dat_o, wb_dat_i,
    wb_ack_i, wb_err_i,
    soft_reset, dma_crash,
    dma_done,
    disable_crashes
  );
  parameter FROM_ACM_A        = 16'd0;
  parameter FROM_LC_A         = 16'd40;
  parameter LC_THRESHS_A      = 16'd128;
  parameter ACM_AQUADS_A      = 16'd384;
  parameter VS_INDIRECT_A     = 16'd512;
  parameter SYSTIME_A         = 16'd8;
  parameter CRASHSRC_A        = 16'd12;
  parameter CRASHVAL_A        = 16'd13;
  parameter LEVELSVALID_A     = 16'd14;
  parameter SYSCONFIG_A       = 16'd576;
  parameter FLASH_A           = 16'd1024;
  parameter FLASH_SYSCONFIG_A = 16'hffff;

  input  wb_clk_i, wb_rst_i;
  output wb_cyc_o, wb_stb_o, wb_we_o;
  output [15:0] wb_adr_o;
  output [15:0] wb_dat_o;
  input  [15:0] wb_dat_i;
  input  wb_ack_i, wb_err_i;

  input  soft_reset;
  input  dma_crash;
  output dma_done;
  input  disable_crashes;

  reg [2:0] mode;
  localparam MODE_FLASH     = 3'd0;
  localparam MODE_LC        = 3'd1;
  localparam MODE_ACM       = 3'd2;
  localparam MODE_SYSCONFIG = 3'd3;
  localparam MODE_DONE      = 3'd4;

  reg [13:0] progress; //this needs to be big enough to handle max ring buffer size

  reg [15:0] wb_dat_buf;

  reg [2:0] state;

  reg wb_cyc_o;
  assign wb_stb_o = wb_cyc_o;
  reg wb_we_o;
  reg [15:0] wb_adr_o;
  assign wb_dat_o = wb_dat_buf;

  assign dma_done = mode == MODE_DONE;

`ifdef DEBUG
  always @(*) begin
    $display("dma: mode = %d", mode);
  end
`endif

  always @(posedge wb_clk_i) begin
    wb_cyc_o <= 1'b0;
    if (wb_rst_i) begin
      mode     <= MODE_DONE;
      progress <= 14'd0;
      state    <= 3'b0;
    end else begin
      case (mode) 
  /***************** Flash Memory Crash Backup State Machine ***************/        
        MODE_FLASH: begin
          if (progress == 14'd0) begin
            /* Freeze the ring buffer */
            case (state)
              3'd0: begin
                wb_cyc_o <= 1'b1;
                wb_we_o  <= 1'b1;
                wb_adr_o <= VS_INDIRECT_A;
                wb_dat_buf <= 16'd0; 
                state <= 3'd1;
              end
              3'd1: begin
                if (wb_ack_i || wb_err_i) begin
                  progress <= 1;
                  state <= 3'd0;
                end
              end
            endcase
          end else if (progress == 14'd1) begin
            /* Write the marker and the Current time */
            case (state)
              3'd0: begin
                wb_cyc_o   <= 1'b1;
                wb_we_o    <= 1'b1;
                wb_adr_o   <= FLASH_A;
                wb_dat_buf <= 16'hdead; 
                state      <= 3'd1;
              end
              3'd1: begin
                if (wb_ack_i || wb_err_i) begin
                  wb_cyc_o   <= 1'b1;
                  wb_we_o    <= 1'b0;
                  wb_adr_o   <= SYSTIME_A;
                  state      <= 3'd2;
                end
              end
              3'd2: begin
                if (wb_ack_i || wb_err_i) begin
                  wb_cyc_o   <= 1'b1;
                  wb_we_o    <= 1'b1;
                  wb_adr_o   <= FLASH_A + 1;
                  wb_dat_buf <= wb_dat_i; 
                  state      <= 3'd3;
                end
              end
              3'd3: begin
                if (wb_ack_i || wb_err_i) begin
                  wb_cyc_o   <= 1'b1;
                  wb_we_o    <= 1'b0;
                  wb_adr_o   <= SYSTIME_A + 1;
                  state      <= 3'd4;
                end
              end
              3'd4: begin
                if (wb_ack_i || wb_err_i) begin
                  wb_cyc_o   <= 1'b1;
                  wb_we_o    <= 1'b1;
                  wb_adr_o   <= FLASH_A + 2;
                  wb_dat_buf <= wb_dat_i; 
                  state      <= 3'd5;
                end
              end
              3'd5: begin
                if (wb_ack_i || wb_err_i) begin
                  wb_cyc_o   <= 1'b1;
                  wb_we_o    <= 1'b0;
                  wb_adr_o   <= SYSTIME_A + 2;
                  state      <= 3'd6;
                end
              end
              3'd6: begin
                if (wb_ack_i || wb_err_i) begin
                  wb_cyc_o   <= 1'b1;
                  wb_we_o    <= 1'b1;
                  wb_adr_o   <= FLASH_A + 3;
                  wb_dat_buf <= wb_dat_i; 
                  state      <= 3'd7;
                end
              end
              3'd7: begin
                if (wb_ack_i || wb_err_i) begin
                  progress   <= 2;
                  state      <= 3'd0;
                end
              end
            endcase
          end else if (progress == 14'd2) begin
              /* Write the channel and level which caused the crash */
            case (state)
              3'd0: begin
                wb_cyc_o   <= 1'b1;
                wb_we_o    <= 1'b0;
                wb_adr_o   <= CRASHSRC_A;
                state      <= 3'd1;
              end
              3'd1: begin
                if (wb_ack_i || wb_err_i) begin
                  wb_cyc_o   <= 1'b1;
                  wb_we_o    <= 1'b1;
                  wb_adr_o   <= FLASH_A + 4;
                  wb_dat_buf <= wb_dat_i; 
                  state      <= 3'd2;
                end
              end
              3'd2: begin
                if (wb_ack_i || wb_err_i) begin
                  wb_cyc_o   <= 1'b1;
                  wb_we_o    <= 1'b0;
                  wb_adr_o   <= CRASHVAL_A;
                  state      <= 3'd3;
                end
              end
              3'd3: begin
                if (wb_ack_i || wb_err_i) begin
                  wb_cyc_o   <= 1'b1;
                  wb_we_o    <= 1'b1;
                  wb_adr_o   <= FLASH_A + 5;
                  wb_dat_buf <= wb_dat_i; 
                  state      <= 3'd4;
                end
              end
              3'd4: begin
                if (wb_ack_i || wb_err_i) begin
                  progress   <= 3;
                  state      <= 3'd0;
                end
              end
            endcase
          end else begin
            /* Dump the ring buffer */
            case (state)
              3'd0: begin
                wb_cyc_o <= 1'b1;
                wb_we_o  <= 1'b0;
                wb_adr_o <= VS_INDIRECT_A;
                state    <= 3'd1;
              end
              3'd1: begin
                if (wb_ack_i || wb_err_i) begin
                  wb_dat_buf <= wb_dat_i;
                  wb_cyc_o <= 1'b1;
                  wb_we_o  <= 1'b1;
                  wb_adr_o <= FLASH_A + 6 + progress - 3;
                  state <= 3'd2;
                end
              end
              3'd2: begin
                if (wb_ack_i || wb_err_i) begin
                  if (wb_dat_buf[15] || progress == {13{1'b1}}) begin
                    /* ring buffer dumped - let it run again */
                    wb_cyc_o <= 1'b1;
                    wb_we_o  <= 1'b1;
                    wb_adr_o <= VS_INDIRECT_A;
                    wb_dat_buf <= 16'hffff; 
                    state <= 3'd3;
                  end else begin
                    state <= 3'd0;
                    progress <= progress + 1;
                  end
                end
              end
              3'd3: begin
                if (wb_ack_i || wb_err_i) begin
                  state <= 3'd0;
                  progress <= 14'd0;
                  mode <= MODE_LC;
                end
              end
            endcase
          end
        end
  /***************** Level Checker Configuration State Machine ***************/        
        MODE_LC: begin
          case (state)
            3'd0: begin
              wb_cyc_o <= 1'b1;
              wb_we_o  <= 1'b0;
              wb_adr_o <= FROM_LC_A + progress;
              state <= 3'd1;
            end
            3'd1: begin
              if (wb_ack_i || wb_err_i) begin
                if (wb_dat_i == 16'hff) begin
                  wb_dat_buf <= 16'hfff; //8'hff in FROM disable too high conditions
                end else begin
                  wb_dat_buf <= wb_dat_i << 4;
                end
                wb_cyc_o <= 1'b1;
                wb_we_o  <= 1'b1;
                wb_adr_o <= LC_THRESHS_A + progress;
                state <= 3'd2;
              end
            end
            3'd2: begin
              if (wb_ack_i || wb_err_i) begin
                if (progress == 14'd63) begin
                  state <= 3'd0;
                  progress <= 14'd0;
                  mode <= MODE_ACM;
                end else begin
                  progress <= progress + 1;
                  state <= 3'd0;
                end
              end
            end
          endcase
        end
  /***************** ACM initialization State Machine ***************/        
        MODE_ACM: begin
          case (state)
            3'd0: begin
              wb_cyc_o <= 1'b1;
              wb_we_o  <= 1'b0;
              wb_adr_o <= FROM_ACM_A + progress;
              state <= 3'd1;
            end
            3'd1: begin
              if (wb_ack_i || wb_err_i) begin
                wb_dat_buf <= wb_dat_i;
                wb_cyc_o <= 1'b1;
                wb_we_o  <= 1'b1;
                wb_adr_o <= ACM_AQUADS_A + progress;
                state <= 3'd2;
              end
            end
            3'd2: begin
              if (wb_ack_i || wb_err_i) begin
                if (progress == 14'd39) begin
                  state <= 3'd0;
                  progress <= 14'd0;
                  mode <= MODE_SYSCONFIG;
                end else begin
                  progress <= progress + 1;
                  state <= 3'd0;
                end
              end
            end
          endcase
        end
  /***************** Sys Config State Machine ***************/        
        MODE_SYSCONFIG: begin
          case (state)
            3'd0: begin
              wb_cyc_o <= 1'b1;
              wb_we_o  <= 1'b0;
              wb_adr_o <= FLASH_SYSCONFIG_A;
              state <= 3'd1;
            end
            3'd1: begin
              if (wb_ack_i || wb_err_i) begin
                if (wb_dat_i > 16'h00ff) begin
		  // This is a hack to not load a bad system configuration
		  // if the flash hasn't been initialized.
                  wb_dat_buf <= 16'h0000;
                end else begin
                  wb_dat_buf <= wb_dat_i;
                end
                wb_cyc_o <= 1'b1;
                wb_we_o  <= 1'b1;
                wb_adr_o <= SYSCONFIG_A;
                state <= 3'd2;
              end
            end
            3'd2: begin
              if (wb_ack_i || wb_err_i) begin
                /* set hard levels valid */
                state      <= 3'd3;
                wb_cyc_o   <= 1'b1;
                wb_we_o    <= 1'b1;
                wb_adr_o   <= LEVELSVALID_A;
                wb_dat_buf <= {15'b0, ~disable_crashes};
              end
            end
            3'd3: begin
              if (wb_ack_i || wb_err_i) begin
                state    <= 3'd0;
                progress <= 14'd0;
                mode     <= MODE_DONE;
              end
            end
          endcase
        end
        MODE_DONE: begin
          if (soft_reset) begin
            mode <= dma_crash ? MODE_FLASH : MODE_LC;
            progress <= 14'd0;
            state <= 3'b0;
          end
        end
      endcase
    end
  end
 
endmodule
