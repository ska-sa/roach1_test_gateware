`define SIMLENGTH 10000
`define CLK_PERIOD 2


module TB_wbs_arbiter();
  /* Simulation defines */
  localparam NUM_SLAVES = 14;

  localparam SLAVE_ADDR = {32'h000d_0000, 32'h000c_0000, 32'h000b_0000, 32'h000a_0000, //slaves 13:10
                           32'h0009_0000, 32'h0008_0000, 32'h0007_0000, 32'h0006_0000, //slaves 9:6
                           32'h0005_0000, 32'h0004_0000, 32'h0003_0000, 32'h0002_0000, //slaves 5:2
                           32'h0001_0000, 32'h0000_0000};                              //slaves 1:0

  localparam SLAVE_HIGH = {32'h000d_ffff, 32'h000c_ffff, 32'h000b_ffff, 32'h000a_ffff, //slaves 13:10
                           32'h0009_ffff, 32'h0008_ffff, 32'h0007_ffff, 32'h0006_ffff, //slaves 9:6
                           32'h0005_ffff, 32'h0004_ffff, 32'h0003_ffff, 32'h0002_ffff, //slaves 5:2
                           32'h0001_ffff, 32'h0000_ffff};                              //slaves 1:0
// localparam NUM_SLAVES = 4;
// localparam SLAVE_ADDR = {32'h0003_0000, 32'h0002_0000, 32'h0001_0000, 32'h0000_0000}; //slaves 3:0
// localparam SLAVE_HIGH = {32'h0003_ffff, 32'h0002_ffff, 32'h0001_ffff, 32'h0000_ffff}; //slaves 3:0
  localparam TEST_DATA  = 16'hbe_ef;
  localparam TEST_ADDR  = 32'h0000_dead;

  reg reset;
  wire clk;

  reg   wbm_cyc_i;
  reg   wbm_stb_i;
  reg   wbm_we_i;
  reg   [31:0] wbm_adr_i;
  reg   [15:0] wbm_dat_i;
  wire  [15:0] wbm_dat_o;
  wire  wbm_ack_o;
  wire  wbm_err_o;

  wire [NUM_SLAVES - 1:0] wbs_cyc_o;
  wire [NUM_SLAVES - 1:0] wbs_stb_o;
  wire wbs_we_o;
  wire [31:0] wbs_adr_o;
  wire [15:0] wbs_dat_o;
  reg  [16*(NUM_SLAVES) - 1:0] wbs_dat_i;
  reg  [NUM_SLAVES - 1:0] wbs_ack_i;

  wbs_arbiter #(
    .NUM_SLAVES(NUM_SLAVES),
    .SLAVE_ADDR(SLAVE_ADDR),
    .SLAVE_HIGH(SLAVE_HIGH)
  ) wbs_arbiter_inst(
    .wb_clk_i(clk), .wb_rst_i(reset),
    .wbm_cyc_i(wbm_cyc_i), .wbm_stb_i(wbm_stb_i), .wbm_we_i(wbm_we_i), .wbm_sel_i(2'b11),
    .wbm_adr_i(wbm_adr_i), .wbm_dat_i(wbm_dat_i), .wbm_dat_o(wbm_dat_o),
    .wbm_ack_o(wbm_ack_o), .wbm_err_o(wbm_err_o),
    .wbs_cyc_o(wbs_cyc_o), .wbs_stb_o(wbs_stb_o), .wbs_we_o(wbs_we_o),
    .wbs_adr_o(wbs_adr_o), .wbs_dat_o(wbs_dat_o), .wbs_dat_i(wbs_dat_i),
    .wbs_ack_i(wbs_ack_i)
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

  reg mode;
  localparam MODE_WRITE = 1'b0;
  localparam MODE_READ  = 1'b1;

  reg [31:0] mode_progress;
  reg mode_done;

  reg [15:0] master_mem [NUM_SLAVES - 1:0];
  reg [15:0] slave_mem  [NUM_SLAVES - 1:0];

  integer i;

  always @(posedge clk) begin
    if (reset) begin
      mode <= MODE_WRITE;
    end else begin
      case (mode)
        MODE_WRITE: begin
          if (mode_done) begin
            mode <= MODE_READ;
          end
        end
        MODE_READ: begin
          if (mode_done) begin
            for (i=0; i < NUM_SLAVES; i=i+1) begin
              if (slave_mem[i] !== TEST_DATA) begin
                $display("FAILED: slave %d mem failed - got %x, expected %x", i, slave_mem[i], TEST_DATA);
                $finish;
              end else if (master_mem[i] !== TEST_DATA) begin
                $display("FAILED: master %d mem failed - got %x, expected %x", i, master_mem[i], TEST_DATA);
                $finish;
              end else if (i==NUM_SLAVES-1) begin
                $display("PASSED");
                $finish;
              end
            end
          end
        end
      endcase
    end
  end

  /********* Wishbone Master *********/

  reg [1:0] wbm_state;
  localparam WBM_STATE_SEND    = 2'd0;
  localparam WBM_STATE_COLLECT = 2'd1;
  localparam WBM_STATE_WAIT    = 2'd2;

  always @(posedge clk) begin
    wbm_cyc_i <= 1'b0;
    wbm_stb_i <= 1'b0;
    mode_done <= 1'b0;
    if (reset) begin
      wbm_state <= WBM_STATE_SEND;
      mode_progress <= 0;
    end else begin
      case (wbm_state)
        WBM_STATE_SEND: begin
          wbm_cyc_i <= 1'b1;
          wbm_stb_i <= 1'b1;
          if (mode == MODE_WRITE) begin
            wbm_we_i <= 1'b1;
          end else begin
            wbm_we_i <= 1'b0;
          end
          wbm_adr_i <= {mode_progress[15:0], TEST_ADDR[15:0]};
          wbm_dat_i <= TEST_DATA;
          wbm_state <= WBM_STATE_COLLECT;
        end
        WBM_STATE_COLLECT: begin
          if (wbm_ack_o) begin
            if (~wbm_we_i) begin
              master_mem[mode_progress] <= wbm_dat_o;
            end
            if (mode_progress == NUM_SLAVES - 1) begin
              mode_done <= 1'b1;
              mode_progress <= 0;
              wbm_state <= WBM_STATE_WAIT;
            end else begin
              mode_progress <= mode_progress + 1;
              wbm_state <= WBM_STATE_SEND;
            end
          end else if (wbm_err_o) begin
            $display("FAILED: unexpected bus failure");
            $finish;
          end
        end
        WBM_STATE_WAIT: begin
          wbm_state <= WBM_STATE_SEND;
        end
      endcase
    end
  end

  /******** Wishbone Slaves ********/ 
  function [NUM_SLAVES-1:0] encode;
    input [NUM_SLAVES-1:0] in;

    integer trans;
    begin
      encode = 0; //default condition
      for (trans=0; trans < NUM_SLAVES; trans=trans+1) begin
        if (in[trans]) begin
          encode = trans; 
        end
      end
    end
  endfunction

  wire [NUM_SLAVES - 1:0] wbs_cyc_o;
  wire [NUM_SLAVES - 1:0] wbs_stb_o;
  wire wbs_we_o;
  wire [31:0] wbs_adr_o;
  wire [15:0] wbs_dat_o;
  reg  [16*(NUM_SLAVES) - 1:0] wbs_dat_i;
  reg  [NUM_SLAVES - 1:0] wbs_ack_i;

  wire [NUM_SLAVES - 1:0] wbs_act = encode(wbs_cyc_o & wbs_stb_o);

  always @(posedge clk) begin
    wbs_ack_i <= {NUM_SLAVES{1'b0}};
    if (reset) begin
    end else begin
      if ((wbs_cyc_o & wbs_stb_o) && !(wbs_ack_i)) begin
        if (wbs_act != mode_progress) begin
          $display("FAILED: expected activity on slave %d, got %d", mode_progress, wbs_act);
          $finish;
        end else begin
          wbs_ack_i[wbs_act] <= 1'b1;
          if (wbs_we_o) begin
            if (wbs_adr_o !== TEST_ADDR) begin
              $display("FAILED: slave address invalid");
              $finish;
            end 
            slave_mem[wbs_act] <= wbs_dat_o;
`ifdef DEBUG
            $display("wbs: slave %d write, addr = %x, data = %x", wbs_act, wbs_we_o, wbs_adr_o, wbs_dat_o);
`endif
          end else begin
            wbs_dat_i<= slave_mem[wbs_act] << (16*wbs_act);
`ifdef DEBUG
            $display("wbs: slave %d read, addr = %x, data = %x", wbs_act, wbs_we_o, wbs_adr_o, slave_mem[wbs_act]);
`endif
          end
        end
      end
    end
  end
  
endmodule
