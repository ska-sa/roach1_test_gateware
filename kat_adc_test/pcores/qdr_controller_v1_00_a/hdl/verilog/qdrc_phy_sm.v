module qdrc_phy_sm(
    clk,
    reset,
    /* qdr_dll_off_n signal */
    qdr_dll_off_n,
    /* PHY status signals */
    phy_rdy,
    cal_fail,
    /* Bit and burst alignment signals */
    bit_align_start,
    bit_align_done,
    bit_align_fail,
    burst_align_start,
    burst_align_done,
    burst_align_fail
  );
  input  clk, reset;
  output qdr_dll_off_n;
  output phy_rdy, cal_fail;

  output bit_align_start;
  input  bit_align_done,   bit_align_fail;
  output burst_align_start;
  input  burst_align_done, burst_align_fail;

  reg [2:0] phy_state;

  localparam STATE_DLLOFF      = 3'd0;
  localparam STATE_WAIT        = 3'd1;
  localparam STATE_BIT_ALIGN   = 3'd2;
  localparam STATE_BURST_ALIGN = 3'd3;
  localparam STATE_DONE        = 3'd4;

  reg [13:0] wait_counter;
  /* qdr_dll_off needs to be deactivated for 2048 cycle after reset is
   * released
   */

  reg bit_align_start, burst_align_start;
  reg cal_fail;

  assign qdr_dll_off_n = !(phy_state == STATE_DLLOFF);
  assign phy_rdy       = phy_state == STATE_DONE;

  always @(posedge clk) begin
    /* Single Cycle Strobes */
    bit_align_start   <= 1'b0;
    burst_align_start <= 1'b0;

    if (reset) begin
      cal_fail     <= 1'b0;
      wait_counter <= 14'b0;
      phy_state    <= STATE_DLLOFF;
    end else begin
      case (phy_state)
        STATE_DLLOFF:      begin
          if (wait_counter[13] == 1'b1) begin
            phy_state    <= STATE_BIT_ALIGN;
            bit_align_start <= 1'b1;
          end else begin
            wait_counter <= wait_counter + 1;
          end
        end
        STATE_BIT_ALIGN:   begin
          if (bit_align_done) begin
            if (bit_align_fail) begin
              cal_fail  <= 1'b1;
              phy_state <= STATE_DONE;
            end else begin
              phy_state <= STATE_BURST_ALIGN;
              burst_align_start <= 1'b1;
            end
          end
        end
        STATE_BURST_ALIGN: begin
          if (burst_align_done) begin
            if (burst_align_fail) begin
              cal_fail  <= 1'b1;
            end
            phy_state <= STATE_DONE;
          end
        end
        STATE_DONE:        begin
        end
      endcase
    end
  end

endmodule
