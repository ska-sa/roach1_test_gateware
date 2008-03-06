module mmc_ro(
    clk, reset,
    mmc_clk,
    mmc_cmd_o, mmc_cmd_i, mmc_cmd_oen,
    mmc_data_i,
    user_data_o, user_data_strb,
    user_rdy,
    boot_sel
  );
  input  clk, reset;

  output mmc_clk;

  output mmc_cmd_o;
  input  mmc_cmd_i;
  output mmc_cmd_oen; // active high

  input  [7:0] mmc_data_i;

  output [7:0] user_data_o;
  output user_data_strb;
  input  user_rdy;

  input  [1:0] boot_sel;

  
  reg mmc_clk; //control

  localparam CMD1  = { //Set OCR Reg
                      1'b0, 1'b1,    //Startbit, transmission bit
                      6'd1,          //CMD index
                      32'h80ff_8000, //OCR Reg
                      7'h57,         //CRC
                      1'b1           //Stop bit
                     };
  localparam CMD2  = { //Rqst CID
                      1'b0, 1'b1,    //Startbit, transmission bit
                      6'd2,          //CMD index
                      32'h0,         //Stuff bits
                      7'h26,         //CRC
                      1'b1           //Stop bit
                     };
  localparam CMD3  = { //set RCA
                      1'b0, 1'b1,    //Startbit, transmission bit
                      6'd3,          //CMD index
                      {16'd1, 16'h0},//RCA, stuff bits
                      7'h3f,         //CRC
                      1'b1           //Stop bit
                     };
  localparam CMD7  = { //Select Card
                      1'b0, 1'b1,    //Startbit, transmission bit
                      6'd7,          //CMD index
                      {16'd1, 16'h0},//RCA, stuff bits
                      7'h6e,         //CRC
                      1'b1           //Stop bit
                     };
  localparam CMD16 = { //Set block size
                      1'b0, 1'b1,    //Startbit, transmission bit
                      6'd16,         //CMD index
                      32'd3,         //Block size, 4 bytes
                      7'h07,         //CRC
                      1'b1           //Stop bit
                     };
  localparam CMD18_0 = { //Multiple block read -- no setup == for ever
                      1'b0, 1'b1,    //Startbit, transmission bit
                      6'd18,         //CMD index
                      32'h0000_0000, //Block size, 4 bytes
                      7'h1c,         //CRC
                      1'b1           //Stop bit
                     };
  localparam CMD18_1 = { //Multiple block read -- no setup == for ever
                      1'b0, 1'b1,    //Startbit, transmission bit
                      6'd18,         //CMD index
                      32'h00a0_0000, //Block size, 4 bytes
                      7'h6a,         //CRC
                      1'b1           //Stop bit
                     };
  localparam CMD18_2 = { //Multiple block read -- no setup == for ever
                      1'b0, 1'b1,    //Startbit, transmission bit
                      6'd18,         //CMD index
                      32'h0140_0000, //Block size, 4 bytes
                      7'h79,         //CRC
                      1'b1           //Stop bit
                     };
  localparam CMD18_3 = { //Multiple block read -- no setup == for ever
                      1'b0, 1'b1,    //Startbit, transmission bit
                      6'd18,         //CMD index
                      32'h01e0_0000, //Block size, 4 bytes
                      7'h0f,         //CRC
                      1'b1           //Stop bit
                     };

  reg [2:0] current_command;
  reg got_start;
  reg [7:0] cmd_index;
  reg cmd_sent;

  assign mmc_cmd_oen = ~cmd_sent;
  assign mmc_cmd_o = current_command == 3'd0 ? (cmd_sent ? 1'b1 :  CMD1[47 - cmd_index]) :
                     current_command == 3'd1 ? (cmd_sent ? 1'b1 :  CMD2[47 - cmd_index]) :
                     current_command == 3'd2 ? (cmd_sent ? 1'b1 :  CMD3[47 - cmd_index]) :
                     current_command == 3'd3 ? (cmd_sent ? 1'b1 :  CMD7[47 - cmd_index]) :
                     current_command == 3'd4 ? (cmd_sent ? 1'b1 : CMD16[47 - cmd_index]) :
                     boot_sel == 2'b00 ? (cmd_sent ? 1'b1 : CMD18_0[47 - cmd_index]) :
                     boot_sel == 2'b01 ? (cmd_sent ? 1'b1 : CMD18_1[47 - cmd_index]) :
                     boot_sel == 2'b10 ? (cmd_sent ? 1'b1 : CMD18_2[47 - cmd_index]) :
                                         (cmd_sent ? 1'b1 : CMD18_3[47 - cmd_index]);

`ifdef DEBUG
  always @* begin
    $display("cmd progress: %d %d %d", current_command, cmd_sent, cmd_index);
  end
`endif

  /************ Command / Response handling *****************/

  always @(posedge clk) begin
    if (reset) begin
      current_command <= 3'b0;
      got_start <= 1'b0;
      cmd_sent <= 1'b0;
      cmd_index <= 8'b0;
    end else if (mmc_clk) begin
      if (~cmd_sent) begin
        if (cmd_index == 8'd47) begin
          cmd_index <= 8'd0;
          cmd_sent <= 1'b1;
        end else begin
          cmd_index <= cmd_index + 1;
        end
      end else if (got_start) begin
        if (current_command == 3'b1 ? cmd_index == 8'd135 : cmd_index == 8'd47) begin
          cmd_index <= 8'd0;
          got_start <= 1'b0;
          cmd_sent <= 1'b0;
          current_command <= current_command + 1;
        end else if (current_command != 3'd5) begin
          cmd_index <= cmd_index + 1;
        end
      end else begin
        if (~mmc_cmd_i) begin
          got_start <= 1'b1;
        end
      end
    end
  end

  /************** Data Decode ****************/
  wire bus_hold;


  reg wait_crc;
  reg block_started;
  reg [1:0] data_index;

  assign user_data_o = mmc_data_i;
  assign user_data_strb = mmc_clk & ~wait_crc & block_started;

`ifdef DEBUG
  always @* begin
    $display("data progress: %d %d %d", block_started, data_index, wait_crc);
  end
`endif

  always @(posedge clk) begin
    if (reset) begin
      block_started<=1'b0;
      wait_crc <= 1'b0;
      data_index <= 8'b0;
    end else if (mmc_clk && current_command == 3'd5 && cmd_sent) begin
      if (wait_crc) begin
        wait_crc <= 1'b0;
        block_started <= 1'b0;
        data_index <= 8'b0;
      end else if (block_started) begin
        if (data_index == 2'b11) begin
          wait_crc <= 1'b1;
        end else begin
          data_index <= data_index + 1;
        end
      end else begin
        if (mmc_data_i == 8'b0) begin
          block_started <= 1'b1;
        end
      end
    end
  end

  /************** Clock Control *************/

  always @(posedge clk) begin
    if (reset) begin
      mmc_clk <= 1'b0;
    end else begin
      if (mmc_clk) begin
        mmc_clk <= 1'b0;
      end else if (user_rdy || (wait_crc || ~block_started)) begin //dont clock in/out data if user not ready and data transfer is pending
        mmc_clk <= 1'b1;
      end
    end
  end


endmodule
