
`define SIMLENGTH 64000
`define CLK_PERIOD 10

module TB_gpio_test();
  localparam GPIO_COUNT = 80;

  wire        wb_clk_i;
  wire        wb_rst_i;
  wire        wb_cyc_i;
  wire        wb_stb_i;
  wire        wb_we_i;
  wire  [1:0] wb_sel_i;
  wire [31:0] wb_adr_i;
  wire [15:0] wb_dat_i;
  wire [15:0] wb_dat_o;
  wire        wb_ack_o;
  wire [GPIO_COUNT-1:0] gpio;

  gpio_test  #(
    .GPIO_COUNT (GPIO_COUNT)
  ) gpio_test (
    /* Wishbone Interface */
    .wb_clk_i(wb_clk_i),
    .wb_rst_i(wb_rst_i),
    .wb_cyc_i(wb_cyc_i),
    .wb_stb_i(wb_stb_i),
    .wb_we_i(wb_we_i),
    .wb_sel_i(wb_sel_i),
    .wb_adr_i(wb_adr_i),
    .wb_dat_i(wb_dat_i),
    .wb_dat_o(wb_dat_o),
    .wb_ack_o(wb_ack_o),
    .gpio(gpio)
  );

  reg reset;
  reg [31:0] clk_counter;

  initial begin
    reset <=1'b1;
    clk_counter <=32'b0;
    $dumpvars();
    #50
    reset <=1'b0;
`ifdef DEBUG
    $display("sys: reset cleared");
`endif
    #`SIMLENGTH
    $display("FAILED: simulation timed out");
    $finish;
  end

  wire clk = clk_counter < ((`CLK_PERIOD) / 2);

  always begin
    #1 clk_counter <= (clk_counter == `CLK_PERIOD - 1 ? 32'b0 : clk_counter + 1);
  end

  /** **/

  assign wb_clk_i = clk;
  assign wb_rst_i = reset;

  reg [31:0] progress;
  reg [31:0] wb_adr;
  reg [15:0] wb_dat;
  reg wb_stb;
  reg wb_we;

  reg mode;

  assign gpio = mode == 0 ? {GPIO_COUNT{1'b1}} : {GPIO_COUNT{1'bz}};

  always @(posedge wb_clk_i) begin
    wb_stb <= 1'b0;
    if (wb_rst_i) begin
      progress <= 0;
      mode <= 0;
    end else begin
      case (progress)
        0: begin
          wb_adr  <= 16'h40;
          wb_we   <= 1;
          wb_stb  <= 1'b1;
          wb_dat  <= 16'h0;
          progress <= progress + 1;
        end
        1: begin
          if (wb_ack_o) begin
            wb_adr  <= 16'h42;
            wb_we   <= 1;
            wb_stb  <= 1'b1;
            wb_dat  <= 16'h0;
            progress <= progress + 1;
          end
        end
        2: begin
          if (wb_ack_o) begin
            wb_adr  <= 16'h44;
            wb_we   <= 1;
            wb_stb  <= 1'b1;
            wb_dat  <= 16'h0;
            progress <= progress + 1;
          end
        end
        3: begin
          if (wb_ack_o) begin
            wb_adr  <= 0;
            wb_we   <= 0;
            wb_stb  <= 1'b1;
            progress <= progress + 1;
          end
        end
        4: begin
          if (wb_ack_o) begin
            wb_adr  <= 2;
            wb_we   <= 0;
            wb_stb  <= 1'b1;
            progress <= progress + 1;
            $display("%x %x", progress, wb_dat_o);
          end
        end
        5: begin
          if (wb_ack_o) begin
            wb_adr  <= 4;
            wb_we   <= 0;
            wb_stb  <= 1'b1;
            progress <= progress + 1;
            $display("%x %x", progress, wb_dat_o);
          end
        end
        /***** OEs ******/
        6: begin
          if (wb_ack_o) begin
            $display("%x %x", progress, wb_dat_o);
            mode <= 1;
            wb_adr  <= 16'h40;
            wb_we   <= 1;
            wb_stb  <= 1'b1;
            wb_dat  <= 16'hffff;
            progress <= progress + 1;
          end
        end
        7: begin
          if (wb_ack_o) begin
            wb_adr  <= 16'h42;
            wb_we   <= 1;
            wb_stb  <= 1'b1;
            wb_dat  <= 16'hffff;
            progress <= progress + 1;
          end
        end
        8: begin
          if (wb_ack_o) begin
            wb_adr  <= 16'h44;
            wb_we   <= 1;
            wb_stb  <= 1'b1;
            wb_dat  <= 16'hffff;
            progress <= progress + 1;
          end
        end
        /* Data Wr */
        9: begin
          if (wb_ack_o) begin
            wb_adr  <= 16'h20;
            wb_we   <= 1;
            wb_stb  <= 1'b1;
            wb_dat  <= 16'hdead;
            progress <= progress + 1;
          end
        end
        10: begin
          if (wb_ack_o) begin
            wb_adr  <= 16'h22;
            wb_we   <= 1;
            wb_stb  <= 1'b1;
            wb_dat  <= 16'hbeef;
            progress <= progress + 1;
          end
        end
        11: begin
          if (wb_ack_o) begin
            wb_adr  <= 16'h24;
            wb_we   <= 1;
            wb_stb  <= 1'b1;
            wb_dat  <= 16'hbeef;
            progress <= progress + 1;
          end
        end
        12: begin
          if (wb_ack_o) begin
            $display("gpio %x", gpio);
            $finish;
          end
        end
      endcase
    end
  end

  assign wb_cyc_i = wb_stb;
  assign wb_stb_i = wb_stb;
  assign wb_we_i  = wb_we;
  assign wb_adr_i = wb_adr;
  assign wb_dat_i = wb_dat;
  assign wb_sel_i = 2'b11;


endmodule
