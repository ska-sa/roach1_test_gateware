/* This test bench runs through 'all' the states associated with the power
 * manager.*/

`timescale 1ns/10ps
`include "memlayout.v"

`define TB_STATE_WRITE 3'd0
`define TB_STATE_WAITW 3'd1
`define TB_STATE_READ 3'd2
`define TB_STATE_WAITR 3'd3
`define TB_STATE_IDLE 3'd4

`define TEST_MODE_NOP 5'd0
`define TEST_MODE_WRITE 5'd1
`define TEST_MODE_READ 5'd2
`define TEST_MODE_CRASH_READ 5'd3
`define TEST_MODE_CHASSIS_ALERT_READ 5'd4
`define TEST_MODE_CRASH_ACK 5'd5
`define TEST_MODE_USER_SHUTDOWN 5'd6
`define TEST_MODE_CHASSIS_ALERT_ACK 5'd7

module TB_power_manager();
  wire clk;
  reg hard_reset;

  reg lb_rd,lb_wr;
  reg [15:0] lb_data_in;
  reg [15:0] lb_addr;
  wire [15:0] lb_data_out;
  wire lb_strb;

  wire TRACK_2V5,SLP_0V9_0,SLP_0V9_1;
  wire INHIBIT_1V2,INHIBIT_1V8,INHIBIT_2V5,MARGIN_UP_2V5,MARGIN_DOWN_2V5;
  reg MGT0_1V2_PG,MGT1_1V2_PG,PG_1V5;
  wire MGT0_1V2_EN,MGT1_1V2_EN,ENABLE_1V5;
  wire [9:0] AG_EN;
  wire [4:0] BP_GA;
  reg BP_PERST_N,BP_ATNLED;
  wire BP_PWREN_N,BP_MPWRGD,BP_WAKE_N;
  reg BP_SCLI,BP_SDAI;
  wire BP_SCLO,BP_SDAO;
  wire BP_ALERT_N;
 
  reg CHS_ALERT_N;
  wire CHS_NOTIFY;
  wire [2:0] PS_LEDS;
  
  wire chassis_irq,dma_crash,soft_reset;
  reg power_down,dma_done;

  wire no_power;

  assign BP_GA=5'b00010;


  power_manager power_manager(
  .hard_reset(hard_reset),
  .TRACK_2V5(TRACK_2V5),
  .SLP_0V9_0(SLP_0V9_0),.SLP_0V9_1(SLP_0V9_1),
  .INHIBIT_1V2(INHIBIT_1V2),.INHIBIT_1V8(INHIBIT_1V8),.INHIBIT_2V5(INHIBIT_2V5),
  .MARGIN_UP_2V5(MARGIN_UP_2V5),.MARGIN_DOWN_2V5(MARGIN_DOWN_2V5),
  .MGT0_1V2_PG(MGT0_1V2_PG),.MGT1_1V2_PG(MGT1_1V2_PG),
  .MGT0_1V2_EN(MGT0_1V2_EN),.MGT1_1V2_EN(MGT1_1V2_EN),
  .ENABLE_1V5(ENABLE_1V5),.PG_1V5(PG_1V5),
  .AG_EN(AG_EN),
  .BP_GA(BP_GA),.BP_PERST_N(BP_PERST_N),.BP_PWREN_N(BP_PWREN_N),
  .BP_ATNLED(BP_ATNLED),.BP_MPWRGD(BP_MPWRGD),.BP_WAKE_N(BP_WAKE_N),
  .BP_SCLI(BP_SCLI),.BP_SCLO(BP_SCLO),.BP_SDAI(BP_SDAI),.BP_SDAO(BP_SDAO),.BP_ALERT_N(BP_ALERT_N),
  .CHS_ALERT_N(CHS_ALERT_N),.CHS_NOTIFY(CHS_NOTIFY),.PS_LEDS(PS_LEDS),
  .chassis_irq(chassis_irq),.power_down(power_down),.dma_crash(dma_crash),
  .soft_reset(soft_reset),.dma_done(dma_done),.no_power(no_power),
  .lb_addr(lb_addr),.lb_data_in(lb_data_in),.lb_data_out(lb_data_out),
  .lb_rd(lb_rd),.lb_wr(lb_wr),.lb_strb(lb_strb),.lb_clk(clk)
  );
   
  reg [31:0] counter;
  assign clk=counter[7];

  reg dma_got_a_crash;
  reg got_a_chassis_irq;
  reg chassis_alert_happened;
  reg crash_happened;
  reg soft_reset_reply;
  reg [7:0] test_mode;
  reg power_down_event;

  initial begin
`ifdef DEBUG
    $display("Starting Simulation");
`endif
    power_down_event<=1'b0;
    counter<=32'b0;
    dma_got_a_crash<=1'b0;
    got_a_chassis_irq<=1'b0;
    crash_happened<=1'b0;
    chassis_alert_happened<=1'b0;
    soft_reset_reply<=1'b0;
    CHS_ALERT_N<=1'b1;
    test_mode<=`TEST_MODE_NOP;

    hard_reset<=1'b1;
    #512 hard_reset<=1'b0;
/*TEST: does hard_reset trigger a soft reset? */
`ifdef DEBUG
  $display("/*TEST: does hard_reset trigger a soft reset? */");
`endif
    #5120
    if (~soft_reset_reply) begin
      $display("FAILED: hard reset didn't generate soft_reset");
      $finish;
    end
    soft_reset_reply<=1'b0;
/*TEST: trigger user shutdown*/
`ifdef DEBUG
  $display("/*TEST: trigger user shutdown*/");
`endif
    #512
    test_mode<=`TEST_MODE_USER_SHUTDOWN;
    #5120
    if (~soft_reset_reply) begin
      $display("FAILED: No user shutdown apparent");
      $finish;
    end
/*TEST: check chassis alert flag*/
`ifdef DEBUG
  $display("/*TEST: check chassis alert flag*/");
`endif
    #300  
    test_mode<=`TEST_MODE_CHASSIS_ALERT_READ;
    #5120
`ifdef DEBUG
  $display("TEST: asserting chs alert");
`endif
    
    CHS_ALERT_N<=1'b0;
    #300 chassis_alert_happened<=1'b1;
    #5120
/*TEST: chassis alert ack */
`ifdef DEBUG
  $display("/*TEST: chassis alert ack */");
`endif
    soft_reset_reply<=1'b0;
    test_mode<=`TEST_MODE_CHASSIS_ALERT_ACK;
    #512
    test_mode<=`TEST_MODE_NOP;
    #51200
    if (~CHS_NOTIFY || PS_LEDS!=3'b111) begin
      $display("FAILED: Chassis Shutdown has not occurred");
      $finish;
    end
    if (soft_reset_reply) begin
      $display("FAILED: spurious reset on chassis shutdown");
      $finish;
    end
    CHS_ALERT_N<=1'b1;
    hard_reset<=1'b1;
    #512 hard_reset<=1'b0;

/*TEST: crash flag*/
`ifdef DEBUG
  $display("/*TEST: crash flag*/");
`endif
    test_mode<=`TEST_MODE_CRASH_READ;
    #5120
    test_mode<=`TEST_MODE_NOP;
/*TEST: crash 0 */
`ifdef DEBUG
  $display("/*TEST: crash 0 */");
`endif
    power_down_event<=1'b1;
    #512
    power_down_event<=1'b0;
    soft_reset_reply<=1'b0;
    #5120
    if (~soft_reset_reply) begin
      $display("FAILED: no crash");
      $finish;
    end
    crash_happened<=1'b1;
/*TEST: crash flag*/
`ifdef DEBUG
  $display("/*TEST: crash flag*/");
`endif
    test_mode<=`TEST_MODE_CRASH_READ;
    #5120
/*TEST: clear crash flag*/
`ifdef DEBUG
  $display("/*TEST: clear crash flag*/");
`endif
    test_mode<=`TEST_MODE_CRASH_ACK;
    #5120
    test_mode<=`TEST_MODE_NOP;
/*TEST: crash 1*/
`ifdef DEBUG
  $display("/*TEST: crash 1*/");
`endif
    power_down_event<=1'b1;
    #512
    power_down_event<=1'b0;
    soft_reset_reply<=1'b0;
    #5120
    if (~soft_reset_reply) begin
      $display("FAILED: no crash");
      $finish;
    end
/*TEST: crash 2*/
`ifdef DEBUG
  $display("/*TEST: crash 2*/");
`endif
    power_down_event<=1'b1;
    #512
    power_down_event<=1'b0;
    soft_reset_reply<=1'b0;
    #5120
    if (~soft_reset_reply) begin
      $display("FAILED: no crash");
      $finish;
    end
/*TEST: crash 3*/
`ifdef DEBUG
  $display("/*TEST: crash 3*/");
`endif
    power_down_event<=1'b1;
    #512
    power_down_event<=1'b0;
    soft_reset_reply<=1'b0;
    #5120
    if (~soft_reset_reply) begin
      $display("FAILED: no crash");
      $finish;
    end
/*TEST: crash 4*/
`ifdef DEBUG
  $display("/*TEST: crash 4*/");
`endif
    power_down_event<=1'b1;
    #512
    power_down_event<=1'b0;
    soft_reset_reply<=1'b0;
    #5120
    if (~soft_reset_reply) begin
      $display("FAILED: no crash");
      $finish;
    end
/*TEST: crash 5*/
`ifdef DEBUG
  $display("/*TEST: crash 5*/");
`endif
    power_down_event<=1'b1;
    #512
    power_down_event<=1'b0;
    soft_reset_reply<=1'b0;
    #51200
    if (~no_power) begin
      $display("FAILED: no fatal crash");
      $finish;
    end
    test_mode<=`TEST_MODE_WRITE;
    #80000
    test_mode<=`TEST_MODE_READ;
    #80000
    hard_reset<=1'b1;
    #512
    hard_reset<=1'b0;
    #512
    soft_reset_reply<=1'b0;
    #80000
    if (~soft_reset_reply) begin
      $display("FAILED: no watchdog timeout");
      $finish;
    end
    #800000
    soft_reset_reply<=1'b0;
    #80000
    if (soft_reset_reply) begin
      $display("FAILED: watchdog max failure");
      $finish;
    end
    

    $display("PASSED");
    $finish;
  end

  always begin
    #1 counter<=counter+1;
  end
/* FAKE ALC MODULE */
  always @(posedge clk) begin
    if (soft_reset) begin
      power_down<=1'b0;
    end else begin
      if (power_down_event) begin
`ifdef DEBUG
        $display("alc: asserting power_down");
`endif
        power_down<=1'b1;
      end
    end
  end

/* FAKE DMA MODULE */
  reg [4:0] dma_counter;
`ifdef DEBUG
  reg dma_start;
`endif
  always @(posedge clk) begin
    if (soft_reset) begin
      soft_reset_reply<=1'b1;

      dma_done<=1'b0;
`ifdef DEBUG
      dma_start<=1'b1;
`endif
      if (dma_crash) begin
        dma_counter<=5'b111;
        dma_got_a_crash<=1'b1;
      end else 
        dma_counter<=5'b11;
    end else begin
`ifdef DEBUG
      dma_start<=1'b0;
      if (dma_start)
        $display("dma: operation start -- crash = %d",dma_counter==5'b111);
`endif
      if (dma_counter==5'b0) begin
        dma_done<=1'b1;
`ifdef DEBUG
        if (~dma_done) 
          $display("dma: operation complete");
`endif
      end else 
        dma_counter<=dma_counter - 5'b1;
    end
  end
/* FAKE IRQ MODULE */
  always @(posedge clk) begin
    if (soft_reset) begin
    end else begin
      if (chassis_irq) begin
`ifdef DEBUG        
       // $display("irq: got chassis irq");
`endif
      end
    end
  end

  
/*Fake LBus Controller Module*/ 
  reg [2:0] state;
  reg [3:0] fault_countdown;
  always @ (posedge clk) begin
    if (soft_reset) begin
      lb_addr<=16'b0;
      lb_rd<=1'b0;
      lb_wr<=1'b0;
      state<=`TB_STATE_IDLE;
      fault_countdown<=4'b0;
    end else begin
      case (state)
        `TB_STATE_IDLE: begin
          case (test_mode)
            `TEST_MODE_WRITE: begin
              lb_addr<=lb_addr+16'b1;
              lb_data_in<=16'b0;
              state<=`TB_STATE_WRITE;
            end
            `TEST_MODE_READ: begin
              lb_addr<=lb_addr+16'b1;
              state<=`TB_STATE_READ;
            end
            `TEST_MODE_CRASH_READ: begin
              lb_addr<=`PC_CRASH_A;
              state<=`TB_STATE_READ;
            end
            `TEST_MODE_CHASSIS_ALERT_READ: begin
              lb_addr<=`PC_CHASSIS_ALERT_A;
              state<=`TB_STATE_READ;
            end
            `TEST_MODE_CRASH_ACK: begin
              lb_addr<=`PC_CRASH_A;
              lb_data_in<=16'b11100111010;
              state<=`TB_STATE_WRITE;
            end
            `TEST_MODE_USER_SHUTDOWN: begin
              lb_addr<=`PC_SHUTDOWN_A;
              lb_data_in<=16'b11100111010;
              state<=`TB_STATE_WRITE;
            end
            `TEST_MODE_CHASSIS_ALERT_ACK: begin
              lb_addr<=`PC_CHASSIS_ALERT_A;
              lb_data_in<=16'b11100111010;
              state<=`TB_STATE_WRITE;
            end
            `TEST_MODE_NOP: begin
            end
          endcase
        end
        `TB_STATE_WRITE: begin
            lb_wr<=1'b1;
            state<=`TB_STATE_WAITW;
`ifdef DESPERATE_DEBUG
            //$display("lb_wrote_data = %d, ",lb_data_in);
`endif
          end
        `TB_STATE_READ:
          begin
            lb_rd<=1'b1;
            state<=`TB_STATE_WAITR;
          end
        `TB_STATE_WAITR:
          begin
            if (fault_countdown == 4'b1111) begin
              state<=`TB_STATE_IDLE;
              fault_countdown<=4'b0;
              if (lb_addr >= `PC_A && lb_addr < `PC_A + `PC_L) begin
                  $display("FAILED: invalid timeout on write: address %x",lb_addr);
                  $finish;
              end
`ifdef DEBUG
              $display("bus timeout at address: %x", lb_addr);
`endif
            end else begin
              fault_countdown<=fault_countdown + 4'b1;
              if (lb_rd)
                lb_rd<=1'b0;
              if (lb_strb) begin
                if (lb_addr < `PC_A || lb_addr >= `PC_A + `PC_L) begin
                  $display("FAILED: invalid reply on write: address %x",lb_addr);
                  $finish;
                end
                state<=`TB_STATE_IDLE;
                fault_countdown<=4'b0;
                if (lb_data_out[7:0]===8'hxx)begin
                  $display("FAILED: test data failure -> lb_data_out === X, addr %x",lb_addr - (`PC_A));
                  $finish;
                end else begin
                  case (test_mode)
                  `TEST_MODE_CRASH_READ: begin
`ifdef DEBUG
                    $display("lbus: got crash read");
`endif
                    if (crash_happened && lb_data_out != 16'hffff) begin
                      $display("FAILED: crash flag invalid - should be ffff");
                      $finish;
                    end else if (~crash_happened && lb_data_out != 16'b0000) begin
                      $display("FAILED: crash flag invalid - should be 0000");
                      $finish;
                    end
                  end
                  `TEST_MODE_CHASSIS_ALERT_READ: begin
`ifdef DEBUG
                    $display("lbus: got alert read");
`endif
                    if (chassis_alert_happened && lb_data_out != 16'hffff) begin
                      $display("FAILED: chassis flag invalid - should be ffff");
                      $finish;
                    end else if (~chassis_alert_happened && lb_data_out != 16'h0000) begin
                      $display("FAILED: chassis flag invalid - should be 0000");
                      $finish;
                    end
                  end
                  endcase
                end
              end
            end
          end
        `TB_STATE_WAITW:
          begin
            if (fault_countdown == 4'b1111) begin
              state<=`TB_STATE_IDLE;
              fault_countdown<=4'b0;
              if (lb_addr >= `PC_A && lb_addr < `PC_A + `PC_L) begin
                  $display("FAILED: invalid timeout on write: address %x",lb_addr);
                  $finish;
              end
`ifdef DEBUG
              $display("bus timeout at address: %x", lb_addr);
`endif
            end else begin
              fault_countdown<=fault_countdown + 4'b1;
              if (lb_wr)
                lb_wr<=1'b0;

              if (lb_strb) begin
                if (lb_addr < `PC_A || lb_addr >= `PC_A + `PC_L) begin
                  $display("FAILED: invalid reply on write: address %x",lb_addr);
                  $finish;
                end
`ifdef DEBUG
              //$display("lbus: write, addr=%d,data=%d", lb_addr, lb_data_in);
`endif
                state<=`TB_STATE_IDLE;
                fault_countdown<=4'b0;
              end
            end
          end
      endcase
    end
  end
endmodule
