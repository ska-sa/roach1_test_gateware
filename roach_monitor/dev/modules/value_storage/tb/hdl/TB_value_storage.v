`timescale 10ns/1ps
`define SIM_LENGTH 10000000
`define CLK_PERIOD 2

`define NUM_SRAM_TRIPS 7 

`define RAM_HIGH ((`NUM_SRAM_TRIPS)*1024)
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

  wire ram_ren, ram_wen;
  wire [12:0] ram_raddr;
  wire [12:0] ram_waddr;
  wire [11:0] ram_rdata;
  wire [11:0] ram_wdata;


  value_storage #( 
    .RAM_HIGH(`RAM_HIGH)
  ) value_storage_inst (
    .wb_clk_i(clk), .wb_rst_i(reset),
    .wb_stb_i(wb_stb_i), .wb_cyc_i(wb_cyc_i), .wb_we_i(wb_we_i),
    .wb_adr_i(wb_adr_i), .wb_dat_i(wb_dat_i), .wb_dat_o(wb_dat_o),
    .wb_ack_o(wb_ack_o),
    .adc_result(adc_result), .adc_channel(adc_channel), .adc_strb(adc_strb),
    .ram_ren(ram_ren), .ram_wen(ram_wen),
    .ram_raddr(ram_raddr), .ram_waddr(ram_waddr),
    .ram_rdata(ram_rdata), .ram_wdata(ram_wdata)
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
            for (i=0; i < mode_total - 1; i=i+1) begin
              if (master_mem[i] !== 1024 + 31 - (i%32)) begin
                $display("FAILED: mode == INDIRECT, %x != %x", master_mem[i], 1024 + 31 - (i%32));
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
                  if (wb_dat_o == 16'hffff) begin
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
`ifdef MODELSIM
  wire [`NUM_SRAM_TRIPS - 1:0] ram_sel = (1 << ram_waddr[12:10]);
  wire [`NUM_SRAM_TRIPS - 1:0] ram_we_b = ~(ram_sel & {`NUM_SRAM_TRIPS{ram_wen}});

  wire [(`NUM_SRAM_TRIPS) - 1:0] ram_rdata_arr [11:0];

  genvar gen_i;
  generate for (gen_i=0; gen_i < 12; gen_i=gen_i+1) begin : G0
    assign ram_rdata[gen_i] = ram_rdata_arr[gen_i][ram_raddr[12:10]];
  end endgenerate

  /*
  always @(ram_we_b) begin
    if (ram_we_b != {`NUM_SRAM_TRIPS{1'b1}}) begin
      $display("ram write: we_b %b, addr %x, data %x", ram_we_b, ram_waddr, ram_wdata);
    end
  end

  reg [12:0] prev_raddr;
  always @(posedge clk) begin
    #1
    prev_raddr <= ram_raddr;
    if (ram_raddr != prev_raddr)
    $display("ram read: addr %x, data %x", ram_raddr, ram_rdata);
  end
  */

  RAM4K9 ram_0[`NUM_SRAM_TRIPS - 1:0](
    .RESET(~reset),
    .CLKA(clk),
    .ADDRA11(1'b0), .ADDRA10(1'b0), .ADDRA9(ram_waddr[9]), .ADDRA8(ram_waddr[8]),
    .ADDRA7(ram_waddr[7]), .ADDRA6(ram_waddr[6]), .ADDRA5(ram_waddr[5]), .ADDRA4(ram_waddr[4]),
    .ADDRA3(ram_waddr[3]), .ADDRA2(ram_waddr[2]), .ADDRA1(ram_waddr[1]), .ADDRA0(ram_waddr[0]),
    .DINA8(1'b0), .DINA7(1'b0), .DINA6(1'b0), .DINA5(1'b0),.DINA4(1'b0),
    .DINA3(ram_wdata[3]), .DINA2(ram_wdata[2]), .DINA1(ram_wdata[1]), .DINA0(ram_wdata[0]),
    .DOUTA8(), .DOUTA7(), .DOUTA6(), .DOUTA5(),.DOUTA4(), .DOUTA3(),.DOUTA2(),.DOUTA1(),.DOUTA0(),
    .WIDTHA1(1'b1), .WIDTHA0(1'b0), .PIPEA(1'b0), .WMODEA(1'b0), .BLKA(1'b0), .WENA(ram_we_b),
    .CLKB(clk),
    .ADDRB11(1'b0), .ADDRB10(1'b0), .ADDRB9(ram_raddr[9]), .ADDRB8(ram_raddr[8]),
    .ADDRB7(ram_raddr[7]), .ADDRB6(ram_raddr[6]), .ADDRB5(ram_raddr[5]), .ADDRB4(ram_raddr[4]),
    .ADDRB3(ram_raddr[3]), .ADDRB2(ram_raddr[2]), .ADDRB1(ram_raddr[1]), .ADDRB0(ram_raddr[0]),
    .DINB8(1'b0), .DINB7(1'b0), .DINB6(1'b0), .DINB5(1'b0),.DINB4(1'b0),
    .DINB3(1'b0), .DINB2(1'b0), .DINB1(1'b0), .DINB0(1'b0),
    .DOUTB8(), .DOUTB7(), .DOUTB6(), .DOUTB5(),.DOUTB4(),
    .DOUTB3(ram_rdata_arr[3]),.DOUTB2(ram_rdata_arr[2]),.DOUTB1(ram_rdata_arr[1]),.DOUTB0(ram_rdata_arr[0]),
    .WIDTHB1(1'b1), .WIDTHB0(1'b0), .PIPEB(1'b0), .WMODEB(1'b0), .BLKB(1'b0), .WENB(1'b1)

  );
  RAM4K9 ram_1[`NUM_SRAM_TRIPS - 1:0](
    .RESET(~reset),
    .CLKA(clk),
    .ADDRA11(1'b0), .ADDRA10(1'b0), .ADDRA9(ram_waddr[9]), .ADDRA8(ram_waddr[8]),
    .ADDRA7(ram_waddr[7]), .ADDRA6(ram_waddr[6]), .ADDRA5(ram_waddr[5]), .ADDRA4(ram_waddr[4]),
    .ADDRA3(ram_waddr[3]), .ADDRA2(ram_waddr[2]), .ADDRA1(ram_waddr[1]), .ADDRA0(ram_waddr[0]),
    .DINA8(1'b0), .DINA7(1'b0), .DINA6(1'b0), .DINA5(1'b0),.DINA4(1'b0),
    .DINA3(ram_wdata[7]), .DINA2(ram_wdata[6]), .DINA1(ram_wdata[5]), .DINA0(ram_wdata[4]),
    .DOUTA8(), .DOUTA7(), .DOUTA6(), .DOUTA5(),.DOUTA4(), .DOUTA3(),.DOUTA2(),.DOUTA1(),.DOUTA0(),
    .WIDTHA1(1'b1), .WIDTHA0(1'b0), .PIPEA(1'b0), .WMODEA(1'b0), .BLKA(1'b0), .WENA(ram_we_b),
    .CLKB(clk),
    .ADDRB11(1'b0), .ADDRB10(1'b0), .ADDRB9(ram_raddr[9]), .ADDRB8(ram_raddr[8]),
    .ADDRB7(ram_raddr[7]), .ADDRB6(ram_raddr[6]), .ADDRB5(ram_raddr[5]), .ADDRB4(ram_raddr[4]),
    .ADDRB3(ram_raddr[3]), .ADDRB2(ram_raddr[2]), .ADDRB1(ram_raddr[1]), .ADDRB0(ram_raddr[0]),
    .DINB8(1'b0), .DINB7(1'b0), .DINB6(1'b0), .DINB5(1'b0),.DINB4(1'b0),
    .DINB3(1'b0), .DINB2(1'b0), .DINB1(1'b0), .DINB0(1'b0),
    .DOUTB8(), .DOUTB7(), .DOUTB6(), .DOUTB5(),.DOUTB4(),
    .DOUTB3(ram_rdata_arr[7]),.DOUTB2(ram_rdata_arr[6]),.DOUTB1(ram_rdata_arr[5]),.DOUTB0(ram_rdata_arr[4]),
    .WIDTHB1(1'b1), .WIDTHB0(1'b0), .PIPEB(1'b0), .WMODEB(1'b0), .BLKB(1'b0), .WENB(1'b1)
  );

  RAM4K9 ram_2[`NUM_SRAM_TRIPS - 1:0](
    .RESET(~reset),
    .CLKA(clk),
    .ADDRA11(1'b0), .ADDRA10(1'b0), .ADDRA9(ram_waddr[9]), .ADDRA8(ram_waddr[8]),
    .ADDRA7(ram_waddr[7]), .ADDRA6(ram_waddr[6]), .ADDRA5(ram_waddr[5]), .ADDRA4(ram_waddr[4]),
    .ADDRA3(ram_waddr[3]), .ADDRA2(ram_waddr[2]), .ADDRA1(ram_waddr[1]), .ADDRA0(ram_waddr[0]),
    .DINA8(1'b0), .DINA7(1'b0), .DINA6(1'b0), .DINA5(1'b0),.DINA4(1'b0),
    .DINA3(ram_wdata[11]), .DINA2(ram_wdata[10]), .DINA1(ram_wdata[9]), .DINA0(ram_wdata[8]),
    .DOUTA8(), .DOUTA7(), .DOUTA6(), .DOUTA5(),.DOUTA4(), .DOUTA3(),.DOUTA2(),.DOUTA1(),.DOUTA0(),
    .WIDTHA1(1'b1), .WIDTHA0(1'b0), .PIPEA(1'b0), .WMODEA(1'b0), .BLKA(1'b0), .WENA(ram_we_b),
    .CLKB(clk),
    .ADDRB11(1'b0), .ADDRB10(1'b0), .ADDRB9(ram_raddr[9]), .ADDRB8(ram_raddr[8]),
    .ADDRB7(ram_raddr[7]), .ADDRB6(ram_raddr[6]), .ADDRB5(ram_raddr[5]), .ADDRB4(ram_raddr[4]),
    .ADDRB3(ram_raddr[3]), .ADDRB2(ram_raddr[2]), .ADDRB1(ram_raddr[1]), .ADDRB0(ram_raddr[0]),
    .DINB8(1'b0), .DINB7(1'b0), .DINB6(1'b0), .DINB5(1'b0),.DINB4(1'b0),
    .DINB3(1'b0), .DINB2(1'b0), .DINB1(1'b0), .DINB0(1'b0),
    .DOUTB8(), .DOUTB7(), .DOUTB6(), .DOUTB5(),.DOUTB4(),
    .DOUTB3(ram_rdata_arr[11]),.DOUTB2(ram_rdata_arr[10]),.DOUTB1(ram_rdata_arr[9]),.DOUTB0(ram_rdata_arr[8]),
    .WIDTHB1(1'b1), .WIDTHB0(1'b0), .PIPEB(1'b0), .WMODEB(1'b0), .BLKB(1'b0), .WENB(1'b1)
  );
`else

  reg [12:0] ram_rdata_reg;
  assign ram_rdata = ram_rdata_reg;
  reg [11:0] ram_mem [8*1024 - 1:0];

  always @(posedge clk) begin
    if (reset) begin
    end else begin
      if (ram_wen) begin
        ram_mem[ram_waddr] <= ram_wdata;
   //     $display("ram_write: a = %x, d = %x", ram_waddr, ram_wdata);
      end
      ram_rdata_reg <= ram_mem[ram_raddr];
    end
  end

  always @(ram_raddr) begin
 //   $display("ram_read: a = %x, d = %x", ram_raddr, ram_mem[ram_raddr]);
  end
`endif

  
endmodule
