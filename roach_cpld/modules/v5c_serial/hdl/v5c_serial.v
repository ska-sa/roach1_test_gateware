module v5c_serial(
    clk, reset,
    serial_boot_enable,
    serial_boot_busy,
    user_data, user_data_strb,
    user_rdy,
    v5c_mode,
    v5c_prog_n, v5c_init_n, v5c_done,
    v5c_din, v5c_cclk,
    abort
  );
  input  clk, reset;

  input  serial_boot_enable;
  output serial_boot_busy;

  input  [7:0] user_data;
  input  user_data_strb;
  output user_rdy;

  output [2:0] v5c_mode;
  output v5c_prog_n, v5c_init_n;
  input  v5c_done;
  output v5c_din, v5c_cclk;

  input abort;

  assign v5c_mode   = 3'b111; //serial slave mode
  assign v5c_init_n = 1'b1; //dont delay mode sampling

  reg v5c_prog_n, v5c_cclk;

  reg serial_boot_busy;
  reg sending_data;
  reg prog_n_sent;
  reg [2:0] data_index;

  assign v5c_din = user_data[data_index];

  assign user_rdy = !(!prog_n_sent || !serial_boot_busy || user_data_strb || sending_data && !(v5c_cclk == 1'b0 && data_index == 3'b111));
  /* the module tells the mmc that it is ready just before it clocks out the
   * last data byte so the mmc sends the next one without wasting a cycle */ 
/*  always @(*) begin
    $display("v5c_s: user_rdy = %b sending_data = %b data_index = %b", user_rdy, sending_data, data_index);
  end*/


  always @(posedge clk) begin
    //strobes
    v5c_prog_n <= 1'b1;

    if (reset) begin
      serial_boot_busy <= serial_boot_enable;
      v5c_cclk <= 1'b0;
      sending_data <= 1'b0;
      data_index <= 2'b0;
      prog_n_sent <= 1'b0;
    end else if (serial_boot_busy) begin
      if (v5c_done || abort) begin
        serial_boot_busy <= 1'b0;
      end

      if (~prog_n_sent) begin
        v5c_prog_n <= 1'b0;
        prog_n_sent <= 1'b1;
      end else begin
        if (v5c_cclk) begin
          v5c_cclk <= 1'b0;
          if (data_index == 3'b111) begin
            sending_data <= 1'b0;
            data_index <= 3'b0;
          end else begin
            data_index <= data_index + 1;
          end
        end else begin
          if (sending_data || user_data_strb) begin
            v5c_cclk <= 1'b1;
          end 
          if (user_data_strb) begin
            sending_data <= 1'b1;
          end
        end
      end
    end
  end

endmodule
