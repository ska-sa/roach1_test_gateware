module gpio_controller #(
    parameter NUM_GPIO     = 12,
    parameter OE_DEFAULTS  = 0,
    parameter OUT_DEFAULTS = 0,
    parameter DED_DEFAULTS = 0

  ) (
    input                 wb_clk_i,
    input                 wb_rst_i,
    input                 wb_stb_i,
    input                 wb_cyc_i,
    input                 wb_we_i,
    input          [15:0] wb_adr_i,
    input          [15:0] wb_dat_i,
    output         [15:0] wb_dat_o,
    output                wb_ack_o,

    output [NUM_GPIO-1:0] gpio_oe,
    output [NUM_GPIO-1:0] gpio_out,
    input  [NUM_GPIO-1:0] gpio_in,

    //dedicated function enable
    output [NUM_GPIO-1:0] ded_en
  );

  reg [NUM_GPIO-1:0] gpio_oe_reg;
  reg [NUM_GPIO-1:0] gpio_out_reg;
  reg [NUM_GPIO-1:0] ded_en_reg;

  assign gpio_oe  = gpio_oe_reg;
  assign gpio_out = gpio_out_reg;
  assign ded_en   = ded_en_reg;

  reg wb_ack_reg;
  assign wb_ack_o = wb_ack_reg;

  localparam REG_OE  = 0;
  localparam REG_OUT = 1;
  localparam REG_IN  = 2;
  localparam DED_EN  = 3;

  always @(posedge wb_clk_i) begin
    wb_ack_reg <= 1'b0;

    if (wb_rst_i) begin
      gpio_oe_reg  <= OE_DEFAULTS;
      gpio_out_reg <= OUT_DEFAULTS;
      ded_en_reg   <= DED_DEFAULTS;
    end else begin
      if (wb_stb_i && wb_cyc_i && !wb_ack_reg) begin
        wb_ack_reg <= 1'b1;
        if (wb_we_i) begin
          case (wb_adr_i[1:0])
            REG_OE: begin
              gpio_oe_reg  <= wb_dat_i[NUM_GPIO-1:0];
            end
            REG_OUT: begin
              gpio_out_reg <= wb_dat_i[NUM_GPIO-1:0];
            end
            DED_EN: begin
              ded_en_reg <= wb_dat_i[NUM_GPIO-1:0];
            end
            default: begin
            end
          endcase
        end
      end
    end
  end

  reg [15:0] wb_dat_o_reg;
  assign wb_dat_o = wb_dat_o_reg;
  always @(*) begin
    case (wb_adr_i[1:0])
      REG_OE:
        wb_dat_o_reg <= gpio_oe_reg;
      REG_OUT:
        wb_dat_o_reg <= gpio_out_reg;
      REG_IN:
        wb_dat_o_reg <= gpio_in;
      DED_EN:
        wb_dat_o_reg <= ded_en;
      default:
        wb_dat_o_reg <= 0;
    endcase
  end

endmodule
