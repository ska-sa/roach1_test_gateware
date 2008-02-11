`timescale 1ns/10ps
module serial_uart(
    clk, reset,
    serial_in, serial_out,
    as_data_i,  as_data_o,
    as_dstrb_i, as_busy_o, as_dstrb_o
  );
  parameter BAUD        = 115200;
  parameter CLOCK_RATE  = 100000000;
  /*
   * serial/serial side signals
   */

  input clk;
  input reset;
  
  input serial_in;
  output serial_out;
  /*
   * Host signals
   */
  output [7:0] as_data_o;
  input  [7:0] as_data_i;
  input  as_dstrb_i;
  output as_busy_o;
  output as_dstrb_o;
  
  wire [31:0] serial_bitwidth = CLOCK_RATE / BAUD; //divide optimized?


/*********** Serial Input  ***********/
`define S_I_STATE_HUNT      2'd0
`define S_I_STATE_STARTHALF 2'd1
`define S_I_STATE_DATA      2'd2

  reg [31:0] s_i_counter;
  reg [ 1:0] s_i_state;
  reg [ 3:0] s_i_progress;
  reg [ 7:0] s_i_data;

  assign as_data_o = s_i_data;

  reg as_dstrb_o;

  always @(posedge clk) begin
    if (reset) begin
      as_dstrb_o<=1'b0;
      s_i_state<=`S_I_STATE_HUNT;
    end else begin
      as_dstrb_o<=1'b0;

      case (s_i_state)
        `S_I_STATE_HUNT: begin
          if (serial_in == 1'b0) begin
            s_i_counter<=32'b0;
            s_i_progress<=4'b0;
            s_i_state<=`S_I_STATE_STARTHALF;
          end
        end
        `S_I_STATE_STARTHALF: begin
          if (s_i_counter == (serial_bitwidth >> 1) - 1) begin
            s_i_counter<=32'b0;
            s_i_state<=`S_I_STATE_DATA;
          end else begin
            s_i_counter<=s_i_counter + 1;
          end
        end
        `S_I_STATE_DATA: begin
          if (s_i_counter == serial_bitwidth - 1) begin
            s_i_counter<=32'b0;
            if (s_i_progress < 8) begin
              s_i_data[s_i_progress]<=serial_in;
              s_i_progress<=s_i_progress + 1;
            end else begin
              as_dstrb_o<=1'b1; //one cycle late but - hey - its slow anyway
              s_i_state<=`S_I_STATE_HUNT; //dont worry about reset of stopbit
            end
          end else begin
            s_i_counter<=s_i_counter + 1;
          end
        end
      endcase
    end
  end

/*********** Serial Output ***********/
`define S_O_STATE_WAIT 1'b0
`define S_O_STATE_SEND 1'b1

  reg [31:0] s_o_counter;
  reg s_o_state;
  reg [ 3:0] s_o_progress;
  reg [ 7:0] s_o_data;

  reg serial_out;
  assign as_busy_o = as_dstrb_i | (s_o_state == `S_O_STATE_SEND);

  always @(posedge clk) begin
    if (reset) begin
      s_o_state<=`S_O_STATE_WAIT;
      serial_out<=1'b1;
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

          if (s_o_counter < serial_bitwidth - 1) begin
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
