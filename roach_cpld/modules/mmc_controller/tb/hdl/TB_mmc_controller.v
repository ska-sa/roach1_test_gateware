`timescale 1ns/10ps

`define CLK_PERIOD 10
`define SIMLENGTH 800000

module TB_mmc_controller();

  wire       wb_clk_i;
  wire       wb_rst_i;
  reg        wb_stb_i;
  reg        wb_we_i;
  reg  [2:0] wb_adr_i;
  reg  [7:0] wb_dat_i;
  wire [7:0] wb_dat_o;
  wire       wb_ack_o;

  wire       mmc_clk;
  wire       mmc_cmd_o;
  wire       mmc_cmd_i;
  wire       mmc_cmd_oe;
  wire [7:0] mmc_dat_i;
  wire [7:0] mmc_dat_o;
  wire       mmc_dat_oe;
  wire       mmc_cdetect;

  wire       irq_cdetect;
  wire       irq_got_cmd;
  wire       irq_got_dat;
  wire       irq_got_busy;

  mmc_controller mmc_controller(
    .wb_clk_i(wb_clk_i),
    .wb_rst_i(wb_rst_i),
    .wb_cyc_i(wb_stb_i),
    .wb_stb_i(wb_stb_i),
    .wb_we_i(wb_we_i),
    .wb_adr_i(wb_adr_i),
    .wb_dat_i(wb_dat_i),
    .wb_dat_o(wb_dat_o),
    .wb_ack_o(wb_ack_o),

    .mmc_clk(mmc_clk),
    .mmc_cmd_o(mmc_cmd_o),
    .mmc_cmd_i(mmc_cmd_i),
    .mmc_cmd_oe(mmc_cmd_oe),
    .mmc_dat_i(mmc_dat_i),
    .mmc_dat_o(mmc_dat_o),
    .mmc_dat_oe(mmc_dat_oe),
    .mmc_cdetect(mmc_cdetect),

    .irq_cdetect(irq_cdetect),
    .irq_got_cmd(irq_got_cmd),
    .irq_got_dat(irq_got_dat),
    .irq_got_busy(irq_got_busy)
  );


  reg reset;
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

  wire clk = clk_counter < ((`CLK_PERIOD) / 2);

  always begin
    #1 clk_counter <= (clk_counter == `CLK_PERIOD - 1 ? 32'b0 : clk_counter + 1);
  end


  assign wb_clk_i = clk;
  assign wb_rst_i = reset;

//`define BLOCK_READ
//`define WR_ADV
`define BUSY

`ifdef BUSY
  reg [31:0] progress;
  always @(posedge wb_clk_i) begin
    wb_stb_i <= 1'b0;
    if (wb_rst_i) begin
      progress <= 0;
    end else begin
      case (progress)
        0: begin
          wb_stb_i <= 1'b1;
          wb_we_i  <= 1'b1;
          wb_adr_i <= 3'd4;
          wb_dat_i <= 8'b0011_0001; //4bit, med clk 
          progress <= 1;
        end
        1: begin
          if (wb_ack_o) begin
            wb_stb_i <= 1'b1;
            wb_we_i  <= 1'b1;
            wb_adr_i <= 3'd2;
            wb_dat_i <= 8'b0100_0000; //adv_wr
            progress <= 2;
          end
        end 
      endcase
    end
  end
`endif


`ifdef WR_ADV

  reg [31:0] progress;
  always @(posedge wb_clk_i) begin
    wb_stb_i <= 1'b0;
    if (wb_rst_i) begin
      progress <= 0;
    end else begin
      case (progress)
        0: begin
          wb_stb_i <= 1'b1;
          wb_we_i  <= 1'b1;
          wb_adr_i <= 3'd4;
          wb_dat_i <= 8'b0011_0000; //4bit, fast clk 
          progress <= 1;
        end
        1: begin
          if (wb_ack_o) begin
            wb_stb_i <= 1'b1;
            wb_we_i  <= 1'b1;
            wb_adr_i <= 3'd2;
            wb_dat_i <= 8'b0010_0000; //adv_wr
            progress <= 2;
          end
        end 
        2: begin
          if (wb_ack_o) begin
            wb_dat_i <= 8'b0000_1111;
            wb_stb_i <= 1'b1;
            wb_we_i  <= 1'b1;
            wb_adr_i <= 3'd1;
            progress <= progress + 1;
          end
        end
        3: begin
          if (wb_ack_o) begin
            wb_dat_i <= 8'b0001_1110;
            wb_stb_i <= 1'b1;
            wb_we_i  <= 1'b1;
            wb_adr_i <= 3'd1;
            progress <= progress + 1;
          end
        end
        4: begin
          if (wb_ack_o) begin
            wb_dat_i <= 8'b0011_1100;
            wb_stb_i <= 1'b1;
            wb_we_i  <= 1'b1;
            wb_adr_i <= 3'd1;
            progress <= progress + 1;
          end
        end
      endcase
    end
  end


`endif

`ifdef BLOCK_READ

  wire [31:0] douche;
  reg [31:0] count;
  reg [31:0] progress;
  reg [7:0] backoff;
  localparam BACKOFF = 16;
  always @(posedge wb_clk_i) begin
    wb_stb_i <= 1'b0;
    if (wb_rst_i) begin
      progress <= 0;
      backoff <= 0;
      count <= 0;
    end else begin
      case (progress)
        0: begin
          wb_stb_i <= 1'b1;
          wb_we_i  <= 1'b1;
          wb_adr_i <= 3'd4;
          wb_dat_i <= 8'b0011_0101;
          progress <= 1;
        end
        1: begin
          if (wb_ack_o) begin
            wb_stb_i <= 1'b1;
            wb_we_i  <= 1'b1;
            wb_adr_i <= 3'd2;
            wb_dat_i <= 8'b0001_0000;
            progress <= 2;
          end
        end 
        2: begin
          if (wb_ack_o) begin
            progress <= 3;
            wb_stb_i <= 1'b1;
            wb_we_i  <= 1'b0;
            wb_adr_i <= 3'd2;
          end
        end
        3: begin
          if (wb_ack_o) begin
            if (wb_dat_o[0]) begin
              progress <= 4;
              $display("wbm: got start\n");
            end else begin
              wb_stb_i <= 1'b1;
              wb_we_i  <= 1'b0;
              wb_adr_i <= 3'd2;
            end
          end
        end
        4: begin
          if (backoff == BACKOFF) begin
            wb_stb_i <= 1'b1;
            wb_we_i  <= 1'b0;
            wb_adr_i <= 3'd1;

            progress <= 5;
          end else begin
            backoff <= backoff + 1;
          end
        end
        5: begin
          if (wb_ack_o) begin
            backoff  <= 0;
            progress <= 4;
            
            if (count < 512) begin
              if (wb_dat_o[7:0] !== douche[7:0]) begin
                $display("FAILED: data mismatch, got = %x, expected = %x, count = %d\n", wb_dat_o, douche[7:0], count);
                $display("%x %x",count, douche[7:0]);
                $finish;
              end
            end else begin
              if (count == 512) begin
                if (wb_dat_o[7:0] !== 8'hde) begin
                  $display("FAILED: data mismatch, got = %x, expected = %x\n", wb_dat_o, 8'hde);
                  $finish;
                end
              end
              if (count == 513) begin
                if (wb_dat_o[7:0] !== 8'had) begin
                  $display("FAILED: data mismatch, got = %x, expected = %x\n", wb_dat_o, 8'had);
                  $finish;
                end
              end
              if (count == 514) begin
                if (wb_dat_o[7:0] !== 8'hff) begin
                  $display("FAILED: data mismatch, got = %x, expected = %x\n", wb_dat_o, 8'hff);
                  $finish;
                end else begin
                  $display("PASSED: block read");
                  $finish;
                end
              end
            end
            count <= count + 1;
          end
        end

      endcase
    end
  end
  assign douche = (((count*2) & 16'h0f) << 4) | ((((count*2) + 8'h1) & 8'h0f));

`endif

  /* MMC stuff */
  reg [31:0] mmc_progress;

  reg  [7:0] mmc_dat_reg;
  assign mmc_dat_i = mmc_dat_reg;

  initial begin
    mmc_dat_reg  <= 8'hff;
    mmc_progress <= 0;
  end

  always @(negedge mmc_clk) begin
    mmc_progress <= mmc_progress + 1;
    case (mmc_progress)
      9:         mmc_dat_reg <= 8'h0;
      1024+10+0:  mmc_dat_reg <= 8'b1;
      1024+10+1:  mmc_dat_reg <= 8'b1;
      1024+10+2:  mmc_dat_reg <= 8'b0;
      1024+10+3:  mmc_dat_reg <= 8'b1;
      1024+10+4:  mmc_dat_reg <= 8'b1;
      1024+10+5:  mmc_dat_reg <= 8'b1;
      1024+10+6:  mmc_dat_reg <= 8'b1;
      1024+10+7:  mmc_dat_reg <= 8'b0;
      1024+10+8:  mmc_dat_reg <= 8'b1;
      1024+10+9:  mmc_dat_reg <= 8'b0;
      1024+10+10: mmc_dat_reg <= 8'b1;
      1024+10+11: mmc_dat_reg <= 8'b0;
      1024+10+12: mmc_dat_reg <= 8'b1;
      1024+10+13: mmc_dat_reg <= 8'b1;
      1024+10+14: mmc_dat_reg <= 8'b0;
      1024+10+15: mmc_dat_reg <= 8'b1;
      1024+10+16: mmc_dat_reg <= 8'hff;
    endcase
    if (mmc_progress >= 10 && mmc_progress < 1024 + 10) begin
      mmc_dat_reg <= mmc_progress - 10;
    end
  end

  
endmodule
