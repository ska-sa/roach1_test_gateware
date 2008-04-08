module ddr2_controller(
    clk, reset,
    af_cmnd_i, af_addr_i, af_wen_i,
    af_afull_o,
    df_data_i, df_mask_i, df_wen_i,
    df_afull_o,
    data_o, dvalid_o,
    phy_rdy
  );
  input  clk, reset;
  input    [2:0] af_cmnd_i;
  input   [30:0] af_addr_i;
  input  af_wen_i;
  output af_afull_o;
  input  [127:0] df_data_i;
  input   [15:0] df_mask_i;
  input  df_wen_i;
  output df_afull_o;
  output [127:0] data_o;
  output dvalid_o;
  output phy_rdy;

  /* Address Fifo */

  wire  [2:0] af_cmnd;
  wire [30:0] af_addr;
  wire af_empty;
  reg  af_rd;

  wire [33:0] af_d_int;
  assign af_cmnd = af_d_int[33:31];
  assign af_addr = af_d_int[30:0];


  dist_fifo #(
    .WIDTH(34),
    .SIZE(32),
    .ID(0)
  ) a_fifo (
    .clk(clk), .reset(reset),
    .d_in({af_cmnd_i, af_addr_i}),  .wr_en(af_wen_i),
    .d_out(af_d_int), .rd_en(af_rd),
    .full(),  .empty(af_empty),
    .afull(af_afull_o), .aempty()
  );
 

  /* Data Fifo */

  wire [127:0] df_data;
  wire  [15:0] df_mask;
  wire df_empty;
  reg  df_rd;

  wire [143:0] df_d_int;
  assign df_data = df_d_int[143:16];
  assign df_mask = df_d_int[15:0];

  dist_fifo #(
    .WIDTH(144),
    .SIZE(32),
    .ID(1)
  ) d_fifo (
    .clk(clk), .reset(reset),
    .d_in({df_data_i, df_mask_i}),  .wr_en(df_wen_i),
    .d_out(df_d_int), .rd_en(df_rd),
    .full(),  .empty(df_empty),
    .afull(df_afull_o), .aempty()
  );

  /* Simulated Memory */

  reg [63:0] mem [65535:0];

  reg [2:0] state;
  localparam STATE_STARTUP = 3'd0;
  localparam STATE_IDLE    = 3'd1;
  localparam STATE_WR      = 3'd2;
  localparam STATE_RD      = 3'd3;

  reg   [3:0] write_timer; 
  localparam WRITE_LATENCY = 4; 
  reg   [3:0] read_timer; 
  localparam READ_LATENCY = 4; 

  reg [127:0] data_o;
  reg dvalid_o;

  reg [31:0] startup_counter;
  localparam STARTUP_TIME = 20;

  assign phy_rdy = state != STATE_STARTUP;

  reg [63:0] foo;

  wire [15:0] yoma = af_addr[15:0];

  always @(posedge clk) begin
    //strobes
    df_rd    <= 1'b0;
    af_rd    <= 1'b0;
    dvalid_o <= 1'b0;

    if (reset) begin
      startup_counter <= 32'b0;
      state <= STATE_STARTUP;
    end else if (df_rd | af_rd) begin//lame
    end else begin
      case (state)
        STATE_STARTUP: begin
          if (startup_counter == STARTUP_TIME) begin
            state <= STATE_IDLE;
          end else begin
            startup_counter <= startup_counter + 1;
          end
        end
        STATE_IDLE: begin
          if (!af_empty) begin
            if (af_cmnd == 3'b001) begin //read
              read_timer <= 0;
              state <= STATE_RD;
`ifdef DEBUG
              $display("ddr2: got rd, addr = %x", af_addr);
`endif
            end else if (af_cmnd == 3'b000) begin //write
              if (df_empty) begin
                $display("FAILED: attempted to write with empty data fifo");
                $finish;
              end else begin
                foo [  7:0] = df_mask[0]  ? df_data[  7:0] : mem[af_addr[15:0] + 0] [  7:0]; 
                foo [ 15:8] = df_mask[1]  ? df_data[ 15:8] : mem[af_addr[15:0] + 0] [ 15:8]; 
                foo [23:16] = df_mask[2]  ? df_data[23:16] : mem[af_addr[15:0] + 0] [23:16]; 
                foo [31:24] = df_mask[3]  ? df_data[31:24] : mem[af_addr[15:0] + 0] [31:24]; 
                foo [39:32] = df_mask[4]  ? df_data[39:32] : mem[af_addr[15:0] + 0] [39:32]; 
                foo [47:40] = df_mask[5]  ? df_data[47:40] : mem[af_addr[15:0] + 0] [47:40]; 
                foo [55:48] = df_mask[6]  ? df_data[55:48] : mem[af_addr[15:0] + 0] [55:48]; 
                foo [63:56] = df_mask[7]  ? df_data[63:56] : mem[af_addr[15:0] + 0] [63:56]; 
                mem[af_addr[15:0]] <= foo;

                foo [  7:0] = df_mask[8]  ? df_data[64 +  7:0  + 64] : mem[af_addr[15:0] + 1] [  7:0]; 
                foo [ 15:8] = df_mask[9]  ? df_data[64 + 15:8  + 64] : mem[af_addr[15:0] + 1] [ 15:8]; 
                foo [23:16] = df_mask[10] ? df_data[64 + 23:16 + 64] : mem[af_addr[15:0] + 1] [23:16]; 
                foo [31:24] = df_mask[11] ? df_data[64 + 31:24 + 64] : mem[af_addr[15:0] + 1] [31:24]; 
                foo [39:32] = df_mask[12] ? df_data[64 + 39:32 + 64] : mem[af_addr[15:0] + 1] [39:32]; 
                foo [47:40] = df_mask[13] ? df_data[64 + 47:40 + 64] : mem[af_addr[15:0] + 1] [47:40]; 
                foo [55:48] = df_mask[14] ? df_data[64 + 55:48 + 64] : mem[af_addr[15:0] + 1] [55:48]; 
                foo [63:56] = df_mask[15] ? df_data[64 + 63:56 + 64] : mem[af_addr[15:0] + 1] [63:56]; 
                mem[af_addr[15:0]+1] <= foo;

                write_timer <= 0;
                df_rd <= 1'b1;
                state <= STATE_WR;
`ifdef DEBUG
                $display("ddr2: got wr, addr = %x, data = %x, mask=%b", af_addr[15:0], df_data, df_mask);
`endif
              end
            end else begin
              $display("FAILED: invalid command");
              $finish;
            end
          end
        end
        STATE_RD: begin
          if (read_timer == READ_LATENCY) begin
            data_o   <= {mem[af_addr[15:0] + 1], mem[af_addr[15:0] + 0]};
            dvalid_o <= 1'b1;
            read_timer <= read_timer + 1;

            $display("ddr2: read data 0 - %x", {mem[af_addr[15:0] + 1], mem[af_addr[15:0] + 0]});
          end else if (read_timer == READ_LATENCY + 1) begin
            data_o   <= {mem[af_addr[15:0] + 3], mem[af_addr[15:0] + 2]};
            dvalid_o <= 1'b1;
            af_rd <= 1'b1;

            $display("ddr2: read data 1 - %x", {mem[af_addr[15:0] + 3], mem[af_addr[15:0] + 2]});
            state <= STATE_IDLE;
          end else begin
            read_timer <= read_timer + 1;
          end
        end
        STATE_WR: begin
          if (write_timer == 0) begin
            if (df_empty) begin
              $display("FAILED: attempted to write with empty data fifo");
              $finish;
            end else begin
              foo [  7:0] = df_mask[0]  ? df_data[  7:0] : mem[af_addr[15:0] + 2] [  7:0]; 
              foo [ 15:8] = df_mask[1]  ? df_data[ 15:8] : mem[af_addr[15:0] + 2] [ 15:8]; 
              foo [23:16] = df_mask[2]  ? df_data[23:16] : mem[af_addr[15:0] + 2] [23:16]; 
              foo [31:24] = df_mask[3]  ? df_data[31:24] : mem[af_addr[15:0] + 2] [31:24]; 
              foo [39:32] = df_mask[4]  ? df_data[39:32] : mem[af_addr[15:0] + 2] [39:32]; 
              foo [47:40] = df_mask[5]  ? df_data[47:40] : mem[af_addr[15:0] + 2] [47:40]; 
              foo [55:48] = df_mask[6]  ? df_data[55:48] : mem[af_addr[15:0] + 2] [55:48]; 
              foo [63:56] = df_mask[7]  ? df_data[63:56] : mem[af_addr[15:0] + 2] [63:56]; 
              mem[af_addr[15:0]+2] <= foo;

              foo [  7:0] = df_mask[8]  ? df_data[64 +  7:0  + 64] : mem[af_addr[15:0] + 3] [  7:0]; 
              foo [ 15:8] = df_mask[9]  ? df_data[64 + 15:8  + 64] : mem[af_addr[15:0] + 3] [ 15:8]; 
              foo [23:16] = df_mask[10] ? df_data[64 + 23:16 + 64] : mem[af_addr[15:0] + 3] [23:16]; 
              foo [31:24] = df_mask[11] ? df_data[64 + 31:24 + 64] : mem[af_addr[15:0] + 3] [31:24]; 
              foo [39:32] = df_mask[12] ? df_data[64 + 39:32 + 64] : mem[af_addr[15:0] + 3] [39:32]; 
              foo [47:40] = df_mask[13] ? df_data[64 + 47:40 + 64] : mem[af_addr[15:0] + 3] [47:40]; 
              foo [55:48] = df_mask[14] ? df_data[64 + 55:48 + 64] : mem[af_addr[15:0] + 3] [55:48]; 
              foo [63:56] = df_mask[15] ? df_data[64 + 63:56 + 64] : mem[af_addr[15:0] + 3] [63:56]; 
              mem[af_addr[15:0]+3] <= foo;
`ifdef DEBUG
              $display("ddr2: word 2 - data = %x, mask=%b", df_data, df_mask);
`endif

              df_rd <= 1'b1;
              af_rd <= 1'b1;
            end
          end

          if (write_timer == WRITE_LATENCY) begin
             $display("MOO 0 : %x", mem[0]);
             $display("MOO 1 : %x", mem[1]);
             $display("MOO 2 : %x", mem[2]);
             $display("MOO 3 : %x", mem[3]);
             $display("MOO 4 : %x", mem[4]);
             $display("MOO 5 : %x", mem[5]);
             $display("MOO 6 : %x", mem[6]);
             $display("MOO 7 : %x", mem[7]);
            state <= STATE_IDLE;
          end else begin
            write_timer <= write_timer + 1;
          end
        end
      endcase
    end
  end

endmodule
