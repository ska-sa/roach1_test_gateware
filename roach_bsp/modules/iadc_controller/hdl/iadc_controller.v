`include "iadc_controller.vh"

`timescale 1ns/10ps

module iadc_controller(
    /* Wishbone Interface */
    wb_clk_i, wb_rst_i,
    wb_cyc_i, wb_stb_i, wb_we_i, wb_sel_i,
    wb_adr_i, wb_dat_i, wb_dat_o,
    wb_ack_o,

    /* ADC inputs */
    adc_clk_0,
    adc_data,  // [ch 1:3, ch1:2, ch1:1, ch1:0, ch 0:3, ch0:2, ch0:1, ch0:0]
    adc_sync,
    adc_outofrange,

    /* ADC config bits */
    adc_ctrl_clk,
    adc_ctrl_data,
    adc_ctrl_strobe_n,
    adc_mode, //interleave mode config
    adc_ddrb, adc_dcm_reset
  );
  parameter ENABLE_DATA_BUFFER = 0;
  /* Wishbone Interface */
  input  wb_clk_i, wb_rst_i;
  input  wb_cyc_i, wb_stb_i, wb_we_i;
  input   [1:0] wb_sel_i;
  input  [31:0] wb_adr_i;
  input  [15:0] wb_dat_i;
  output [15:0] wb_dat_o;
  output wb_ack_o;

  /* ADC inputs */
  input adc_clk_0;
  input [63:0] adc_data;
  input  [3:0] adc_sync;
  input  [3:0] adc_outofrange;

  /* ADC config bits */
  output adc_ctrl_clk;
  output adc_ctrl_data;
  output adc_ctrl_strobe_n;
  output adc_mode;
  output adc_ddrb, adc_dcm_reset;

  /******************* Common Signals **********************/

  //direct adc ctrl pins
  reg adc_mode;
  reg adc_ddrb;

  //adc three wire interface registers
  reg [15:0] adc_twi_data;
  reg  [2:0] adc_twi_addr;
  reg adc_twi_tx_strb;

  //usr fifo control
  wire [71:0] fifo_rd_data;
  reg fifo_rd_strb;
  wire [3:0] fifo_status;
  reg fifo_enable;

  /******************  ADC0 CLK test ***********************/
  reg [31:0] adc_clk_counter;

  always @(posedge adc_clk_0) begin
    adc_clk_counter <= adc_clk_counter + 1;
  end

  /**************** Wishbone Attachment ********************/ 

  wire twi_xfer_busy;

  reg wb_ack_o;
  reg [3:0] wb_dat_src;
  assign wb_dat_o = wb_dat_src == `REG_IADC_RESET       ? {15'b0, adc_ddrb}           :
                    wb_dat_src == `REG_IADC_MODE        ? {15'b0, adc_mode}           :
                    wb_dat_src == `REG_IADC_TWI_ADDR    ? {13'b0, adc_twi_addr}       :
                    wb_dat_src == `REG_IADC_TWI_DATA    ? adc_twi_data                :
                    wb_dat_src == `REG_IADC_TWI_TX      ? {15'b0, twi_xfer_busy}      :
                    wb_dat_src == `REG_IADC_FIFODATA_4  ? {8'b0, fifo_rd_data[71:64]} :
                    wb_dat_src == `REG_IADC_FIFODATA_3  ? fifo_rd_data[63:48]         :
                    wb_dat_src == `REG_IADC_FIFODATA_2  ? fifo_rd_data[47:32]         :
                    wb_dat_src == `REG_IADC_FIFODATA_1  ? fifo_rd_data[31:16]         :
                    wb_dat_src == `REG_IADC_FIFODATA_0  ? fifo_rd_data[15:0]          :
                    wb_dat_src == `REG_IADC_FIFO_ADV    ? 16'b0                       :
                    wb_dat_src == `REG_IADC_FIFO_STATUS ? {12'b0, fifo_status}        :
                    wb_dat_src == `REG_IADC_FIFO_CTRL   ? {15'b0, fifo_enable}        :
                    wb_dat_src == `REG_IADC_CLKTEST1    ? adc_clk_counter[31:16]      :
                    wb_dat_src == `REG_IADC_CLKTEST0    ? adc_clk_counter[15:0]       :
                                                          16'b0;

  
  always @(posedge wb_clk_i) begin
    //strobes
    wb_ack_o        <= 1'b0;
    adc_twi_tx_strb <= 1'b0;
    fifo_rd_strb    <= 1'b0;
    adc_ddrb        <= 1'b0;

    if (wb_rst_i) begin
      adc_twi_data <= 16'b0;
      adc_twi_addr <= 3'b0;
      adc_mode     <= 1'b0;
      adc_ddrb     <= 1'b0;
      wb_dat_src   <= 4'b0;
      fifo_enable  <= 1'b0;
    end else begin
      if (wb_cyc_i & wb_stb_i & ~wb_ack_o) begin
        wb_ack_o <= 1'b1;
        wb_dat_src <= wb_adr_i[4:1];
        if (wb_we_i) begin
          case (wb_adr_i[4:1]) 
            `REG_IADC_RESET: begin
              if (wb_sel_i[0])
                adc_ddrb <= 1'b1; //strobe reset
            end
            `REG_IADC_MODE: begin
              if (wb_sel_i[0])
                adc_mode <= wb_dat_i[0];
            end
            `REG_IADC_TWI_ADDR: begin
              if (wb_sel_i[0])
                adc_twi_addr <= wb_dat_i[2:0];
            end
            `REG_IADC_TWI_DATA: begin
              if (wb_sel_i[1])
                adc_twi_data[15:8] <= wb_dat_i[15:8];
              if (wb_sel_i[0])
                adc_twi_data[7:0] <= wb_dat_i[7:0];
            end
            `REG_IADC_TWI_TX: begin
              if (wb_sel_i[0]) begin
                adc_twi_tx_strb <= 1'b1;
`ifdef DEBUG
                $display("iadc_controller: got adc_ctrl_tx command");
`endif
              end
            end
            `REG_IADC_FIFODATA_4: begin
            end
            `REG_IADC_FIFODATA_3: begin
            end
            `REG_IADC_FIFODATA_2: begin
            end
            `REG_IADC_FIFODATA_1: begin
            end
            `REG_IADC_FIFODATA_0: begin
            end
            `REG_IADC_FIFO_ADV: begin
              if (wb_sel_i[0]) begin
                fifo_rd_strb <= wb_dat_i[0]; //bit[0] high to enable strobe
              end
            end
            `REG_IADC_FIFO_STATUS: begin
            end
            `REG_IADC_FIFO_CTRL: begin
              if (wb_sel_i[0]) begin
                fifo_enable <= wb_dat_i[0];
              end
            end
          endcase
        end
      end
    end
  end

  reg [7:0] dcm_wait;
  assign adc_dcm_reset = dcm_wait != 8'd0;

  always @(posedge wb_clk_i) begin
    if (wb_rst_i) begin
      dcm_wait <= 8'd0;
    end else begin
      if (adc_ddrb) begin
        dcm_wait <= {8{1'b1}};
      end else if (dcm_wait) begin
        dcm_wait <= dcm_wait - 1;
      end
    end
  end

  /********** Three-wire Interface Control ************/
  //adc three wire interface registers
  reg  [6:0] clk_counter;
  reg [18:0] shift_register;

  reg  [2:0] xfer_state;
  localparam STATE_IDLE   = 0; //nothing being sent
  localparam STATE_WAIT   = 1; //waiting for clock negedge
  localparam STATE_STRB0  = 2; //1 cycle with strobe inactive
  localparam STATE_DATA   = 3; //19 cycles to xfer data
  localparam STATE_COMMIT = 4; //1 cycle for commit bit commit 
  localparam STATE_STRB1  = 5; //1 cycle for strb inactive
  localparam STATE_SWAIT  = 6; //wait one cycle with previous strobe actived

  reg  [4:0] xfer_progress;

  always @(posedge wb_clk_i) begin
    if (wb_rst_i) begin
      clk_counter    <= 7'b0;
    end else begin
      /* Let counter trickle over */
      if (clk_counter == 7'b111_1111) begin
        clk_counter <= 7'b0;
      end else begin
        clk_counter <= clk_counter + 1;
      end
    end
  end

  always @(posedge wb_clk_i) begin
    if (wb_rst_i) begin
      xfer_progress  <= 5'b0;
      shift_register <= 19'b0;
      xfer_state     <= STATE_IDLE;
    end else begin

      if (adc_twi_tx_strb && xfer_state == STATE_IDLE) begin //old transfers get pre
        shift_register <= {adc_twi_addr, adc_twi_data};
        xfer_state     <= STATE_WAIT;
        xfer_progress  <= 5'b0;
      end

      if (clk_counter == 7'b111_1111) begin //on negedge clk
        case (xfer_state)
          STATE_IDLE:   begin
          end
          STATE_WAIT:   begin
            xfer_state <= STATE_STRB0;
          end
          STATE_STRB0:  begin
            xfer_state <= STATE_DATA;
          end
          STATE_DATA:   begin
            shift_register <= {shift_register, 1'b0};
            xfer_progress  <= xfer_progress + 1;
            if (xfer_progress == 18) begin
              xfer_state <= STATE_COMMIT;
            end
          end
          STATE_COMMIT: begin
            xfer_state <= STATE_STRB1;
          end
          STATE_STRB1:  begin
            xfer_state <= STATE_SWAIT;
          end
          STATE_SWAIT:  begin
            xfer_state <= STATE_IDLE;
          end
        endcase
      end
    end
  end 

  assign twi_xfer_busy     = xfer_state != STATE_IDLE;

  assign adc_ctrl_clk      = xfer_state == STATE_IDLE || xfer_state == STATE_WAIT ? 1'b0 : clk_counter[6];
  assign adc_ctrl_strobe_n = !(xfer_state == STATE_DATA || xfer_state == STATE_COMMIT);
  assign adc_ctrl_data     = shift_register[18];

  /******************** ADC Fifo ***************************/

  /***** Register Data *****/


  reg [71:0] fifo_wr_data;

  reg fifo_enable_reg;

  always @(posedge adc_clk_0) begin
    fifo_wr_data <= {adc_sync, adc_outofrange, adc_data};
    //Cross [badly] over to adc_clk_0 domain
    fifo_enable_reg <= fifo_enable;
  end

  /**** Fifo Control ****/
  wire fifo_reset;

  reg prev_fifo_enable;
  always @(posedge wb_clk_i) begin
    prev_fifo_enable <= fifo_enable;
  end

  assign fifo_reset = fifo_enable != prev_fifo_enable && fifo_enable;

  /**** Fifo Instantiation ****/

  wire fifo_almost_empty, fifo_almost_full, fifo_empty, fifo_full;
  assign fifo_status = {fifo_full, fifo_almost_full, fifo_almost_empty, fifo_empty};

generate if (ENABLE_DATA_BUFFER) begin: fifo_gen

  fifo_72 fifo_72_inst(
    .din(fifo_wr_data),
    .wr_clk(adc_clk_0),
    .wr_en(fifo_enable_reg),

    .dout(fifo_rd_data),
    .rd_clk(wb_clk_i),
    .rd_en(fifo_rd_strb),

    .rst(fifo_reset | wb_rst_i),

    .almost_empty(fifo_almost_empty), .almost_full(fifo_almost_full),
    .empty(fifo_empty), .full(fifo_full)
  );
  //synthesis attribute box_type fifo_72_inst "black_box"

end endgenerate

endmodule
