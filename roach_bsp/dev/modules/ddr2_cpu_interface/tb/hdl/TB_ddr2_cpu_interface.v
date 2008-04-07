`include "ddr2_cpu_interface.vh"

//`timescale 1ns/10ps

`define SIMLENGTH  1_000_000
`define CLK_PERIOD 2

`define NUM_OPERATIONS 1_000

module TB_ddr2_cpu_interface();

  wire clk;
  reg  reset;

  reg  reg_wb_we_i, reg_wb_cyc_i, reg_wb_stb_i;
  reg  [31:0] reg_wb_adr_i;
  reg  [15:0] reg_wb_dat_i;
  wire [15:0] reg_wb_dat_o;
  wire reg_wb_ack_o;

  reg  mem_wb_we_i, mem_wb_cyc_i, mem_wb_stb_i;
  reg  [31:0] mem_wb_adr_i;
  reg  [15:0] mem_wb_dat_i;
  wire [15:0] mem_wb_dat_o;
  wire mem_wb_ack_o;
  wire mem_wb_burst;

  wire ddr2_clk_o, ddr2_rst_o;
  wire ddr2_request_o, ddr2_granted_i;
  wire  [2:0] ddr2_af_cmnd_o;
  wire [30:0] ddr2_af_addr_o;
  wire ddr2_af_wen_o;
  wire ddr2_af_afull_i;
  wire [127:0] ddr2_df_data_o;
  wire  [15:0] ddr2_df_mask_o;
  wire ddr2_df_wen_o;
  wire ddr2_df_afull_i;
  wire [127:0] ddr2_data_i;
  wire ddr2_dvalid_i;
  wire ddr2_phy_rdy;

   /* DUT */
  ddr2_cpu_interface #(
    .SOFT_ADDR_BITS(8)
  ) ddr2_cpu_interface_inst (
    //memory wb slave IF
    .wb_clk_i(clk), .wb_rst_i(reset),
    .reg_wb_we_i(reg_wb_we_i), .reg_wb_cyc_i(reg_wb_cyc_i), .reg_wb_stb_i(reg_wb_stb_i), .reg_wb_sel_i(2'b11),
    .reg_wb_adr_i(reg_wb_adr_i), .reg_wb_dat_i(reg_wb_dat_i), .reg_wb_dat_o(reg_wb_dat_o),
    .reg_wb_ack_o(reg_wb_ack_o),
    .mem_wb_we_i(mem_wb_we_i), .mem_wb_cyc_i(mem_wb_cyc_i), .mem_wb_stb_i(mem_wb_stb_i), .mem_wb_sel_i(2'b11),
    .mem_wb_adr_i(mem_wb_adr_i), .mem_wb_dat_i(mem_wb_dat_i), .mem_wb_dat_o(mem_wb_dat_o),
    .mem_wb_ack_o(mem_wb_ack_o), .mem_wb_burst(mem_wb_burst),
    .ddr2_clk_o(ddr2_clk_o), .ddr2_rst_o(ddr2_rst_o),
    .ddr2_phy_rdy(ddr2_phy_rdy),
    .ddr2_request_o(ddr2_request_o), .ddr2_granted_i(ddr2_granted_i),
    .ddr2_af_cmnd_o(ddr2_af_cmnd_o), .ddr2_af_addr_o(ddr2_af_addr_o), .ddr2_af_wen_o(ddr2_af_wen_o),
    .ddr2_af_afull_i(ddr2_af_afull_i),
    .ddr2_df_data_o(ddr2_df_data_o), .ddr2_df_mask_o(ddr2_df_mask_o), .ddr2_df_wen_o(ddr2_df_wen_o),
    .ddr2_df_afull_i(ddr2_df_afull_i),
    .ddr2_data_i(ddr2_data_i), .ddr2_dvalid_i(ddr2_dvalid_i)
  );

  reg [31:0] clk_counter;

  initial begin
    reset<=1'b1;
    clk_counter<=32'b0;
    #50
    reset<=1'b0;
`ifdef DEBUG
    $display("sys: reset cleared");
`endif
    #`SIMLENGTH
    $display("FAILED: simulation timed out");
    $finish;
  end

  assign clk = clk_counter < ((`CLK_PERIOD) / 2);

  always begin
    #1 clk_counter <= (clk_counter == `CLK_PERIOD - 1 ? 32'b0 : clk_counter + 1);
  end

  /********************** Mode Control *************************/  

  reg [2:0] mode;
  localparam MODE_CONFIG = 3'd0; // write appropriate bits to registers
  localparam MODE_WAIT   = 3'd1; // wait for phy to come up
  localparam MODE_WRITE  = 3'd2; // write some stuff to memory
  localparam MODE_READ   = 3'd3; // read some stuff back
  localparam MODE_ALT    = 3'd4; // read some stuff back

  reg [4:0] mode_done;

  always @(posedge clk) begin
    if (reset) begin
      mode <= MODE_CONFIG;
    end else begin
      case (mode)
        MODE_CONFIG: begin
          if (mode_done[MODE_CONFIG]) begin
            mode <= MODE_WAIT;
`ifdef DEBUG
            $display("mode: CONFIG passed");
`endif
          end
        end
        MODE_WAIT: begin
          if (mode_done[MODE_WAIT]) begin
            mode <= MODE_WRITE;
`ifdef DEBUG
            $display("mode: WAIT passed");
`endif
          end
        end
        MODE_WRITE: begin
          if (mode_done[MODE_WRITE]) begin
            mode <= MODE_READ;
`ifdef DEBUG
            $display("mode: WRITE passed");
`endif
          end
        end
        MODE_READ: begin
          if (mode_done[MODE_READ]) begin
            //some check
            $display("PASSED");
            $finish;
          end
        end
      endcase
    end
  end

  /********************** DDR2 Arbiter *************************/  
  assign ddr2_granted_i = ddr2_request_o;

  /******************** DDR2 Controller ************************/  

  ddr2_controller ddr2_controller_inst(
    .clk(ddr2_clk_o), .reset(reset | ddr2_rst_o),
    .af_cmnd_i(ddr2_af_cmnd_o), .af_addr_i(ddr2_af_addr_o), .af_wen_i(ddr2_af_wen_o),
    .af_afull_o(ddr2_af_afull_i),
    .df_data_i(ddr2_df_data_o), .df_mask_i(ddr2_df_mask_o), .df_wen_i(ddr2_df_wen_o),
    .df_afull_o(ddr2_df_afull_i),
    .data_o(ddr2_data_i), .dvalid_o(ddr2_dvalid_i),
    .phy_rdy(ddr2_phy_rdy)
  );

  /***************** WishBone Reg Interface ********************/  

  reg [15:0] readback_mem [65535:0]; // 64k 
  reg [1:0] reg_wbm_state;
  localparam REG_WBM_STATE_COMMAND = 2'd0;
  localparam REG_WBM_STATE_COLLECT = 2'd1;
  localparam REG_WBM_STATE_WAIT    = 2'd2;

  reg [31:0] reg_progress;

  always @(posedge clk) begin
    // strobes
    reg_wb_cyc_i <= 1'b0;
    reg_wb_stb_i <= 1'b0;
    mode_done[MODE_CONFIG] <= 1'b0;
    mode_done[MODE_WAIT]   <= 1'b0;

    if (reset) begin
      reg_wbm_state <= REG_WBM_STATE_COMMAND;
      reg_progress  <= 32'd0;
    end else begin
      case (reg_wbm_state)
        REG_WBM_STATE_COMMAND: begin
          case (mode)
            MODE_CONFIG: begin
              reg_wb_cyc_i <= 1'b1;
              reg_wb_stb_i <= 1'b1;
              reg_wb_we_i  <= 1'b1;
              case (reg_progress)
                32'd0: begin
                  reg_wb_dat_i <= 16'h1;
                  reg_wb_adr_i <= `REG_DDR2_RESET << 1;
                end
                32'd1: begin
                  reg_wb_dat_i <= 16'h1;
                  reg_wb_adr_i <= `REG_DDR2_BUS_RQST << 1;
                end
                32'd2: begin
                  reg_wb_dat_i <= 16'hff; //soft bits all 1
                  reg_wb_adr_i <= `REG_DDR2_SOFT_ADDR << 1;
                end
              endcase

              reg_wbm_state <= REG_WBM_STATE_COLLECT;
            end
            MODE_WAIT: begin
              reg_wb_cyc_i <= 1'b1;
              reg_wb_stb_i <= 1'b1;
              reg_wb_we_i  <= 1'b0;
              case (reg_progress)
                32'd0: begin
                  reg_wb_adr_i <= `REG_DDR2_PHY_READY << 1;
                end
                32'd1: begin
                  reg_wb_adr_i <= `REG_DDR2_BUS_GRNTD << 1;
                end
              endcase

              reg_wbm_state <= REG_WBM_STATE_COLLECT;
            end
            default: begin
            end
          endcase
        end
        REG_WBM_STATE_COLLECT: begin
          if (reg_wb_ack_o) begin
            case (mode)
              MODE_CONFIG: begin
                if (reg_progress == 32'd2) begin
                  mode_done[MODE_CONFIG] <= 1'b1;
                  reg_wbm_state <= REG_WBM_STATE_WAIT;
                end else begin
                  reg_progress <= reg_progress + 1;
                  reg_wbm_state <= REG_WBM_STATE_COMMAND;
                end
              end
              MODE_WAIT: begin
                case (reg_progress)
                  32'd0: begin
                    if (reg_wb_dat_o[0] === 1'd1) begin
                      reg_progress <= 32'd1;
                      reg_wbm_state <= REG_WBM_STATE_COMMAND;
                    end else begin
                      reg_wbm_state <= REG_WBM_STATE_COMMAND;
`ifdef DESPERATE_DEBUG
                      $display("reg_wbm: phy not ready, flag = %b", reg_wb_dat_o[0]);
`endif
                      //$finish;
                    end
                  end
                  32'd1: begin
                    if (reg_wb_dat_o === 16'd1) begin
                      mode_done[MODE_WAIT] <= 1'b1;
                      reg_wbm_state <= REG_WBM_STATE_WAIT;
                    end else begin
                      $display("FAILED: bus not granted");
                      $finish;
                    end
                  end
                endcase
              end
            endcase
          end
        end
        REG_WBM_STATE_WAIT: begin
          reg_progress  <= 32'd0;
          reg_wbm_state <= REG_WBM_STATE_COMMAND;
        end
      endcase
    end
  end

  /***************** WishBone Mem Interface ********************/  
  reg [1:0] mem_wbm_state;
  localparam MEM_WBM_STATE_COMMAND = 2'd0;
  localparam MEM_WBM_STATE_COLLECT = 2'd1;
  localparam MEM_WBM_STATE_WAIT    = 2'd2;

  reg [31:0] mem_progress;

  assign mem_wb_burst = 1'b0;

  always @(posedge clk) begin
    // strobes
    mem_wb_cyc_i <= 1'b0;
    mem_wb_stb_i <= 1'b0;
    mode_done[MODE_WRITE] <= 1'b0;
    mode_done[MODE_READ]  <= 1'b0;

    if (reset) begin
      mem_wbm_state <= MEM_WBM_STATE_COMMAND;
      mem_progress <= 32'b0;
    end else begin
      case (mem_wbm_state)
        MEM_WBM_STATE_COMMAND: begin
          case (mode)
            MODE_WRITE: begin
              mem_wb_cyc_i <= 1'b1;
              mem_wb_stb_i <= 1'b1;
              mem_wb_we_i  <= 1'b1;
              mem_wb_adr_i <= mem_progress[15:0] << 1;
              mem_wb_dat_i <= mem_progress[15:0];
              mem_wbm_state <= MEM_WBM_STATE_COLLECT;
            end
            MODE_READ: begin
              mem_wb_cyc_i <= 1'b1;
              mem_wb_stb_i <= 1'b1;
              mem_wb_we_i  <= 1'b0;
              mem_wb_adr_i <= mem_progress[15:0] << 1;
              mem_wbm_state <= MEM_WBM_STATE_COLLECT;
            end
            default: begin
            end
          endcase
        end
        MEM_WBM_STATE_COLLECT: begin
          if (mem_wb_ack_o) begin
            case (mode)
              MODE_WRITE: begin
                if (mem_progress == `NUM_OPERATIONS - 1) begin
                  mode_done[MODE_WRITE]  <= 1'b1;
                  mem_wbm_state <= MEM_WBM_STATE_WAIT;
                end else begin
                  mem_progress <= mem_progress + 1;
                  mem_wbm_state <= MEM_WBM_STATE_COMMAND;
                end
              end
              MODE_READ: begin
                readback_mem[mem_progress] <= mem_wb_dat_o;
                $display("ddr_wbm: rd - prog = %x, dat = %x", mem_progress, mem_wb_dat_o);
                if (mem_progress == `NUM_OPERATIONS - 1) begin
                  mode_done[MODE_READ]  <= 1'b1;
                  mem_wbm_state <= MEM_WBM_STATE_WAIT;
                end else begin
                  mem_progress <= mem_progress + 1;
                  mem_wbm_state <= MEM_WBM_STATE_COMMAND;
                end
              end
            endcase
          end
        end
        MEM_WBM_STATE_WAIT: begin
          mem_progress <= 32'd0;
          mem_wbm_state <= MEM_WBM_STATE_COMMAND;
        end
      endcase
    end
  end


endmodule
