module mem_rd_cache(
    clk, reset,
    rd_strb_i, rd_addr_i,
    rd_data_o, rd_ack_o,
    wr_strb_i, //write input to check coherence 
    
    ddr_addr_o, ddr_strb_o,
    ddr_data_i, ddr_dvalid_i,
    ddr_af_full_i
  );
  input  clk, reset;
  input  rd_strb_i;
  input   [32:0] rd_addr_i;
  //the 16-bit words that can be accessed on the entire ddr2 memory
  output  [15:0] rd_data_o;
  output rd_ack_o;
  // The ddr2 controller interface
  output  [30:0] ddr_addr_o;
  output ddr_strb_o;
  input  [127:0] ddr_data_i;
  input  ddr_dvalid_i;
  input  ddr_af_full_i; //TODO: should use this

  reg [30:0] cache_addr;

  localparam CACHE_WORDS = 4 * 4 * 2;
  reg [16 * CACHE_WORDS - 1:0] cache_data;

  reg first_loaded; //is a first value loaded
  reg second_loaded; //is a second value loaded

  /************ Continuous cache logic **************/
  function [4:0] cache_offset;
    input [32:0] target_addr;
    input [30:0] cache_addr;
    begin
      if (cache_addr > target_addr[32:2]) begin //miss low
        cache_offset = 5'b10000;
      end else if (target_addr[32:2] - cache_addr >= 8) begin //miss high
        cache_offset = 5'b10000;
      end else begin
        cache_offset = target_addr[32:2] - cache_addr;
      end
    end
  endfunction

  wire [4:0] cache_offset_int = cache_offset(rd_addr_i, cache_addr, second_loaded);

  wire cache_first_hit  = first_loaded  & ~cache_offset_int[4] & ~cache_offset_int[3];
  wire cache_second_hit = second_loaded & ~cache_offset_int[4] &  cache_offset_int[3];

  wire cache_hit = cache_first_hit | cache_second_hit;
  wire [3:0] cache_index = cache_offset_int[3:0];


  /***************** Output Assignments *******************/
  reg store_first_done; //this is asserted when requested data is retrieved after a cache miss

  assign rd_ack = cache_hit & rd_strb | store_first_done;

  //generate assignment of rd_data from cache data and cache index
  genvar gen_i;
  generate for (gen_i=0; gen_i < 15; gen_i=gen_i + 1)
    assign rd_data[i] = cache_data[cache_index*16 + gen_i];
  endgenerate

  /************** DDR2 memory store logic *****************/
  reg [1:0] store_state;
  localparam STORE_IDLE   = 2'd0;
  localparam STORE_FIRST  = 2'd1;
  localparam STORE_SECOND = 2'd2;

  reg progress;

  reg cache_miss_strb;
  reg cache_second_strb;

  always @(posedge clk) begin
    store_first_done <= 1'b0;
    if (reset) begin
      store_state <= STORE_IDLE;
      first_loaded <= 1'b0;
      second_loaded <= 1'b0;
    end else if (wr_strb_i & cache_hit) begin
      store_state <= STORE_IDLE;
      first_loaded <= 1'b0;
      second_loaded <= 1'b0;
    end else begin
      case (store_state)
        STORE_IDLE: begin
          progress <= 1'b0;
          if (cache_miss_strb) begin
            store_state <= STORE_FIRST;
          end else if (cache_second_strb) begin
            store_state <= STORE_SECOND;
            cache_data[16*CACHE_WORDS/2 - 1:0] <= cache_data[16*CACHE_WORDS - 1:16*CACHE_WORDS/2]; //shift the data along
            first_loaded <= 1'b1;
            second_loaded <= 1'b0;
          end
        end
        STORE_FIRST: begin
          if (ddr_dvalid_i) begin
            if (progress == 1'b0) begin
              cache_data[(1+0)*128 - 1:(0)*128] <= ddr_data_i;
              progress <= 1'b1;
            end else begin
              cache_data[(1+1)*128 - 1:(1)*128] <= ddr_data_i;
              progress <= 1'b0;
              first_loaded <= 1'b1;
              store_first_done <= 1'b1;
              store_state <= STORE_SECOND;
            end
          end
        end
        STORE_SECOND: begin
          if (progress == 1'b0) begin
             cache_data[(2+1)*128 - 1:(2)*128] <= ddr_data_i;
             progress <= 1'b1;
          end else begin
            cache_data[(3+1)*128 - 1:(3)*128] <= ddr_data_i;
            second_loaded <= 1'b1;
            store_state <= STORE_IDLE;
          end
        end
      endcase
    end
  end

  /************** DDR2 memory fetch logic *****************/
  reg [1:0] fetch_state;
  localparam FETCH_IDLE   = 2'd0;
  localparam FETCH_WAIT   = 2'd1;
  localparam FETCH_SECOND = 2'd2;

  reg ddr_addr_src;
  reg ddr_strb_o;

  assign ddr_addr_o = ddr_addr_src == 1'b0 ? rd_addr_i[32:2] : rd_addr_i[32:2] + 1;

  always @(posedge clk) begin
    ddr_strb_o        <= 1'b0;
    cache_miss_strb   <= 1'b0;
    cache_second_strb <= 1'b0;
    if (reset) begin
      fetch_state <= FETCH_IDLE;
      ddr_addr_src <= 1'b0;
    end else begin
      case(fetch_state)
        FETCH_IDLE: begin
          if (rd_strb && !cache_hit) begin
            //double cache miss, do a double fetch
            ddr_addr_src <= 1'b0;
            if (store_state == STORE_IDLE) begin
              ddr_strb_o <= 1'b1;
              cache_miss_strb <= 1'b1;
              cache_addr <= rd_addr_i[32:2]; //store the new address
              fetch_state <= FETCH_SECOND;
            end else begin
              fetch_state <= FETCH_WAIT;
            end
          end else if (rd_strb && cache_hit_second) begin
            ddr_addr_src <= 1'b1; // a single cache miss, fetch the second value
            if (store_state == STORE_IDLE) begin
              cache_second_strb <= 1'b1;
              ddr_strb_o <= 1'b1;
              cache_addr <= cache_addr + 4; //move the prefetch column into top of cache
              fetch_state <= FETCH_IDLE;
            end else begin
              fetch_state <= FETCH_WAIT;
            end
          end
        end
        FETCH_WAIT: begin
          if (store_state == STORE_IDLE) begin //when cache reads are done proceed
            if (ddr_addr_src) begin
              ddr_strb_o <= 1'b1;
              cache_miss_strb <= 1'b1;
              cache_addr <= rd_addr_i[32:2]; //store the new address
              fetch_state <= FETCH_IDLE;
            end else begin
              cache_second_strb <= 1'b1;
              cache_addr <= cache_addr + 4; //move the prefetch column into top of cache
              ddr_strb_o <= 1'b1;
              fetch_state <= FETCH_SECOND;
            end
          end
        end
        FETCH_SECOND: begin
          ddr_addr_src <= 1'b1; // the second in a double cache miss, fetch the second value
          ddr_strb_o <= 1'b1;
          fetch_state <= FETCH_IDLE;
        end
      endcase
    end
  end


endmodule

