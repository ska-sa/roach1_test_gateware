`include "irq_controller.vh"
module irq_controller(
    wb_rst_i, wb_clk_i,
    wb_cyc_i, wb_stb_i, wb_we_i,
    wb_adr_i, wb_dat_i, wb_dat_o,
    wb_ack_o,
    irq_i, irq_o
  );
  parameter NUM_SOURCES = 4;
  input  wb_rst_i, wb_clk_i;
  input  wb_cyc_i, wb_stb_i, wb_we_i;
  input  [15:0] wb_adr_i;
  input  [15:0] wb_dat_i;
  output [15:0] wb_dat_o;
  output wb_ack_o;
  input  [NUM_SOURCES - 1:0] irq_i;
  output irq_o;
  
  reg wb_ack_o;
  reg wb_dat_o_src;

  reg [NUM_SOURCES:0] irq_mask;
  reg [NUM_SOURCES:0] irq_flag;
  assign wb_dat_o = wb_dat_o_src ? {{16 - (NUM_SOURCES + 1){1'b0}}, irq_mask} :
                                   {{16 - (NUM_SOURCES + 1){1'b0}}, irq_flag};
  assign irq_o=((irq_flag & irq_mask) != 5'b0);

  always @(posedge wb_clk_i) begin
    wb_ack_o <= 1'b0;
    if (wb_rst_i) begin
      irq_mask<={NUM_SOURCES + 1 {1'b1}};
      irq_flag<={NUM_SOURCES + 1 {1'b0}};
    end else begin
      if (wb_cyc_i & wb_stb_i & ~wb_ack_o) begin
        wb_ack_o <= 1'b1;
        case (wb_adr_i)
          `REG_IRQC_FLAG: begin
            if (wb_we_i) begin
              irq_flag<=irq_flag & wb_dat_i[NUM_SOURCES:0]; //leave zeros, clear ones
`ifdef DEBUG

              $display("irqc: setting flags to %b -- events = %b",irq_flag & wb_dat_i[NUM_SOURCES:0],irq_i);
`endif
            end else begin
              wb_dat_o_src <= 1'b0;
            end
          end
          `REG_IRQC_USER: begin
            if (wb_we_i) begin
              irq_flag[NUM_SOURCES] <= wb_dat_i == 16'hff_ff; // set the user irq bit
            end 
          end
          `REG_IRQC_MASK: begin
            if (wb_we_i) begin
              irq_mask<=wb_dat_i[NUM_SOURCES:0];
            end else begin
              wb_dat_o_src <= 1'b1;
            end
          end
        endcase
      end else begin
        irq_flag<=(irq_flag | {1'b0, irq_i}); //leave ones, set zeros
`ifdef DEBUG
        if ( irq_flag != (irq_flag | {1'b0, irq_i})) begin
          $display("irqc: got irq -- events == %b", irq_i);
        end
`endif 
      end 
    end 
  end
  
endmodule
