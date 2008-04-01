`timescale 1ns/10ps

`define CLK_PERIOD 10
`define SIM_LENGTH 10000

`define AS_CMND_NOP   8'd0
`define AS_CMND_READ  8'd1
`define AS_CMND_WRITE 8'd2

module TB_as_wb_bridge();
  reg  reset;
  wire clk;
  reg  [7:0] as_data_in;
  wire [7:0] as_data_out;
  wire as_ostrb;
  reg  as_busy,as_gotdata;
  wire wb_stb_o, wb_cyc_o, wb_we_o;
  wire [31:0] wb_adr_o;
  wire [15:0] wb_dat_o;
  reg  [15:0] wb_dat_i;
  reg wb_ack_i;

  as_wb_bridge as_wb_bridge(
  .clk(clk), .reset(reset),
  .as_data_i(as_data_in),.as_data_o(as_data_out),
  .as_dstrb_o(as_ostrb),.as_busy_i(as_busy),.as_dstrb_i(as_gotdata),
  .wb_stb_o(wb_stb_o), .wb_cyc_o(wb_cyc_o), .wb_we_o(wb_we_o),
  .wb_adr_o(wb_adr_o), .wb_dat_o(wb_dat_o), .wb_dat_i(wb_dat_i),
  .wb_ack_i(wb_ack_i)
  );

  reg [31:0] clk_counter;

  initial begin
    reset<=1'b1;
    clk_counter<=32'b0;
    #50
    reset<=1'b0;
    #`SIM_LENGTH
    $display("FAILED: simulation timed out");
    $finish;
  end

  assign clk=clk_counter < ((`CLK_PERIOD) / 2);

  always begin
    #1 clk_counter <= (clk_counter == `CLK_PERIOD - 1 ? 32'b0 : clk_counter + 1);
  end

  /********** AS Master ************/
  `define TEST_ADDR 32'hdead_beef
  `define TEST_DATA 16'hfeed

  `define AS_M_STATE_WRITE 1'b0
  `define AS_M_STATE_READ  1'b1

  reg as_m_state;
  reg [3:0] as_m_progress;

  reg [15:0] as_m_data;
  reg [31:0] as_m_addr;

  always @(posedge clk) begin
    if (reset) begin
      as_busy<=1'b0;
      as_m_state<=`AS_M_STATE_WRITE;
      as_m_progress<=4'b0;
      as_gotdata<=1'b0;
      as_m_data<=`TEST_DATA;
      as_m_addr<=`TEST_ADDR;
    end else begin
      case (as_m_state)
        `AS_M_STATE_WRITE: begin
          if (as_gotdata) begin
            as_gotdata<=1'b0;
          end else begin
            case (as_m_progress)
              4'd0: begin
                as_data_in<=`AS_CMND_WRITE;
                as_gotdata<=1'b1;
                as_m_progress<=4'd1;
              end
              4'd1: begin
                as_data_in<=as_m_addr[7:0];
                as_gotdata<=1'b1;
                as_m_progress<=4'd2;
              end
              4'd2: begin
                as_data_in<=as_m_addr[15:8];
                as_gotdata<=1'b1;
                as_m_progress<=4'd3;
              end
              4'd3: begin
                as_data_in<=as_m_addr[23:16];
                as_gotdata<=1'b1;
                as_m_progress<=4'd4;
              end
              4'd4: begin
                as_data_in<=as_m_addr[31:24];
                as_gotdata<=1'b1;
                as_m_progress<=4'd5;
              end
              4'd5: begin
                as_data_in<=as_m_data[7:0];
                as_gotdata<=1'b1;
                as_m_progress<=4'd6;
              end
              4'd6: begin
                as_data_in<=as_m_data[15:8];
                as_gotdata<=1'b1;
                as_m_state<=`AS_M_STATE_READ;
                as_m_progress<=4'b0;
              end
            endcase
          end
        end
        `AS_M_STATE_READ: begin
          case (as_m_progress)
            4'd0: begin
              as_data_in<=`AS_CMND_READ;
              if (~as_gotdata) begin
                as_gotdata<=1'b1;
                as_m_progress<=4'd1;
              end else begin
                as_gotdata<=1'b0;
              end
            end
            4'd1: begin
              as_data_in<=as_m_addr[7:0];
              if (~as_gotdata) begin
                as_gotdata<=1'b1;
                as_m_progress<=4'd2;
              end else begin
                as_gotdata<=1'b0;
              end
            end
            4'd2: begin
              as_data_in<=as_m_addr[15:8];
              if (~as_gotdata) begin
                as_gotdata<=1'b1;
                as_m_progress<=4'd3;
              end else begin
                as_gotdata<=1'b0;
              end
            end
            4'd3: begin
              as_data_in<=as_m_addr[23:16];
              if (~as_gotdata) begin
                as_gotdata<=1'b1;
                as_m_progress<=4'd4;
              end else begin
                as_gotdata<=1'b0;
              end
            end
            4'd4: begin
              as_data_in<=as_m_addr[31:24];
              if (~as_gotdata) begin
                as_gotdata<=1'b1;
                as_m_progress<=4'd5;
              end else begin
                as_gotdata<=1'b0;
              end
            end
            4'd5: begin
              if (as_busy) begin
                as_busy<=1'b0;
              end else begin
                if (as_ostrb) begin
                  as_busy<=1'b1;
                  as_m_data[7:0]<=as_data_out;
                  as_m_progress<=4'd6;
                end
              end
            end
            4'd6: begin
              if (as_busy) begin
                as_busy<=1'b0;
              end else begin
                if (as_ostrb) begin
                  as_busy<=1'b1;
                  as_m_data[15:8]<=as_data_out;
                  as_m_progress<=4'd7;
                end
              end
            end
            4'd7: begin
              /* FINISH HIM!!!!!!!!*/
              if (!(as_m_data === `TEST_DATA)) begin
                $display("FAILED: data mismatch - got = %x, expected = %x",as_m_data,`TEST_DATA);
                $finish;
              end else begin
                $display("PASSED");
                $finish;
              end
            end
          endcase
        end
      endcase
    end
  end

  /********** WB Slave *************/
  reg [15:0] memory [65535:0];
  
  always @(posedge clk) begin
    if (reset) begin
      wb_ack_i<=1'b0;
    end else begin
      wb_ack_i<=1'b0;
      if (wb_stb_o & wb_cyc_o) begin
        wb_ack_i<=1'b1;
        if (wb_we_o) begin
          memory[wb_adr_o%65536]<=wb_dat_o;
`ifdef DEBUG        
          $display("wb_s: got write - addr = %x, data = %x",wb_adr_o,wb_dat_o);
`endif
        end else begin
          wb_dat_i<=memory[wb_adr_o%65536];
`ifdef DEBUG        
          $display("wb_s: got read - addr = %x, data = %x",wb_adr_o,memory[wb_adr_o]);
`endif
        end
      end
    end
  end
endmodule
