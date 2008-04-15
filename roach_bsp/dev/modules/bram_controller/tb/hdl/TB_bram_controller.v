`define SIMLENGTH 100000
`define CLK_PERIOD 2

//1024*2 operation, 2 bytes per operation === 4K

`define OP_COUNT 1024*2
module TB_bram_controller();
  reg reset;
  wire clk;

  reg  wb_we_i, wb_cyc_i, wb_stb_i;
  wire  [1:0] wb_sel_i;
  reg  [31:0] wb_adr_i;
  reg  [15:0] wb_dat_i;
  wire [15:0] wb_dat_o;
  wire wb_ack_o;

  assign wb_sel_i = 2'b11;

  localparam RAM_SIZE = ((`OP_COUNT + 1)/1024)*2;

  bram_controller #(
    .RAM_SIZE_K(RAM_SIZE)
  ) bram_controller_inst ( 
    .wb_clk_i(clk), .wb_rst_i(reset),
    .wb_we_i(wb_we_i), .wb_cyc_i(wb_cyc_i), .wb_stb_i(wb_stb_i), .wb_sel_i(wb_sel_i),
    .wb_adr_i(wb_adr_i), .wb_dat_i(wb_dat_i), .wb_dat_o(wb_dat_o),
    .wb_ack_o(wb_ack_o)
  );

  reg [31:0] clk_counter;

  initial begin
    reset<=1'b1;
    clk_counter<=32'b0;
    #50
    reset<=1'b0;
`ifdef DEBUG
    $display("sys: reset cleared");
`endif
    #`SIMLENGTH
    $display("FAILED: simulation timed out");
    $finish;
  end

  assign clk = clk_counter < ((`CLK_PERIOD) / 2);

  always begin
    #1 clk_counter <= (clk_counter == `CLK_PERIOD - 1 ? 32'b0 : clk_counter + 1);
  end

  reg [15:0] readback_mem [64*1024-1:0];

  reg mode;
  localparam MODE_WRITE = 1'b0;
  localparam MODE_READ  = 1'b1;

  reg [1:0] mode_done;

  integer i;

  always @(posedge clk) begin
    if (reset) begin
      mode <= MODE_WRITE;
    end else begin
      case (mode)
        MODE_WRITE: begin
          if (mode_done[MODE_WRITE]) begin
            mode <= MODE_READ;
`ifdef DEBUG
            $display("mode: MODE_WRITE done");
`endif
          end
        end
        MODE_READ: begin
          if (mode_done[MODE_READ]) begin
            for (i=0; i < `OP_COUNT; i=i+1) begin
              if (readback_mem[i] !== i) begin
                $display("FAILED: data check failed - expected %x, got %x", i, readback_mem[i]);
                $finish;
              end
            end
            $display("PASSED");
            $finish;
          end
        end
      endcase
    end
  end

  reg [1:0] wb_state;
  localparam WB_COMMAND = 2'd0;
  localparam WB_COLLECT = 2'd1;
  localparam WB_WAIT    = 2'd2;

  reg [31:0] mode_progress;

  always @(posedge clk) begin
    wb_stb_i <= 1'b0;
    wb_cyc_i <= 1'b0;
    mode_done[MODE_WRITE] <= 1'b0;
    mode_done[MODE_READ]  <= 1'b0;
    if (reset) begin
      wb_state <= WB_COMMAND;
      mode_progress <= 32'b0;
    end else begin
      case (wb_state)
        WB_COMMAND: begin
          
          case (mode)
            MODE_WRITE: begin
              wb_we_i <= 1'b1;
`ifdef DEBUG
              $display("wbm: write, addr = %x, data = %x", {mode_progress[30:0], 1'b0}, mode_progress[15:0]);
`endif
            end
            MODE_READ: begin
              wb_we_i <= 1'b0;
`ifdef DEBUG
              $display("wbm: read, addr = %x", {mode_progress[30:0], 1'b0});
`endif
            end
          endcase

          wb_dat_i <= mode_progress[15:0];
          wb_adr_i <= {mode_progress[30:0], 1'b0};
          wb_stb_i <= 1'b1;
          wb_cyc_i <= 1'b1;
          wb_state <= WB_COLLECT;
        end
        WB_COLLECT: begin
          if (wb_ack_o) begin
            if (mode_progress < `OP_COUNT - 1) begin
              mode_progress <= mode_progress + 1;
              wb_state <= WB_COMMAND;
            end else begin
              mode_progress <= 32'b0;
              mode_done[mode] <= 1'b1;
              wb_state <= WB_WAIT;
            end
            if (mode == MODE_READ) begin
              readback_mem[mode_progress[15:0]] <= wb_dat_o;
`ifdef DEBUG
              $display("wbm: read response, data = %x", wb_dat_o);
`endif
            end
          end
        end
        WB_WAIT: begin
          wb_state <= WB_COMMAND;
        end
      endcase
    end
  end
endmodule
