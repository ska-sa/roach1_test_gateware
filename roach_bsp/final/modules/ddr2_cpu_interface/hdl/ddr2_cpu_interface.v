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
  );
  parameter ECC_ENABLED_DIMM = 0;
  parameter SOFT_ADDR_BITS   = 8;

  localparam DATA_BITS = ECC_ENABLED_DIMM ? 144 : 128;
  localparam MASK_BITS = ECC_ENABLED_DIMM ? 18  : 16;

  input ddr_clk_0, ddr_clk_90;
  
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
  output [DATA_BITS - 1:0] ddr2_df_data_o;
  output [MASK_BITS - 1:0] ddr2_df_mask_o;
  output ddr2_df_wen_o;
  input  ddr2_df_afull_i;
  input  [DATA_BITS - 1:0] ddr2_data_i;
  input  ddr2_dvalid_i;

  wire [SOFT_ADDR_BITS - 1:0] soft_addr;

  wire ddr_reset_int;

  reg_wb_attach #(
    .SOFT_ADDR_BITS(SOFT_ADDR_BITS)
  ) reg_wb_attach_inst (
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

  /*************** Indirect Interface ****************/

  reg  wr_strb, rd_strb;
  reg  rd_done, wr_done;

  reg  wr_got, rd_got;
  reg  wr_ack, rd_ack;

  reg [2*DATA_BITS - 1:0] rd_buffer;
  reg [2*DATA_BITS - 1:0] wr_buffer;
  reg [2*MASK_BITS - 1:0] mask_buffer;
  reg  [30:0] addr_buffer;

  reg  [15:0] mem_wb_dat_o;
  reg mem_wb_ack_o;

  always @(posedge wb_clk_i) begin
    mem_wb_ack_o <= 1'b0;
    if (wb_rst_i) begin
      wr_got <= 1'b0;
      rd_got <= 1'b0;
    end else begin
      if (rd_ack) begin
        rd_got <= 1'b0;
      end
      if (wr_ack) begin
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
              mem_wb_dat_o <= {15'b0, wr_done};
            end
          end
          7'd1: begin
            if (mem_wb_we_i) begin
              rd_got <= 1'b1;
            end else begin
              mem_wb_dat_o <= {15'b0, rd_done};
            end
          end
          /* Address */
          7'd2: begin
            if (mem_wb_we_i) begin
              addr_buffer[15:0] <= mem_wb_dat_i;
            end else begin
              mem_wb_dat_o <= addr_buffer[15:0];
            end
          end
          7'd3: begin
            if (mem_wb_we_i) begin
              addr_buffer[30:16] <= mem_wb_dat_i[14:0];
            end else begin
              mem_wb_dat_o <= {1'b0, addr_buffer[30:16]};
            end
          end
          /* Mask */
          7'd4: begin
            if (mem_wb_we_i) begin
              mask_buffer[15:0] <= mem_wb_dat_i;
            end else begin
              mem_wb_dat_o <= mask_buffer[15:0];
            end
          end
          7'd5: begin
            if (mem_wb_we_i) begin
              mask_buffer[31:16] <= mem_wb_dat_i;
            end else begin
              mem_wb_dat_o <= mask_buffer[31:16];
            end
          end
          7'd6: begin
            if (MASK_BITS == 18) begin
              if (mem_wb_we_i) begin
                mask_buffer[35:32] <= mem_wb_dat_i;
              end else begin
                mem_wb_dat_o <= {12'b0, mask_buffer[35:32]};
              end
            end
          end

          /* Wr Data */
          7'd7: begin
            if (mem_wb_we_i) begin
              wr_buffer[16*(1+0) - 1:16*0] <= mem_wb_dat_i;
            end else begin
              mem_wb_dat_o <= wr_buffer[16*(1+0) - 1:16*0];
            end
          end
          7'd8: begin
            if (mem_wb_we_i) begin
              wr_buffer[16*(1+1) - 1:16*1] <= mem_wb_dat_i;
            end else begin
              mem_wb_dat_o <= wr_buffer[16*(1+1) - 1:16*1];
            end
          end
          7'd9: begin
            if (mem_wb_we_i) begin
              wr_buffer[16*(1+2) - 1:16*2] <= mem_wb_dat_i;
            end else begin
              mem_wb_dat_o <= wr_buffer[16*(1+2) - 1:16*2];
            end
          end
          7'd10: begin
            if (mem_wb_we_i) begin
              wr_buffer[16*(1+3) - 1:16*3] <= mem_wb_dat_i;
            end else begin
              mem_wb_dat_o <= wr_buffer[16*(1+3) - 1:16*3];
            end
          end
          7'd11: begin
            if (mem_wb_we_i) begin
              wr_buffer[16*(1+4) - 1:16*4] <= mem_wb_dat_i;
            end else begin
              mem_wb_dat_o <= wr_buffer[16*(1+4) - 1:16*4];
            end
          end
          7'd12: begin
            if (mem_wb_we_i) begin
              wr_buffer[16*(1+5) - 1:16*5] <= mem_wb_dat_i;
            end else begin
              mem_wb_dat_o <= wr_buffer[16*(1+5) - 1:16*5];
            end
          end
          7'd13: begin
            if (mem_wb_we_i) begin
              wr_buffer[16*(1+6) - 1:16*6] <= mem_wb_dat_i;
            end else begin
              mem_wb_dat_o <= wr_buffer[16*(1+6) - 1:16*6];
            end
          end
          7'd14: begin
            if (mem_wb_we_i) begin
              wr_buffer[16*(1+7) - 1:16*7] <= mem_wb_dat_i;
            end else begin
              mem_wb_dat_o <= wr_buffer[16*(1+7) - 1:16*7];
            end
          end
          7'd15: begin
            if (mem_wb_we_i) begin
              wr_buffer[16*(1+8) - 1:16*8] <= mem_wb_dat_i;
            end else begin
              mem_wb_dat_o <= wr_buffer[16*(1+8) - 1:16*8];
            end
          end
          7'd16: begin
            if (mem_wb_we_i) begin
              wr_buffer[16*(1+9) - 1:16*9] <= mem_wb_dat_i;
            end else begin
              mem_wb_dat_o <= wr_buffer[16*(1+9) - 1:16*9];
            end
          end
          7'd17: begin
            if (mem_wb_we_i) begin
              wr_buffer[16*(1+10) - 1:16*10] <= mem_wb_dat_i;
            end else begin
              mem_wb_dat_o <= wr_buffer[16*(1+10) - 1:16*10];
            end
          end
          7'd18: begin
            if (mem_wb_we_i) begin
              wr_buffer[16*(1+11) - 1:16*11] <= mem_wb_dat_i;
            end else begin
              mem_wb_dat_o <= wr_buffer[16*(1+11) - 1:16*11];
            end
          end
          7'd19: begin
            if (mem_wb_we_i) begin
              wr_buffer[16*(1+12) - 1:16*12] <= mem_wb_dat_i;
            end else begin
              mem_wb_dat_o <= wr_buffer[16*(1+12) - 1:16*12];
            end
          end
          7'd20: begin
            if (mem_wb_we_i) begin
              wr_buffer[16*(1+13) - 1:16*13] <= mem_wb_dat_i;
            end else begin
              mem_wb_dat_o <= wr_buffer[16*(1+13) - 1:16*13];
            end
          end
          7'd21: begin
            if (mem_wb_we_i) begin
              wr_buffer[16*(1+14) - 1:16*14] <= mem_wb_dat_i;
            end else begin
              mem_wb_dat_o <= wr_buffer[16*(1+14) - 1:16*14];
            end
          end
          7'd22: begin
            if (mem_wb_we_i) begin
              wr_buffer[16*(1+15) - 1:16*15] <= mem_wb_dat_i;
            end else begin
              mem_wb_dat_o <= wr_buffer[16*(1+15) - 1:16*15];
            end
          end
          7'd23: begin
            if (DATA_BITS == 144) begin
              if (mem_wb_we_i) begin
                wr_buffer[16*(1+16) - 1:16*16] <= mem_wb_dat_i;
              end else begin
                mem_wb_dat_o <= wr_buffer[16*(1+16) - 1:16*16];
              end
            end
          end
          7'd24: begin
            if (DATA_BITS == 144) begin
              if (mem_wb_we_i) begin
                wr_buffer[16*(1+17) - 1:16*17] <= mem_wb_dat_i;
              end else begin
                mem_wb_dat_o <= wr_buffer[16*(1+17) - 1:16*17];
              end
            end
          end
          /* Rd Data */
          7'd25: begin
            if (mem_wb_we_i) begin
            end else begin
              mem_wb_dat_o <= rd_buffer[16*(1+0) - 1:16*0];
            end
          end
          7'd26: begin
            if (mem_wb_we_i) begin
            end else begin
              mem_wb_dat_o <= rd_buffer[16*(1+1) - 1:16*1];
            end
          end
          7'd27: begin
            if (mem_wb_we_i) begin
            end else begin
              mem_wb_dat_o <= rd_buffer[16*(1+2) - 1:16*2];
            end
          end
          7'd28: begin
            if (mem_wb_we_i) begin
            end else begin
              mem_wb_dat_o <= rd_buffer[16*(1+3) - 1:16*3];
            end
          end
          7'd29: begin
            if (mem_wb_we_i) begin
            end else begin
              mem_wb_dat_o <= rd_buffer[16*(1+4) - 1:16*4];
            end
          end
          7'd30: begin
            if (mem_wb_we_i) begin
            end else begin
              mem_wb_dat_o <= rd_buffer[16*(1+5) - 1:16*5];
            end
          end
          7'd31: begin
            if (mem_wb_we_i) begin
            end else begin
              mem_wb_dat_o <= rd_buffer[16*(1+6) - 1:16*6];
            end
          end
          7'd32: begin
            if (mem_wb_we_i) begin
            end else begin
              mem_wb_dat_o <= rd_buffer[16*(1+7) - 1:16*7];
            end
          end
          7'd33: begin
            if (mem_wb_we_i) begin
            end else begin
              mem_wb_dat_o <= rd_buffer[16*(1+8) - 1:16*8];
            end
          end
          7'd34: begin
            if (mem_wb_we_i) begin
            end else begin
              mem_wb_dat_o <= rd_buffer[16*(1+9) - 1:16*9];
            end
          end
          7'd35: begin
            if (mem_wb_we_i) begin
            end else begin
              mem_wb_dat_o <= rd_buffer[16*(1+10) - 1:16*10];
            end
          end
          7'd36: begin
            if (mem_wb_we_i) begin
            end else begin
              mem_wb_dat_o <= rd_buffer[16*(1+11) - 1:16*11];
            end
          end
          7'd37: begin
            if (mem_wb_we_i) begin
            end else begin
              mem_wb_dat_o <= rd_buffer[16*(1+12) - 1:16*12];
            end
          end
          7'd38: begin
            if (mem_wb_we_i) begin
            end else begin
              mem_wb_dat_o <= rd_buffer[16*(1+13) - 1:16*13];
            end
          end
          7'd39: begin
            if (mem_wb_we_i) begin
            end else begin
              mem_wb_dat_o <= rd_buffer[16*(1+14) - 1:16*14];
            end
          end
          7'd40: begin
            if (mem_wb_we_i) begin
            end else begin
              mem_wb_dat_o <= rd_buffer[16*(1+15) - 1:16*15];
            end
          end
          7'd41: begin
            if (DATA_BITS == 144) begin
              if (mem_wb_we_i) begin
              end else begin
                mem_wb_dat_o <= rd_buffer[16*(1+16) - 1:16*16];
              end
            end
          end
          7'd42: begin
            if (DATA_BITS == 144) begin
              if (mem_wb_we_i) begin
              end else begin
                mem_wb_dat_o <= rd_buffer[16*(1+17) - 1:16*17];
              end
            end
          end
          /* */
        endcase
      end
    end
  end

  always @(posedge ddr_clk_0) begin
    wr_strb <= 1'b0;
    if (wb_rst_i) begin
      wr_ack <= 1'b0;
    end else begin
      if (wr_got & ~wr_ack) begin
        wr_ack <= 1'b1;
        wr_strb <= 1'b1;
      end else if (~wr_got) begin
        wr_ack <= 1'b0;
      end
    end
  end

  always @(posedge ddr_clk_0) begin
    rd_strb <= 1'b0;
    if (wb_rst_i) begin
      rd_ack <= 1'b1;
    end else begin
      if (rd_got & ~wr_ack) begin
        rd_ack <= 1'b1;
        rd_strb <= 1'b1;
      end else if (~wr_got) begin
        rd_ack <= 1'b0;
      end
    end
  end

  reg [1:0] wr_state;
  localparam WR_STATE_IDLE = 2'd0;
  localparam WR_STATE_0    = 2'd1;
  localparam WR_STATE_1    = 2'd2;

  always @(posedge ddr_clk_0) begin
    if (wb_rst_i) begin
      wr_state <= WR_STATE_IDLE;
      wr_done <= 1'b0;
    end else begin
      case (wr_state)
        WR_STATE_IDLE: begin
          if (wr_strb) begin
            wr_state <= WR_STATE_0;
            wr_done  <= 1'b0;
          end
        end 
        WR_STATE_0: begin
          wr_state <= WR_STATE_1;
        end
        WR_STATE_1: begin
          wr_state <= WR_STATE_IDLE;
          wr_done  <= 1'b1;
        end
      endcase
    end
  end

  reg rd_index;

  always @(posedge ddr_clk_90) begin
    if (wb_rst_i) begin
      rd_index <= 1'b0;
      rd_done  <= 1'b0;
    end else begin
      if (rd_strb) begin
        rd_index <= 1'b0;
        rd_done  <= 1'b0;
      end

      if (ddr2_dvalid_i) begin
        rd_index <= rd_index + 1;
        if (!rd_index) begin
          rd_buffer[DATA_BITS - 1:0]   <= ddr2_data_i;
        end else begin
          rd_buffer[DATA_BITS*2 - 1:DATA_BITS] <= ddr2_data_i;
          rd_done <= 1'b1;
        end
      end
    end
  end

  assign ddr2_af_cmnd_o = wr_state == WR_STATE_IDLE ? 3'b001 : 3'b000;
  assign ddr2_af_addr_o = addr_buffer;
  assign ddr2_af_wen_o  = rd_strb || wr_state == WR_STATE_0;

  assign ddr2_df_data_o = wr_state == WR_STATE_0 ?   wr_buffer[DATA_BITS - 1:0] :   wr_buffer[DATA_BITS*2 - 1:DATA_BITS];
  assign ddr2_df_mask_o = wr_state == WR_STATE_0 ? mask_buffer[MASK_BITS - 1:0] : mask_buffer[MASK_BITS*2 - 1:MASK_BITS];
  assign ddr2_df_wen_o  = wr_state != WR_STATE_IDLE; 




  /*
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

  wire [2:0] mem_offset = mem_wb_adr_i[3:1];

  assign ddr2_af_addr_o = {3'b0, mem_wb_adr_i[31:4]};
  assign ddr2_af_cmnd_o = mem_wb_we_i ? 3'b000 : 3'b001;

  //assign ddr2_df_data_o = ddr2_af_wen_o ? 128'h1001_1002_1003_1004_1005_1006_1007_1008 : 128'ha001_a002_a003_a004_a005_a006_a007_a008;
  //assign ddr2_df_mask_o = ~(ddr2_af_wen_o ? 16'hffff  : 16'hffff);
  assign ddr2_df_data_o = {8{mem_wb_dat_i}};
  assign ddr2_df_mask_o = ~(!ddr2_af_wen_o ? 16'h0000 : mem_wb_sel_i << (2*mem_offset[1:0]);

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
            case (mem_offset)
              3'b00: begin
                ddr_data <= ddr2_data_i_reg[15:0];
              end
              3'b01: begin
                ddr_data <= ddr2_data_i_reg[31:16];
              end
              3'b10: begin
                ddr_data <= ddr2_data_i_reg[47:32];
              end
              3'b11: begin
                ddr_data <= ddr2_data_i_reg[63:48];
              end
              3'b100: begin
                ddr_data <= ddr2_data_i_reg[15+64:0+64];
              end
              3'b101: begin
                ddr_data <= ddr2_data_i_reg[31+64:16+64];
              end
              3'b110: begin
                ddr_data <= ddr2_data_i_reg[47+64:32+64];
              end
              3'b111: begin
                ddr_data <= ddr2_data_i_reg[63+64:48+64];
              end
            endcase
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
  */
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
