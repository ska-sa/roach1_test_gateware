`include "FIFO.v"
module TB_as_wb_bridge();

  localparam TEST_LENGTH = 32;

  reg clk, reset;

  reg  [7:0] as_data_i;
  wire [7:0] as_data_o;
  reg  as_dstrb_i;
  wire as_busy_i;
  wire as_busy_o; 
  wire as_dstrb_o;

  wire wb_cyc_o, wb_stb_o, wb_we_o; 
  wire [15:0] wb_adr_o;
  wire [15:0] wb_dat_o;
  reg  [15:0] wb_dat_i;
  reg  wb_ack_i;

  as_wb_bridge #(
    .USE_INPUT_FIFO  (1),
    .USE_OUTPUT_FIFO (1)
  ) as_wb_bridge_inst (
    .clk   (clk),
    .reset (reset),

    .as_data_i  (as_data_i), 
    .as_data_o  (as_data_o),
    .as_dstrb_i (as_dstrb_i),
    .as_busy_i  (as_busy_i),
    .as_busy_o  (as_busy_o),
    .as_dstrb_o (as_dstrb_o),

    .wb_stb_o(wb_stb_o), .wb_cyc_o(wb_cyc_o), .wb_we_o(wb_we_o),
    .wb_adr_o(wb_adr_o), .wb_dat_o(wb_dat_o), .wb_dat_i(wb_dat_i),
    .wb_ack_i(wb_ack_i), .wb_err_i(1'b0)
  );

  reg readback_command;
  reg got_something;

  initial begin
    $dumpvars;
    clk<=1'b0;
    reset<=1'b1;
    #5 reset<=1'b0;
`ifdef DEBUG
    $display("sim: clearing reset");
`endif
    #80000
    $display("FAILED: simulation timed out");
    $finish;
  end

  always begin
    #1 clk <=~clk;
  end

  /* Mode Control */

  reg mode;
  localparam MODE_WRITE = 1'b0;
  localparam MODE_READ  = 1'b1;

  wire [1:0] mode_done;

  reg [15:0] mode_mem [TEST_LENGTH-1:0];

  reg [31:0] write_acks;

  integer i;

  always @ (posedge clk) begin
    if (reset) begin
      mode <= MODE_WRITE;
    end else begin
      case (mode)
        MODE_WRITE: begin
          if (mode_done[MODE_WRITE]) begin
            mode <= MODE_READ;
`ifdef DEBUG
            $display("mode: MODE_WRITE passed");
`endif
          end
        end
        MODE_READ: begin
          if (mode_done[MODE_READ]) begin
            for (i = 0; i < TEST_LENGTH; i=i+1) begin
              if (mode_mem[i] !== ~(i[15:0]))  begin
                $display("FAILED: data mismatch - got %x, expected %x", mode_mem[i], ~(i[15:0]));
                $finish;
              end
            end
            $display("PASSED");
            $finish;
          end
        end
      endcase
    end
  end

  /* Serial Write */

  reg  [2:0] write_state;
  reg [31:0] write_progress;
  reg [31:0] read_progress;

  always @(*) begin
    if (mode == MODE_WRITE) begin
      as_dstrb_i <= write_progress < TEST_LENGTH;
    end
    if (mode == MODE_READ) begin
      as_dstrb_i <= read_progress < TEST_LENGTH;
    end
    case (write_state)
      0: begin
        if (mode == MODE_WRITE) begin
          as_data_i <= 8'd2;
        end
        if (mode == MODE_READ) begin
          as_data_i <= 8'd1;
        end
      end
      1: begin
        if (mode == MODE_READ) begin
          as_data_i <= read_progress[7:0];
        end else begin
          as_data_i <= write_progress[7:0];
        end
      end
      2: begin
        if (mode == MODE_READ) begin
          as_data_i <= read_progress[15:8];
        end else begin
          as_data_i <= write_progress[15:8];
        end
      end
      3: begin
        as_data_i <= ~write_progress[7:0];
      end
      4: begin
        as_data_i <= ~write_progress[15:8];
      end
      default: begin
      end
    endcase
  end

  always @(posedge clk) begin
    if (reset) begin
      read_progress  <= 32'd0;
      write_progress <= 32'd0;
      write_state    <=  3'd0;
    end else begin

      /* issue write commands over as interface */
      if (mode == MODE_WRITE && !as_busy_o) begin

        case (write_state)
          3'd0: begin
            if (write_progress < TEST_LENGTH) begin
              write_state <= 3'd1;
            end
          end
          3'd1: begin
            write_state <= 3'd2;
          end
          3'd2: begin
            write_state <= 3'd3;
          end
          3'd3: begin
            write_state <= 3'd4;
          end
          3'd4: begin
            write_state <= 3'd0;
            write_progress <= write_progress + 1;
          end
        endcase
      end
      /* issue write commands over as interface */
      if (mode == MODE_READ && !as_busy_o) begin

        case (write_state)
          3'd0: begin
            if (read_progress < TEST_LENGTH) begin
              write_state <= 3'd1;
            end
          end
          3'd1: begin
            write_state <= 3'd2;
          end
          3'd2: begin
            read_progress <= read_progress + 1;
            write_state   <= 3'd0;
          end
        endcase
      end
    end
  end

  /* Serial Read */

  reg [3:0] busy_timer;

  reg [1:0] read_state;

  reg  [7:0] read_buff;
  reg [31:0] s_read_progress;

  /* */

  always @(posedge clk) begin
    if (reset) begin
      busy_timer <= 3'b0;
      write_acks <= 32'd0;
      read_state <= 2'b0;
      s_read_progress <= 32'b0;
    end else begin
      if (busy_timer) begin
        busy_timer <= busy_timer - 1;
      end else begin
        if (as_dstrb_o && mode == MODE_WRITE) begin
          if (as_data_o === 8'd1) begin
            write_acks <= write_acks + 1;
`ifdef DEBUG
            $display("serial_read: got ack in MODE_WRITE");
`endif
          end else begin
            $display("ERROR: expected ack (%x) in write mode, got %x", 8'h1, as_data_o);
            $finish;
          end
        end

        if (as_dstrb_o && mode == MODE_READ) begin
          case (read_state)
            0: begin
              if (as_data_o === 8'd1) begin
                read_state <= 2'd1;
`ifdef DEBUG
                $display("serial_read: got ack in MODE_READ");
`endif
              end else begin
                $display("ERROR: expected ack (%x) in write mode, got %x", 8'h1, as_data_o);
                $finish;
              end
            end
            1: begin
              read_buff  <= as_data_o;
              read_state <= 2'd2;
            end
            2: begin
              read_state <= 2'd0;
              mode_mem[s_read_progress] <= {as_data_o, read_buff};
              s_read_progress <= s_read_progress + 1;
`ifdef DEBUG
              $display("serial_read: got read - data = %x", {as_data_o, read_buff});
`endif
            end
          endcase
        end
      end
    end
  end
  assign as_busy_i = busy_timer != 0;
  assign mode_done[MODE_READ]  = read_state == 2'd0 && s_read_progress == TEST_LENGTH;
  assign mode_done[MODE_WRITE] = as_dstrb_o && mode == MODE_WRITE && as_data_o == 8'd1 && write_acks == TEST_LENGTH - 1;
  /* */
  
  /* WishBone Slave */
  
  reg [15:0] mem_dump [TEST_LENGTH-1:0];

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

