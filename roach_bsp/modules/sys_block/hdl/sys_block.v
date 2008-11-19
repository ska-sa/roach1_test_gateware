`include "sys_block.vh"
module sys_block(
    //wb slave
    wb_clk_i, wb_rst_i,
    wb_we_i, wb_cyc_i, wb_stb_i, wb_sel_i,
    wb_adr_i, wb_dat_i, wb_dat_o,
    wb_ack_o,
    soft_reset,
    irq_n,
    app_irq,
    sys_irq
  );
  parameter BOARD_ID     = 16'hdead;
  parameter REV_MAJOR    = 16'haaaa;
  parameter REV_MINOR    = 16'hbbbb;
  parameter REV_RCS      = 16'hcccc;
  parameter RCS_UPTODATE = 1'b1;

  input  wb_clk_i;
  input  wb_rst_i;
  input  wb_we_i;
  input  wb_cyc_i;
  input  wb_stb_i;
  input   [1:0] wb_sel_i;
  input  [31:0] wb_adr_i;
  input  [15:0] wb_dat_i;
  output [15:0] wb_dat_o;
  output wb_ack_o;

  output soft_reset;
  output irq_n;
  input  [31:0] app_irq;
  input  [31:0] sys_irq;

  /* IRQ signals */
  wire [31:0] sys_irq_reg;
  wire [31:0] app_irq_reg;
  reg  [31:0] irq_sys_mask;
  reg  [31:0] irq_app_mask;

  reg soft_reset;

  reg wb_ack_o;
  reg  [4:0] wb_dat_o_sel;
  reg [31:0] scratch_pad;

  /* V5 System Monitor Signals */
  reg  mon_strb;
  reg  mon_we;
  reg   [6:0] mon_addr;
  reg  [15:0] mon_data;
  wire [15:0] mon_datai;
  wire mon_rdy;
  wire mon_busy;

  assign wb_dat_o = wb_dat_o_sel == `REG_BOARD_ID     ? BOARD_ID              :
                    wb_dat_o_sel == `REG_REV_MAJOR    ? REV_MAJOR             :
                    wb_dat_o_sel == `REG_REV_MINOR    ? REV_MINOR             :
                    wb_dat_o_sel == `REG_REV_RCS      ? REV_RCS               :
                    wb_dat_o_sel == `REG_RCS_UPTODATE ? {15'b0, RCS_UPTODATE} :
                    wb_dat_o_sel == `REG_SCRATCHPAD1  ? scratch_pad[31:16]    :
                    wb_dat_o_sel == `REG_SCRATCHPAD0  ? scratch_pad[15:0]     :
                    wb_dat_o_sel == `REG_SOFT_RESET   ? {15'b0, soft_reset}   :
                    wb_dat_o_sel == `REG_MON_ADDR     ? {9'b0, mon_addr}      :
                    wb_dat_o_sel == `REG_MON_DATA     ? mon_data              :
                    wb_dat_o_sel == `REG_MON_STATUS   ? {15'b0, mon_busy}     :
                    wb_dat_o_sel == `REG_IRQ_USR1     ? app_irq_reg[31:16]    :
                    wb_dat_o_sel == `REG_IRQ_USR0     ? app_irq_reg[15:0]     :
                    wb_dat_o_sel == `REG_IRQ_SYS1     ? sys_irq_reg[31:16]    :
                    wb_dat_o_sel == `REG_IRQ_SYS0     ? sys_irq_reg[15:0]     :
                    wb_dat_o_sel == `REG_IRQ_MASKUSR1 ? irq_app_mask[31:16]   :
                    wb_dat_o_sel == `REG_IRQ_MASKUSR0 ? irq_app_mask[15:0]    :
                    wb_dat_o_sel == `REG_IRQ_MASKSYS1 ? irq_sys_mask[31:16]   :
                    wb_dat_o_sel == `REG_IRQ_MASKSYS0 ? irq_sys_mask[15:0]    :
                    16'b0;


  reg irq_sys_clear;
  reg irq_app_clear;

  reg mon_wait; // wait state for monitor

  always @(posedge wb_clk_i) begin
    irq_sys_clear <= 1'b0;
    irq_app_clear <= 1'b0;

    wb_ack_o <= 1'b0;
    mon_strb <= 1'b0;
    if (wb_rst_i) begin
      soft_reset <= 1'b0;
      mon_wait   <= 1'b0;
      mon_we     <= 1'b0;
    end else begin
      if (mon_wait && mon_rdy) begin
        mon_wait <= 1'b0;
        wb_ack_o <= 1'b1;
        if (!mon_we) //if we are reading latch the incoming data
          mon_data <= mon_datai;
      end
      if (wb_cyc_i & wb_stb_i & ~wb_ack_o) begin
        if (wb_adr_i[4:1] == `REG_MON_DATA) begin
          mon_we   <= wb_we_i;
          mon_strb <= 1'b1;
          mon_wait <= 1'b1;
          wb_ack_o <= 1'b0;
        end else begin
          mon_wait <= 1'b0;
          wb_ack_o <= 1'b1;
        end
        wb_dat_o_sel <= wb_adr_i[5:1];

        case (wb_adr_i[4:1])
          `REG_BOARD_ID: begin
          end
          `REG_REV_MAJOR: begin
          end
          `REG_REV_MINOR: begin
          end
          `REG_REV_RCS: begin
          end
          `REG_RCS_UPTODATE: begin
          end
          `REG_SCRATCHPAD1: begin
            if (wb_we_i) begin
              if (wb_sel_i[0])
                scratch_pad[23:16] <= wb_dat_i[7:0];
              if (wb_sel_i[1])
                scratch_pad[31:24] <= wb_dat_i[15:8];
            end
          end
          `REG_SCRATCHPAD0: begin
            if (wb_we_i) begin
              if (wb_sel_i[0])
                scratch_pad[7:0] <= wb_dat_i[7:0];
              if (wb_sel_i[1])
                scratch_pad[15:8] <= wb_dat_i[15:8];
            end
          end
          `REG_SOFT_RESET: begin
            if (wb_we_i && wb_sel_i[0]) begin
              soft_reset <= wb_dat_i[0];
            end
          end
          `REG_MON_ADDR: begin
            if (wb_we_i && wb_sel_i[0]) begin
              mon_addr <= wb_dat_i[6:0];
            end
          end
          `REG_MON_DATA: begin
            if (wb_we_i) begin
              if (wb_sel_i[0])
                mon_data[7:0]  <= wb_dat_i[7:0];
              if (wb_sel_i[1])
                mon_data[15:8] <= wb_dat_i[15:8];
            end
          end
          `REG_MON_STATUS: begin
          end
          `REG_IRQ_USR1: begin
            if (wb_we_i) begin
              irq_app_clear <= 1'b1;
            end
          end
          `REG_IRQ_USR0: begin
            if (wb_we_i) begin
              irq_app_clear <= 1'b1;
            end
          end
          `REG_IRQ_SYS1: begin
            if (wb_we_i) begin
              irq_sys_clear <= 1'b1;
            end
          end
          `REG_IRQ_SYS0: begin
            if (wb_we_i) begin
              irq_sys_clear <= 1'b1;
            end
          end
          `REG_IRQ_MASKUSR1: begin
            if (wb_we_i) begin
              if (wb_sel_i[0])
                irq_app_mask[23:16]  <= wb_dat_i[7:0];
              if (wb_sel_i[1])
                irq_app_mask[31:24] <= wb_dat_i[15:8];
            end
          end
          `REG_IRQ_MASKUSR0: begin
            if (wb_we_i) begin
              if (wb_sel_i[0])
                irq_app_mask[7:0]  <= wb_dat_i[7:0];
              if (wb_sel_i[1])
                irq_app_mask[15:8] <= wb_dat_i[15:8];
            end
          end
          `REG_IRQ_MASKSYS1: begin
            if (wb_we_i) begin
              if (wb_sel_i[0])
                irq_sys_mask[23:16]  <= wb_dat_i[7:0];
              if (wb_sel_i[1])
                irq_sys_mask[31:24] <= wb_dat_i[15:8];
            end
          end
          `REG_IRQ_MASKSYS0: begin
            if (wb_we_i) begin
              if (wb_sel_i[0])
                irq_sys_mask[7:0]  <= wb_dat_i[7:0];
              if (wb_sel_i[1])
                irq_sys_mask[15:8] <= wb_dat_i[15:8];
            end
          end
        endcase
      end
    end
  end

  v5_sysmon v5_sysmon(
    .clk   (wb_clk_i),
    .reset (wb_rst_i),

    .drp_den   (mon_strb),
    .drp_dwe   (mon_we),
    .drp_daddr (mon_addr),
    .drp_datai (mon_data),
    .drp_datao (mon_datai),
    .drp_drdy  (mon_rdy), 

    .port_busy (mon_busy)
  );

  wire irq_out_int;

  irq_controller irq_controller_inst(
    .clk (clk),
    .rst (rst),
    .irq_sys_i (sys_irq),
    .irq_app_i (app_irq),
    .irq_sys_mask (irq_sys_mask), 
    .irq_app_mask (irq_app_mask), 
    .irq_sys_o (sys_irq_reg),
    .irq_app_o (app_irq_reg),
    .irq_sys_clear (irq_sys_clear),
    .irq_app_clear (irq_app_clear),
    .irq_out (irq_out_int)
  );

  assign irq_n = !irq_out_int;

endmodule
