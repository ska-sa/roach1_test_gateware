module qdr_cpu_interface(
    //memory wb slave IF
    wb_clk_i, wb_rst_i,
    reg_wb_we_i, reg_wb_cyc_i, reg_wb_stb_i, reg_wb_sel_i,
    reg_wb_adr_i, reg_wb_dat_i, reg_wb_dat_o,
    reg_wb_ack_o,
    //memory wb slave IF
    mem_wb_we_i, mem_wb_cyc_i, mem_wb_stb_i, mem_wb_sel_i,
    mem_wb_adr_i, mem_wb_dat_i, mem_wb_dat_o,
    mem_wb_ack_o,
    //qdr interface

    qdr_clk_i,
    qdr_rst_o,
    qdr_phy_rdy,
    qdr_cal_fail,

    qdr_addr,
    qdr_wr_data,
    qdr_wr_be,
    qdr_wr_en,

    qdr_rd_data,
    qdr_rd_dvld,
    qdr_rd_en
  );
  parameter CLK_FREQ = 0;
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

  /* QDR signals */
  input  qdr_clk_i;
  output qdr_rst_o;
  input  qdr_phy_rdy;
  input  qdr_cal_fail;

  /* QDR write port signals */
  output [21:0] qdr_addr;
  output qdr_wr_en;
  output [35:0] qdr_wr_data;
  output  [3:0] qdr_wr_be;

  /* QDR read port signals */
  output qdr_rd_en;
  input  [35:0] qdr_rd_data;
  input  qdr_rd_dvld;

  wire   qdr_reset_int;

  qdr_wb_attach #(
    .CLK_FREQ(CLK_FREQ)
  ) reg_wb_attach_inst (
    //memory wb slave IF
    .wb_clk_i(wb_clk_i), .wb_rst_i(wb_rst_i),
    .wb_we_i(reg_wb_we_i), .wb_cyc_i(reg_wb_cyc_i), .wb_stb_i(reg_wb_stb_i), .wb_sel_i(reg_wb_sel_i),
    .wb_adr_i(reg_wb_adr_i), .wb_dat_i(reg_wb_dat_i), .wb_dat_o(reg_wb_dat_o),
    .wb_ack_o(reg_wb_ack_o),
    .phy_ready (qdr_phy_rdy),
    .cal_fail  (qdr_cal_fail),
    .qdr_reset (qdr_reset_int)
  );

  /* stretch the reset pulse out */
  reg [7:0] reset_reg;
  always @(posedge wb_clk_i) begin
    if (qdr_reset_int) begin
      reset_reg <= 8'b1111_1111;
    end else begin
      reset_reg <= reset_reg << 1;
    end
  end

  /* Cross clock domain */
  wire qdr_rst_o_int = reset_reg[7];
  reg [1:0] qdr_rst_reg;
  assign qdr_rst_o = qdr_rst_reg[1];
  always @(posedge qdr_clk_i) begin
    qdr_rst_reg[0] <= qdr_rst_o_int;
    qdr_rst_reg[1] <= qdr_rst_reg[0];
  end

  /*************** Indirect Interface ****************/

  reg  wr_strb, rd_strb;

  reg  wr_got, rd_got;
  reg  wr_ack, rd_ack;

  reg  wr_ack_reg, rd_ack_reg;
  // synthesis attribute ASYNC_REG of wr_ack_reg is true 
  // synthesis attribute ASYNC_REG of rd_ack_reg is true 

  localparam ADDR_BITS   = 22;
  localparam DATA_BITS   = 18;
  localparam MASK_BITS   = 2;
  localparam BURST_WIDTH = 4;

  
  reg [BURST_WIDTH*DATA_BITS - 1:0] rd_buffer;
  reg [BURST_WIDTH*DATA_BITS - 1:0] wr_buffer;
  reg [BURST_WIDTH*MASK_BITS - 1:0] mask_buffer;
  reg [ADDR_BITS-1:0] addr_buffer;

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
        case (mem_wb_adr_i[7:1]) 
          /* Ctrl */
          7'd0: begin
            if (mem_wb_we_i) begin
              wr_got <= 1'b1;
            end else begin
              mem_wb_dat_o <= {15'b0, wr_got};
            end
          end
          7'd1: begin
            if (mem_wb_we_i) begin
              rd_got <= 1'b1;
            end else begin
              mem_wb_dat_o <= {15'b0, rd_got};
            end
          end
          /* Address */
          7'd2: begin
            if (mem_wb_we_i) begin
              addr_buffer[ADDR_BITS - 1:16] <= mem_wb_dat_i[(ADDR_BITS%16)-1:0];
            end else begin
              mem_wb_dat_o <= {1'b0, addr_buffer[ADDR_BITS - 1:16]};
            end
          end
          7'd3: begin
            if (mem_wb_we_i) begin
              addr_buffer[15:0] <= mem_wb_dat_i;
            end else begin
              mem_wb_dat_o <= addr_buffer[15:0];
            end
          end
          /* Mask */
          7'd4: begin
            if (mem_wb_we_i) begin
              mask_buffer[BURST_WIDTH*MASK_BITS-1:0] <= mem_wb_dat_i;
            end else begin
              mem_wb_dat_o <= {{16 - (BURST_WIDTH*MASK_BITS)%16{1'b0}}, mask_buffer};
            end
          end
          /* Wr Data */
          /* Burst word 0, rise */
          7'd5: begin
            if (mem_wb_we_i) begin
              wr_buffer[17:16] <= mem_wb_dat_i[1:0];
            end else begin
              mem_wb_dat_o <= {16'b0, wr_buffer[17:16]};
            end
          end
          7'd6: begin
            if (mem_wb_we_i) begin
              wr_buffer[15:0] <= mem_wb_dat_i;
            end else begin
              mem_wb_dat_o <= wr_buffer[15:0];
            end
          end
          /* Burst word 0, fall */
          7'd7: begin
            if (mem_wb_we_i) begin
              wr_buffer[35:34] <= mem_wb_dat_i[1:0];
            end else begin
              mem_wb_dat_o <= {14'b0, wr_buffer[35:34]};
            end
          end
          7'd8: begin
            if (mem_wb_we_i) begin
              wr_buffer[33:18] <= mem_wb_dat_i;
            end else begin
              mem_wb_dat_o <= wr_buffer[33:18];
            end
          end
          /* Burst word 1, rise */
          7'd9: begin
            if (mem_wb_we_i) begin
              wr_buffer[53:52] <= mem_wb_dat_i[1:0];
            end else begin
              mem_wb_dat_o <= {14'b0, wr_buffer[53:52]};
            end
          end
          7'd10: begin
            if (mem_wb_we_i) begin
              wr_buffer[51:36] <= mem_wb_dat_i;
            end else begin
              mem_wb_dat_o <= wr_buffer[51:36];
            end
          end
          /* Burst word 1, fall */
          7'd11: begin
            if (mem_wb_we_i) begin
              wr_buffer[71:70] <= mem_wb_dat_i[1:0];
            end else begin
              mem_wb_dat_o <= {14'b0, wr_buffer[71:70]};
            end
          end
          7'd12: begin
            if (mem_wb_we_i) begin
              wr_buffer[69:54] <= mem_wb_dat_i;
            end else begin
              mem_wb_dat_o <= wr_buffer[69:54];
            end
          end

          /* Rd Data */
          /* Burst word 0, rise */
          7'd13: begin
            if (mem_wb_we_i) begin
            end else begin
              mem_wb_dat_o <= {16'b0, rd_buffer[17:16]};
            end
          end
          7'd14: begin
            if (mem_wb_we_i) begin
            end else begin
              mem_wb_dat_o <= rd_buffer[15:0];
            end
          end
          /* Burst word 0, fall */
          7'd15: begin
            if (mem_wb_we_i) begin
            end else begin
              mem_wb_dat_o <= {14'b0, rd_buffer[35:34]};
            end
          end
          7'd16: begin
            if (mem_wb_we_i) begin
            end else begin
              mem_wb_dat_o <= rd_buffer[33:18];
            end
          end
          /* Burst word 1, rise */
          7'd17: begin
            if (mem_wb_we_i) begin
            end else begin
              mem_wb_dat_o <= {14'b0, rd_buffer[53:52]};
            end
          end
          7'd18: begin
            if (mem_wb_we_i) begin
            end else begin
              mem_wb_dat_o <= rd_buffer[51:36];
            end
          end
          /* Burst word 1, fall */
          7'd19: begin
            if (mem_wb_we_i) begin
            end else begin
              mem_wb_dat_o <= {14'b0, rd_buffer[71:70]};
            end
          end
          7'd20: begin
            if (mem_wb_we_i) begin
            end else begin
              mem_wb_dat_o <= rd_buffer[69:54];
            end
          end
          /* */
        endcase
      end
    end
  end

  reg wr_got_reg;

  always @(posedge qdr_clk_i) begin
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

  always @(posedge qdr_clk_i) begin
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

  reg [1:0] wr_state;
  localparam WR_STATE_IDLE = 2'd0;
  localparam WR_STATE_0    = 2'd1;
  localparam WR_STATE_1    = 2'd2;

  always @(posedge qdr_clk_i) begin
    if (wb_rst_i) begin
      wr_state <= WR_STATE_IDLE;
    end else begin
      case (wr_state)
        WR_STATE_IDLE: begin
          if (wr_strb) begin
            wr_state <= WR_STATE_0;
          end
        end 
        WR_STATE_0: begin
          wr_state <= WR_STATE_1;
        end
        WR_STATE_1: begin
          wr_state <= WR_STATE_IDLE;
        end
      endcase
    end
  end

  reg rd_busy;

  always @(posedge qdr_clk_i) begin
    if (wb_rst_i) begin
      rd_busy <= 1'b0;
    end else begin
      if (qdr_rd_dvld) begin
        rd_buffer[DATA_BITS*2 - 1:0]   <= qdr_rd_data;
        rd_busy <= 1'b1;
      end else if (rd_busy) begin
        rd_buffer[DATA_BITS*4 - 1:DATA_BITS*2] <= qdr_rd_data;
        rd_busy <= 1'b0;
      end
    end
  end

  assign qdr_wr_en   = wr_strb;
  assign qdr_wr_data = wr_strb ? wr_buffer[2*DATA_BITS - 1:0] : wr_buffer[4*DATA_BITS - 1:2*DATA_BITS];
  assign qdr_wr_be   = wr_strb ? mask_buffer[2*MASK_BITS - 1:0] : mask_buffer[4*MASK_BITS - 1:2*MASK_BITS];

  assign qdr_addr    = addr_buffer;
  assign qdr_rd_en   = rd_strb;

endmodule
