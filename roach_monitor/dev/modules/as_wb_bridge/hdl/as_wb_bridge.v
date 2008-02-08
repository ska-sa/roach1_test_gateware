`timescale 1ns/10ps

`define ASWB_STATE_CMND  3'd0
`define ASWB_STATE_ADDR0 3'd1
`define ASWB_STATE_ADDR1 3'd2
`define ASWB_STATE_DATA0 3'd3
`define ASWB_STATE_DATA1 3'd4
`define ASWB_STATE_WRITE 3'd5
`define ASWB_STATE_READ  3'd6

`define COMMAND_NOP   8'b0
`define COMMAND_READ  8'b01
`define COMMAND_WRITE 8'b10
 
module as_wb_bridge(
    clk, reset, 
    as_data_i, as_data_o,
    as_dstrb_i, as_busy_i, as_dstrb_o,

    wb_we_o, wb_cyc_o, wb_stb_o,
    wb_adr_o, wb_dat_o, wb_dat_i,
    wb_ack_i,

    wb_timeout
  );

  input  clk, reset;
  
  input  [7:0] as_data_i;
  output [7:0] as_data_o;
  input  as_dstrb_i, as_busy_i;
  output as_dstrb_o;
  
  output wb_we_o, wb_cyc_o, wb_stb_o;
  output [15:0] wb_adr_o;
  output [15:0] wb_dat_o;
  input  [15:0] wb_dat_i;
  input  wb_ack_i;

  input  wb_timeout;

  reg [2:0] state;

  reg t_wr_rd_n; //is the command a or write or read?

  reg [15:0] wb_adr_o;
  reg [15:0] wb_dat_o;
  reg [15:0] wb_dat_i_buf;
  reg wb_stb_o;
  reg wb_cyc_o;
  reg wb_we_o;

  reg as_dstrb_o;
  reg [7:0] as_data_o;

  //continuous assign to assert wb_rqst on the same cycle as the state is
  //processed

  always @(posedge clk) begin
    if (reset) begin
      state<=`ASWB_STATE_CMND;

      as_dstrb_o <= 1'b0;
      
      wb_stb_o <= 1'b0;
      wb_cyc_o <= 1'b0;

`ifdef DEBUG
      $display("ciface: RESET");
`endif
    end begin
      //strobes
      as_dstrb_o <= 1'b0;
      wb_stb_o   <= 1'b0;
      wb_cyc_o   <= 1'b0;


      case (state)
        `ASWB_STATE_CMND: begin
	  if (as_dstrb_i) begin
            case (as_data_i)
              `COMMAND_WRITE: begin
	        state<=`ASWB_STATE_ADDR0;
	        t_wr_rd_n<=1'b1;
`ifdef DEBUG
                $display("ciface: got command write");
`endif
              end
              `COMMAND_READ: begin
	        state<=`ASWB_STATE_ADDR0;
	        t_wr_rd_n<=1'b0;
`ifdef DEBUG
                $display("ciface: got command read");
`endif
              end
              `COMMAND_NOP: begin
              end
              default: begin
              end
            endcase
	  end 
	end
	`ASWB_STATE_ADDR0: begin
	  if (as_dstrb_i) begin
	    wb_adr_o[7:0]<=as_data_i;
	    state<=`ASWB_STATE_ADDR1;
`ifdef DEBUG
            $display("ciface: got addr0 - %x",as_data_i);
`endif
	  end 
	end
	`ASWB_STATE_ADDR1: begin
	  if (t_wr_rd_n) begin
            if (as_dstrb_i) begin
	      wb_adr_o[15:8] <= as_data_i;
	      state<=`ASWB_STATE_DATA0;
            end
          end else if (~t_wr_rd_n) begin 
            if (as_dstrb_i) begin
	      wb_adr_o[15:8] <= as_data_i;
              wb_stb_o <= 1'b1;
              wb_cyc_o <= 1'b1;
              wb_we_o  <= 1'b0;
	      state<=`ASWB_STATE_READ;
`ifdef DEBUG
              $display("ciface: got addr1 - %x",as_data_i);
`endif
            end
	  end 
	end
	`ASWB_STATE_DATA0: begin
	  if (t_wr_rd_n) begin 
	    if (as_dstrb_i) begin
              wb_dat_o[7:0]<=as_data_i;
              state<=`ASWB_STATE_DATA1;
`ifdef DEBUG
            $display("ciface: got write data0 - %x",as_data_i);
`endif
            end
	  end else begin
            if (~as_busy_i & ~as_dstrb_o) begin
	      as_data_o<=wb_dat_i_buf[7:0];
	      as_dstrb_o<=1'b1;
	      state<=`ASWB_STATE_DATA1;
`ifdef DEBUG
              $display("ciface: outputting write data0 - %x",wb_dat_i_buf[7:0]);
`endif
            end
	  end
	end
	`ASWB_STATE_DATA1: begin
          if (t_wr_rd_n) begin 
	    if (as_dstrb_i) begin
              wb_dat_o[15:8]<=as_data_i;
              wb_stb_o <= 1'b1;
              wb_cyc_o <= 1'b1;
              wb_we_o  <= 1'b1;
              state<=`ASWB_STATE_WRITE;
`ifdef DEBUG
              $display("ciface: got write data1 - %x", as_data_i);
`endif
            end
	  end else begin
            if (~as_busy_i & ~as_dstrb_o) begin
	      as_data_o<=wb_dat_i_buf[15:8];
	      as_dstrb_o<=1'b1;
	      state<=`ASWB_STATE_CMND;
`ifdef DEBUG
              $display("ciface: outputting write data0 - %x",wb_dat_i_buf[15:8]);
`endif
            end
	  end
	end
	`ASWB_STATE_WRITE: begin
	  if (wb_timeout) begin
	    state<=`ASWB_STATE_CMND;
          end else if (wb_ack_i) begin
	    state<=`ASWB_STATE_CMND;
`ifdef DEBUG
            $display("ciface: got wb write reply");
`endif
          end
	end
	`ASWB_STATE_READ: begin
	  if (wb_timeout) begin
	    state<=`ASWB_STATE_CMND;
          end else if (wb_ack_i) begin
	    wb_dat_i_buf<=wb_dat_i;
	    state<=`ASWB_STATE_DATA0;
`ifdef DEBUG
            $display("ciface: got wb read reply - data %x",wb_dat_i);
`endif
	  end 
	end
      endcase
    end
  end

endmodule
