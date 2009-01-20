`include "log2.v"
`timescale 1ns/10ps
module serial_uart(
    clk,
    reset,
    serial_in,  serial_out,
    serial_rts, serial_cts,
    as_data_i, as_dstrb_i, as_busy_o,
    as_data_o, as_dstrb_o, as_busy_i
  );
  parameter BAUD        = 115200;
  parameter CLOCK_RATE  = 10000000;

  /*
   * serial/serial side signals
   */

  input  clk;
  input  reset;
  
  input  serial_in;
  output serial_out;
  input  serial_rts;
  output serial_cts;

  /*
   * Host signals
   */

  input  [7:0] as_data_i;
  input  as_dstrb_i;
  output as_busy_o;
  output [7:0] as_data_o;
  output as_dstrb_o;
  input  as_busy_i;
  
  localparam SERIAL_BITWIDTH = CLOCK_RATE / BAUD;
  localparam SERIAL_BITWIDTH_DIV_2 = SERIAL_BITWIDTH / 2;
`ifdef __ICARUS__
  localparam BITWIDTH_BITS = 32;
`else
  localparam BITWIDTH_BITS = `LOG2(SERIAL_BITWIDTH-1) + 1;
`endif


/*********** Serial Input  ***********/
   
  /* Flow Control */

  /* Active High */
  assign serial_cts = !as_busy_i;

  localparam S_I_STATE_HUNT      = 2'd0;
  localparam S_I_STATE_STARTHALF = 2'd1;
  localparam S_I_STATE_DATA      = 2'd2;

  reg  [BITWIDTH_BITS - 2:0] s_i_counter; // synthesis syn_preserve=1
  reg  [1:0] s_i_state;
  reg  [3:0] s_i_progress;
  reg  [7:0] s_i_data;

  assign as_data_o = s_i_data;

  reg as_dstrb_o;

  reg count_start;

  always @(posedge clk) begin
    if (reset | count_start) begin
      s_i_counter <= {BITWIDTH_BITS-1{1'b0}};
    end else begin
      s_i_counter <= s_i_counter + 1;
    end
  end
  
  wire count_done = (~count_start) && (s_i_counter == SERIAL_BITWIDTH_DIV_2 - 2);

  reg count_double;

  reg serial_in_stable;
  reg serial_in_reg;

  //TODO: add relative placement constraints
  always @(posedge clk) begin
    serial_in_reg <= serial_in;
    serial_in_stable <= serial_in_reg;
  end

  always @(posedge clk) begin
    as_dstrb_o  <= 1'b0;
    count_start <= 1'b0;
    if (reset) begin
      s_i_state<=S_I_STATE_HUNT;
      count_double <= 1'b0;
    end else begin
      case (s_i_state)
        S_I_STATE_HUNT: begin
          if (serial_in_stable == 1'b0) begin //start bit
            s_i_progress <= 4'b0;
            count_start <= 1'b1;
            s_i_state <= S_I_STATE_STARTHALF;
          end
        end
        S_I_STATE_STARTHALF: begin
          if (count_done) begin
            s_i_state <= S_I_STATE_DATA;
            count_start <= 1'b1;
            count_double <= 1'b0;
          end
        end
        S_I_STATE_DATA: begin
          if (count_done & count_double) begin
            if (s_i_progress < 4'd8) begin
              count_start <= 1'b1;
              s_i_data[s_i_progress] <= serial_in_stable;
              s_i_progress <= s_i_progress + 1;
              if (s_i_progress == 4'b0111)
                as_dstrb_o <= 1'b1;
            end else begin
              s_i_state <= S_I_STATE_HUNT;
            end
            count_double <= 1'b0;
          end else if (count_done & ~count_double) begin
            count_double <= 1'b1;
            count_start <= 1'b1;
          end
        end
      endcase
    end
  end

/*********** Serial Output ***********/
`define S_O_STATE_WAIT 1'b0
`define S_O_STATE_SEND 1'b1

  reg [BITWIDTH_BITS - 1:0] s_o_counter;
  reg s_o_state;
  reg [ 3:0] s_o_progress;
  reg [ 7:0] s_o_data;

  reg serial_out;
  assign as_busy_o = (s_o_state == `S_O_STATE_SEND);

  always @(posedge clk) begin
    if (reset) begin
      s_o_state<=`S_O_STATE_WAIT;
      serial_out<=1'b1;
      s_o_progress<=4'b0;
      s_o_counter<=32'b0;
    end else begin
      case (s_o_state)
        `S_O_STATE_WAIT: begin
          serial_out<=1'b1;
          if (as_dstrb_i) begin
            s_o_progress<=4'b0;
            s_o_counter<=32'b0;
            s_o_data<=as_data_i;
            s_o_state<=`S_O_STATE_SEND;
          end
        end
        `S_O_STATE_SEND: begin

          case (s_o_progress)
           4'd0 : serial_out <= 1'b0;
           4'd1 : serial_out <= s_o_data[0];
           4'd2 : serial_out <= s_o_data[1];
           4'd3 : serial_out <= s_o_data[2];
           4'd4 : serial_out <= s_o_data[3];
           4'd5 : serial_out <= s_o_data[4];
           4'd6 : serial_out <= s_o_data[5];
           4'd7 : serial_out <= s_o_data[6];
           4'd8 : serial_out <= s_o_data[7];
           default : serial_out <= 1'b1; 
          endcase

          if (s_o_counter < SERIAL_BITWIDTH - 1) begin
            s_o_counter<=s_o_counter + 1;
          end else if (s_o_progress == 4'd9) begin //start, 8 data, start - 1
            s_o_state<=`S_O_STATE_WAIT;
          end else begin
            s_o_counter<=32'b0;
            s_o_progress<=s_o_progress + 1;
          end
        end
      endcase
    end
  end 

endmodule


