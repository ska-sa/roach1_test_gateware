module fifo_512_8 (
    input        reset,

    input        rd_clk,
    output [7:0] rd_data,
    input        rd_en,

    input        wr_clk,
    input  [7:0] wr_data,
    input        wr_en,

    output       empty,
    output       full,
    output       aempty,
    output       afull
  );

  wire [11:0] aempty_lev;
  wire [11:0] afull_lev;

  wire [18:0] write_data;
  wire [18:0] read_data;

  assign aempty_lev = 2;
  assign afull_lev  = 510;

  assign write_data = {10'b0, wr_data};
  assign rd_data    = read_data[7:0];

  /* signal for fake fwft mode */
  wire true_empty, true_rd_en;

  FIFO4K18 fifo4k18_inst(
    .RESET (!reset), //active low

    .AEVAL11 (aempty_lev[11]), .AEVAL10 (aempty_lev[10]), .AEVAL9 (aempty_lev[9]),
    .AEVAL8  (aempty_lev[8]),  .AEVAL7  (aempty_lev[7]),  .AEVAL6 (aempty_lev[6]), 
    .AEVAL5  (aempty_lev[5]),  .AEVAL4  (aempty_lev[4]),  .AEVAL3 (aempty_lev[3]),
    .AEVAL2  (aempty_lev[2]),  .AEVAL1  (aempty_lev[1]),  .AEVAL0 (aempty_lev[0]), 

    .AFVAL11 (afull_lev[11]), .AFVAL10 (afull_lev[10]), .AFVAL9 (afull_lev[9]),
    .AFVAL8  (afull_lev[8]),  .AFVAL7  (afull_lev[7]),  .AFVAL6 (afull_lev[6]), 
    .AFVAL5  (afull_lev[5]),  .AFVAL4  (afull_lev[4]),  .AFVAL3 (afull_lev[3]),
    .AFVAL2  (afull_lev[2]),  .AFVAL1  (afull_lev[1]),  .AFVAL0 (afull_lev[0]), 

    .WD17 (write_data[17]), .WD16 (write_data[16]), .WD15 (write_data[15]),
    .WD14 (write_data[14]), .WD13 (write_data[13]), .WD12 (write_data[12]),
    .WD11 (write_data[11]), .WD10 (write_data[10]), .WD9  (write_data[9]),
    .WD8  (write_data[8]),  .WD7  (write_data[7]),  .WD6  (write_data[6]),
    .WD5  (write_data[5]),  .WD4  (write_data[4]),  .WD3  (write_data[3]),
    .WD2  (write_data[2]),  .WD1  (write_data[1]),  .WD0  (write_data[0]), 

    .RD17 (read_data[17]), .RD16 (read_data[16]), .RD15 (read_data[15]),
    .RD14 (read_data[14]), .RD13 (read_data[13]), .RD12 (read_data[12]),
    .RD11 (read_data[11]), .RD10 (read_data[10]), .RD9  (read_data[9]),
    .RD8  (read_data[8]),  .RD7  (read_data[7]),  .RD6  (read_data[6]),
    .RD5  (read_data[5]),  .RD4  (read_data[4]),  .RD3  (read_data[3]),
    .RD2  (read_data[2]),  .RD1  (read_data[1]),  .RD0  (read_data[0]), 

    .RCLK (rd_clk), .REN (true_rd_en), .RBLK (1'b0), .RPIPE (1'b0),
    .WCLK (wr_clk), .WEN (!wr_en),     .WBLK (1'b0), //WEN active low
    .FULL (full), .AFULL (afull), .EMPTY(true_empty), .AEMPTY(aempty),

    .WW2 (1'b0), .WW1 (1'b1), .WW0 (1'b1),
    .RW2 (1'b0), .RW1 (1'b1), .RW0 (1'b1),
    .ESTOP (1'b1), .FSTOP (1'b1)
   );

   reg dvld;

   always @(posedge rd_clk) begin
     if (reset) begin
       dvld <= 1'b0;
     end else begin
       if (dvld) begin
         if (rd_en && true_empty) begin
           dvld <= 1'b0;
         end
         if (rd_en && !true_empty) begin
           dvld <= 1'b1;
         end
       end else if (!true_empty) begin
         dvld <= 1'b1;
       end
     end
   end
   assign empty = !dvld;
   assign true_rd_en = !dvld && !true_empty || dvld && rd_en && !true_empty;

endmodule
