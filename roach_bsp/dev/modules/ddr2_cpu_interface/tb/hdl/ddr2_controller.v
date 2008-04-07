module ddr2_controller(
    clk, reset,
    af_cmnd_i, af_addr_i, af_wen_i,
    af_afull_o,
    df_data_i, df_mask_i, df_wen_i,
    df_afull_o,
    data_o, dvalid_o
  );
  input  clk, reset;
  input    [2:0] af_cmnd_i;
  input   [30:0] af_addr_i;
  input  af_wen_i;
  output af_afull_o;
  input  [127:0] df_data_i;
  input   [15:0] df_mask_i;
  input  df_wen_i;
  output df_afull_o;
  output [127:0] data_o;
  output dvalid_o;

  /* Address Fifo */
 
  reg [32:0] address_fifo [31:0];

  reg [4:0] fifo_head;
  reg [4:0] fifo_tail;
  reg fifo_empty;

  always @(posedge clk) begin
    if (reset) begin
      fifo_empty <= 1'b1;
      fifo_head  <= 5'd0;
      fifo_tail  <= 5'd0;
    end else begin
    end
  end


  /* Data Fifo */

endmodule
