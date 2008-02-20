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

  assign wb_dat_o = 16'b0;
  reg wb_ack_o;
  assign fan_control = {NUM_FANS{1'b1}}; //on

  always @(posedge wb_clk_i) begin
    //strobes
    wb_ack_o <= 1'b0;
    if (wb_rst_i) begin
    end else begin
      if (wb_cyc_i & wb_stb_i & ~wb_ack_o) begin
        wb_ack_o <= 1'b1;
      end
    end
  end
endmodule

