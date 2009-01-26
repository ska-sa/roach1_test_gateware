`timescale 1ns/10ps

module i2c_slave(
    clk, reset,
    sda_i, sda_o, scl_i, scl_o, sda_oen, scl_oen,
    as_data_i,  as_data_o, 
    as_dstrb_o, as_dstrb_i, as_busy_o, as_busy_i,
    i2c_cmnd_strb_o
  );
  parameter FREQ          = 100_000;
  parameter CLOCK_RATE    = 10_000_000;
  parameter [6:0] ADDRESS = 7'b0101010;

  localparam BIT_WIDTH    = ((CLOCK_RATE)/(FREQ));
  localparam BIT_WIDTH_10 = (BIT_WIDTH*10)/100;
  
  input clk;
  input reset;
  
  input  sda_i, scl_i;
  output sda_o, scl_o;
  output sda_oen, scl_oen; //active low
  input  [7:0] as_data_i;
  output [7:0] as_data_o;
  output as_dstrb_o;
  input  as_dstrb_i;
  output as_busy_o;
  input  as_busy_i;

  output i2c_cmnd_strb_o; //i2c_command_strb [could be used for special transactions]
  
  reg sda_oen;
  assign scl_oen = 1'b1; //leave clock alone
  assign sda_o   = 1'b0; //let oens do the work
  assign scl_o   = 1'b0;
  /************** Byte Interaction ***********/
  reg ostrb, istrb, cstrb;
  reg [7:0] odata;
  reg [7:0] idata;

  reg as_busy_reg;
  assign as_busy_o = as_busy_reg;

  always @(posedge clk) begin
    if (reset) begin
      as_busy_reg<=1'b0;
      odata<=8'b1010_0011;
    end else begin
      if (!as_busy_reg) begin
        if (as_dstrb_i) begin
          odata<=as_data_i;
          as_busy_reg<=1'b1;
        end
      end else begin
        if (ostrb) begin
          as_busy_reg<=1'b0;
          odata <= 8'b0; //clear the data
        end
      end
    end
  end
  assign i2c_cmnd_strb_o = cstrb;
  assign as_data_o  = idata;
  assign as_dstrb_o = istrb;

  /************** Debounce Inputs ************/
  localparam I2C_BACKOFF = 4'b0111;
  reg [3:0] sda_backoff;
  reg [3:0] scl_backoff;
  reg sda_i_reg;
  reg scl_i_reg;

  always @(posedge clk) begin
    if (reset) begin 
      sda_i_reg<=sda_i;
      scl_i_reg<=scl_i;
      sda_backoff<=4'b0;
      scl_backoff<=4'b0;
    end else begin
      if (sda_backoff != 4'b0) begin
        sda_backoff<=sda_backoff - 4'b1;
      end else if (sda_i != sda_i_reg) begin
        sda_i_reg<=sda_i;
        sda_backoff<=I2C_BACKOFF;
      end
      if (scl_backoff != 4'b0) begin
        scl_backoff<=scl_backoff - 4'b1;
      end else if (scl_i != scl_i_reg) begin
        scl_i_reg<=scl_i;
        scl_backoff<=I2C_BACKOFF;
      end
    end
  end

  /******************* Condition Detection ******************/

  reg sda_i_reg_prev;
  reg scl_i_reg_prev;
  always @(posedge clk) begin
    sda_i_reg_prev<=sda_i_reg;
    scl_i_reg_prev<=scl_i_reg;
  end

  wire posedge_scl =  scl_i_reg & (scl_i_reg != scl_i_reg_prev);
  wire negedge_scl = ~scl_i_reg & (scl_i_reg != scl_i_reg_prev);
  wire posedge_sda =  sda_i_reg & (sda_i_reg != sda_i_reg_prev);
  wire negedge_sda = ~sda_i_reg & (sda_i_reg != sda_i_reg_prev);

  wire start_con = negedge_sda & scl_i_reg;
  wire stop_con  = posedge_sda & scl_i_reg;

  reg busy;
  always @(posedge clk) begin
    if (reset) begin
      busy<=1'b0;
    end else begin
      if (start_con) begin
        busy<=1'b1;
      end else if (stop_con) begin
        busy<=1'b0;
      end
    end
  end

  /***************** Bit Control and State ***************************/
  // Common Signals 
  reg send_bit_strb;
  reg sent_bit_strb;
  reg obit;
  reg last;

  reg get_bit_strb;
  reg got_bit_strb;
  reg ibit;
  /******************* Bit Control *******************/
  localparam BIT_STATE_IDLE         = 4'd0;
  localparam BIT_STATE_CONTROL_READ = 4'd1;
  localparam BIT_STATE_CONTROL_PROC = 4'd2;
  localparam BIT_STATE_ACK_SEND     = 4'd3;
  localparam BIT_STATE_ACK_WAIT     = 4'd4;
  localparam BIT_STATE_WORD_SEND    = 4'd5;
  localparam BIT_STATE_WORD_WAIT    = 4'd6;
  localparam BIT_STATE_WORD_READ    = 4'd7;
  localparam BIT_STATE_WORD_PROC    = 4'd8;
  localparam BIT_STATE_ACK_READ     = 4'd9;
  localparam BIT_STATE_ACK_PROC     = 4'd10;
  /* TODO: introduce scheme to reduce state count */

  reg [3:0] bit_state;

  wire [6:0] address = idata[7:1];
  reg rw_n;
  reg [2:0] bit_index;

  always @(posedge clk) begin
    istrb<=1'b0;
    ostrb<=1'b0;
    cstrb<=1'b0;
    get_bit_strb  <= 1'b0;
    send_bit_strb <= 1'b0;
    if (reset | stop_con | start_con) begin
      bit_state <= BIT_STATE_CONTROL_READ;
      bit_index <= 3'b0;
    end else if (busy) begin
      case (bit_state)
        BIT_STATE_IDLE: begin
        end
        BIT_STATE_CONTROL_READ: begin
          get_bit_strb<=1'b1;
          bit_state<=BIT_STATE_CONTROL_PROC;
        end
        BIT_STATE_CONTROL_PROC: begin
          if (got_bit_strb) begin
            idata[3'b111 - bit_index]<=ibit;
            if (bit_index == 3'b111) begin
              rw_n<=ibit;
              if (address != ADDRESS) begin
                bit_state <= BIT_STATE_IDLE;
`ifdef DEBUG
                $display("i2c_s: addr mismatch, got %b, expected %b", address, ADDRESS);
`endif
              end else begin
                bit_state <= BIT_STATE_ACK_SEND;
`ifdef DEBUG
                $display("i2c_s: got control, addr = %b, rw_n = %b",address,ibit);
`endif
              end
            end else begin
              bit_index <= bit_index + 3'b1;
              bit_state <= BIT_STATE_CONTROL_READ;
            end
          end
        end
        BIT_STATE_ACK_SEND: begin
          send_bit_strb<=1'b1;
          obit<=1'b0;
          if (rw_n) begin
            last<=1'b0;
          end else begin
            last<=1'b1;
          end
          bit_state <= BIT_STATE_ACK_WAIT;
        end
        BIT_STATE_ACK_WAIT: begin
          if (sent_bit_strb) begin
            cstrb<=1'b1;
            bit_index<=3'b0;
            if (rw_n) begin
              bit_state <= BIT_STATE_WORD_SEND;
            end else begin
              bit_state <= BIT_STATE_WORD_READ;
            end
          end
        end
        BIT_STATE_WORD_READ: begin
          get_bit_strb<=1'b1;
          bit_state <= BIT_STATE_WORD_PROC;
        end
        BIT_STATE_WORD_PROC: begin
          if (got_bit_strb) begin
            idata[3'b111 - bit_index]<=ibit;
            if (bit_index == 3'b111) begin
              bit_state <= BIT_STATE_ACK_SEND;
              istrb<=1'b1;
            end else begin
              bit_state <= BIT_STATE_WORD_READ;
              bit_index <= bit_index + 3'b1;
            end
          end
        end
        BIT_STATE_WORD_SEND: begin
          obit<=odata[3'b111 - bit_index];
          send_bit_strb<=1'b1;
          if (bit_index == 3'b111) begin
            ostrb<=1'b1;
            last<=1'b1;
          end else begin
            last<=1'b0;
          end
          bit_state <= BIT_STATE_WORD_WAIT;
        end
        BIT_STATE_WORD_WAIT: begin
          if (sent_bit_strb) begin
            if (bit_index == 3'b111) begin
              bit_state <= BIT_STATE_ACK_READ;
            end else begin
              bit_state <= BIT_STATE_WORD_SEND;
              bit_index<=bit_index + 3'b1;
            end
          end
        end
        BIT_STATE_ACK_READ: begin
          get_bit_strb<=1'b1;
          bit_state <= BIT_STATE_ACK_PROC;
        end
        BIT_STATE_ACK_PROC: begin
          if (got_bit_strb) begin
            if (ibit == 1'b1) begin //not ACK [end of transfer]
              bit_state <= BIT_STATE_IDLE;
            end else begin
              bit_state <= BIT_STATE_WORD_SEND;
              bit_index<=3'b0;
            end
          end
        end
      endcase
    end
  end

  /***************** Bit Output and State **********************/
  localparam OBIT_STATE_IDLE = 2'd0;
  localparam OBIT_STATE_EDGE = 2'd1;
  localparam OBIT_STATE_WAIT = 2'd2;
  reg  [1:0] obit_state;
  reg [15:0] obit_counter;

  always @(posedge clk) begin
    if (reset | start_con | stop_con) begin
      obit_state<=OBIT_STATE_IDLE;
      obit_counter<=16'b0;
      sent_bit_strb<=1'b0;
      sda_oen<=1'b1;  //leave bus
    end else begin
      sent_bit_strb<=1'b0;
      case (obit_state)
        OBIT_STATE_IDLE: begin
          if (send_bit_strb) begin
            sda_oen<=obit; //send bit
            obit_state<=OBIT_STATE_EDGE;
          end else begin
            obit_counter<=16'b0;
          end
        end
        OBIT_STATE_EDGE: begin
          if (negedge_scl) begin
            obit_counter<=BIT_WIDTH_10;
            obit_state<=OBIT_STATE_WAIT;
          end
        end
        OBIT_STATE_WAIT: begin
          if (obit_counter != 16'b0) begin
            obit_counter<=obit_counter - 16'b1;
          end else begin
            sent_bit_strb<=1'b1;
            if (last) begin
              sda_oen<=1'b1; //give bus back
            end
            obit_state<=OBIT_STATE_IDLE;
          end
        end
      endcase
    end
  end
  /***************** Bit Input Control ***********************/
  localparam IBIT_STATE_IDLE  = 2'd0;
  localparam IBIT_STATE_FIND  = 2'd1;
  localparam IBIT_STATE_NFIND = 2'd2;
  localparam IBIT_STATE_WAIT  = 2'd3;
  reg  [1:0] ibit_state;
  reg [15:0] ibit_counter;

  always @(posedge clk) begin
    got_bit_strb<=1'b0;
    if (reset | start_con | stop_con) begin
      ibit_state<=IBIT_STATE_IDLE;
    end else begin
      case (ibit_state) 
        IBIT_STATE_IDLE: begin
          if (get_bit_strb) begin
            ibit_state<=IBIT_STATE_FIND;
          end
        end
        IBIT_STATE_FIND: begin
          if (posedge_scl) begin
            ibit_state<=IBIT_STATE_NFIND;
            ibit<=sda_i_reg;
          end
        end
        IBIT_STATE_NFIND: begin
          if (negedge_scl) begin
            ibit_counter<=BIT_WIDTH_10;
            ibit_state<=IBIT_STATE_WAIT;
          end
        end
        IBIT_STATE_WAIT: begin
          if (ibit_counter != 16'b0) begin
            ibit_counter<=ibit_counter - 16'b1;
          end else begin
            ibit_state<=IBIT_STATE_IDLE;
            got_bit_strb<=1'b1;
          end
        end
      endcase
    end
  end

endmodule
