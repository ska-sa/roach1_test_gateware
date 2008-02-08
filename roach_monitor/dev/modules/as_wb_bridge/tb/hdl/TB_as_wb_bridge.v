module TB_as_wb_bridge();
  reg clk, reset;

  reg  s_busy;
  wire s_ostrb;
  reg  s_gotdata;
  reg  [7:0] s_data_i;
  wire [7:0] s_data_o; 

  wire wb_cyc_o, wb_stb_o, wb_we_o; 
  wire [15:0] wb_adr_o;
  wire [15:0] wb_dat_o;
  reg  [15:0] wb_dat_i;
  reg  wb_ack_i;
  
  as_wb_bridge as_wb_bridge(
    .clk(clk), .reset(reset),
    .as_data_i(s_data_i),.as_data_o(s_data_o),.as_dstrb_i(s_gotdata),.as_busy_i(s_busy),.as_dstrb_o(s_ostrb),
    .wb_stb_o(wb_stb_o), .wb_cyc_o(wb_cyc_o), .wb_we_o(wb_we_o),
    .wb_adr_o(wb_adr_o), .wb_dat_o(wb_dat_o), .wb_dat_i(wb_dat_i),
    .wb_ack_i(wb_ack_i), .wb_timeout(1'b0)
  );

  reg readback_command;
  reg got_something;

  initial begin
    readback_command<=1'b0;
    clk<=1'b0;
    got_something<=1'b0;
    reset<=1'b1;
`ifdef DEBUG
    $display("starting sim");
`endif
    #5 reset<=1'b0;
`ifdef DEBUG
    $display("clearing reset");
`endif
    #8000
    readback_command<=1'b1;
    #8000 
    if (~got_something) begin
      $display("FAILED: got nothing");
    end else
      $display("PASSED");
    $finish;

  end

  always begin
    #1 clk <=~clk;
  end

/*serial interface*/
  reg [2:0] serial_test_state;
  reg s_ostrb_fresh,readback_mode;
  reg [5:0] read_wait;
  reg [5:0] write_wait;
  reg [15:0] wr_addr;
  reg [15:0] wr_data;
/*delays for read/write: these are needed in the design.*/
`define SERIAL_READ_WAIT 6'd10 /*absolute minimum 7*/
`define SERIAL_WRITE_WAIT 6'd10 /*absolute minimum 7*/

`define S_STATE_COMMAND 3'd0
`define S_STATE_ADDRESS0 3'd1
`define S_STATE_ADDRESS1 3'd2
`define S_STATE_DATA0 3'd3
`define S_STATE_DATA1 3'd4

  always @ (posedge clk) begin
    if (reset) begin
      wr_addr<=16'hffff;
      s_ostrb_fresh<=1'b1;
      read_wait<=6'b0;
      write_wait<=6'b0;
      s_busy<=1'b0;
      s_gotdata<=1'b0;
      readback_mode<=1'b0;
      serial_test_state<=`S_STATE_COMMAND;
/*command 2xADDRESS READ/WRITE*/
    end else begin
      case (serial_test_state) 
	`S_STATE_COMMAND: begin
          if (~readback_mode & readback_command & write_wait == 6'b0) begin
            readback_mode<=1'b1;
            wr_addr<=16'hffff;
`ifdef DEBUG
	    $display("READBACK_MODE");
`endif
          end else begin
            if (!s_gotdata && write_wait == `SERIAL_WRITE_WAIT) begin
              s_data_i<=(readback_mode ? 8'b1 : 8'b10);          
              s_gotdata<=1'b1;
              wr_addr<=wr_addr+16'b1;
              wr_data<=wr_addr+16'b1;
`ifdef DEBUG 
              if (readback_mode)
                $display("serial read command");
	      else
                $display("serial write command");
`endif
            end else if (s_gotdata) begin
              write_wait<=6'b0;
              serial_test_state<=`S_STATE_ADDRESS0;
              s_gotdata<=1'b0;
            end else
              write_wait<=write_wait + 6'b1;
          end
        end
        `S_STATE_ADDRESS0: begin
          if (!s_gotdata && write_wait == `SERIAL_WRITE_WAIT) begin
            s_data_i<=wr_addr[7:0];          
            s_gotdata<=1'b1;
          end else if (s_gotdata) begin
            s_gotdata<=1'b0;
            serial_test_state<=`S_STATE_ADDRESS1;
            write_wait<=6'b0;
          end else
            write_wait<=write_wait + 6'b1;
        end
        `S_STATE_ADDRESS1: begin
          if (!s_gotdata && write_wait == `SERIAL_WRITE_WAIT) begin
            s_data_i<=wr_addr[15:8];          
            s_gotdata<=1'b1;
`ifdef DEBUG 
              $display("serial sent addr: %x",wr_addr);
`endif
          end else if (s_gotdata) begin
            write_wait<=6'b0;
            s_gotdata<=1'b0;
            serial_test_state<=`S_STATE_DATA0;
          end else
            write_wait<=write_wait + 6'b1;
        end
        `S_STATE_DATA0: begin
          if (~readback_mode) begin
            if (!s_gotdata && write_wait == `SERIAL_WRITE_WAIT) begin
              s_data_i<=wr_data[7:0];          
              s_gotdata<=1'b1;
            end else if (s_gotdata) begin
              s_gotdata<=1'b0;
              write_wait<=6'b0;
              serial_test_state<=`S_STATE_DATA1;
            end else
              write_wait<=write_wait + 6'b1;
          end else begin
            if (~s_ostrb & ~s_ostrb_fresh)
               s_ostrb_fresh<=1'b1;
            if (s_ostrb & s_ostrb_fresh) begin
              s_ostrb_fresh<=1'b0;
	      s_busy<=1'b1;
	      read_wait<=6'b0;
	      wr_data[7:0] <= s_data_o;
            end
            if (s_busy) begin
              if (read_wait==`SERIAL_READ_WAIT) begin
                read_wait<=6'b0;
                s_busy<=1'b0;
                serial_test_state<=`S_STATE_DATA1;
              end else begin
                read_wait<=read_wait + 6'b1;
              end
            end
          end
        end
        `S_STATE_DATA1: begin
           if (~readback_mode) begin
            if (!s_gotdata && write_wait == `SERIAL_WRITE_WAIT) begin
              s_data_i<=wr_data[15:8];          
`ifdef DEBUG 
              $display("serial wrote data: %x",wr_data);
`endif
              s_gotdata<=1'b1;
            end else if(s_gotdata) begin
              s_gotdata<=1'b0;
              write_wait<=6'b0;
              serial_test_state<=`S_STATE_COMMAND;
            end else
              write_wait<=write_wait + 6'b1;
          end else begin
            if (~s_ostrb & ~s_ostrb_fresh)
               s_ostrb_fresh<=1'b1;
            if (s_ostrb & s_ostrb_fresh) begin
              s_ostrb_fresh<=1'b0;
	      s_busy<=1'b1;
	      read_wait<=6'b0;
	      if ({s_data_o,wr_data[7:0]} == wr_addr) begin
	        got_something<=1'b1;
`ifdef DEBUG 
	        $display("serial got data: %x",{s_data_o,wr_data[7:0]});
`endif
	      end else begin
	        $display("FAILED: data mismatch");
	      end
            end
            if (s_busy) begin
              if (read_wait==`SERIAL_READ_WAIT) begin
                read_wait<=6'b0;
                s_busy<=1'b0;
                serial_test_state<=`S_STATE_COMMAND;
              end else begin
                read_wait<=read_wait + 6'b1;
              end
            end
          end
        end       
      endcase
    end
  end
  
  
  reg [15:0] mem_dump [65535:0];
/*bus element*/
  always @ (posedge clk) begin
    if (reset) begin
      wb_ack_i<=1'b0;
    end else begin
      wb_ack_i<=1'b0;
      if (wb_cyc_o & wb_stb_o & wb_we_o & ~wb_ack_i) begin
        mem_dump[wb_adr_o] <= wb_dat_o;
        wb_ack_i<=1'b1;
`ifdef DEBUG 
        $display("wbs: got write, addr: %x - data input: %x",wb_adr_o,wb_dat_o);
`endif
      end
      if (wb_cyc_o & wb_stb_o & ~wb_we_o & ~wb_ack_i) begin
        wb_dat_i<=mem_dump[wb_adr_o];
        wb_ack_i<=1'b1;
`ifdef DEBUG 
        $display("wbs: got read, addr: %x - data reply: %x",wb_adr_o,mem_dump[wb_adr_o]);
`endif
      end
    end
  end

endmodule

