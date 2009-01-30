`timescale 10ns/10ps

`define SIM_LENGTH 100000
`define CLK_PERIOD 2

`define FROM_ACM_A        16'd0
`define FROM_LC_A         16'd40
`define LC_THRESHS_A      16'd128
`define ACM_AQUADS_A      16'd384
`define VS_INDIRECT_A     16'd512
`define SYSCONFIG_A       16'd576
`define FLASH_A           16'd1024
`define FLASH_SYSCONFIG_A 16'hffff

`define DEFAULT_SYSCONFIG 16'h00ee
`define VS_INDIRECT_L     13'hfff

module TB_dma_engine();
  wire clk;
  reg  reset;

  wire wb_cyc_o, wb_stb_o, wb_we_o;
  wire [15:0] wb_adr_o;
  wire [15:0] wb_dat_o;
  reg  [15:0] wb_dat_i;
  reg  wb_ack_i, wb_err_i;

  reg soft_reset, dma_crash;
  wire dma_done;

  dma_engine #(
    .FROM_ACM_A(`FROM_ACM_A),
    .FROM_LC_A(`FROM_LC_A),
    .LC_THRESHS_A(`LC_THRESHS_A),
    .ACM_AQUADS_A(`ACM_AQUADS_A),
    .VS_INDIRECT_A(`VS_INDIRECT_A),
    .SYSCONFIG_A(`SYSCONFIG_A),
    .FLASH_A(`FLASH_A),
    .FLASH_SYSCONFIG_A(`FLASH_SYSCONFIG_A)
  ) dma_engine_inst (
    .wb_clk_i(clk), .wb_rst_i(reset),
    .wb_cyc_o(wb_cyc_o), .wb_stb_o(wb_stb_o), .wb_we_o(wb_we_o),
    .wb_adr_o(wb_adr_o), .wb_dat_o(wb_dat_o), .wb_dat_i(wb_dat_i),
    .wb_ack_i(wb_ack_i), .wb_err_i(wb_err_i),
    .soft_reset(soft_reset), .dma_crash(dma_crash),
    .dma_done(dma_done)
  );

  reg [7:0] clk_counter;

  initial begin
    clk_counter<=8'b0;
    reset<=1'b1;
`ifdef DEBUG
    $display("sim: starting sim");
`endif
    #5
    reset<=1'b0;
`ifdef DEBUG
    $display("sim: clearing reset");
`endif
    #`SIM_LENGTH 
    $display("FAILED: simulation timed out");
    $finish;
  end

  assign clk = clk_counter < ((`CLK_PERIOD) / 2);

  always begin
    #1 clk_counter <= (clk_counter == `CLK_PERIOD - 1 ? 32'b0 : clk_counter + 1);
  end

  /********* Mode Control ************/
  reg [15:0] sysconfig_mem;
  reg [15:0] acm_mem   [39:0];
  reg [15:0] flash_mem [1024*64 - 1:0];
  reg [15:0] lc_mem    [63:0];

  reg mode;

  localparam MODE_POWERUP = 1'd0;
  localparam MODE_CRASH   = 1'd1;

  reg mode_progress;

  integer i,j,k;

  always @(posedge clk) begin
    soft_reset <= 1'b0;
    dma_crash <= 1'b0;
    if (reset) begin
      mode <= MODE_POWERUP;
      mode_progress <= 1'b0;
      soft_reset <= 1'b1;
    end else begin
      if (~dma_done)
        mode_progress <= 1'b1;

      if (dma_done & mode_progress) begin
        if (sysconfig_mem !== `DEFAULT_SYSCONFIG) begin
          $display("FAILED: mode = %d, sysconfig invalid, expected %x - got %x", mode, `DEFAULT_SYSCONFIG, sysconfig_mem);
          $finish;
        end
        for (i=0; i < 40; i=i+1) begin
          if (acm_mem[i] !== i) begin
            $display("FAILED: mode = %d, acm_mem invalid, expected %x - got %x", mode, i, acm_mem[i]);
            $finish;
          end
        end
        for (j=0; j < 64; j=j+1) begin
          if (j == 8'hff) begin
            if (lc_mem[j] !== 16'hfff) begin
              $display("FAILED: mode = %d, lc invalid, expected %x - got %x", mode, j, lc_mem[j]);
              $finish;
            end
          end else begin
            if (lc_mem[j] !== (j << 4)) begin
              $display("FAILED: mode = %d, lc invalid, expected %x - got %x", mode, j << 4, lc_mem[j]);
              $finish;
            end
          end
        end
        if (mode == MODE_CRASH) begin
          for (k=0; k <= `VS_INDIRECT_L; k=k+1) begin
            if (k == `VS_INDIRECT_L) begin
              if (16'hffff !== flash_mem[k+6]) begin
                $display("FAILED: mode = %d, flash invalid, expected %x - got %x", 16'hffff, mode, flash_mem[k+6]);
                $finish;
              end
            end else begin
              if (k !== flash_mem[k+6]) begin
                $display("FAILED: mode = %d, flash invalid, expected %x - got %x", mode, k, flash_mem[k+6]);
                $finish;
              end
            end
          end
        end
        #1
        case (mode)
          MODE_POWERUP: begin
            mode_progress <= 1'b0;
            mode <= MODE_CRASH;
            soft_reset <= 1'b1;
            dma_crash <= 1'b1;
`ifdef DEBUG
            $display("mode: MODE_POWERUP passed"); 
`endif
          end
          MODE_CRASH: begin
`ifdef DEBUG
            $display("mode: MODE_CRASH passed"); 
`endif
            $display("PASSED");
            $finish;
          end
        endcase
      end
    end
  end

  /************* Wishbone Slave Simulation **************/

  wire sel_flash_sys = wb_adr_o == `FLASH_SYSCONFIG_A;
  wire sel_flash     = wb_adr_o >= `FLASH_A;
  wire sel_sys       = wb_adr_o == `SYSCONFIG_A;
  wire sel_vs        = wb_adr_o == `VS_INDIRECT_A;
  wire sel_aq        = wb_adr_o >= `ACM_AQUADS_A && wb_adr_o < `ACM_AQUADS_A + 40;
  wire sel_lc        = wb_adr_o >= `LC_THRESHS_A && wb_adr_o < `LC_THRESHS_A + 64;
  wire sel_from_aq   = wb_adr_o >= `FROM_ACM_A && wb_adr_o < `FROM_ACM_A + 40;
  wire sel_from_lc   = wb_adr_o >= `FROM_LC_A && wb_adr_o < `FROM_LC_A + 64;

  wire wb_trans = wb_cyc_o & wb_stb_o & ~wb_ack_i;

  reg vs_pause;
  reg [12:0] vs_counter;

  always @(posedge clk) begin
    wb_ack_i <= 1'b0;
    wb_err_i <= 1'b0;
    if (reset) begin
      vs_pause <= 1'b0;
      vs_counter <= 13'b0;
    end else begin
`ifdef DESPERATE_DEBUG 
      if (wb_trans)
        $display("wbm: got wb_trans, we = %b, adr = %x, dat = %x", wb_we_o, wb_adr_o, wb_dat_o);
      if (wb_ack_i)
        $display("wbm: gave response, dat = %x", wb_dat_i);
`endif

      if (sel_flash_sys & wb_trans) begin
        wb_dat_i <= `DEFAULT_SYSCONFIG;
        wb_ack_i <= 1'b1;
      end else if (sel_flash & wb_trans) begin
        wb_ack_i <= 1'b1;
        if (wb_we_o) begin
          flash_mem[wb_adr_o - `FLASH_A] <= wb_dat_o;
        end
      end else if (sel_sys & wb_trans) begin
        wb_ack_i <= 1'b1;
        if (wb_we_o) begin
          sysconfig_mem <= wb_dat_o;
        end
      end else if (sel_vs & wb_trans) begin
        wb_ack_i <= 1'b1;
        if (wb_we_o) begin
          if (wb_dat_o == 16'd0) begin
            vs_pause <= 1'b1;
            vs_counter <= 13'b0;
          end else begin
            vs_pause <= 1'b0;
          end
        end else begin
          if (vs_counter == `VS_INDIRECT_L) begin
            wb_dat_i <= 16'hffff;
          end else begin
            wb_dat_i <= vs_counter;
            vs_counter <= vs_counter + 1;
          end
        end
      end else if (sel_aq & wb_trans) begin
        wb_ack_i <= 1'b1;
        if (wb_we_o) begin
          acm_mem[wb_adr_o - `ACM_AQUADS_A] <= wb_dat_o;
        end
      end else if (sel_lc & wb_trans) begin
        wb_ack_i <= 1'b1;
        if (wb_we_o) begin
          lc_mem[wb_adr_o - `LC_THRESHS_A] <= wb_dat_o;
        end
      end else if (sel_from_aq & wb_trans) begin
        wb_dat_i <= wb_adr_o - `FROM_ACM_A;
        wb_ack_i <= 1'b1;
      end else if (sel_from_lc & wb_trans) begin
        wb_dat_i <= wb_adr_o - `FROM_LC_A;
        wb_ack_i <= 1'b1;
      end
    end
  end




endmodule
