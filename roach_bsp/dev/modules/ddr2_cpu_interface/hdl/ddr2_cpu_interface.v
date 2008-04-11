module ddr2_cpu_interface(
    //memory wb slave IF
    wb_clk_i, wb_rst_i,
    reg_wb_we_i, reg_wb_cyc_i, reg_wb_stb_i, reg_wb_sel_i,
    reg_wb_adr_i, reg_wb_dat_i, reg_wb_dat_o,
    reg_wb_ack_o,
    //memory wb slave IF
    mem_wb_we_i, mem_wb_cyc_i, mem_wb_stb_i, mem_wb_sel_i,
    mem_wb_adr_i, mem_wb_dat_i, mem_wb_dat_o,
    mem_wb_ack_o, mem_wb_burst,
    //ddr interface
    ddr2_clk_o, ddr2_rst_o,
    ddr2_phy_rdy,
    ddr2_request_o, ddr2_granted_i,
    ddr2_af_cmnd_o, ddr2_af_addr_o, ddr2_af_wen_o,
    ddr2_af_afull_i,
    ddr2_df_data_o, ddr2_df_mask_o, ddr2_df_wen_o,
    ddr2_df_afull_i,
    ddr2_data_i, ddr2_dvalid_i,
    ddr_clk_0, ddr_clk_90
    ,debug
  );
  input ddr_clk_0, ddr_clk_90;
  input [7:0] debug;
  reg   [15:0] debug_int;

  parameter SOFT_ADDR_BITS  = 8;
  
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
  input  mem_wb_burst;

  output ddr2_clk_o, ddr2_rst_o;
  input  ddr2_phy_rdy;
  output ddr2_request_o;
  input  ddr2_granted_i;
  output   [2:0] ddr2_af_cmnd_o;
  output  [30:0] ddr2_af_addr_o;
  output ddr2_af_wen_o;
  input  ddr2_af_afull_i;
  output [127:0] ddr2_df_data_o;
  output  [15:0] ddr2_df_mask_o;
  output ddr2_df_wen_o;
  input  ddr2_df_afull_i;
  input  [127:0] ddr2_data_i;
  input  ddr2_dvalid_i;

  wire [SOFT_ADDR_BITS - 1:0] soft_addr;

  wire ddr_reset_int;

  reg [127:0] ddr2_data_i_reg;
  reg ddr2_dvalid_i_reg;

  always @(posedge ddr_clk_0) begin
    ddr2_dvalid_i_reg <= ddr2_dvalid_i;
    ddr2_data_i_reg   <= ddr2_data_i;
  end

  reg_wb_attach #(
    .SOFT_ADDR_BITS(SOFT_ADDR_BITS)
  ) reg_wb_attach_inst (
    .debug(debug_int),
    //memory wb slave IF
    .wb_clk_i(wb_clk_i), .wb_rst_i(wb_rst_i),
    .wb_we_i(reg_wb_we_i), .wb_cyc_i(reg_wb_cyc_i), .wb_stb_i(reg_wb_stb_i), .wb_sel_i(reg_wb_sel_i),
    .wb_adr_i(reg_wb_adr_i), .wb_dat_i(reg_wb_dat_i), .wb_dat_o(reg_wb_dat_o),
    .wb_ack_o(reg_wb_ack_o),
    .soft_addr(soft_addr),
    .phy_ready(ddr2_phy_rdy),
    .ddr2_reset(ddr_reset_int),
    .ddr2_bus_rqst(ddr2_request_o),
    .ddr2_bus_grntd(ddr2_granted_i)
  );

  reg [7:0] reset_reg;
  assign ddr2_rst_o = reset_reg[7];
  always @(posedge wb_clk_i) begin
    if (ddr_reset_int) begin
      reset_reg <= 8'b1111_1111;
    end else begin
      reset_reg <= reset_reg << 1;
    end
  end

  assign ddr2_clk_o = wb_clk_i;

  reg cmnd_got;
  reg cmnd_ack;

  reg response_got;
  reg response_ack;

  reg [1:0] wb_state;
  localparam WB_IDLE = 2'd0;
  localparam WB_CMND = 2'd1;
  localparam WB_RESP = 2'd2;

  reg cmnd;

  reg [15:0] ddr_data;

  reg mem_wb_ack_o;
  assign mem_wb_dat_o = ddr_data;

  always @(posedge wb_clk_i) begin
    mem_wb_ack_o <= 1'b0;
    if (wb_rst_i | ddr2_rst_o) begin
      cmnd_got     <= 1'b0;
      response_ack <= 1'b0;

      wb_state <= WB_IDLE;

      debug_int[3:0] <= 4'b0;
    end else begin
      case (wb_state)
        WB_IDLE: begin
          if (mem_wb_cyc_i & mem_wb_stb_i & !mem_wb_ack_o) begin
            cmnd_got <= 1'b1;
            cmnd     <= mem_wb_we_i;
            wb_state <= WB_CMND;
            if (mem_wb_we_i) begin
              debug_int[1:0] <= debug_int[1:0] + 1;
            end else begin
              debug_int[3:2] <= debug_int[3:2] + 1;
            end
          end else begin
            cmnd_got <= 1'b0;
          end
        end
        WB_CMND: begin
          if (cmnd_ack) begin
            cmnd_got <= 1'b0;
          end else if (!cmnd_got) begin
            wb_state <= WB_RESP;
          end
        end
        WB_RESP: begin
          if (response_got) begin
            response_ack <= 1'b1;
          end else if (response_ack) begin
            response_ack <= 1'b0;
            mem_wb_ack_o <= 1'b1;
            wb_state <= WB_IDLE;
          end
        end
      endcase
    end
  end

  reg [2:0] ddr_state;
  localparam DDR_IDLE  = 3'd0;
  localparam DDR_CMND  = 3'd1;
  localparam DDR_WRESP = 3'd2;
  localparam DDR_READ  = 3'd3;
  localparam DDR_RRESP = 3'd4;

  reg ddr2_af_wen_o;
  reg ddr2_df_wen_o;

  wire [1:0] mem_offset = mem_wb_adr_i[2:1];

  assign ddr2_af_addr_o = mem_wb_adr_i[31:1];
  assign ddr2_af_cmnd_o = mem_wb_we_i ? 3'b000 : 3'b001;

  assign ddr2_df_data_o = ddr2_af_wen_o ? 128'h00_11_22_33_44_22_33_55 : 128'haa_11_22_cc_00_ee_0d_cd;
  assign ddr2_df_mask_o = ~(ddr2_af_wen_o ? 16'hffff  : 16'hffff);

  always @(posedge ddr_clk_0) begin
    ddr2_af_wen_o <= 1'b0;
    ddr2_df_wen_o <= 1'b0;
    debug_int[15:8] <= {1'b0, ddr_state, 2'b0, wb_state};
    if (wb_rst_i | ddr2_rst_o) begin
      ddr_state <= DDR_IDLE;
      cmnd_ack  <= 1'b0;
      response_got <= 1'b0;

      debug_int[7:4] <= 4'b0;
    end else begin
      case (ddr_state)
        DDR_IDLE: begin
          if (cmnd_got) begin
            cmnd_ack  <= 1'b1;
            ddr_state <= DDR_CMND;
          end else begin
            cmnd_ack  <= 1'b0;
          end
        end
        DDR_CMND: begin
          if (!cmnd_got) begin
            cmnd_ack <= 1'b0; 
            if (cmnd) begin
              ddr2_af_wen_o <= 1'b1;
              ddr2_df_wen_o <= 1'b1;

              response_got <= 1'b1;
              ddr_state <= DDR_WRESP;
            end else begin
              ddr2_af_wen_o <= 1'b1;
              ddr_state <= DDR_READ;
            end
          end
        end
        DDR_WRESP: begin
          if (ddr2_af_wen_o) begin
            ddr2_df_wen_o <= 1'b1;
          end

          if (response_ack) begin
            response_got <= 1'b0;
          end else if (!response_got) begin
            ddr_state <= DDR_IDLE;
            debug_int[5:4] <= debug_int[5:4] + 1;
          end
        end
        DDR_READ: begin
          if (ddr2_dvalid_i_reg) begin
            ddr_data <= ddr2_data_i_reg[15:0];
            /*
            case (mem_offset)
              2'b00: begin
                ddr_data <= ddr2_data_i_reg[15:0];
              end
              2'b01: begin
                ddr_data <= ddr2_data_i_reg[31:16];
              end
              2'b10: begin
                ddr_data <= ddr2_data_i_reg[47:32];
              end
              2'b11: begin
                ddr_data <= ddr2_data_i_reg[63:48];
              end
            endcase
            */
            ddr_state <= DDR_RRESP;
            response_got <= 1'b1;
          end
        end
        DDR_RRESP: begin
          if (response_ack) begin
            response_got <= 1'b0;
          end else if (!response_got) begin
            ddr_state <= DDR_IDLE;
            debug_int[7:6] <= debug_int[7:6] + 1;
          end
        end
      endcase
    end
  end

  /*
  mem_rd_cache mem_rd_cache_inst(
    .clk(wb_clk_i), .reset(wb_rst_i),
    .rd_strb_i(mem_wb_cyc_i & mem_wb_stb_i & ~mem_wb_we_i),
    .rd_addr_i({soft_addr, mem_wb_adr_i[34 - SOFT_ADDR_BITS - 1:0] }), //this has to be 34 bits wide
    .rd_data_o(mem_wb_dat_o), .rd_ack_o(mem_rd_ack),
    .wr_strb_i(mem_wb_cyc_i & mem_wb_stb_i & mem_wb_we_i),
    
    .ddr_addr_o(ddr_rd_addr), .ddr_strb_o(ddr_rd_strb),
    .ddr_data_i(ddr2_data_i | ddr2_rst_o), .ddr_dvalid_i(ddr2_dvalid_i),
    .ddr_af_afull_i(ddr2_af_afull_i)
  );

  mem_wr_cache mem_wr_cache_inst(
    .clk(wb_clk_i), .reset(wb_rst_i | ddr2_rst_o),
    .wr_strb_i(mem_wb_cyc_i & mem_wb_stb_i & mem_wb_we_i),
    .wr_sel_i(mem_wb_sel_i),
    .wr_addr_i({soft_addr, mem_wb_adr_i[34 - SOFT_ADDR_BITS - 1:0]}),
    .wr_data_i(mem_wb_dat_i), .wr_ack_o(mem_wr_ack),
    .wr_eob(~mem_wb_burst), //end-of-burst strobe
    .ddr_data_o(ddr2_df_data_o), .ddr_mask_o(ddr2_df_mask_o), .ddr_data_wen_o(ddr2_df_wen_o),
    .ddr_addr_o(ddr_wr_addr), .ddr_addr_wen_o(ddr_wr_strb),
    .ddr_af_afull_i(ddr2_af_afull_i), .ddr_df_afull_i(ddr2_df_afull_i)
  );
  */
endmodule
