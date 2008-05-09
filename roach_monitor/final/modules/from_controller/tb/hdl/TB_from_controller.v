`timescale 1ns/1ns
`define CLK_PERIOD 25

`ifdef MODELSIM
`include "fusion.v"
`endif
module TB_from_controller();
  wire clk;
  reg  reset;
  wire [7:0] from_data;
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


  reg [7:0] clk_counter;

  initial begin
    $dumpvars();
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
    #80000 
    $display("FAILED: simulation timed out");
    $finish;
  end

  assign clk = clk_counter < ((`CLK_PERIOD) / 2);

  always begin
    #1 clk_counter <= (clk_counter == `CLK_PERIOD - 1 ? 32'b0 : clk_counter + 1);
  end

  /*from goodies*/
  `ifdef MODELSIM
  UFROM #(
    .MEMORYFILE("include/from.mem")
  ) UFROM_inst(
    .ADDR6(from_addr[6]), .ADDR5(from_addr[5]), .ADDR4(from_addr[4]), .ADDR3(from_addr[3]),
    .ADDR2(from_addr[2]), .ADDR1(from_addr[1]), .ADDR0(from_addr[0]),
    .CLK(from_clk),
    .DO7(from_data[7]), .DO6(from_data[6]), .DO5(from_data[5]), .DO4(from_data[4]),
    .DO3(from_data[3]), .DO2(from_data[2]), .DO1(from_data[1]), .DO0(from_data[0])
  );
  `else
  reg [7:0] from_data_reg;
  assign from_data = from_data_reg;
  always @(posedge from_clk) begin
    from_data_reg<={1'b0,from_addr};
  end
  `endif

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
`ifdef DEBUG
          $display("wbm: read command, adr = %x", {9'b0, counter});
`endif
        end
        `STATE_WAIT: begin
          if (wb_ack_o) begin
`ifdef DEBUG
            $display("wbm: read reply,  data = %x", wb_dat_o);
`endif
            if (wb_dat_o[6:0] !== counter) begin
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
