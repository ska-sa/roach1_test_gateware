module system_block #(
    parameter DESIGN_ID = 0,
    parameter REV_MAJOR = 0,
    parameter REV_MINOR = 0,
    parameter REV_RCS   = 0
  ) (
    input        wb_clk_i,
    input        wb_rst_i,
    input        wb_stb_i,
    input        wb_cyc_i,
    input        wb_we_i,
    input  [2:0] wb_adr_i,
    input  [7:0] wb_dat_i,
    output [7:0] wb_dat_o,
    output       wb_ack_o,

    input  [3:0] irq_src,
    output       irq
  );

  localparam REG_ID_1  = 0;
  localparam REG_ID_0  = 1;
  localparam REG_MAJ   = 2;
  localparam REG_MIN   = 3;
  localparam REG_RCS_1 = 4;
  localparam REG_RCS_0 = 5;
  localparam REG_IRQM  = 6;
  localparam REG_IRQR  = 7;

  reg wb_ack_o_reg;

  always @(posedge wb_clk_i) begin
    wb_ack_o_reg <= wb_stb_i;
  end
  assign wb_ack_o = wb_ack_o_reg;

  wire [15:0] rev_id  = DESIGN_ID;
  wire  [7:0] rev_maj = REV_MAJOR;
  wire  [7:0] rev_min = REV_MINOR;
  wire [15:0] rev_rcs = REV_RCS;

  localparam IRQS = 2;
  reg [IRQS-1:0] irq_m;
  reg [IRQS-1:0] irq_r;

  reg [7:0] wb_dat_o_reg;
  always @(*) begin
    case (wb_adr_i)
      REG_ID_1: begin
        wb_dat_o_reg <= rev_id[15:8];
      end
      REG_ID_0: begin
        wb_dat_o_reg <= rev_id[ 7:0];
      end
      REG_MAJ: begin
        wb_dat_o_reg <= rev_maj[ 7:0];
      end
      REG_MIN: begin
        wb_dat_o_reg <= rev_min[ 7:0];
      end
      REG_RCS_1: begin
        wb_dat_o_reg <= rev_rcs[15:8];
      end
      REG_RCS_0: begin
        wb_dat_o_reg <= rev_rcs[ 7:0];
      end
      REG_IRQM: begin
        wb_dat_o_reg <= irq_m;
      end
      REG_IRQR: begin
        wb_dat_o_reg <= irq_r;
      end
      default: begin
        wb_dat_o_reg  <= 8'd0;
      end
    endcase
  end
  assign wb_dat_o = wb_dat_o_reg;

  always @(posedge wb_clk_i) begin
    if (wb_rst_i) begin
      irq_r <= {IRQS{1'b0}};
      irq_m <= {IRQS{1'b0}};
    end else begin
      irq_r <= irq_src | irq_r;

      if (wb_stb_i && wb_cyc_i && wb_we_i) begin
        if (wb_adr_i == REG_IRQM) begin
          irq_m <= wb_dat_i[IRQS-1:0];
        end
        if (wb_adr_i == REG_IRQR) begin
          irq_r <= wb_dat_i[IRQS-1:0];
        end
      end
    end
  end

  assign irq = |(irq_r & irq_m);
endmodule
