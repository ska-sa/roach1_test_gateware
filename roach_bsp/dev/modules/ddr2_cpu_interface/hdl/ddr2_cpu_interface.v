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
    ddr2_data_i, ddr2_dvalid_i
    ,debug
  );
  input [7:0] debug;

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

  reg_wb_attach #(
    .SOFT_ADDR_BITS(SOFT_ADDR_BITS)
  ) reg_wb_attach_inst (
    .debug(debug),
    //memory wb slave IF
    .wb_clk_i(wb_clk_i), .wb_rst_i(wb_rst_i),
    .wb_we_i(reg_wb_we_i), .wb_cyc_i(reg_wb_cyc_i), .wb_stb_i(reg_wb_stb_i), .wb_sel_i(reg_wb_sel_i),
    .wb_adr_i(reg_wb_adr_i), .wb_dat_i(reg_wb_dat_i), .wb_dat_o(reg_wb_dat_o),
    .wb_ack_o(reg_wb_ack_o),
    .soft_addr(soft_addr),
    .phy_ready(ddr2_phy_rdy),
    .ddr2_reset(ddr2_rst_o),
    .ddr2_bus_rqst(ddr2_request_o),
    .ddr2_bus_grntd(ddr2_granted_i)
  );

  assign ddr2_clk_o = wb_clk_i;

  wire mem_rd_ack, mem_wr_ack;
 // assign mem_wb_ack_o = mem_rd_ack | mem_wr_ack;

  wire [30:0] ddr_rd_addr;
  wire ddr_rd_strb;
  wire [30:0] ddr_wr_addr;
  wire ddr_wr_strb;

  assign ddr2_af_cmnd_o = ddr_wr_strb ? 3'b000 : 3'b001;
  assign ddr2_af_addr_o = ddr_wr_strb ? ddr_wr_addr : ddr_rd_addr;

  wire ddr_error = ddr_rd_strb & ddr_wr_strb;
  wire ddr2_af_wen_o = ddr_rd_strb | ddr_wr_strb;

  always @(wb_clk_i) begin
    if (wb_rst_i) begin
    end else begin
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
