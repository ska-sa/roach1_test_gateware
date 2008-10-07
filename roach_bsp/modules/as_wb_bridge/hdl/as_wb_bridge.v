`timescale 1ns/10ps

`define AS_CMND_NOP   8'd0
`define AS_CMND_READ  8'd1
`define AS_CMND_WRITE 8'd2

`define AS_T_STATE_HELLO 2'd0
`define AS_T_STATE_WAIT  2'd1
`define AS_T_STATE_DATA  2'd2

`define AS_R_STATE_CMND 2'd0
`define AS_R_STATE_ADDR 2'd1
`define AS_R_STATE_DATA 2'd2

`define WB_M_STATE_CMND     1'b0
`define WB_M_STATE_RESPONSE 1'b1

module as_wb_bridge(
    clk, reset,
    as_data_i, as_data_o, 
    as_dstrb_o, as_busy_i, as_dstrb_i,
    wb_stb_o, wb_cyc_o, wb_we_o, wb_sel_o,
    wb_adr_o, wb_dat_o, wb_dat_i,
    wb_ack_i, wb_err_i
  );
  input  clk, reset;
  input  [7:0] as_data_i;
  output [7:0] as_data_o;
  output as_dstrb_o;
  input  as_busy_i,as_dstrb_i;
  output wb_stb_o, wb_cyc_o, wb_we_o;
  output  [1:0] wb_sel_o;
  output [31:0] wb_adr_o;
  output [15:0] wb_dat_o;
  input  [15:0] wb_dat_i;
  input  wb_ack_i, wb_err_i;

  /* Interaction Signals */
  reg as_command_strb;
  reg wb_response_strb;
  /* Common Registers */
  reg [15:0] as_data;
  reg [31:0] as_addr;
  reg [7:0]  as_cmnd;

  reg [15:0] wb_data;

  /************ AS Write Side **************/

  reg [1:0] as_t_state;
  reg [1:0] as_t_progress;
  reg as_t_wait;
  reg [7:0] as_data_o;
  reg as_dstrb_o;

  localparam DISABLE_HELLO = 1; //this was a dump idea

  always @(posedge clk) begin
    if (reset) begin
      if (DISABLE_HELLO) begin
        as_t_state<=`AS_T_STATE_WAIT;
      end else begin
        as_t_state<=`AS_T_STATE_HELLO;
      end
      as_dstrb_o<=1'b0;
      as_data_o<=8'b0;
      as_t_progress<=2'b0;
    end else begin
      as_dstrb_o<=1'b0;
      case (as_t_state) 
        `AS_T_STATE_HELLO: begin
          if (as_dstrb_o != 1'b1 && ~as_busy_i) begin
            as_dstrb_o<=1'b1;
            as_t_progress<=as_t_progress+1;
            case (as_t_progress)
              2'b00: begin
                as_data_o<="m";
              end
              2'b01: begin
                as_data_o<="o";
              end
              2'b10: begin
                as_data_o<="n";
              end
              2'b11: begin
                as_data_o<="\n";
                as_t_state<=`AS_T_STATE_WAIT;
              end
            endcase
          end
        end
        `AS_T_STATE_WAIT: begin
          if (wb_response_strb) begin
            as_t_state<=`AS_T_STATE_DATA;
            as_t_progress<=2'b00;
            as_t_wait<=1'b0;
`ifdef DEBUG
            $display("as_t: got wb strb - data=%x",wb_data);
`endif
          end
        end
        `AS_T_STATE_DATA: begin
          if (as_t_wait) begin
            as_t_wait<=~as_t_wait;
`ifdef DEBUG
            $display("as_t: progress = %d, as_data_o=%x",as_t_progress,as_data_o);
`endif
          end else if(~as_busy_i) begin
            as_dstrb_o<=1'b1;
            as_t_wait<=~as_t_wait;
            case (as_t_progress)
              2'b00: begin
                as_data_o<=wb_data[7:0];
                as_t_progress<=2'b01;
              end
              2'b01: begin
                as_data_o<=wb_data[15:8];
                as_t_progress<=2'b00;
                as_t_state<=`AS_T_STATE_WAIT;
              end
            endcase
          end
        end
      endcase
    end
  end

  /************* AS Read Side ************/

  reg [1:0] as_r_state;
  reg [9:0] as_r_progress;

  always @(posedge clk) begin
    // Strobes
    as_command_strb<=1'b0;
    if (reset) begin
      as_r_state<=`AS_R_STATE_CMND;
    end else begin
      case (as_r_state) 
        `AS_R_STATE_CMND: begin
          if (as_dstrb_i) begin
            case (as_data_i)
              `AS_CMND_READ: begin
                as_r_progress<=10'b0;
                as_r_state<=`AS_R_STATE_ADDR;
                as_cmnd<=`AS_CMND_READ;
              end
              `AS_CMND_WRITE: begin
                as_r_progress<=10'b0;
                as_r_state<=`AS_R_STATE_ADDR;
                as_cmnd<=`AS_CMND_WRITE;
              end
              `AS_CMND_NOP: begin
                as_r_state<=`AS_R_STATE_CMND;
              end
              default: begin
                as_r_state<=`AS_R_STATE_CMND;
              end
            endcase
          end
        end
        `AS_R_STATE_ADDR: begin
          if (as_dstrb_i) begin
            case (as_r_progress)
              10'd0: begin
                as_addr[7:0] <= as_data_i;
                as_r_progress<=10'b1;
              end
              10'd1: begin
                as_addr[15:8] <= as_data_i;
                as_r_progress<=10'd2;
              end
              10'd2: begin
                as_addr[23:16] <= as_data_i;
                as_r_progress<=10'd3;
              end
              10'd3: begin
                as_addr[31:24] <= as_data_i;
                if (as_cmnd == `AS_CMND_READ) begin
                  as_r_state<=`AS_R_STATE_CMND;
                  as_command_strb<=1'b1;//do it
                end else if (as_cmnd == `AS_CMND_WRITE) begin
                  as_r_state<=`AS_R_STATE_DATA;
                  as_r_progress<=10'b0;
                end else begin
                  as_r_state<=`AS_R_STATE_CMND;
                end
              end
              default: begin
                as_r_state<=`AS_R_STATE_CMND;
              end
            endcase
          end
        end
        `AS_R_STATE_DATA: begin
          if (as_dstrb_i) begin
            case (as_r_progress)
              10'd0: begin
                as_data[7:0] <= as_data_i;
                as_r_progress<=10'd1;
              end
              10'd1: begin
                as_data[15:8] <= as_data_i;
                as_r_state<=`AS_R_STATE_CMND;
                as_command_strb<=1'b1;//do it
              end
              default: begin
                as_r_state<=`AS_R_STATE_CMND;
              end
            endcase
          end
        end
      endcase
    end
  end

  /*************** WB_Master side ***************/

  reg wb_m_state;

  reg wb_cyc_o, wb_we_o;
  assign wb_stb_o = wb_cyc_o;
  reg [31:0] wb_adr_o;
  reg [15:0] wb_dat_o;
  assign wb_sel_o = 2'b11;

  always @(posedge clk) begin
    //strobes
    wb_cyc_o<=1'b0;
    if (reset) begin
      wb_m_state<=`WB_M_STATE_CMND;
      wb_response_strb<=1'b0;
    end else begin
      wb_response_strb<=1'b0;
      case (wb_m_state)
        `WB_M_STATE_CMND: begin
          if (as_command_strb) begin
            wb_cyc_o<=1'b1;
            wb_adr_o<=as_addr;
            wb_dat_o<=as_data;
            wb_m_state<=`WB_M_STATE_RESPONSE;
            if (as_cmnd == `AS_CMND_READ) begin
              wb_we_o<=1'b0;
`ifdef DEBUG
              $display("wb_m: sent read - addr = %x",as_addr);
`endif
            end else if (as_cmnd == `AS_CMND_WRITE) begin
              wb_we_o<=1'b1;
`ifdef DEBUG
              $display("wb_m: sent write - addr = %x data = %x",as_addr,as_data);
`endif
            end
          end
        end
        `WB_M_STATE_RESPONSE: begin
          if (wb_ack_i | wb_err_i) begin
            wb_m_state<=`WB_M_STATE_CMND;
            if (~wb_we_o) begin
              wb_data <= wb_dat_i;
              wb_response_strb<=1'b1;
`ifdef DEBUG
              $display("wb_m: got read response - data=%x",wb_dat_i);
`endif
            end else begin
`ifdef DEBUG
              $display("wb_m: got write response");
`endif
            end
          end
        end
      endcase
    end
  end
  
endmodule
