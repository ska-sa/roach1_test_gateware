module gpio_test #(
    parameter GPIO_COUNT = 48
  ) (
    /* Wishbone Interface */
    input         wb_clk_i,
    input         wb_rst_i,
    input         wb_cyc_i,
    input         wb_stb_i,
    input         wb_we_i,
    input   [1:0] wb_sel_i,
    input  [31:0] wb_adr_i,
    input  [15:0] wb_dat_i,
    output [15:0] wb_dat_o,
    output        wb_ack_o,
    inout  [GPIO_COUNT-1:0] gpio
  );

  wire [GPIO_COUNT - 1:0] gpio_o;
  wire [GPIO_COUNT - 1:0] gpio_i;
  wire [GPIO_COUNT - 1:0] gpio_oe;

  genvar moo;

  IOBUF iob_gpio[GPIO_COUNT-1:0](
    .IO (gpio),
    .O  (gpio_i),
    .I  (gpio_o),
    .T  (~gpio_oe)
  );

  reg wb_ack_o_reg;

  always @(posedge wb_clk_i) begin
    wb_ack_o_reg <= 1'b0;
    if (wb_rst_i) begin
    end else begin
      if (wb_cyc_i && wb_stb_i && !wb_ack_o) begin
        wb_ack_o_reg <= 1'b1;
      end
    end
  end
  assign wb_ack_o = wb_ack_o_reg;

  wire wb_trans = wb_cyc_i && wb_stb_i && !wb_ack_o;

  wire [1:0] type_sel = wb_adr_i[6:5];
  wire [3:0] reg_sel  = wb_adr_i[4:1];

  /************ WB Read Logic ************/

  wire [15:0] gpio_i_val;
  wire [15:0] gpio_o_val;
  wire [15:0] gpio_oe_val;

  reg [15:0] wb_dat_o_reg;
  always @(*) begin
    case (type_sel)
      2'b00: begin
        wb_dat_o_reg <= gpio_i_val;
      end 
      2'b01: begin
        wb_dat_o_reg <= gpio_o_val;
      end 
      default: begin
        wb_dat_o_reg <= gpio_oe_val;
      end 
    endcase
  end
  assign wb_dat_o = wb_dat_o_reg;

  assign gpio_i_val  = gpio_i  >> (reg_sel * 16);
  assign gpio_o_val  = gpio_o  >> (reg_sel * 16);
  assign gpio_oe_val = gpio_oe >> (reg_sel * 16);

  /************ WB Write Logic ************/

  reg [15:0] data_o_array  [15:0];
  reg [15:0] data_oe_array [15:0];
  integer i,j,k;

  always @(posedge wb_clk_i) begin
    if (wb_rst_i) begin
    end else if (wb_trans && wb_we_i) begin
      case (type_sel)
        2'b01: begin
          for (i=0; i < 16; i=i+1) begin
            if (reg_sel == i) begin
                data_o_array[i]  <= {(wb_sel_i[1] ? wb_dat_i[15:8] : data_o_array[i] [15:8]),
                                     (wb_sel_i[0] ? wb_dat_i[ 7:0] : data_o_array[i] [ 7:0])};
            end
          end
        end 
        default: begin
          for (k=0; k < 16; k=k+1) begin
            if (reg_sel == k) begin
                data_oe_array[k] <= {(wb_sel_i[1] ? wb_dat_i[15:8] : data_oe_array[k] [15:8]),
                                     (wb_sel_i[0] ? wb_dat_i[ 7:0] : data_oe_array[k] [ 7:0])};
            end
          end
        end 
      endcase
    end
  end

  wire [255:0] data_o_cat;
  wire [255:0] data_oe_cat;

  genvar genj;

generate for (genj=0; genj< 16; genj=genj+1) begin : catgen
  assign data_o_cat [16*(genj+1) - 1: 16*genj] = data_o_array[genj];
  assign data_oe_cat[16*(genj+1) - 1: 16*genj] = data_oe_array[genj];
end endgenerate

  assign gpio_o  = data_o_cat;
  assign gpio_oe = data_oe_cat;

endmodule
