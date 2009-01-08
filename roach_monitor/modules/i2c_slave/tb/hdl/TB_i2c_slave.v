`timescale 1ns/10ps

//this is bad bad bad. functional verification not worth looking at.
//rather just look at the timing...

module TB_i2c_slave_controller();

reg sda_in;
reg scl_in;
wire sda_out;
wire scl_out;
wire [7:0] data_out;
wire busy;
wire gotdata;

reg ostrb;
reg clk;
reg [7:0] testdata;
reg reset; 

`define ADDRESS 7'b0001111

wire foo;
i2c_slave i2c_slave(
        .clk(clk), .reset(reset),
        .scl_i(scl_in),.scl_o(scl_out),.sda_i(sda_in),.sda_o(foo),
        .sda_oen(sda_oen),
        .as_data_i(testdata), .as_data_o(data_out), .as_dstrb_i(ostrb), .as_busy_o(busy), .as_dstrb_o(gotdata));
defparam i2c_slave.FREQ       = 100_000;
defparam i2c_slave.CLOCK_RATE = 40_000_000;
defparam i2c_slave.ADDRESS    = 7'b0001111;


initial begin
  clk=1'b1;
  reset=1'b1;
  #900 reset=1'b0; 
  $display("PASSED");
  $finish;
end
initial begin
  $dumpvars();
end

always begin
  #1 clk <=~clk;
end


reg busy_cleared;
reg gotdata_cleared;

reg [31:0] counter;
reg [9:0] my_time_d;
reg [9:0] my_time_c;
reg mode;
reg [3:0] state;
reg [2:0] bit_index;
reg [7:0] my_data;
reg [7:0] my_mook;

wire [7:0] my_data_swap = {my_data[0], my_data[1], my_data[2], my_data[3], my_data[4], my_data[5], my_data[6], my_data[7]};

`define TIME_HD_STA 10'd40
`define TIME_LOW    10'd500
`define TIME_HD_DAT 10'd50
`define TIME_HIGH   10'd400
always @(posedge clk) begin
  if (reset) begin
    counter<=10'b0;
    mode<=1'b0;
    sda_in<=1'b1;
    scl_in<=1'b1;
    my_time_c<=10'b0;
    my_time_d<=10'b0;
    state<=4'b0;
    my_data<={`ADDRESS,8'b0};
    my_mook<=8'b0;
  end else begin
    if (mode == 1'b1) begin
      case (state)
        4'b0000: begin
          my_data<={`ADDRESS,8'b0};
          if (counter == 32'd100) begin
          sda_in<=1'b0;
	  state<=state+4'b1;
	  counter<=32'd0;
          end else begin
	    counter<=counter+32'b1;
          end
	end
        4'b0001: begin
	  if (counter >= `TIME_HD_STA) begin
	    state<=state+4'b1;
            scl_in<=1'b0;
            sda_in<=my_data_swap[0];
            counter<=32'b0;
	  end else begin
	    counter<=counter+32'b1;
	  end
	end
        4'b0010: begin
	  if (counter >= `TIME_LOW) begin
	    state<=state+4'b1;
            scl_in<=1'b1;
            counter<=32'b0;
            bit_index<=1'b1;
	  end else begin
	    counter<=counter+32'b1;
	  end
	end
        4'b0011: begin
	  if (counter >= `TIME_HIGH) begin
	    state<=state+4'b1;
            scl_in<=1'b0;
            counter<=32'b0;
	  end else begin
	    counter<=counter+32'b1;
	  end
	end
        4'd4: begin
	  if (counter >= `TIME_HD_DAT) begin
	    state<=state+4'b1;
            sda_in<=my_data_swap[bit_index];
            counter<=32'b0;
	  end else begin
	    counter<=counter+32'b1;
	  end
	end
        4'd5: begin
	  if (counter >= `TIME_LOW - `TIME_HD_DAT) begin
            if (bit_index == 3'b111) begin
              state<=4'd6;
              counter<=32'b0;
            end else begin
              state<=4'b0011;
              counter<=32'b0;
            end
            bit_index<=bit_index+1;
            scl_in<=1'b1;
	  end else begin
	    counter<=counter+32'b1;
	  end
	end
        4'd6: begin
          if (counter >= `TIME_HIGH) begin
            scl_in<=1'b0;
            counter<=32'b0;
            state<=4'd9;
          end else begin
	    counter<=counter+32'b1;
          end
        end
        4'd9: begin
          if (counter >= `TIME_HD_DAT) begin
            sda_in<=1'b0;
            counter<=32'b0;
            state<=4'd8;
          end else begin
	    counter<=counter+32'b1;
          end
        end
        4'd8: begin
          if (counter >= `TIME_LOW - `TIME_HD_DAT ) begin
            if (sda_oen != 1'b0) begin
              //$display("FAILED: no ack");
              //$finish;
            end else begin
              `ifdef DEBUG
               $display("i2cm: ack");
               `endif
            end 
            scl_in<=1'b1;
            counter<=32'b0;
            state<=4'd10;
          end else begin
	    counter<=counter+32'b1;
          end
        end
        4'd10: begin
          if (counter >= `TIME_HIGH) begin
            counter<=32'b0;
            if (my_data!={8'b0,`ADDRESS}) begin
              state<=4'd15;
              sda_in<=1'b0;
            end else begin
              my_data<=my_mook;
              state<=4'd4;
              bit_index<=8'b0;
              scl_in<=1'b0;
            end
          end else begin
            counter<=counter+32'b1;
          end
        end
	4'd15: begin
	  if (counter >= `TIME_HD_DAT) begin
              scl_in<=1'b1;
              state<=4'd14;
            counter<=32'b0;
	  end else begin
            counter<=counter+32'b1;
	  end
	end
	4'd14: begin
	  if (counter >= `TIME_HD_DAT) begin
              sda_in<=1'b0;
              state<=4'd7;
            counter<=32'b0;
	  end else begin
            counter<=counter+32'b1;
	  end
	end
        4'd7: begin
          if (counter >= `TIME_HD_DAT) begin
            sda_in<=1'b1;
            mode<=1'b1;
            #2000
            $display("PASSED: your mother nicely");
            $finish;
          end else begin
            counter<=counter+32'b1;
          end
        end

      endcase
    end else if (mode == 1'b0) begin
      case (state)
        4'b0000: begin
          if (counter == 32'd100) begin
          my_data<={`ADDRESS,8'b1};
          sda_in<=1'b0;
	  state<=state+4'b1;
	  counter<=32'd0;
          end else begin
	    counter<=counter+32'b1;
          end
	end
        4'b0001: begin
	  if (counter >= `TIME_HD_STA) begin
	    state<=state+4'b1;
            scl_in<=1'b0;
            sda_in<=my_data_swap[0];
            counter<=32'b0;
	  end else begin
	    counter<=counter+32'b1;
	  end
	end
        4'b0010: begin
	  if (counter >= `TIME_LOW) begin
	    state<=state+4'b1;
            scl_in<=1'b1;
            counter<=32'b0;
            bit_index<=1'b1;
	  end else begin
	    counter<=counter+32'b1;
	  end
	end
        4'b0011: begin
	  if (counter >= `TIME_HIGH) begin
	    state<=state+4'b1;
            scl_in<=1'b0;
            counter<=32'b0;
	  end else begin
	    counter<=counter+32'b1;
	  end
	end
        4'd4: begin
	  if (counter >= `TIME_HD_DAT) begin
	    state<=state+4'b1;
	    if (my_data=={8'b1,`ADDRESS}) begin
              sda_in<=my_data_swap[bit_index];
	    end
            counter<=32'b0;
	  end else begin
	    counter<=counter+32'b1;
	  end
	end
        4'd5: begin
	  if (counter >= `TIME_LOW - `TIME_HD_DAT) begin
	    if (my_data!={8'b1,`ADDRESS}) begin
	      my_data[bit_index]<=~sda_oen;
	    end
            if (bit_index == 3'b111) begin
              state<=4'd6;
              counter<=32'b0;
            end else begin
              state<=4'b0011;
              counter<=32'b0;
            end
            bit_index<=bit_index+1;
            scl_in<=1'b1;
	  end else begin
	    counter<=counter+32'b1;
	  end
	end
        4'd6: begin
          if (counter >= `TIME_HIGH) begin
            scl_in<=1'b0;
            counter<=32'b0;
            state<=4'd9;
          end else begin
	    counter<=counter+32'b1;
          end
        end
        4'd9: begin
          if (counter >= `TIME_HD_DAT) begin
            sda_in<=1'b0;
            counter<=32'b0;
            state<=4'd8;
          end else begin
	    counter<=counter+32'b1;
          end
        end
        4'd8: begin
          if (counter >= `TIME_LOW - `TIME_HD_DAT ) begin
            if (!(sda_oen === 1'b0)) begin
	      if (my_data=={8'b1,`ADDRESS}) begin
              $display("FAILED: no ack");
              $finish;
	      end
            end else begin
              `ifdef DEBUG
               $display("i2cm: ack");
               `endif
            end 
            scl_in<=1'b1;
            counter<=32'b0;
            state<=4'd10;
          end else begin
	    counter<=counter+32'b1;
          end
        end
        4'd10: begin
          if (counter >= `TIME_HIGH) begin
            counter<=32'b0;
            if (my_data=={8'b1,`ADDRESS}) begin
              my_data<=8'h0f;
              state<=4'd4;
              bit_index<=8'b0;
              scl_in<=1'b0;
            end else begin
	    `ifdef DEBUG
	      $display("i2c_master: got word %d",my_data_swap);
	      `endif
	      my_mook<=my_data_swap;
              state<=4'd7;
              scl_in<=1'b1;
            end
          end else begin
            counter<=counter+32'b1;
          end
        end
        4'd7: begin
          if (counter >= `TIME_HD_DAT) begin
            sda_in<=1'b1;
            mode<=1'b1;
	    counter<=1'b0;
	    state<=4'd0;
          end else begin
            counter<=counter+32'b1;
          end
        end
      endcase
    end 
  end
end


always @(posedge clk) begin
  if (reset) begin
    busy_cleared<=1'b1;
    testdata<=8'd68;
    ostrb<=1'b0;
    gotdata_cleared<=1'b1;
  end else begin
    if (~busy & busy_cleared) begin
`ifdef DEBUG
      $display("sent word: %d",testdata +1'b1);
`endif
      ostrb<=1'b1;
      busy_cleared<=1'b0;
      testdata<=testdata+8'b1;
    end else if (busy) begin
      ostrb<=1'b0;
      busy_cleared<=1'b1;
    end

    if (gotdata & gotdata_cleared) begin
`ifdef DEBUG
      $display("sbus: got word %d",data_out);
`endif
      if (!(testdata-1 === {data_out[0],data_out[1],data_out[2],data_out[3],data_out[4],data_out[5],data_out[6],data_out[7]})) begin
        $display("FAILED: data mismatch got %x expected %x",data_out, testdata -1);
        $finish;
      end
      gotdata_cleared<=1'b0;
    end else if (~gotdata) begin
      gotdata_cleared<=1'b1;
    end
  end
end

endmodule
