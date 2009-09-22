module miic_ops #(
    IIC_FREQ  = 100,
    CORE_FREQ = 100000,
  ) (
    input        clk,
    input        rst,
    input        op_valid,
    input        op_start,
    input        op_stop,
    input        op_rnw,
    input  [7:0] op_wr_data,
    output [7:0] op_rd_data,
    output       op_ack,
    output       op_err,

    output       sda_o,
    input        sda_i,
    output       sda_t,

    output       scl_o,
    input        scl_i,
    output       scl_t
  );

  reg [2:0] iic_state;
  localparam IIC_IDLE  = 0;
  localparam IIC_START = 1;
  localparam IIC_RUN   = 2;
  localparam IIC_DATA  = 3;
  localparam IIC_STOP  = 4;

  wire send_start;
  wire send_stop;
  wire send_data;

  wire done_start;
  wire done_stop;
  wire done_data;

  /* Is this xfer a read or write ?*/
  reg trans_rnw;

  reg op_ack_reg;
  assign op_ack = op_ack_reg;

  always @(posedge clk) begin
    op_ack_reg <= 1'b0;

    if (rst) begin
      iic_state <= IIC_IDLE;
    end else begin
      case (iic_state)
        IIC_IDLE: begin
          if (op_valid && op_start) begin
            iic_state <= IIC_START;
          end else begin
            op_ack_reg <= 1'b1;
          end
        end
        IIC_START: begin
          if (done_start) begin
            iic_state <= IIC_DATA;
            trans_rnw <= op_rnw;
          end
        end
        IIC_RUN: begin
          if (op_valid && !op_ack_reg) begin
            if (op_start) begin
              iic_state <= IIC_START;
            end else begin
              iic_state <= IIC_DATA;
            end
          end
        end
        IIC_DATA: begin
          if (done_data) begin
            first_start <= 1'b0;

            if (op_stop) begin
              iic_state  <= IIC_STOP;
            end else begin
              op_ack_reg <= 1'b1;
              iic_state  <= IIC_RUN;
            end
          end
        end
        IIC_STOP: begin
          if (done_stop) begin
            op_ack_reg <= 1'b1;
            iic_state  <= IIC_IDLE;
          end
        end
      endcase
    end
  end

  assign send_start = iic_state == IIC_START;
  assign send_stop  = iic_state == IIC_STOP;
  assign send_data  = iic_state == IIC_DATA;

  /*********** 8 *************/

  reg sda_o_reg;
  reg op_err_reg;

  reg [7:0] op_rd_data_reg;

  reg [2:0] bit_state;
  reg BIT_IDLE  = 0;
  reg BIT_START = 1;
  reg BIT_STOP  = 2;
  reg BIT_DATA  = 3;
  reg BIT_ACK   = 4;

  reg bit_first;
  reg [2:0] bit_index;

  wire clk_pos;
  wire clk_neg;

  reg issue_full_clk;
  reg issue_half_clk;
  reg clk_pend;
  wire clk_done;

  always @(posedge clk) begin
    issue_full_clk <= 1'b0;
    issue_half_clk <= 1'b0;

    if (clk_done)
      clk_pend <= 1'b0;

    if (rst) begin
      bit_state <= BIT_IDLE;
      issue_full_clk <= 1'b0;
      clk_pend <= 1'b0;
      op_err_reg <= 1'b0;
    end else begin
      case (bit_state)
        BIT_IDLE: begin
          if (send_start) begin
            bit_state <= BIT_START;
          end
          if (send_stop) begin
            bit_state <= BIT_STOP;
          end
          if (send_data) begin
            bit_first <= 1'b1;
            bit_state <= BIT_DATA;
          end
        end
        BIT_START: begin
          if (!clk_pend) begin
            if (scl_i && sda_o_reg) begin
              sda_o_reg <= 1'b0;
              bit_state <= BIT_IDLE;
              issue_half_clk <= 1'b1; //ensure scl is '0'
            end
            if (scl_i && !sda_o_reg) begin
              issue_half_clk <= 1'b1;
              clk_pend <= 1'b1;
            end
            if (!scl_i) begin
              sda_o_reg <= 1'b1;
              issue_half_clk <= 1'b1;
            end
          end
        end
        BIT_STOP: begin
          if (!clk_pend) begin
            if (scl_i && !sda_o_reg) begin
              sda_o_reg <= 1'b1;
              bit_state <= BIT_IDLE;
            end
            if (scl_i && sda_o_reg) begin
              issue_half_clk <= 1'b1;
              clk_pend <= 1'b1;
            end
            if (!scl_i) begin
              sda_o_reg <= 1'b0;
              issue_half_clk <= 1'b1;
              clk_pend <= 1'b1;
            end
          end
        end
        BIT_DATA: begin
          if (!clk_pend) begin
            if (op_rnw) begin
              sda_o_reg <= 1'b0;
              bit_first <= 1'b0;
              if (bit_index != 3'b111) begin
                issue_full_clk <= 1'b1;
                clk_pend <= 1'b1;
              end else begin
                bit_state <= BIT_ACK;
              end

              if (!bit_first) begin
                bit_index <= bit_index + 1;
                op_rd_data[7 - bit_index] <= sda_i;
              end
            end

            if (!op_rnw) begin
              sda_o_reg <= op_wr_data[7 - bit_index];
              bit_index <= bit_index + 1;

              issue_full_clk <= 1'b1;
              clk_pend <= 1'b1;

              bit_index <= bit_index + 1;

              if (bit_index == 3'b111) begin
                bit_state <= BIT_ACK;
              end
            end
          end
        end
        BIT_ACK: begin
          if (!clk_pend) begin
            if (op_rnw) begin
              if (op_stop) begin
                sda_o_reg <= 1'b1; // Send no ack condition
              end else begin
                sda_o_reg <= 1'b0;
              end
              issue_full_clk <= 1'b1;
              bit_state <= BIT_IDLE;
            end
            if (!op_rnw) begin
              if (bit_first) begin
                issue_full_clk <= 1'b1;
              end else begin
                op_err_reg <= sda_i;
                bit_state <= BIT_IDLE;
              end
            end
          end
        end
      endcase
    end
  end

  /*********** ***********/

  assign sda_o = 1'b0; // Let the output enables do the work
  assign scl_o = 1'b0; // Let the output enables do the work


endmodule
