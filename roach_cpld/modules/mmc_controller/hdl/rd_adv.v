module rd_adv(
    input        clk,
    input        rst,
    input        enable,
    input        data_width,     
    input  [7:0] mmc_dat_i,
    output [7:0] bus_data,
    input        bus_req,
    output       bus_ack,
    output       clk_tick,
    input        clk_done
  );
  localparam BLK_SIZE      = 512;
  localparam BLK_SIZE_LOG2 = 9;

  reg [2:0] state;
  localparam IDLE   = 0;
  localparam SEARCH = 1;
  localparam DATA   = 2;
  localparam CRC    = 3;
  localparam STOP   = 4;

  reg [BLK_SIZE_LOG2 - 1:0] progress;

  wire data_done;
  assign bus_ack = data_done;

  wire data_rdy;
  reg data_rdy_latch;
  assign data_done = data_rdy_latch || data_rdy;

  reg bus_req_latch;
  //wire bus_trans = bus_req || bus_req_latch;
  wire bus_trans = bus_req_latch;

  always @(posedge clk) begin
    if (bus_req) begin
      bus_req_latch <= 1'b1;
    end
    if (bus_ack && bus_req_latch) begin
      bus_req_latch <= 1'b0;
    end

    if (data_rdy) begin
      data_rdy_latch <= 1'b1;
    end
    if (bus_trans && bus_ack) begin
      data_rdy_latch <= 1'b0;
    end

    if (rst || !enable) begin
      progress <= 0;
      state    <= IDLE;
      data_rdy_latch <= 1'b0;
      bus_req_latch  <= 1'b0;
    end else begin
      case (state)
        IDLE: begin
          if (enable) begin
            state    <= SEARCH;
          end
        end
        SEARCH: begin
          if (clk_done && !mmc_dat_i[0]) begin
            progress <= 0;
            state    <= DATA;
          end
        end
        DATA: begin
          if (data_done && bus_trans) begin
            if (progress == BLK_SIZE - 1) begin
              progress <= 0;
              state    <= CRC;
            end else begin
              progress <= progress + 1;
            end
          end
        end
        CRC: begin
          if (data_done && bus_trans) begin
            if (progress == 1) begin
              state <= STOP;
            end else begin
              progress <= progress + 1;
            end
          end 
        end
        STOP: begin
          if (data_done && bus_trans) begin
            state <= SEARCH;
          end
        end
      endcase
    end
  end 

  reg data_req;
  always @(*) begin
    data_req <= 0;
    case (state)
      SEARCH: begin
        data_req <= clk_done && !mmc_dat_i[0];
      end
      DATA: begin
        data_req <= bus_trans;
      end
      CRC: begin
        data_req <= bus_trans;
      end
    endcase
  end

  /******** Data Accumulation ********/

  reg busy;
  reg [2:0] dacc;
  reg [7:0] data_accum;

  wire [2:0] targ;

  always @(posedge clk) begin
    if (rst || !enable) begin
      busy <= 1'b0;
    end else begin
      case (busy)
        0: begin
          if (data_req) begin
            busy <= 1'b1;
            dacc <= 3'd0;
          end
        end
        1: begin
          if (clk_done) begin
            if (targ == 7)
              data_accum[7 - dacc] <= mmc_dat_i[0];
            if (targ == 1 && !dacc[0])
              data_accum[3:0] <= mmc_dat_i[3:0];

            dacc <= dacc + 1;
            if (dacc == targ) begin
              if (data_req) begin
                dacc <= 0;
              end else begin
                busy <= 1'b0;
                dacc <= 0;
              end
            end
          end
        end
      endcase
    end
  end

  assign data_rdy = dacc == targ && clk_done && busy;
  wire data_tick = data_req || busy && (dacc != targ);

  reg [2:0] targ_reg;
  assign targ = targ_reg;
  always @(*) begin
    case (state)
      DATA: begin
        case (data_width)
          0: /* 1bit */
            targ_reg <= 7;
          default: /* 4bit */
            targ_reg <= 1;
        endcase
      end
      CRC: begin
        targ_reg <= 7;
      end
      default: begin
        targ_reg <= 0;
      end
    endcase
  end

  /******* Bus Data Assignment *******/
  reg [7:0] bus_data_reg;
  assign bus_data = bus_data_reg;

  always @(*) begin
    case (state)
      DATA: begin
        case (data_width)
          0: /* 1bit */
            bus_data_reg <= {data_accum[7:1], mmc_dat_i[0]};
          default: /* 4bit */
            bus_data_reg <= {data_accum[3:0], mmc_dat_i[3:0]};
        endcase
      end
      CRC: begin
        bus_data_reg <= {data_accum[7:1], mmc_dat_i[0]};
      end
      default: begin
        bus_data_reg <= mmc_dat_i[7:0];
      end
    endcase
  end

  assign clk_tick = data_tick || state == SEARCH;
  /* be careful ^^^^^^^^^^^^^! */

endmodule
