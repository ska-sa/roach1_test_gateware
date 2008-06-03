`timescale 1ns/10ps

`define SIMLENGTH 64000
`define CLK_PERIOD 10

`define NUM_MASTERS 4
module TB_wbm_arbiter();

  reg reset;
  wire clk;

  reg   [`NUM_MASTERS*1 - 1:0] wbm_cyc_i;
  reg   [`NUM_MASTERS*1 - 1:0] wbm_stb_i;
  reg   [`NUM_MASTERS*1 - 1:0] wbm_we_i;
  reg  [`NUM_MASTERS*32 - 1:0] wbm_adr_i;
  reg  [`NUM_MASTERS*16 - 1:0] wbm_dat_i;
  wire  [16 - 1:0] wbm_dat_o;
  wire  [`NUM_MASTERS*1 - 1:0] wbm_ack_o;
  wire  [`NUM_MASTERS*1 - 1:0] wbm_err_o;

  wire wbs_cyc_o, wbs_stb_o, wbs_we_o;
  wire [31:0] wbs_adr_o;
  wire [15:0] wbs_dat_o;
  reg  [15:0] wbs_dat_i;
  reg  wbs_ack_i;

  wbm_arbiter #(
    .NUM_MASTERS(`NUM_MASTERS)
  ) wbm_arbiter (
    .wb_clk_i(clk), .wb_rst_i(reset),
    .wbm_cyc_i(wbm_cyc_i), .wbm_stb_i(wbm_stb_i), .wbm_we_i(wbm_we_i), .wbm_sel_i(2'b11),
    .wbm_adr_i(wbm_adr_i), .wbm_dat_i(wbm_dat_i), .wbm_dat_o(wbm_dat_o),
    .wbm_ack_o(wbm_ack_o), .wbm_err_o(wbm_err_o),
    .wbs_cyc_o(wbs_cyc_o), .wbs_stb_o(wbs_stb_o), .wbs_we_o(wbs_we_o),
    .wbs_adr_o(wbs_adr_o), .wbs_dat_o(wbs_dat_o), .wbs_dat_i(wbs_dat_i),
    .wbs_ack_i(wbs_ack_i), .wbs_err_i(1'b0),
    .wbm_id(),
    .wbm_mask({`NUM_MASTERS{1'b1}})
  );

  reg [31:0] clk_counter;

  initial begin
    reset<=1'b1;
    clk_counter<=32'b0;
    $dumpvars();
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

  /********** Mode Control ***********/

  `define MODE_WRITE_BLAST 1'b0
  `define MODE_READ_BLAST  1'b1
  reg mode;
  reg mode_done_strb;
  reg [15:0] slave_mem  [65535:0];
  reg [15:0] master_mem [65535:0];

  integer i;

  always @(posedge clk) begin
    if (reset) begin
      mode <= `MODE_WRITE_BLAST;
    end else begin
      case (mode)
        `MODE_WRITE_BLAST: begin
          if (mode_done_strb) begin
            mode <= `MODE_READ_BLAST;
`ifdef DEBUG
            $display("mode: WRITE_BLAST mode complete");
`endif
          end
        end
        `MODE_READ_BLAST: begin
          if (mode_done_strb) begin
            for (i=0; i < `NUM_MASTERS; i=i+1) begin
              if (master_mem[i] !== (`NUM_MASTERS - i - 1)) begin
                //note: reverse order is due to master[n] having greater
                //      priority than master[n-1]
                $display("FAILED: master_mem readback fail - got %d, expected %d", master_mem[i], `NUM_MASTERS - i - 1);
                $finish;
              end else if (i == `NUM_MASTERS - 1) begin
                $display("PASSED");
                $finish;
              end
            end
          end
        end
      endcase
    end
  end

  /******* Simulated WB Slave ********/

  reg [15:0] sindex;

  always @(posedge clk) begin
    if (reset) begin
      sindex <= 16'b0;
      wbs_ack_i<=1'b0;
    end else begin
      wbs_ack_i<=1'b0;
      if (wbs_cyc_o & wbs_stb_o & ~wbs_ack_i) begin
        if (wbs_we_o) begin
          wbs_ack_i<=1'b1;
          slave_mem[sindex] <= wbs_dat_o;
          sindex <= sindex + 1;
`ifdef DEBUG
          $display("wbs: got write, addr = %x, data = %x, sindex == %x", wbs_adr_o, wbs_dat_o, sindex);
`endif
        end else begin
          wbs_ack_i<=1'b1;
          wbs_dat_i <= slave_mem[wbs_adr_o[15:0]];
`ifdef DEBUG
          $display("wbs: got read, addr = %x, data = %x", wbs_adr_o, slave_mem[wbs_adr_o[15:0]]);
`endif
        end
      end
    end
  end 

  /******** Simulated WB Masters *******/

`define MSTATE_SEND 1'b0
`define MSTATE_WAIT 1'b1
  reg mstate;

  integer j,k;

  reg [31:0] mindex;

  reg [`NUM_MASTERS - 1:0] got_response;

  wire [(`NUM_MASTERS)*16 - 1 : 0] test_data;
  genvar gen_i;
  generate for (gen_i=0; gen_i < `NUM_MASTERS; gen_i=gen_i+1) begin : GEN0
    assign test_data[(gen_i + 1)*16 - 1 : gen_i*16] = gen_i;
  end endgenerate


  always @(posedge clk) begin
    //strobes
    mode_done_strb <= 1'b0;
    wbm_cyc_i <= {`NUM_MASTERS{1'b0}};
    wbm_stb_i <= {`NUM_MASTERS{1'b0}};
    if (reset) begin
      mindex<=32'b0;
      mstate <= `MSTATE_SEND;
    end else if (~mode_done_strb) begin
      case (mstate)
        `MSTATE_SEND: begin
          case (mode)
            `MODE_WRITE_BLAST: begin
              wbm_cyc_i <= {`NUM_MASTERS{1'b1}};
              wbm_stb_i <= {`NUM_MASTERS{1'b1}};
              wbm_we_i  <= {`NUM_MASTERS{1'b1}};
              wbm_adr_i <= {`NUM_MASTERS{32'b0}};
              wbm_dat_i <= test_data;
              mstate <= `MSTATE_WAIT;
`ifdef DEBUG
              $display("wbm: sent block of writes, data = %h", test_data);
`endif
            end
            `MODE_READ_BLAST: begin
              wbm_cyc_i[0] <= 1'b1;
              wbm_stb_i[0] <= 1'b1;
              wbm_we_i[0]  <= 1'b0;
              wbm_adr_i[31:0] <= mindex;
              mstate <= `MSTATE_WAIT;
            end
          endcase
        end
        `MSTATE_WAIT: begin
          case (mode)
            `MODE_WRITE_BLAST: begin
              for (k=0; k < `NUM_MASTERS; k=k+1) begin
                if (wbm_ack_o[k]) begin
                  got_response[k]<=1'b1;
                end
              end
              if (got_response == {`NUM_MASTERS{1'b1}}) begin
                mode_done_strb <= 1'b1;
                mstate <= `MSTATE_SEND;
              end
            end
            `MODE_READ_BLAST: begin
              if (wbm_ack_o[0]) begin
                master_mem[mindex] <= wbm_dat_o;
                if (mindex >= `NUM_MASTERS - 1) begin
                  mode_done_strb <= 1'b1;
                end else begin
                  mindex <= mindex + 1;
                end
                mstate <= `MSTATE_SEND;
              end
            end
          endcase
        end
      endcase
    end
  end
  
endmodule
