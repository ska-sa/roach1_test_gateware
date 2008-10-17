module dram_cpu_interface(
    //memory wb slave IF
    wb_clk_i, wb_rst_i,
    reg_wb_we_i, reg_wb_cyc_i, reg_wb_stb_i, reg_wb_sel_i,
    reg_wb_adr_i, reg_wb_dat_i, reg_wb_dat_o,
    reg_wb_ack_o,
    //memory wb slave IF
    mem_wb_we_i, mem_wb_cyc_i, mem_wb_stb_i, mem_wb_sel_i,
    mem_wb_adr_i, mem_wb_dat_i, mem_wb_dat_o,
    mem_wb_ack_o,
    //dram interface

    dram_clk0,
    dram_clk90,
    dram_rst_o,
    dram_phy_rdy,
    dram_cal_fail,

    dram_cmd_rnw,
    dram_cmd_addr,
    dram_cmd_valid,
    dram_wr_data,
    dram_wr_be,

    dram_rd_data,
    dram_rd_valid,

    dram_arb_grant
  );
  parameter CLK_FREQ = 0;
  parameter DQ_WIDTH = 72;

  localparam BE_WIDTH = DQ_WIDTH/8;
  /* Bus interface signals */
  input  wb_clk_i;
  input  wb_rst_i;

  input  reg_wb_we_i;
  input  reg_wb_cyc_i;
  input  reg_wb_stb_i;
  input   [1:0] reg_wb_sel_i;
  input  [31:0] reg_wb_adr_i;
  input  [15:0] reg_wb_dat_i;
  output [15:0] reg_wb_dat_o;
  output reg_wb_ack_o;

  input  mem_wb_we_i;
  input  mem_wb_cyc_i;
  input  mem_wb_stb_i;
  input   [1:0] mem_wb_sel_i;
  input  [31:0] mem_wb_adr_i;
  input  [15:0] mem_wb_dat_i;
  output [15:0] mem_wb_dat_o;
  output mem_wb_ack_o;

  /* DRAM phy signals */
  input  dram_clk0;
  input  dram_clk90;
  output dram_rst_o;
  input  dram_phy_rdy;
  input  dram_cal_fail;
  /* DRAM application interface */
  output dram_cmd_valid;
  output dram_cmd_rnw;
  output [31:0] dram_cmd_addr;
  output [DQ_WIDTH*2 - 1:0] dram_wr_data;
  output [BE_WIDTH*2 - 1:0] dram_wr_be;
  input  [DQ_WIDTH*2 - 1:0] dram_rd_data;
  input  dram_rd_valid;

  /* allow user dram interface to access
   * memory if DRAM_BASIC_ARB is defined
   */
  output dram_arb_grant;

  wire   dram_reset_int;

  dram_reg_wb_attach #(
    .CLK_FREQ(CLK_FREQ)
  ) reg_wb_attach_inst (
    //memory wb slave IF
    .wb_clk_i (wb_clk_i),
    .wb_rst_i (wb_rst_i),
    .wb_cyc_i (reg_wb_cyc_i),
    .wb_stb_i (reg_wb_stb_i),
    .wb_sel_i (reg_wb_sel_i),
    .wb_we_i  (reg_wb_we_i),
    .wb_adr_i (reg_wb_adr_i),
    .wb_dat_i (reg_wb_dat_i),
    .wb_dat_o (reg_wb_dat_o),
    .wb_ack_o (reg_wb_ack_o),

    .phy_ready  (dram_phy_rdy),
    .cal_fail   (dram_cal_fail),

    .dram_reset (dram_reset_int),

    .arb_grant  (dram_arb_grant)
  );

  /* stretch the reset pulse out */
  reg [7:0] reset_reg;
  always @(posedge wb_clk_i) begin
    if (dram_reset_int) begin
      reset_reg <= 8'b1111_1111;
    end else begin
      reset_reg <= reset_reg << 1;
    end
  end

  /* Cross clock domain */
  wire dram_rst_o_int = reset_reg[7];
  reg [1:0] dram_rst_reg;
  assign dram_rst_o = dram_rst_reg[1];
  always @(posedge dram_clk0) begin
    dram_rst_reg[0] <= dram_rst_o_int;
    dram_rst_reg[1] <= dram_rst_reg[0];
  end

 //synthesis attribute U_SET of dram_rst_reg[0] is SET_DRAM0
 //synthesis attribute U_SET of dram_rst_reg[1] is SET_DRAM0
 //synthesis attribute RLOC  of dram_rst_reg[0] is X0Y0
 //synthesis attribute RLOC  of dram_rst_reg[1] is X1Y0


  /*************** Indirect Interface ****************/

  reg  wr_strb, rd_strb;

  reg  wr_got, rd_got;
  reg  wr_ack, rd_ack;

  reg  wr_ack_reg, rd_ack_reg;
  // synthesis attribute ASYNC_REG of wr_ack_reg is true 
  // synthesis attribute ASYNC_REG of rd_ack_reg is true 

  reg  [32   - 1:0] addr_buffer;
  reg  [72*4 - 1:0] rd_buffer;
  wire [72*4 - 1:0] wr_buffer;
  reg    [48 - 1:0] mask_buffer;

  reg  [15:0] wr_buffer_arr [(72*4)/16 - 1:0];
  wire [15:0] rd_buffer_arr [(72*4)/16 - 1:0];

genvar geni;
generate for (geni=0; geni < (72*4)/16; geni=geni+1) begin : rd_buffer_arr_gen

  assign rd_buffer_arr[geni] = rd_buffer[16*(geni+1) - 1:16*geni];

  assign wr_buffer[16*(geni+1) - 1:16*geni] = wr_buffer_arr[geni];

end endgenerate

  wire wr_reg_sel = mem_wb_adr_i[7:1] >= 8  && mem_wb_adr_i[7:1] < 26;
  wire rd_reg_sel = mem_wb_adr_i[7:1] >= 26 && mem_wb_adr_i[7:1] < 44;
  wire [31:0] wr_adr_offset = mem_wb_adr_i[7:1] - 8;
  wire [31:0] rd_adr_offset = mem_wb_adr_i[7:1] - 26;

  reg [15:0] mem_wb_dat_o;
  reg mem_wb_ack_o;

  always @(posedge wb_clk_i) begin
    mem_wb_ack_o <= 1'b0;
    wr_ack_reg <= wr_ack;
    rd_ack_reg <= rd_ack;
    if (wb_rst_i) begin
      wr_got <= 1'b0;
      rd_got <= 1'b0;
    end else begin
      if (rd_ack_reg) begin
        rd_got <= 1'b0;
      end
      if (wr_ack_reg) begin
        wr_got <= 1'b0;
      end

      if (mem_wb_cyc_i & mem_wb_stb_i & ~mem_wb_ack_o) begin
        mem_wb_ack_o <= 1'b1;

        /* Control */
        if (mem_wb_adr_i[7:1] == 7'd0) begin 
          if (mem_wb_we_i) begin
            wr_got <= 1'b1;
          end else begin
            mem_wb_dat_o <= {15'b0, wr_got};
          end
        end
        if (mem_wb_adr_i[7:1] == 7'd1) begin
          if (mem_wb_we_i) begin
            rd_got <= 1'b1;
          end else begin
            mem_wb_dat_o <= {15'b0, rd_got};
          end
        end

        /* Address */
        if (mem_wb_adr_i[7:1] == 7'd2) begin
          if (mem_wb_we_i) begin
            addr_buffer[31:16] <= mem_wb_dat_i;
          end else begin
            mem_wb_dat_o <= addr_buffer[31:16];
          end
        end
        if (mem_wb_adr_i[7:1] == 7'd3) begin
          if (mem_wb_we_i) begin
            addr_buffer[15:0] <= mem_wb_dat_i;
          end else begin
            mem_wb_dat_o <= addr_buffer[15:0];
          end
        end

        /* Mask */
        if (mem_wb_adr_i[7:1] == 7'd4) begin
        end
        if (mem_wb_adr_i[7:1] == 7'd5) begin
          if (mem_wb_we_i) begin
            mask_buffer[47:32] <= mem_wb_dat_i;
          end else begin
            mem_wb_dat_o <= mask_buffer[47:32];
          end
        end
        if (mem_wb_adr_i[7:1] == 7'd6) begin
          if (mem_wb_we_i) begin
            mask_buffer[31:16] <= mem_wb_dat_i;
          end else begin
            mem_wb_dat_o <= mask_buffer[31:16];
          end
        end
        if (mem_wb_adr_i[7:1] == 7'd7) begin
          if (mem_wb_we_i) begin
            mask_buffer[15:0] <= mem_wb_dat_i;
          end else begin
            mem_wb_dat_o <= mask_buffer[15:0];
          end
        end

        /* Wr Data */
        if (wr_reg_sel) begin
          if (mem_wb_we_i) begin
            wr_buffer_arr[wr_adr_offset] <= mem_wb_dat_i;
          end else begin
            mem_wb_dat_o <= wr_buffer_arr[wr_adr_offset];
          end
        end
        /* Rd Data */
        if (rd_reg_sel) begin
          if (mem_wb_we_i) begin
          end else begin
            mem_wb_dat_o <= rd_buffer_arr[rd_adr_offset];
          end
        end
        /* */
      end
    end
  end

  reg wr_got_reg;

  always @(posedge dram_clk0) begin
    wr_got_reg <= wr_got;
    wr_strb <= 1'b0;
    if (wb_rst_i) begin
      wr_ack <= 1'b0;
    end else begin
      if (wr_got_reg & !wr_ack) begin
        wr_ack <= 1'b1;
        wr_strb <= 1'b1;
      end
      if (!wr_got_reg) begin
        wr_ack <= 1'b0;
      end
    end
  end

  reg rd_got_reg;

  always @(posedge dram_clk0) begin
    rd_strb <= 1'b0;
    rd_got_reg <= rd_got;
    if (wb_rst_i) begin
      rd_ack <= 1'b0;
    end else begin
      if (rd_got_reg && !rd_ack) begin
        rd_ack  <= 1'b1;
        rd_strb <= 1'b1;
      end
      if (!rd_got_reg) begin
        rd_ack <= 1'b0;
      end
    end
  end
  // synthesis attribute ASYNC_REG of rd_got_reg is true 
  // synthesis attribute ASYNC_REG of wr_got_reg is true 

  reg rd_busy;

  always @(posedge dram_clk0) begin
    if (wb_rst_i) begin
      rd_busy <= 1'b0;
    end else begin
      if (dram_rd_valid && !rd_busy) begin
        rd_buffer[DQ_WIDTH*2 - 1:0]   <= dram_rd_data;
        rd_busy <= 1'b1;
      end else if (rd_busy) begin
        rd_buffer[DQ_WIDTH*4 - 1:DQ_WIDTH*2] <= dram_rd_data;
        rd_busy <= 1'b0;
      end
    end
  end

  assign dram_cmd_valid = wr_strb || rd_strb;
  assign dram_cmd_rnw   = rd_strb; //default write

  assign dram_wr_data   = wr_strb ?   wr_buffer[2*DQ_WIDTH - 1:0] :   wr_buffer[4*DQ_WIDTH - 1:2*DQ_WIDTH];
  assign dram_wr_be     = wr_strb ? mask_buffer[2*BE_WIDTH - 1:0] : mask_buffer[4*BE_WIDTH - 1:2*BE_WIDTH];

  assign dram_cmd_addr  = addr_buffer;

endmodule
