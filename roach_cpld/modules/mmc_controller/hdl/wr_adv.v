module wr_adv (
    input        clk,
    input        rst,

    input        data_width,

    input        bus_req,
    input  [7:0] bus_dat_i,
    output       bus_ack,

    output [7:0] dat_wr,
    
    output       clk_tick,
    input        clk_done,
    input        clk_ack
  );

  localparam DW_1 = 1'd0;
  localparam DW_4 = 1'd1;

  /* Write Logic */

  reg [2:0] wr_index;  

  always @(posedge clk) begin
    if (bus_req || rst) begin
      wr_index <= 3'd0;
    end else begin
      if (clk_ack) begin
        wr_index <= wr_index + 1;
      end
    end
  end

  reg busy;
  always @(posedge clk) begin
    if (rst) begin
      busy <= 1'b0;
    end else begin
      if (bus_req) begin
        busy <= 1'b1;
      end
      if (busy) begin
        case (data_width)
          DW_1: begin
            if (clk_ack && wr_index == 7)
              busy <= 1'b0;
          end
          default: begin
            if (clk_ack && wr_index == 1)
              busy <= 1'b0;
          end
        endcase
      end
    end
  end

  assign clk_tick = busy || bus_req;
  assign bus_ack  = !busy && clk_done;

  wire [2:0] wr_index_seq = bus_req ? 0 : wr_index;

  assign dat_wr = data_width == DW_1 ? {7'b0, bus_dat_i[7 - wr_index_seq]}                         :
                                       {4'b0, (wr_index_seq[0] ? bus_dat_i[3:0] : bus_dat_i[7:4])};


endmodule
