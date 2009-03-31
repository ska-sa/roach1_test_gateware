`define TGE_REGISTERS_OFFSET   32'h0
`define TGE_REGISTERS_HIGH     32'h7FF
`define TGE_TX_BUFFER_OFFSET   32'h1000
`define TGE_TX_BUFFER_HIGH     32'h17FF
`define TGE_RX_BUFFER_OFFSET   32'h2000
`define TGE_RX_BUFFER_HIGH     32'h27FF
`define TGE_ARP_CACHE_OFFSET   32'h3000
`define TGE_ARP_CACHE_HIGH     32'h37FF

/* the first MAC half word is unused for compatibility */
`define TGE_REG_LOCAL_MAC_2    4'd1
`define TGE_REG_LOCAL_MAC_1    4'd2
`define TGE_REG_LOCAL_MAC_0    4'd3
/* the first GATEWAY half word is unused for compatibility */
`define TGE_REG_LOCAL_GATEWAY  4'd5
`define TGE_REG_LOCAL_IPADDR_1 4'd6
`define TGE_REG_LOCAL_IPADDR_0 4'd7
`define TGE_REG_CPU_TXSIZE     4'd8
`define TGE_REG_CPU_RXSIZE     4'd9
`define TGE_REG_LOCAL_VALID    4'd10
`define TGE_REG_LOCAL_UDP_PORT 4'd11
`define TGE_REG_XAUI_STATUS    4'd12
`define TGE_REG_MGT_CONFIG     4'd13

module wb_attach(
    wb_clk_i, wb_rst_i,
    wb_cyc_i, wb_stb_i, wb_we_i, wb_sel_i,
    wb_adr_i, wb_dat_i, wb_dat_o,
    wb_ack_o,
    //local configurtaion bits
    local_mac, local_ip, local_gateway, local_port, local_valid,
    //xaui status
    phy_status,
    //mgt config
    mgt_rxeqmix, mgt_rxeqpole, mgt_txpreemphasis, mgt_txdiffctrl,
    //tx_buffer bits
    tx_buffer_data_in, tx_buffer_address, tx_buffer_we, tx_buffer_data_out,
    tx_cpu_buffer_size, tx_cpu_free_buffer, tx_cpu_buffer_filled, tx_cpu_buffer_select,
    //rx_buffer bits
    rx_buffer_data_in, rx_buffer_address, rx_buffer_we, rx_buffer_data_out, 
    rx_cpu_buffer_size, rx_cpu_new_buffer, rx_cpu_buffer_cleared, rx_cpu_buffer_select,
    //ARP Cache
    arp_cache_data_in, arp_cache_address, arp_cache_we, arp_cache_data_out
  );
  parameter DEFAULT_FABRIC_MAC     = 48'hffff_ffff_ffff;
  parameter DEFAULT_FABRIC_IP      = {8'd255, 8'd255, 8'd255, 8'd255};
  parameter DEFAULT_FABRIC_GATEWAY = 8'hff;
  parameter DEFAULT_FABRIC_PORT    = 16'hffff;
  parameter FABRIC_RUN_ON_STARTUP  = 1;

  input  wb_clk_i, wb_rst_i;
  input  wb_cyc_i, wb_stb_i, wb_we_i;
  input   [1:0] wb_sel_i;
  input  [31:0] wb_adr_i;
  input  [15:0] wb_dat_i;
  output [15:0] wb_dat_o;
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
    //mgt config
  output  [1:0] mgt_rxeqmix;
  output  [3:0] mgt_rxeqpole;
  output  [2:0] mgt_txpreemphasis;
  output  [2:0] mgt_txdiffctrl;

  /* Registers */
  /* Wishbone registers */
  reg wb_ack_o;
  reg [3:0] wb_dat_o_src;

  /* register accessed via the WB i/f */
  reg [47:0] local_mac;
  reg [31:0] local_ip;
  reg  [7:0] local_gateway;
  reg [15:0] local_port;
  reg local_valid;
  reg  [1:0] mgt_rxeqmix;
  reg  [3:0] mgt_rxeqpole;
  reg  [2:0] mgt_txpreemphasis;
  reg  [2:0] mgt_txdiffctrl;

  /* register relating to tx and rx buffers */
  reg rx_cpu_buffer_cleared, rx_cpu_buffer_select_int;
  reg tx_cpu_buffer_filled, tx_cpu_buffer_select_int;
  reg [7:0] tx_size;
  reg [7:0] rx_size;
  reg [7:0] tx_cpu_buffer_size;
  reg tx_cpu_free_buffer_R, rx_cpu_new_buffer_R;

  /* select which output source to use for wishbone */
  reg use_arp_data, use_tx_data, use_rx_data;

  wire wb_trans = wb_stb_i & wb_cyc_i & ~wb_ack_o;

  /* Decode + translate input addresses */
  wire arp_cache_selected = wb_trans && (wb_adr_i >= (`TGE_ARP_CACHE_OFFSET) && wb_adr_i <= (`TGE_ARP_CACHE_HIGH)); 
  wire rx_buffer_selected = wb_trans && (wb_adr_i >= (`TGE_RX_BUFFER_OFFSET) && wb_adr_i <= (`TGE_RX_BUFFER_HIGH)); 
  wire tx_buffer_selected = wb_trans && (wb_adr_i >= (`TGE_TX_BUFFER_OFFSET) && wb_adr_i <= (`TGE_TX_BUFFER_HIGH)); 
  wire registers_selected = wb_trans && (wb_adr_i >= (`TGE_REGISTERS_OFFSET) && wb_adr_i <= (`TGE_REGISTERS_HIGH)); 

  wire [31:0] arp_cache_addr = wb_adr_i - (`TGE_ARP_CACHE_OFFSET);
  wire [31:0] rx_buffer_addr = wb_adr_i - (`TGE_RX_BUFFER_OFFSET);
  wire [31:0] tx_buffer_addr = wb_adr_i - (`TGE_TX_BUFFER_OFFSET);
  wire [31:0] registers_addr = wb_adr_i - (`TGE_REGISTERS_OFFSET);


  always @(posedge wb_clk_i) begin
    //strobes
    wb_ack_o <= 1'b0;
    use_arp_data <= 1'b0;
    use_tx_data  <= 1'b0;
    use_rx_data  <= 1'b0;

    if (wb_rst_i) begin
      tx_size <= 8'b0;
      rx_size <= 8'b0;
      rx_cpu_buffer_cleared <= 1'b0;
      tx_cpu_buffer_filled  <= 1'b0;
      tx_cpu_free_buffer_R <= 1'b0;
      rx_cpu_new_buffer_R  <= 1'b0;

      local_mac      <= DEFAULT_FABRIC_MAC;
      local_ip       <= DEFAULT_FABRIC_IP;
      local_gateway  <= DEFAULT_FABRIC_GATEWAY;
      local_port     <= DEFAULT_FABRIC_PORT;
      local_valid    <= FABRIC_RUN_ON_STARTUP;

      /* Sensible defaults for mgt config */
      mgt_rxeqmix        <= 2'b0;
      mgt_rxeqpole       <= 4'b0;
      mgt_txpreemphasis  <= 3'b111;
      mgt_txdiffctrl     <= 3'b100;
    end else begin
      tx_cpu_free_buffer_R <= tx_cpu_free_buffer;
      rx_cpu_new_buffer_R  <= rx_cpu_new_buffer;

      if (wb_trans)
        wb_ack_o<=1'b1;

      // RX Buffer control handshake
      if (!rx_cpu_buffer_cleared  && rx_cpu_new_buffer && !rx_cpu_new_buffer_R) begin
        rx_size <= rx_cpu_buffer_size;
        rx_cpu_buffer_select_int <= rx_cpu_buffer_select;
      end
      if (!rx_cpu_buffer_cleared && rx_cpu_new_buffer && rx_cpu_new_buffer_R && rx_size == 8'h00) begin
        rx_cpu_buffer_cleared <= 1'b1;
      end
      if (rx_cpu_buffer_cleared && !rx_cpu_new_buffer) begin
        rx_cpu_buffer_cleared <= 1'b0;
      end

      // TX Buffer control handshake
      if (!tx_cpu_buffer_filled && tx_cpu_free_buffer && !tx_cpu_free_buffer_R) begin
        tx_size <= 8'h00;
        tx_cpu_buffer_select_int <= tx_cpu_buffer_select;
      end
      if (!tx_cpu_buffer_filled && tx_cpu_free_buffer && tx_cpu_free_buffer_R && tx_size != 8'h0) begin
        tx_cpu_buffer_filled <= 1'b1;
        tx_cpu_buffer_size <= tx_size;
      end
      if (tx_cpu_buffer_filled && !tx_cpu_free_buffer) begin
        tx_cpu_buffer_filled <= 1'b0;
      end

  /* most of the work is done in the next always block in coverting 16 bit to 64 bit buffer
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
        wb_dat_o_src <= registers_addr[4:1];
        if (wb_we_i) begin
          case (registers_addr[4:1])
            `TGE_REG_LOCAL_MAC_2: begin
              if (wb_sel_i[0])
                local_mac[39:32] <= wb_dat_i[7:0];
              if (wb_sel_i[1])
                local_mac[47:40] <= wb_dat_i[15:8];
            end
            `TGE_REG_LOCAL_MAC_1: begin
              if (wb_sel_i[0])
                local_mac[23:16] <= wb_dat_i[7:0];
              if (wb_sel_i[1])
                local_mac[31:24] <= wb_dat_i[15:8];
            end
            `TGE_REG_LOCAL_MAC_0: begin
              if (wb_sel_i[0])
                local_mac[7:0]   <= wb_dat_i[7:0];
              if (wb_sel_i[1])
                local_mac[15:8]  <= wb_dat_i[15:8];
            end
            `TGE_REG_LOCAL_GATEWAY: begin
              if (wb_sel_i[0])
                local_gateway[7:0] <= wb_dat_i[7:0];
            end
            `TGE_REG_LOCAL_IPADDR_1: begin
              if (wb_sel_i[0])
                local_ip[23:16] <= wb_dat_i[7:0];
              if (wb_sel_i[1])
                local_ip[31:24] <= wb_dat_i[15:8];
            end
            `TGE_REG_LOCAL_IPADDR_0: begin
              if (wb_sel_i[0])
                local_ip[7:0]   <= wb_dat_i[7:0];
              if (wb_sel_i[1])
                local_ip[15:8]  <= wb_dat_i[15:8];
            end
            `TGE_REG_CPU_TXSIZE: begin
              if (wb_sel_i[0])
                tx_size <= wb_dat_i[7:0];
            end
            `TGE_REG_CPU_RXSIZE: begin
              if (wb_sel_i[0])
                rx_size <= wb_dat_i[7:0];
            end
            `TGE_REG_LOCAL_VALID: begin
              if (wb_sel_i[0])
                local_valid <= wb_dat_i[0];
            end
            `TGE_REG_LOCAL_UDP_PORT: begin
              if (wb_sel_i[0])
                local_port[7:0]   <= wb_dat_i[7:0];
              if (wb_sel_i[1])
                local_port[15:8]  <= wb_dat_i[15:8];
            end
            `TGE_REG_XAUI_STATUS: begin
            end
            `TGE_REG_MGT_CONFIG: begin
              if (wb_sel_i[0]) begin
                mgt_rxeqmix   <= wb_dat_i[1:0];
                mgt_rxeqpole  <= wb_dat_i[7:4];
              end 
              if (wb_sel_i[1]) begin
                mgt_txpreemphasis  <= wb_dat_i[10:8];
                mgt_txdiffctrl     <= wb_dat_i[14:12];
              end
            end
            default: begin
            end
          endcase
        end
      end
    end
  end

  reg arp_cache_we, rx_buffer_we, tx_buffer_we;

  reg [63:0] write_data; //write data for all three buffers

  always @(posedge wb_clk_i) begin
    //strobes
    arp_cache_we <= 1'b0;
    rx_buffer_we <= 1'b0;
    tx_buffer_we <= 1'b0;
    if (wb_rst_i) begin
    end else begin
      //populate write_data according to wishbone transaction info & contents
      //of memory
      if (arp_cache_selected & wb_we_i) begin
        arp_cache_we <= 1'b1;

        write_data[7:0]   <= arp_cache_addr[2:1] == 2'b11 & wb_sel_i[0] ? wb_dat_i[7:0]  : arp_cache_data_out[7:0]; 
        write_data[15:8]  <= arp_cache_addr[2:1] == 2'b11 & wb_sel_i[1] ? wb_dat_i[15:8] : arp_cache_data_out[15:8]; 
        write_data[23:16] <= arp_cache_addr[2:1] == 2'b10 & wb_sel_i[0] ? wb_dat_i[7:0]  : arp_cache_data_out[23:16]; 
        write_data[31:24] <= arp_cache_addr[2:1] == 2'b10 & wb_sel_i[1] ? wb_dat_i[15:8] : arp_cache_data_out[31:24]; 
        write_data[39:32] <= arp_cache_addr[2:1] == 2'b01 & wb_sel_i[0] ? wb_dat_i[7:0]  : arp_cache_data_out[39:32]; 
        write_data[47:40] <= arp_cache_addr[2:1] == 2'b01 & wb_sel_i[1] ? wb_dat_i[15:8] : arp_cache_data_out[47:40]; 
      end
      if (rx_buffer_selected & wb_we_i) begin
        rx_buffer_we <= 1'b1;

        write_data[7:0]   <= rx_buffer_addr[2:1] == 2'b11 & wb_sel_i[0] ? wb_dat_i[7:0]  : rx_buffer_data_out[7:0]; 
        write_data[15:8]  <= rx_buffer_addr[2:1] == 2'b11 & wb_sel_i[1] ? wb_dat_i[15:8] : rx_buffer_data_out[15:8]; 
        write_data[23:16] <= rx_buffer_addr[2:1] == 2'b10 & wb_sel_i[0] ? wb_dat_i[7:0]  : rx_buffer_data_out[23:16]; 
        write_data[31:24] <= rx_buffer_addr[2:1] == 2'b10 & wb_sel_i[1] ? wb_dat_i[15:8] : rx_buffer_data_out[31:24]; 
        write_data[39:32] <= rx_buffer_addr[2:1] == 2'b01 & wb_sel_i[0] ? wb_dat_i[7:0]  : rx_buffer_data_out[39:32]; 
        write_data[47:40] <= rx_buffer_addr[2:1] == 2'b01 & wb_sel_i[1] ? wb_dat_i[15:8] : rx_buffer_data_out[47:40]; 
        write_data[55:48] <= rx_buffer_addr[2:1] == 2'b00 & wb_sel_i[0] ? wb_dat_i[7:0]  : rx_buffer_data_out[55:48]; 
        write_data[63:56] <= rx_buffer_addr[2:1] == 2'b00 & wb_sel_i[1] ? wb_dat_i[15:8] : rx_buffer_data_out[63:56]; 
      end
      if (tx_buffer_selected & wb_we_i) begin
        tx_buffer_we <= 1'b1;

        write_data[7:0]   <= tx_buffer_addr[2:1] == 2'b11 & wb_sel_i[0] ? wb_dat_i[7:0]  : tx_buffer_data_out[7:0]; 
        write_data[15:8]  <= tx_buffer_addr[2:1] == 2'b11 & wb_sel_i[1] ? wb_dat_i[15:8] : tx_buffer_data_out[15:8]; 
        write_data[23:16] <= tx_buffer_addr[2:1] == 2'b10 & wb_sel_i[0] ? wb_dat_i[7:0]  : tx_buffer_data_out[23:16]; 
        write_data[31:24] <= tx_buffer_addr[2:1] == 2'b10 & wb_sel_i[1] ? wb_dat_i[15:8] : tx_buffer_data_out[31:24]; 
        write_data[39:32] <= tx_buffer_addr[2:1] == 2'b01 & wb_sel_i[0] ? wb_dat_i[7:0]  : tx_buffer_data_out[39:32]; 
        write_data[47:40] <= tx_buffer_addr[2:1] == 2'b01 & wb_sel_i[1] ? wb_dat_i[15:8] : tx_buffer_data_out[47:40]; 
        write_data[55:48] <= tx_buffer_addr[2:1] == 2'b00 & wb_sel_i[0] ? wb_dat_i[7:0]  : tx_buffer_data_out[55:48]; 
        write_data[63:56] <= tx_buffer_addr[2:1] == 2'b00 & wb_sel_i[1] ? wb_dat_i[15:8] : tx_buffer_data_out[63:56]; 
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

  wire [15:0] arp_data_int = arp_cache_addr[2:1] == 2'b11 ? arp_cache_data_out[15:0]  :
                             arp_cache_addr[2:1] == 2'b10 ? arp_cache_data_out[31:16] :
                             arp_cache_addr[2:1] == 2'b01 ? arp_cache_data_out[47:32] :
                                                            16'b0;

  wire [15:0] tx_data_int = tx_buffer_addr[2:1] == 2'b11 ? tx_buffer_data_out[15:0]  :
                            tx_buffer_addr[2:1] == 2'b10 ? tx_buffer_data_out[31:16] :
                            tx_buffer_addr[2:1] == 2'b01 ? tx_buffer_data_out[47:32] :
                                                           tx_buffer_data_out[63:48];

  wire [15:0] rx_data_int = rx_buffer_addr[2:1] == 2'b11 ? rx_buffer_data_out[15:0]  :
                            rx_buffer_addr[2:1] == 2'b10 ? rx_buffer_data_out[31:16] :
                            rx_buffer_addr[2:1] == 2'b01 ? rx_buffer_data_out[47:32] :
                                                           rx_buffer_data_out[63:48];

  wire [15:0] wb_data_int = wb_dat_o_src == `TGE_REG_LOCAL_MAC_2    ? local_mac[47:32]      :
                            wb_dat_o_src == `TGE_REG_LOCAL_MAC_1    ? local_mac[31:16]      :
                            wb_dat_o_src == `TGE_REG_LOCAL_MAC_0    ? local_mac[15:0]       :
                            wb_dat_o_src == `TGE_REG_LOCAL_GATEWAY  ? {8'b0, local_gateway} :
                            wb_dat_o_src == `TGE_REG_LOCAL_IPADDR_1 ? local_ip[31:16]       :
                            wb_dat_o_src == `TGE_REG_LOCAL_IPADDR_0 ? local_ip[15:0]        :
                            wb_dat_o_src == `TGE_REG_CPU_TXSIZE     ? {8'b0, tx_size}       :
                            wb_dat_o_src == `TGE_REG_CPU_RXSIZE     ? {8'b0, rx_size}       :
                            wb_dat_o_src == `TGE_REG_LOCAL_VALID    ? {15'b0, local_valid}  :
                            wb_dat_o_src == `TGE_REG_LOCAL_UDP_PORT ? local_port            :
                            wb_dat_o_src == `TGE_REG_XAUI_STATUS    ? {8'b0, phy_status}    :
                            wb_dat_o_src == `TGE_REG_MGT_CONFIG     ? {1'b0, mgt_txdiffctrl, 1'b0, mgt_txpreemphasis,
                                                                               mgt_rxeqpole, 2'b0, mgt_rxeqmix}    :
                                                                      16'b0;

  assign wb_dat_o = use_arp_data ? arp_data_int :
                    use_tx_data  ? tx_data_int  :
                    use_rx_data  ? rx_data_int  :
                                   wb_data_int;

endmodule
