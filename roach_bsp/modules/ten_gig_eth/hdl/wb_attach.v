/*
 * Berkeley TenGe
 * 
 * rewritten in verilog with a wishbone interface by David George
 *
 */
`define TGE_ARP_CACHE_OFFSET 16'h0
`define TGE_ARP_CACHE_HIGH   16'hFF
`define TGE_RX_BUFFER_OFFSET 16'h1000
`define TGE_RX_BUFFER_HIGH   16'h17FF
`define TGE_TX_BUFFER_OFFSET 16'h2000
`define TGE_TX_BUFFER_HIGH   16'h27FF
`define TGE_REGISTERS_OFFSET 16'h3000
`define TGE_REGISTERS_HIGH   16'h37FF

`define TGE_REG_LOCAL_MAC_HIGH 14'd0
`define TGE_REG_LOCAL_MAC_LOW  14'd1
`define TGE_REG_LOCAL_GATEWAY  14'd2  
`define TGE_REG_LOCAL_IP_ADDR  14'd3
`define TGE_REG_BUFFER_SIZES   14'd4
`define TGE_REG_UDP_VALID      14'd5
`define TGE_REG_XAUI_STATUS    14'd6
/*
-- register map :
--                63                                                             0
-- 0x00 -> 0x07 : 0000000000000000MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
--                                |<------------ local MAC address ------------->|

--                63                                                             0
-- 0x08 -> 0x0F : 000000000000000000000000GGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII
--                |<---- gateway IP address ---->||<----- local IP address ----->|

--                63                                                             0
-- 0x10 -> 0x17 : 00000000TTTTTTTT00000000RRRRRRRR000000000000000VPPPPPPPPPPPPPPPP
--                |<- tx size  ->||<- rx size  ->|  local_valid->||<- UDP port ->|
*/

module wb_attach(
  wb_clk_i, wb_rst_i,
  wb_cyc_i, wb_stb_i, wb_we_i, wb_sel_i,
  wb_adr_i, wb_dat_i, wb_dat_o,
  wb_ack_o,
  //local configurtaion bits
  local_mac, local_ip, local_gateway, local_port, local_valid,
  //xaui status
  phy_status,
  //tx_buffer bits
  tx_buffer_data_in, tx_buffer_address, tx_buffer_we, tx_buffer_data_out,
  tx_cpu_buffer_size, tx_cpu_free_buffer, tx_cpu_buffer_filled, tx_cpu_buffer_select,
  //rx_buffer bits
  rx_buffer_data_in, rx_buffer_address, rx_buffer_we, rx_buffer_data_out, 
  rx_cpu_buffer_size, rx_cpu_new_buffer, rx_cpu_buffer_cleared, rx_cpu_buffer_select,
  //ARP Cache
  arp_cache_data_in, arp_cache_address, arp_cache_we, arp_cache_data_out
  ,eof, we, my_status
  );

  input  wb_clk_i, wb_rst_i;
  input  wb_cyc_i, wb_stb_i, wb_we_i;
  input   [3:0] wb_sel_i;
  input  [15:0] wb_adr_i;
  input  [31:0] wb_dat_i;
  output [31:0] wb_dat_o;
  output wb_ack_o;
  //local configurtaion bits
  output [47:0] local_mac;
  output [31:0] local_ip;
  output  [7:0] local_gateway;
  output [15:0] local_port;
  output local_valid;
  //tx_buffer bits
  output [63:0] tx_buffer_data_in;
  output  [8:0] tx_buffer_address;
  output tx_buffer_we;
  input  [63:0] tx_buffer_data_out;
  output  [7:0] tx_cpu_buffer_size;
  input  tx_cpu_free_buffer;
  output tx_cpu_buffer_filled;
  input  tx_cpu_buffer_select;
  //rx_buffer bits
  output [63:0] rx_buffer_data_in;
  output  [8:0] rx_buffer_address;
  output rx_buffer_we;
  input  [63:0] rx_buffer_data_out;
  input   [7:0] rx_cpu_buffer_size;
  input  rx_cpu_new_buffer;
  output rx_cpu_buffer_cleared;
  input  rx_cpu_buffer_select;
  //ARP Cache
  output [47:0] arp_cache_data_in;
  output  [7:0] arp_cache_address;
  output arp_cache_we;
  input  [47:0] arp_cache_data_out;
  //xaui status
  input   [7:0] phy_status;
  input eof,we;
  input [31:0] my_status;

/* Registers */
  reg wb_ack_o;

  reg [31:0] conf_read_reg;

  reg [47:0] local_mac;
  reg [31:0] local_ip;
  reg  [7:0] local_gateway;
  reg [15:0] local_port;
  reg local_valid;

  reg rx_cpu_buffer_cleared, rx_cpu_buffer_select_int;
  reg tx_cpu_buffer_filled, tx_cpu_buffer_select_int;
  reg [7:0] tx_size;
  reg [7:0] rx_size;
  reg [7:0] tx_cpu_buffer_size;

  reg use_arp_data, use_tx_data, use_rx_data;

  reg tx_cpu_free_buffer_R, rx_cpu_new_buffer_R;

  wire wb_trans = wb_stb_i & wb_cyc_i & ~wb_ack_o;

  wire arp_cache_selected = wb_trans && (wb_adr_i >= `TGE_ARP_CACHE_OFFSET & wb_adr_i <= `TGE_ARP_CACHE_HIGH); 
  wire rx_buffer_selected = wb_trans && (wb_adr_i >= `TGE_RX_BUFFER_OFFSET & wb_adr_i <= `TGE_RX_BUFFER_HIGH); 
  wire tx_buffer_selected = wb_trans && (wb_adr_i >= `TGE_TX_BUFFER_OFFSET & wb_adr_i <= `TGE_TX_BUFFER_HIGH); 
  wire registers_selected = wb_trans && (wb_adr_i >= `TGE_REGISTERS_OFFSET & wb_adr_i <= `TGE_REGISTERS_HIGH); 

  wire [15:0] arp_cache_addr = wb_adr_i - (`TGE_ARP_CACHE_OFFSET);
  wire [15:0] rx_buffer_addr = wb_adr_i - (`TGE_RX_BUFFER_OFFSET);
  wire [15:0] tx_buffer_addr = wb_adr_i - (`TGE_TX_BUFFER_OFFSET);
  wire [15:0] registers_addr = wb_adr_i - (`TGE_REGISTERS_OFFSET);

  reg [31:0] we_cnt;
  reg [31:0] eof_cnt;

  always @(posedge wb_clk_i) begin
    if (wb_rst_i) begin
      wb_ack_o <= 1'b0;

      tx_size <= 8'b0;
      rx_size <= 8'b0;
      rx_cpu_buffer_cleared <= 1'b0;
      tx_cpu_buffer_filled  <= 1'b0;
      tx_cpu_free_buffer_R <= 1'b0;
      rx_cpu_new_buffer_R  <= 1'b0;
      local_mac<=48'h1234_1234_1234;
      local_ip<=32'hff_ff_ff_ff;
      local_gateway<=8'b0;
      local_port<=16'h1000;
      local_valid<=1'b1;
      we_cnt<=32'b0;
      eof_cnt<=32'b0;
    end else begin
      if (we) 
        we_cnt<=we_cnt+1;
      if (eof) 
        eof_cnt<=eof_cnt+1;
      wb_ack_o <= 1'b0;

      use_arp_data <= 1'b0;
      use_tx_data  <= 1'b0;
      use_rx_data  <= 1'b0;

      tx_cpu_free_buffer_R <= tx_cpu_free_buffer;
      rx_cpu_new_buffer_R  <= rx_cpu_new_buffer;

      if (wb_trans)
        wb_ack_o<=1'b1;

      // RX Buffer control handshake
      if (~rx_cpu_buffer_cleared  & rx_cpu_new_buffer & ~rx_cpu_new_buffer_R) begin
        rx_size <= rx_cpu_buffer_size;
        rx_cpu_buffer_select_int <= rx_cpu_buffer_select;
      end
      if (~rx_cpu_buffer_cleared & rx_cpu_new_buffer & rx_cpu_new_buffer_R & rx_size == 8'h00) begin
        rx_cpu_buffer_cleared <= 1'b1;
      end
      if (rx_cpu_buffer_cleared & ~rx_cpu_new_buffer) begin
        rx_cpu_buffer_cleared <= 1'b0;
      end

      // TX Buffer control handshake
      if (~tx_cpu_buffer_filled & tx_cpu_free_buffer & ~tx_cpu_free_buffer_R) begin
        tx_size <= 8'h00;
        tx_cpu_buffer_select_int <= tx_cpu_buffer_select;
      end
      if (~tx_cpu_buffer_filled & tx_cpu_free_buffer & tx_cpu_free_buffer_R & tx_size != 8'h0) begin
        tx_cpu_buffer_filled <= 1'b1;
        tx_cpu_buffer_size <= tx_size;
      end

  /* most of the work is done in the next always block in coverting 32 bit to 64 bit buffer
   * transactions */
      // ARP Cache
      if (arp_cache_selected) begin 
        if (wb_we_i) begin
        end else begin
          use_arp_data <= 1'b1;
        end
      end

      // RX Buffer 
      if (rx_buffer_selected) begin
        if (wb_we_i) begin
        end else begin
          use_rx_data <= 1'b1;
        end
      end

      // TX Buffer 
      if (tx_buffer_selected) begin
        if (wb_we_i) begin
        end else begin
          use_tx_data <= 1'b1;
        end
      end

      // registers
      if (registers_selected) begin
        if (wb_we_i) begin
          case (registers_addr[15:2])
            `TGE_REG_LOCAL_MAC_HIGH: begin
              if (wb_sel_i[0])
                local_mac[39:32] <= wb_dat_i[7:0];
              if (wb_sel_i[1])
                local_mac[47:40] <= wb_dat_i[15:8];
            end
            `TGE_REG_LOCAL_MAC_LOW: begin
              if (wb_sel_i[0])
                local_mac[7:0]   <= wb_dat_i[7:0];
              if (wb_sel_i[1])
                local_mac[15:8]  <= wb_dat_i[15:8];
              if (wb_sel_i[2])
                local_mac[23:16] <= wb_dat_i[23:16];
              if (wb_sel_i[3])
                local_mac[31:24] <= wb_dat_i[31:24];
            end
            `TGE_REG_LOCAL_GATEWAY: begin
              if (wb_sel_i[0])
                local_gateway[7:0] <= wb_dat_i[7:0];
            end
            `TGE_REG_LOCAL_IP_ADDR: begin
              if (wb_sel_i[0])
                local_ip[7:0]   <= wb_dat_i[7:0];
              if (wb_sel_i[1])
                local_ip[15:8]  <= wb_dat_i[15:8];
              if (wb_sel_i[2])
                local_ip[23:16] <= wb_dat_i[23:16];
              if (wb_sel_i[3])
                local_ip[31:24] <= wb_dat_i[31:24];
            end
            `TGE_REG_BUFFER_SIZES: begin
              if (wb_sel_i[0])
                rx_size <= wb_dat_i[7:0];

              if (wb_sel_i[2])
                tx_size <= wb_dat_i[23:16];
            end
            `TGE_REG_UDP_VALID: begin
              if (wb_sel_i[0])
                local_port[7:0]   <= wb_dat_i[7:0];
              if (wb_sel_i[1])
                local_port[15:8]  <= wb_dat_i[15:8];

              if (wb_sel_i[2])
                local_valid <= wb_dat_i[16];

            end
            default: begin
            end
          endcase
        end else begin
          case (registers_addr[15:2])
            `TGE_REG_LOCAL_MAC_HIGH: begin
              conf_read_reg <= {16'b0, local_mac[47:32]};
            end
            `TGE_REG_LOCAL_MAC_LOW: begin
              conf_read_reg <= local_mac[31:0];
            end
            `TGE_REG_LOCAL_GATEWAY: begin
              conf_read_reg <= {24'b0, local_gateway[7:0]};
            end
            `TGE_REG_LOCAL_IP_ADDR: begin
              conf_read_reg <= local_ip;
            end
            `TGE_REG_BUFFER_SIZES: begin
              conf_read_reg <= {8'b0, tx_size, 8'b0, rx_size};
            end
            `TGE_REG_UDP_VALID: begin
              conf_read_reg <= {15'b0, local_valid, local_port};
            end
            `TGE_REG_XAUI_STATUS: begin
              conf_read_reg <= {24'b0, phy_status};
            end
            (`TGE_REG_XAUI_STATUS + 1): begin
              conf_read_reg <= eof_cnt;
            end
            (`TGE_REG_XAUI_STATUS + 2): begin
              conf_read_reg <= we_cnt;
            end
            (`TGE_REG_XAUI_STATUS + 3): begin
              conf_read_reg <= my_status;
            end
            default: begin
              conf_read_reg <= 32'b0;
            end
          endcase
        end
      end
    end
  end

  reg arp_cache_we, rx_buffer_we, tx_buffer_we;

  reg [63:0] write_data; //write data for all three buffers

  always @(posedge wb_clk_i) begin
    if (wb_rst_i) begin
      arp_cache_we <= 1'b0;
      rx_buffer_we <= 1'b0;
      tx_buffer_we <= 1'b0;
    end else begin
      arp_cache_we <= 1'b0;
      rx_buffer_we <= 1'b0;
      tx_buffer_we <= 1'b0;
      //populate write_data according to wishbone transaction info & contents
      //of memory
      if (arp_cache_selected & wb_we_i) begin
        arp_cache_we <= 1'b1;
        if (arp_cache_addr[2]) begin
          if (wb_sel_i[0])
            write_data[7:0]   <= wb_dat_i[7:0];
          if (wb_sel_i[1])
            write_data[15:8]  <= wb_dat_i[15:8];
          if (wb_sel_i[2])
            write_data[23:16] <= wb_dat_i[23:16];
          if (wb_sel_i[3])
            write_data[31:24] <= wb_dat_i[31:24];

          write_data[39:32] <= arp_cache_data_out[39:32];
          write_data[47:40] <= arp_cache_data_out[47:40];
        end else begin
          write_data[7:0]   <= arp_cache_data_out[7:0];
          write_data[15:8]  <= arp_cache_data_out[15:8];
          write_data[23:16] <= arp_cache_data_out[23:16];
          write_data[31:24] <= arp_cache_data_out[31:24];

          if (wb_sel_i[0])
            write_data[39:32] <= wb_dat_i[7:0];
          if (wb_sel_i[1])
            write_data[47:40] <= wb_dat_i[15:8];
        end
      end
      if (rx_buffer_selected & wb_we_i) begin
        rx_buffer_we <= 1'b1;
        if (rx_buffer_addr[2]) begin
          if (wb_sel_i[0])
            write_data[7:0]   <= wb_dat_i[7:0];
          if (wb_sel_i[1])
            write_data[15:8]  <= wb_dat_i[15:8];
          if (wb_sel_i[2])
            write_data[23:16] <= wb_dat_i[23:16];
          if (wb_sel_i[3])
            write_data[31:24] <= wb_dat_i[31:24];

          write_data[39:32] <= rx_buffer_data_out[39:32];
          write_data[47:40] <= rx_buffer_data_out[47:40];
          write_data[55:48] <= rx_buffer_data_out[55:48];
          write_data[63:56] <= rx_buffer_data_out[63:56];
        end else begin
          write_data[7:0]   <= rx_buffer_data_out[7:0];
          write_data[15:8]  <= rx_buffer_data_out[15:8];
          write_data[23:16] <= rx_buffer_data_out[23:16];
          write_data[31:24] <= rx_buffer_data_out[31:24];

          if (wb_sel_i[0])
            write_data[39:32] <= wb_dat_i[7:0];
          if (wb_sel_i[1])
            write_data[47:40] <= wb_dat_i[15:8];
          if (wb_sel_i[2])
            write_data[55:48] <= wb_dat_i[23:16];
          if (wb_sel_i[3])
            write_data[63:56] <= wb_dat_i[31:24];
        end
      end
      if (tx_buffer_selected & wb_we_i) begin
        tx_buffer_we <= 1'b1;
        if (tx_buffer_addr[2]) begin
          write_data[39:32] <= tx_buffer_data_out[39:32];
          write_data[47:40] <= tx_buffer_data_out[47:40];
          write_data[55:48] <= tx_buffer_data_out[55:48];
          write_data[63:56] <= tx_buffer_data_out[63:56];
          if (wb_sel_i[0])
            write_data[7:0]   <= wb_dat_i[7:0];
          if (wb_sel_i[1])
            write_data[15:8]  <= wb_dat_i[15:8];
          if (wb_sel_i[2])
            write_data[23:16] <= wb_dat_i[23:16];
          if (wb_sel_i[3])
            write_data[31:24] <= wb_dat_i[31:24];
        end else begin
          write_data[7:0]   <= tx_buffer_data_out[7:0];
          write_data[15:8]  <= tx_buffer_data_out[15:8];
          write_data[23:16] <= tx_buffer_data_out[23:16];
          write_data[31:24] <= tx_buffer_data_out[31:24];
          if (wb_sel_i[0])
            write_data[39:32] <= wb_dat_i[7:0];
          if (wb_sel_i[1])
            write_data[47:40] <= wb_dat_i[15:8];
          if (wb_sel_i[2])
            write_data[55:48] <= wb_dat_i[23:16];
          if (wb_sel_i[3])
            write_data[63:56] <= wb_dat_i[31:24];
        end
      end
    end
  end

  assign arp_cache_address = arp_cache_addr[10:3];

  assign rx_buffer_address = {rx_cpu_buffer_select_int, rx_buffer_addr[10:3]};
  assign tx_buffer_address = {tx_cpu_buffer_select_int, tx_buffer_addr[10:3]};

  assign arp_cache_data_in = write_data[47:0];
  assign rx_buffer_data_in = write_data;
  assign tx_buffer_data_in = write_data;


// select what data to put on the bus

  assign wb_dat_o = use_arp_data ? (arp_cache_addr[2] ? arp_cache_data_out[31:0] : {18'b0, arp_cache_data_out[47:32]}) :
                    use_tx_data  ? (tx_buffer_addr[2] ? tx_buffer_data_out[31:0] : tx_buffer_data_out[63:32]) :
                    use_rx_data  ? (rx_buffer_addr[2] ? rx_buffer_data_out[31:0] : rx_buffer_data_out[63:32]) :
                                   conf_read_reg;
endmodule
