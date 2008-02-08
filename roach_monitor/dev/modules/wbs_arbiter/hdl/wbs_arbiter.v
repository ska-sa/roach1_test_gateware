module wbs_arbiter(
    /*generic wb signals*/
    wb_clk_i, wb_rst_i,
    /*wbm signals*/
    wbm_cyc_i, wbm_stb_i, wbm_we_i,
    wbm_adr_i, wbm_dat_i, wbm_dat_o,
    wbm_ack_o, wbm_err_o,
    /*wbs signals*/
    wbs_cyc_o, wbs_stb_o, wbs_we_o,
    wbs_adr_o, wbs_dat_o, wbs_dat_i,
    wbs_ack_i, 
    /*special signals*/
    wbm_id,
    /*memory violation signals*/
    bm_memv,
    bm_wbm_id,
    bm_addr,
    bm_we,
    bm_timeout
  );
  parameter NUM_MASTERS = 4;

  parameter RESTRICTION0 = 35'b0;
  parameter RESTRICTION1 = 35'b0;
  parameter RESTRICTION2 = 35'b0;

  parameter TOCONF0 = 52'b0;
  parameter TOCONF1 = 52'b0;
  parameter TODEFAULT = 20'b0;
 
  parameter A0_BASE = 16'h0;
  parameter A0_HIGH = 16'h0;
  parameter A1_BASE = 16'h0;
  parameter A1_HIGH = 16'h0;
  parameter A2_BASE = 16'h0;
  parameter A2_HIGH = 16'h0;
  parameter A3_BASE = 16'h0;
  parameter A3_HIGH = 16'h0;
  parameter A4_BASE = 16'h0;
  parameter A4_HIGH = 16'h0;
  parameter A5_BASE = 16'h0;
  parameter A5_HIGH = 16'h0;
  parameter A6_BASE = 16'h0;
  parameter A6_HIGH = 16'h0;
  parameter A7_BASE = 16'h0;
  parameter A7_HIGH = 16'h0;
  parameter A8_BASE = 16'h0;
  parameter A8_HIGH = 16'h0;
  parameter A9_BASE = 16'h0;
  parameter A9_HIGH = 16'h0;

  /*
   * note: memory location bits [5:0] should only be zero
   *       ie the minimum module memory width is 64 bytes
   *       if this is violated the lower memory location 
   *       will take presendance.
   *
   */

  localparam NUM_SLAVES = 9;

  input  wb_clk_i, wb_rst_i;

  input  wbm_cyc_i;
  input  wbm_stb_i;
  input  wbm_we_i;
  input  [15:0] wbm_adr_i;
  input  [15:0] wbm_dat_i;
  output [15:0] wbm_dat_o;
  output wbm_ack_o;
  output wbm_err_o;

  output [NUM_SLAVES - 1:0] wbs_cyc_o;
  output [NUM_SLAVES - 1:0] wbs_stb_o;
  output wbs_we_o;
  output [15:0] wbs_adr_o;
  output [15:0] wbs_dat_o;
  input  [NUM_SLAVES*16 - 1:0] wbs_dat_i;
  input  [NUM_SLAVES - 1:0] wbs_ack_i;

  input  [NUM_MASTERS - 1:0] wbm_id;

  output bm_memv;
  output [NUM_MASTERS - 1:0] bm_wbm_id;
  output [15:0] bm_addr;
  output bm_we;
  output bm_timeout;

  /************************** Common Signals ***************************/

  wire [NUM_SLAVES - 1:0] wbs_sel;
  reg  [NUM_SLAVES - 1:0] wbs_active;

  reg  vcheck; //violation check strobe
  wire vfail;  //violation fail strobe
  wire vpass;  //violation pass strobe

  wire timeout_reset;
  
  // temp
  wire [NUM_SLAVES - 1:0] temp = 1;

  /************************** Bus Protection **************************/
  
  bus_protect #(
    .RESTRICTION0(RESTRICTION0),
    .RESTRICTION1(RESTRICTION1),
    .RESTRICTION2(RESTRICTION2)
  ) bus_protect_inst (
    .vcheck(vcheck),
    .vfail(vfail), .vpass(vpass),
    .adr(wbm_adr_i), .wr_en(wbm_we_i)
  );

  assign bm_memv = vfail;
  assign bm_wbm_id = wbm_id;
  assign bm_addr = wbm_adr_i;
  assign bm_we   = wbm_we_i;

  /************************ Timeout Monitoring **************************/

  timeout #(
    .TOCONF0(TOCONF0),
    .TOCONF1(TOCONF1),
    .TODEFAULT(TODEFAULT)
  ) timeout_inst (
    .clk(wb_clk_i), .reset(wb_rst_i | timeout_reset),
    .adr(wbm_adr_i),
    .timeout(bm_timeout)
  );


  /*********************** WB Slave Arbitration **************************/

  assign wbs_sel = wbm_adr_i[15:6] < A0_HIGH[15:6] && wbm_adr_i[15:6] >= A0_BASE[15:6] ? (temp << 0) : 
                   wbm_adr_i[15:6] < A1_HIGH[15:6] && wbm_adr_i[15:6] >= A1_BASE[15:6] ? (temp << 1) : 
                   wbm_adr_i[15:6] < A2_HIGH[15:6] && wbm_adr_i[15:6] >= A2_BASE[15:6] ? (temp << 2) : 
                   wbm_adr_i[15:6] < A3_HIGH[15:6] && wbm_adr_i[15:6] >= A3_BASE[15:6] ? (temp << 3) : 
                   wbm_adr_i[15:6] < A4_HIGH[15:6] && wbm_adr_i[15:6] >= A4_BASE[15:6] ? (temp << 4) : 
                   wbm_adr_i[15:6] < A5_HIGH[15:6] && wbm_adr_i[15:6] >= A5_BASE[15:6] ? (temp << 5) : 
                   wbm_adr_i[15:6] < A6_HIGH[15:6] && wbm_adr_i[15:6] >= A6_BASE[15:6] ? (temp << 6) : 
                   wbm_adr_i[15:6] < A7_HIGH[15:6] && wbm_adr_i[15:6] >= A7_BASE[15:6] ? (temp << 7) : 
                   wbm_adr_i[15:6] < A8_HIGH[15:6] && wbm_adr_i[15:6] >= A8_BASE[15:6] ? (temp << 8) : 
                   {NUM_SLAVES{1'b0}};

  assign wbm_dat_o = wbs_active == (temp << 0) ? wbs_dat_i[16*(0+1) - 1:16*0] :
                     wbs_active == (temp << 1) ? wbs_dat_i[16*(1+1) - 1:16*1] :
                     wbs_active == (temp << 2) ? wbs_dat_i[16*(2+1) - 1:16*2] :
                     wbs_active == (temp << 3) ? wbs_dat_i[16*(3+1) - 1:16*3] :
                     wbs_active == (temp << 4) ? wbs_dat_i[16*(4+1) - 1:16*4] :
                     wbs_active == (temp << 5) ? wbs_dat_i[16*(5+1) - 1:16*5] :
                     wbs_active == (temp << 6) ? wbs_dat_i[16*(6+1) - 1:16*6] :
                     wbs_active == (temp << 7) ? wbs_dat_i[16*(7+1) - 1:16*7] :
                     wbs_active == (temp << 8) ? wbs_dat_i[16*(8+1) - 1:16*8] :
                     16'b0;

  assign wbs_we_o = wbm_we_i;
  assign wbs_adr_o = wbm_adr_i;
  assign wbs_dat_o = wbm_dat_i;

  reg wbm_err_o, wbm_ack_o;

  reg [NUM_SLAVES - 1:0] wbs_cyc_o;
  reg [NUM_SLAVES - 1:0] wbs_stb_o;

  reg [1:0] state;
  localparam STATE_IDLE   = 2'd0;
  localparam STATE_VCHECK = 2'd1;
  localparam STATE_WAIT   = 2'd2;

  assign timeout_reset = ~(state == STATE_WAIT);

  always @(posedge wb_clk_i) begin
    /* strobes */
    wbs_cyc_o <= 1'b0;
    wbs_stb_o <= 1'b0;
    wbm_ack_o <= 1'b0;
    vcheck <= 1'b0;

    if (wb_rst_i) begin
      state <= STATE_IDLE;
      wbs_active <= {NUM_SLAVES{1'b0}};
    end else begin
      case (state)
        STATE_IDLE: begin
          if (wbm_cyc_i & wbm_stb_i) begin
            wbs_active <= wbs_sel;
            vcheck <=1'b1;
            state <= STATE_VCHECK;
          end else begin
            wbs_active <= {NUM_SLAVES{1'b0}};
            /* this delayed clear is intentional as the wbm_ack depends on the value */
          end
        end
        STATE_VCHECK: begin
          if (vpass) begin
            wbs_stb_o <= 1'b1;
            wbs_cyc_o <= 1'b1;
            state <= STATE_WAIT;
          end else if (vfail) begin
            wbm_err_o <= 1'b1;
            state <= STATE_IDLE;
          end
        end
        STATE_WAIT: begin
          if (wbs_ack_i) begin
            wbm_ack_o <= 1'b1;
            state <= STATE_IDLE;
          end else if(bm_timeout) begin
            wbm_err_o <= 1'b1;
            state <= STATE_IDLE;
          end
        end
      endcase
    end
  end

endmodule
