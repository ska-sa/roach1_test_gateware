`timescale 10ns/1ps
`define SIM_LENGTH 100000
`define CLK_PERIOD 2

`define RAM_HIGH (4*1024)
//`define RAM_HIGH 256

module TB_value_storage();
  wire clk;
  reg  reset;
  reg  wb_stb_i, wb_cyc_i, wb_we_i;
  reg  [15:0] wb_adr_i;
  reg  [15:0] wb_dat_i;
  wire [15:0] wb_dat_o;
  wire wb_ack_o;
 
  reg  adc_strb;
  reg   [4:0] adc_channel;
  reg  [11:0] adc_result;

  wire ram_wen;
  wire [12:0] ram_raddr;
  wire [12:0] ram_waddr;
  wire [11:0] ram_rdata;
  wire [11:0] ram_wdata;


  value_storage value_storage_inst (
    .wb_clk_i(clk), .wb_rst_i(reset),
    .wb_stb_i(wb_stb_i), .wb_cyc_i(wb_cyc_i), .wb_we_i(wb_we_i),
    .wb_adr_i(wb_adr_i), .wb_dat_i(wb_dat_i), .wb_dat_o(wb_dat_o),
    .wb_ack_o(wb_ack_o),
    .adc_result(adc_result), .adc_channel(adc_channel), .adc_strb(adc_strb),
    .ram_wen(ram_wen),
    .ram_raddr(ram_raddr), .ram_waddr(ram_waddr),
    .ram_rdata(ram_rdata), .ram_wdata(ram_wdata)
  );


  reg [7:0] clk_counter;

  initial begin
    $dumpvars;
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

  /************ MODE  *******************/
  reg [15:0] master_mem [1024*64 - 1:0];
  reg [3:0] mode;
`define MODE_WAITADC  4'd0
`define MODE_DIRECT   4'd1
`define MODE_INDIRECT 4'd2
  reg [1:0] mode_done;

  reg [15:0] mode_total;

  reg second_test;
  integer i;

  reg [11:0] first;
  always @(posedge clk) begin
    if (reset) begin
      mode <= `MODE_WAITADC;
      second_test <= 1'b0;
    end else begin
      case (mode)
        `MODE_WAITADC: begin
          if (mode_done[0]) begin
            mode <= `MODE_DIRECT;
`ifdef DEBUG
            $display("mode: mode WAITADC passed, entering DIRECT");
`endif
          end
        end
        `MODE_DIRECT: begin
          if (mode_done[1]) begin
            for (i=0; i < 32; i=i+1) begin
              if (master_mem[i] !== 1024 + i) begin
                $display("FAILED: mode == DIRECT, %x != %x", master_mem[i], 1024 + i);
                $finish;
              end else if (i == 32 - 1) begin
                if (second_test) begin
                  $display("PASSED");
                  $finish;
                end else begin
                  mode <= `MODE_INDIRECT;
`ifdef DEBUG
                  $display("mode: mode DIRECT passed, entering INDIRECT");
`endif
                end
              end
            end
          end
        end
        `MODE_INDIRECT: begin
          if (mode_done[1]) begin
            if (mode_total < `RAM_HIGH - 32) begin
              $display("FAILED: ring buffer readback total too small, x = %d", mode_total);
              $finish;
            end
            first = master_mem[0];
            for (i=1; i < mode_total - 1; i=i+1) begin
              if ((master_mem[i] & 16'hfff) !== (first + i)%32 + 12'h400) begin
                $display("FAILED: mode == INDIRECT, got = %x, expected = %x, i == %d", master_mem[i], (first+i)%32+12'h400, i);
                $finish;
              end else if (i == 32 - 1) begin
                second_test <= 1'b1;
                mode <= `MODE_WAITADC;
`ifdef DEBUG
                $display("mode: mode INDIRECT passed, entering WAITADC");
`endif
              end
            end
          end
        end
      endcase
    end
  end


  /************* ADC ***************/
  reg  [31:0] adc_timer;
  reg  [31:0] channel_set_counter;
  always @(posedge clk) begin
    adc_strb <= 1'b0;
    mode_done[0] <= 1'b0;
    if (reset) begin
      adc_channel <= 13'b0;
      adc_timer <= 32'b0;
      channel_set_counter <= 32'b0;
    end else begin
      if (adc_timer == 32'b0) begin
        adc_strb <= 1'b1;
        adc_channel <= adc_channel + 1;
        adc_result <= 1024 + (adc_channel + 1)%32;
        adc_timer <= 32'd2;
        if (adc_channel == 5'd31) begin
          channel_set_counter <= channel_set_counter + 1;
        end
        if (channel_set_counter + 1 >= (`RAM_HIGH + 1)/32) begin
           mode_done[0] <= 1'b1;
        end
      end else begin
        adc_timer <= adc_timer - 1;
      end
      if (mode != `MODE_WAITADC) begin
        channel_set_counter <= 32'd0;
      end
    end
  end
  /************ WB *******************/
  reg [1:0] wbm_state;
`define STATE_COMMAND 2'd0
`define STATE_COLLECT 2'd1
`define STATE_WAIT    2'd2

  reg [31:0] wbm_progress;

  reg stream_done;

  always @(posedge clk) begin
    wb_cyc_i <= 1'b0;
    wb_stb_i <= 1'b0;
    mode_done[1] <= 1'b0;

    if (reset) begin
      wbm_state <= `STATE_COMMAND;
      wbm_progress <= 32'b0;
      mode_total <= 32'b0;
      stream_done <= 1'b0;
      wb_adr_i <= 16'b0;
    end else begin
      case (wbm_state)
        `STATE_COMMAND: begin
          case (mode)
            `MODE_DIRECT: begin
              wb_cyc_i <= 1'b1;
              wb_stb_i <= 1'b1;
              wb_we_i  <= 1'b0;
              wb_adr_i <= wbm_progress[15:0];
`ifdef DESPERATE_DEBUG
              $display("wbm: direct - %d", wbm_progress[15:0]);
`endif
              wbm_state <= `STATE_COLLECT;
            end
            `MODE_INDIRECT: begin
              wb_cyc_i <= 1'b1;
              wb_stb_i <= 1'b1;
              wb_adr_i <= 16'd32;
              if (stream_done) begin
                wb_we_i  <= 1'b1;
                wb_dat_i <= 16'hffff;
`ifdef DESPERATE_DEBUG
                $display("wbm: stop indirect");
`endif
              end else if (wbm_progress == 32'b0) begin
                wb_we_i  <= 1'b1;
                wb_dat_i <= 16'd0;
`ifdef DESPERATE_DEBUG
                $display("wbm: start indirect");
`endif
              end else begin
                wb_we_i  <= 1'b0;
`ifdef DESPERATE_DEBUG
                $display("wbm: indirect read");
`endif
              end
              wbm_state <= `STATE_COLLECT;
            end
          endcase
        end
        `STATE_COLLECT: begin
          if (wb_ack_o) begin
            case (mode)
              `MODE_DIRECT: begin
                master_mem[wbm_progress] <= wb_dat_o;
                if (wbm_progress == 31) begin
                  wbm_progress <= 32'b0;
                  mode_done[1] <= 1'b1;
                  wbm_state <= `STATE_WAIT;
                end else begin
                  wbm_progress <= wbm_progress + 1;
                  wbm_state <= `STATE_COMMAND;
                end
`ifdef DESPERATE_DEBUG
            $display("wbm: got read, addr = %x,  data = %x", wb_adr_i, wb_dat_o);
`endif
              end
              `MODE_INDIRECT: begin
                if (stream_done) begin
                  mode_done[1] <= 1'b1;
                  wbm_progress <= 32'b0;
                  stream_done <= 1'b0;
                  wbm_state <= `STATE_WAIT;
`ifdef DESPERATE_DEBUG
            $display("wbm: indirect stop ack");
`endif
                end else if (wbm_progress == 32'b0) begin
                  wbm_progress <= wbm_progress + 1;
                  wbm_state <= `STATE_COMMAND;
`ifdef DESPERATE_DEBUG
            $display("wbm: indirect start ack");
`endif
                end else begin
                  if (wb_dat_o[15]) begin
                    mode_total <= wbm_progress;
                    stream_done <= 1'b1;
                    wbm_state <= `STATE_COMMAND;
`ifdef DESPERATE_DEBUG
                    $display("wbm: got last");
`endif
                  end else begin
                    master_mem[wbm_progress - 1] <= wb_dat_o;
                    wbm_progress <= wbm_progress + 1;
                    wbm_state <= `STATE_COMMAND;
                    if (wbm_progress > `RAM_HIGH) begin
                      $display("FAILED: buffer too long, end expected");
                      $finish;
                    end
`ifdef DESPERATE_DEBUG
                    $display("wbm: got read, data = %x", wb_dat_o);
`endif
                  end
                end
`ifdef DESPERATE_DEBUG
                $display("wbm: got ack, adr = %x, data = %x", wb_adr_i, wb_dat_o);
`endif
              end
              default: begin
                $display("FAILED: invalid state");
                $finish;
              end
            endcase

          end
        end
        `STATE_WAIT: begin
           wbm_state <= `STATE_COMMAND;
        end
      endcase
    end
  end 

  /************* Memory *****************/
  buffer buffer_inst(
    .clk       (clk),
    .reset     (reset),
    .ram_raddr (ram_raddr),
    .ram_waddr (ram_waddr),
    .ram_rdata (ram_rdata),
    .ram_wdata (ram_wdata),
    .ram_wen   (ram_wen)
  );

  
endmodule
