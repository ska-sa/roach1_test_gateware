`timescale 1ns/10ps

module fan_controller(
    wb_clk_i, wb_rst_i,
    wb_stb_i, wb_cyc_i, wb_we_i,
    wb_adr_i, wb_dat_i, wb_dat_o,
    wb_ack_o,
    adc_result, adc_channel, adc_strb,
    fan_sense, fan_control
  );
  parameter NUM_FANS = 3;
  input  wb_clk_i, wb_rst_i;
  input  wb_stb_i, wb_cyc_i, wb_we_i;
  input  [15:0] wb_adr_i;
  input  [15:0] wb_dat_i;
  output [15:0] wb_dat_o;
  output wb_ack_o;
 
  input  adc_strb;
  input   [4:0] adc_channel;
  input  [11:0] adc_result;

  input  [NUM_FANS - 1:0] fan_sense;
  output [NUM_FANS - 1:0] fan_control;

/************* Wishbone Attachment ***************/

  /* Wishbone Registers */
  reg        wb_ack_o;
  reg  [2:0] wb_dat_sel;
  reg [15:0] wb_dat_o;

  reg  [8:0] fan_pwm_0;
  reg  [8:0] fan_pwm_1;
  reg  [8:0] fan_pwm_2;

  reg  [7:0] fan_speed_0;
  reg  [7:0] fan_speed_1;
  reg  [7:0] fan_speed_2;

  always @(*) begin
    case (wb_dat_sel)
      0: wb_dat_o <= {8'b0, fan_speed_0};
      1: wb_dat_o <= {8'b0, fan_speed_1};
      2: wb_dat_o <= {8'b0, fan_speed_2};
      3: wb_dat_o <= {7'b0, fan_pwm_0};
      4: wb_dat_o <= {7'b0, fan_pwm_1};
      5: wb_dat_o <= {7'b0, fan_pwm_2};
      default: wb_dat_o <= 16'b0;
    endcase
  end

  always @(posedge wb_clk_i) begin
    //strobes
    wb_ack_o <= 1'b0;
    if (wb_rst_i) begin
      fan_pwm_0 <= 9'h100; // default 100% PWM
      fan_pwm_1 <= 9'h100;
      fan_pwm_2 <= 9'h100;
    end else begin
      if (wb_cyc_i & wb_stb_i & ~wb_ack_o) begin
        wb_ack_o   <= 1'b1;
        wb_dat_sel <= wb_adr_i[2:0];

        case (wb_adr_i)
          /* Fan Status 0-2 (read only) */
          3'd0: begin
          end
          3'd1: begin
          end
          3'd2: begin
          end

          /* Fan CTRL 0-2 (rd/wr) */
          3'd3: begin
            if (wb_we_i)
              fan_pwm_0 <= wb_dat_i[8:0];
          end
          3'd4: begin
            if (wb_we_i)
              fan_pwm_1 <= wb_dat_i[8:0];
          end
          3'd5: begin
            if (wb_we_i)
              fan_pwm_2 <= wb_dat_i[8:0];
          end
        endcase
      end
    end
  end

/************** Fan Control Logic ****************/

  /* The idea here is to PWM the fan control
     signals at a frequency of 21-28kHz with
     a 8-bit width value. 
  */

  reg [2:0] master_clk_div;
  reg [7:0] pwm_progress;

  always @(posedge wb_clk_i) begin
    if (wb_rst_i) begin
      master_clk_div <= 3'b0;
      pwm_progress   <= 8'd0;
    end else begin
      if (master_clk_div >= 3'd5) begin
        pwm_progress   <= pwm_progress + 1;
        /* 256 bit counter that overflows at 26 kHz */
        /* 40 MHz / 6 / 256 == 26 kHz */
        master_clk_div <= 3'd0;
      end else begin
        master_clk_div <= master_clk_div + 1;
      end
    end
  end

  assign fan_control[0] = {1'b0, pwm_progress} < fan_pwm_0;
  assign fan_control[1] = {1'b0, pwm_progress} < fan_pwm_1;
  assign fan_control[2] = {1'b0, pwm_progress} < fan_pwm_2;

/*********** Fan Speed Sense Logic *************/

  reg [NUM_FANS - 1:0] prev_fan_sense;
  reg [7:0] debounce_0;
  reg [7:0] debounce_1;
  reg [7:0] debounce_2;

  reg fan_tick_0;
  reg fan_tick_1;
  reg fan_tick_2;

  always @(posedge wb_clk_i) begin
    fan_tick_0 <= 1'b0;
    fan_tick_1 <= 1'b0;
    fan_tick_2 <= 1'b0;

    prev_fan_sense <= fan_sense;
    if (wb_rst_i) begin
      debounce_0 <= 8'b0;
      debounce_1 <= 8'b0;
      debounce_2 <= 8'b0;
    end else begin
      if (debounce_0) begin
        debounce_0 <= debounce_0 - 1;
      end else begin
        if (fan_sense[0] && prev_fan_sense[0] != fan_sense[0]) begin
          fan_tick_0 <= 1'b1;
          debounce_0 <= 8'hff;
        end
      end
      if (debounce_1) begin
        debounce_1 <= debounce_1 - 1;
      end else begin
        if (fan_sense[1] && prev_fan_sense[1] != fan_sense[1]) begin
          fan_tick_1 <= 1'b1;
          debounce_1 <= 8'hff;
        end
      end
      if (debounce_2) begin
        debounce_2 <= debounce_2 - 1;
      end else begin
        if (fan_sense[2] && prev_fan_sense[2] != fan_sense[2]) begin
          fan_tick_2 <= 1'b1;
          debounce_2 <= 8'hff;
        end
      end
    end
  end

  reg [7:0] half_rev_counter_0;
  reg [7:0] half_rev_counter_1;
  reg [7:0] half_rev_counter_2;

  reg [24:0] half_second_counter;

  always @(posedge wb_clk_i) begin
    if (wb_rst_i) begin
      half_second_counter <= 25'd0;

      half_rev_counter_0 <= 8'd0;
      half_rev_counter_1 <= 8'd0;
      half_rev_counter_2 <= 8'd0;
    end else begin
      if (fan_tick_0) begin
        half_rev_counter_0 <= half_rev_counter_0 + 1;
      end
      if (fan_tick_1) begin
        half_rev_counter_1 <= half_rev_counter_1 + 1;
      end
      if (fan_tick_2) begin
        half_rev_counter_2 <= half_rev_counter_2 + 1;
      end

      if (half_second_counter == 25'd20_000_000 - 1) begin
        /* clk = 40MHz, every 20000000 is 0.5s */
        half_second_counter <= 25'd0;

        fan_speed_0        <= half_rev_counter_0;
        half_rev_counter_0 <= 0;

        fan_speed_1        <= half_rev_counter_1;
        half_rev_counter_1 <= 0;

        fan_speed_2        <= half_rev_counter_2;
        half_rev_counter_2 <= 0;
      end else begin
        half_second_counter <= half_second_counter + 1;
      end
    end
  end

endmodule

