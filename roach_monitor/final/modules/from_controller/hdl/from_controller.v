`timescale 1ns/1ns
module from_controller(
    wb_clk_i, wb_rst_i,
    wb_cyc_i, wb_stb_i, wb_we_i,
    wb_adr_i, wb_dat_i, wb_dat_o,
    wb_ack_o,
    from_clk, from_addr, from_data
  );
  input  wb_clk_i, wb_rst_i;
  input  wb_cyc_i, wb_stb_i, wb_we_i;
  input  [15:0] wb_adr_i;
  input  [15:0] wb_dat_i;
  output [15:0] wb_dat_o;
  output wb_ack_o;

  output from_clk;
  output [6:0] from_addr;
  input  [7:0] from_data;

  reg [1:0] from_clk_counter;
  assign from_clk = from_clk_counter[1];

  assign from_addr = wb_adr_i[6:0];

  reg wb_ack_o;
  assign wb_dat_o = {8'b0, from_data};

  reg [1:0] state; 
  localparam STATE_IDLE      = 2'd0; 
  localparam STATE_WAITCLK   = 2'd1; 
  localparam STATE_WAITTRANS = 2'd2; 

  always @(posedge wb_clk_i) begin
    wb_ack_o <= 1'b0;
    from_clk_counter <= from_clk_counter + 2'b1;

    if (wb_rst_i) begin
      state <= STATE_IDLE;
`ifdef SIMULATION
      if (from_clk_counter === 2'bxx)
        from_clk_counter <= 2'b0;
`endif
    end else begin
      case (state)
        STATE_IDLE: begin
          if (wb_cyc_i & wb_stb_i & ~wb_ack_o) begin
            state <= STATE_WAITCLK;
          end
        end 
        STATE_WAITCLK: begin
          if (from_clk_counter == 2'b00) begin
            state <= STATE_WAITTRANS;
          end
        end
        STATE_WAITTRANS: begin
          if (from_clk_counter == 2'b11) begin
            wb_ack_o <= 1'b1;
            state <= STATE_IDLE;
          end
        end
      endcase 
    end
  end

endmodule
