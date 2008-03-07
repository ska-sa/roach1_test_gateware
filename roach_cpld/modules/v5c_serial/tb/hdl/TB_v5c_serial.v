`timescale 1ns/10ps

`define SIMLENGTH 50000
`define CLK_PERIOD 2

`define BITFILE_SIZE (8*128)


module TB_v5c_serial();
  reg reset;
  wire clk;

  reg [31:0] clk_counter;

  wire serial_boot_busy;
  wire [7:0] user_data;
  wire user_data_strb;
  wire user_rdy;

  wire [2:0] v5c_mode;
  wire v5c_prog_n, v5c_cs_n, v5c_rdwr_n;
  wire v5c_done, v5c_init_n;
  wire v5c_din;
  wire v5c_cclk;

  v5c_serial v5c_serial_inst(
    .clk(clk), .reset(reset),
    .serial_boot_enable(1'b1),
    .serial_boot_busy(serial_boot_busy),
    .user_data(user_data), .user_data_strb(user_data_strb),
    .user_rdy(user_rdy),
    .v5c_mode(v5c_mode),
    .v5c_prog_n(v5c_prog_n), .v5c_done(v5c_done), .v5c_init_n(v5c_init_n),
    .v5c_din(v5c_din),
    .v5c_cclk(v5c_cclk)
  );

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
  /**************** Mode ****************/
  reg config_data [`BITFILE_SIZE - 1:0];

  reg mode_done;

  integer i;

  wire [7:0] foo = i/8;

  always @(posedge clk) begin
    if (reset) begin
    end else begin
      if (mode_done) begin
        for (i=0; i < (`BITFILE_SIZE); i = i + 1) begin
          if (config_data[i] !== foo[i%8] ) begin
            $display("FAILED: config data incorrect - got %d, expected %d", config_data[i], foo[i%8]);
            $finish;
          end else if (i == (`BITFILE_SIZE)/8) begin
            $display("PASSED");
            $finish;
          end
        end
      end
    end
  end

  /************** Simulated data interface ***********/
  reg [31:0] startup_wait;
  reg data_strb;
  reg data_wait;
  reg [7:0] data_counter;
  reg [7:0] data_reg;

  assign user_data = data_reg;
  assign user_data_strb = data_strb;

  always @(posedge clk) begin
    data_strb <= 1'b0;
    if (reset) begin
      data_wait <= 1'b1;
      data_counter <= 8'b0;
      startup_wait <= 32'd1000;
    end else if (startup_wait) begin
      startup_wait <= startup_wait - 1;
    end else begin
      if (data_wait) begin
        data_strb <= 1'b1;
        data_wait <= 1'b0;
        data_reg <= data_counter;
        data_counter <= data_counter + 1;
`ifdef DEBUG
        $display("data: sent byte %d", data_counter);
`endif
      end else if (user_rdy) begin
        data_wait <= 1'b1;
      end
    end
  end


  /**************** V5 Config interface ***********/

  reg [31:0] data_index;

  reg done;

  reg [1:0] state;

  localparam STATE_WAIT    = 2'd0;
  localparam STATE_GOTPROG = 2'd1;
  localparam STATE_DATA    = 2'd2;
  localparam STATE_DONE    = 2'd3;

  reg prev_cclk;

  assign v5c_done = state == STATE_DONE;

  always @(v5c_cclk, v5c_prog_n, v5c_init_n, reset) begin
`ifdef DESPERATE_DEBUG
//     $display("v5c: clk %b prog_n %b init %b", v5c_cclk, v5c_prog_n, v5c_init_n);
`endif
    prev_cclk <= v5c_cclk;
    mode_done <= 1'b0;
    if (reset) begin
      done <= 1'b0;
      state <= STATE_WAIT;
    end else begin
      case (state)
        STATE_WAIT: begin
          if (~v5c_prog_n) begin
            done <= 1'b0;
            state <= STATE_GOTPROG;
            data_index <= 32'b0;
`ifdef DEBUG
            $display("v5c: got prog_b");
`endif
          end
        end
        STATE_GOTPROG: begin
          if (v5c_init_n) begin
`ifdef DEBUG
            $display("v5c: sampled mode bits");
`endif
            state <= STATE_DATA;
            if (v5c_mode !== 3'b111) begin
              $display("FAILED: incorrect mode - got %b, expected %b", v5c_mode, 3'b111);
              $finish;
            end
          end
        end
        STATE_DATA: begin
          if (v5c_cclk != prev_cclk && v5c_cclk) begin
            config_data[data_index] <= v5c_din;
`ifdef DEBUG
            $display("v5c: got bit = %b", v5c_din);
`endif
            if (data_index == `BITFILE_SIZE - 1) begin
              state <= STATE_DONE;
              mode_done <= 1'b1;
`ifdef DEBUG
              $display("v5c: config complete");
`endif
            end else begin
              data_index <= data_index + 1;
            end
          end
        end
        STATE_DONE: begin
        end
      endcase
    end
  end



  
endmodule
