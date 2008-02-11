module TB_from_controller();
  reg clk,reset;
  reg [7:0] from_data;
  wire [6:0] from_addr;
  wire from_clk;

  reg  wb_cyc_i, wb_stb_i, wb_we_i;
  reg  [15:0] wb_adr_i;
  reg  [15:0] wb_dat_i;
  wire [15:0] wb_dat_o;
  wire wb_ack_o;
  
  from_controller from_controller(
    .wb_clk_i(clk), .wb_rst_i(reset),
    .wb_cyc_i(wb_cyc_i), .wb_stb_i(wb_stb_i), .wb_we_i(wb_we_i),
    .wb_adr_i(wb_adr_i), .wb_dat_i(wb_dat_i), .wb_dat_o(wb_dat_o),
    .wb_ack_o(wb_ack_o),
    .from_clk(from_clk), .from_addr(from_addr), .from_data(from_data)
  );


  initial begin
    clk<=1'b0;
    reset<=1'b1;
`ifdef DEBUG
    $display("sim: starting sim");
`endif
    #5
    reset<=1'b0;
`ifdef DEBUG
    $display("sim: clearing reset");
`endif
    #8000 
    $display("FAILED: simulation timed out");
    $finish;
  end

  always begin
    #1 clk <=~clk;
  end

    /*from goodies*/
  always @(posedge from_clk) begin
    from_data<={1'b0,from_addr};
  end

  reg state;
  `define STATE_SEND 1'b0
  `define STATE_WAIT 1'b1

  reg [6:0] counter;
  always @(posedge clk) begin
    wb_cyc_i <= 1'b0;
    wb_stb_i <= 1'b0;
    if (reset) begin
      counter <= 7'b0;
      state <= `STATE_SEND;
    end else begin
      case (state)
        `STATE_SEND: begin
          wb_cyc_i <= 1'b1;
          wb_stb_i <= 1'b1;
          wb_we_i  <= 1'b0;
          wb_adr_i <= {9'b0, counter};
          state <= `STATE_WAIT;
        end
        `STATE_WAIT: begin
          if (wb_ack_o) begin
            if (wb_dat_o[6:0] != counter) begin
              $display("FAILED: invalid data");
              $finish;
            end else if (counter == 7'b111_1111) begin
              $display("PASSED");
              $finish;
            end
            counter <= counter + 1;
            state <= `STATE_SEND;
          end
        end
      endcase
    end
  end


endmodule
