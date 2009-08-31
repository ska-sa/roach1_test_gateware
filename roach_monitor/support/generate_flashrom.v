`define VCC_HIGH      8'd160
`define VCC_LOW       8'd140 
`define TINT_HIGH     8'd87
`define TINT_LOW      8'd0 

`define AV0_HIGH      8'd255
`define AV0_LOW       8'd0
`define AV1_HIGH      8'd255
`define AV1_LOW       8'd0
`define AV2_HIGH      8'd218
`define AV2_LOW       8'd156
`define AV3_HIGH      8'd175
`define AV3_LOW       8'd137
`define AV4_HIGH      8'd226
`define AV4_LOW       8'd187
`define AV5_HIGH      8'd105
`define AV5_LOW       8'd90
`define AV6_HIGH      8'd255
`define AV6_LOW       8'd0
`define AV7_HIGH      8'd155
`define AV7_LOW       8'd140
`define AV8_HIGH      8'd190
`define AV8_LOW       8'd170
`define AV9_HIGH      8'd254
`define AV9_LOW       8'd245

`define AC0_HIGH      8'd255
`define AC0_LOW       8'd0
`define AC1_HIGH      8'd255
`define AC1_LOW       8'd0
`define AC2_HIGH      8'd255
`define AC2_LOW       8'd0
`define AC3_HIGH      8'd255
`define AC3_LOW       8'd0
`define AC4_HIGH      8'd255
`define AC4_LOW       8'd0
`define AC5_HIGH      8'd255
`define AC5_LOW       8'd0
`define AC6_HIGH      8'd255
`define AC6_LOW       8'd0
`define AC7_HIGH      8'd255
`define AC7_LOW       8'd0
`define AC8_HIGH      8'd255
`define AC8_LOW       8'd0
`define AC9_HIGH      8'd255
`define AC9_LOW       8'd0

`define AT0_HIGH      8'd93
`define AT0_LOW       8'd0
`define AT1_HIGH      8'd255
`define AT1_LOW       8'd0
`define AT2_HIGH      8'd90
`define AT2_LOW       8'd0
`define AT3_HIGH      8'd255
`define AT3_LOW       8'd0
`define AT4_HIGH      8'd255
`define AT4_LOW       8'd0
`define AT5_HIGH      8'd255
`define AT5_LOW       8'd0
`define AT6_HIGH      8'd255
`define AT6_LOW       8'd0
`define AT7_HIGH      8'd255
`define AT7_LOW       8'd0
`define AT8_HIGH      8'd255
`define AT8_LOW       8'd0
`define AT9_HIGH      8'd255
`define AT9_LOW       8'd0

`define AV_SCALING_FACTOR_16V                   (8'b000 << 0)
`define AV_SCALING_FACTOR_8V                    (8'b001 << 0)  
`define AV_SCALING_FACTOR_4V                    (8'b010 << 0) 
`define AV_SCALING_FACTOR_2V                    (8'b011 << 0)
`define AV_SCALING_FACTOR_1V                    (8'b100 << 0) 
`define AV_SCALING_FACTOR_0V5                   (8'b101 << 0)
`define AV_SCALING_FACTOR_0V25                  (8'b110 << 0)
`define AV_SCALING_FACTOR_0V125                 (8'b111 << 0)
`define AV_ANALOG_MUX_SELECT_DIRECT             (8'b1   << 3)
`define AV_ANALOG_MUX_SELECT_PRESCALER          (8'b0   << 3)
`define AV_CURRENT_MON_SWITCH_ON                (8'b1   << 4)
`define AV_CURRENT_MON_SWITCH_OFF               (8'b0   << 4)
`define AV_DIRECT_ANALOG_INPUT_ON               (8'b1   << 5)
`define AV_DIRECT_ANALOG_INPUT_OFF              (8'b0   << 5)
`define AV_PAD_POLARITY_POSITIVE                (8'b0   << 6)
`define AV_PAD_POLARITY_NEGATIVE                (8'b1   << 6)
`define AV_PRESCALER_MODE_POWERDOWN             (8'b0   << 7)
`define AV_PRESCALER_MODE_OPERATIONAL           (8'b1   << 7)

`define AC_SCALING_FACTOR_16V                   (8'b000 << 0)
`define AC_SCALING_FACTOR_8V                    (8'b001 << 0)  
`define AC_SCALING_FACTOR_4V                    (8'b010 << 0) 
`define AC_SCALING_FACTOR_2V                    (8'b011 << 0)
`define AC_SCALING_FACTOR_1V                    (8'b100 << 0) 
`define AC_SCALING_FACTOR_0V5                   (8'b101 << 0)
`define AC_SCALING_FACTOR_0V25                  (8'b110 << 0)
`define AC_SCALING_FACTOR_0V125                 (8'b111 << 0)
`define AC_ANALOG_MUX_SELECT_DIRECT             (8'b01  << 3)
`define AC_ANALOG_MUX_SELECT_PRESCALER          (8'b00  << 3)
`define AC_ANALOG_MUX_SELECT_CURRENTAMP         (8'b10  << 3)
`define AC_DIRECT_ANALOG_INPUT_ON               (8'b1   << 5)
`define AC_DIRECT_ANALOG_INPUT_OFF              (8'b0   << 5)
`define AC_PAD_POLARITY_POSITIVE                (8'b0   << 6)
`define AC_PAD_POLARITY_NEGATIVE                (8'b1   << 6)
`define AC_PRESCALER_MODE_POWERDOWN             (8'b0   << 7)
`define AC_PRESCALER_MODE_OPERATIONAL           (8'b1   << 7)

`define AT_SCALING_FACTOR_16V                   (8'b000 << 0)
`define AT_SCALING_FACTOR_8V                    (8'b001 << 0)  
`define AT_SCALING_FACTOR_4V                    (8'b010 << 0) 
`define AT_SCALING_FACTOR_2V                    (8'b011 << 0)
`define AT_SCALING_FACTOR_1V                    (8'b100 << 0) 
`define AT_SCALING_FACTOR_0V5                   (8'b101 << 0)
`define AT_SCALING_FACTOR_0V25                  (8'b110 << 0)
`define AT_SCALING_FACTOR_0V125                 (8'b111 << 0)
`define AT_ANALOG_MUX_SELECT_DIRECT             (8'b01  << 3)
`define AT_ANALOG_MUX_SELECT_PRESCALER          (8'b00  << 3)
`define AT_ANALOG_MUX_SELECT_TEMPMON            (8'b10  << 3)
`define AT_DIRECT_ANALOG_INPUT_ON               (8'b1   << 5)
`define AT_DIRECT_ANALOG_INPUT_OFF              (8'b0   << 5)
`define AT_PRESCALER_MODE_POWERDOWN             (8'b0   << 7)
`define AT_PRESCALER_MODE_OPERATIONAL           (8'b1   << 7)

`define AG_CHIP_TEMP_MONITOR_ON                 (8'b1   << 0)
`define AG_CHIP_TEMP_MONITOR_OFF                (8'b0   << 0)
`define AG_CURRENT_DRIVE_1UA                    (8'b00  << 1)
`define AG_CURRENT_DRIVE_3UA                    (8'b01  << 1)
`define AG_CURRENT_DRIVE_10UA                   (8'b10  << 1)
`define AG_CURRENT_DRIVE_30UA                   (8'b11  << 1)
`define AG_POLARITY_POSITIVE                    (8'b0   << 6)
`define AG_POLARITY_NEGATIVE                    (8'b1   << 6)
`define AG_DRIVER_MODE_LOW                      (8'b0   << 7)
`define AG_DRIVER_MODE_HIGH                     (8'b1   << 7)

/******************* Configuration Starts Here ********************/

`define AG0 (`AG_CHIP_TEMP_MONITOR_ON  | `AG_CURRENT_DRIVE_1UA | `AG_POLARITY_POSITIVE | `AG_DRIVER_MODE_HIGH)
`define AG1 (`AG_CHIP_TEMP_MONITOR_OFF | `AG_CURRENT_DRIVE_1UA | `AG_POLARITY_POSITIVE | `AG_DRIVER_MODE_HIGH)
`define AG2 (`AG_CHIP_TEMP_MONITOR_OFF | `AG_CURRENT_DRIVE_1UA | `AG_POLARITY_POSITIVE | `AG_DRIVER_MODE_HIGH)
`define AG3 (`AG_CHIP_TEMP_MONITOR_OFF | `AG_CURRENT_DRIVE_1UA | `AG_POLARITY_POSITIVE | `AG_DRIVER_MODE_HIGH)
`define AG4 (`AG_CHIP_TEMP_MONITOR_OFF | `AG_CURRENT_DRIVE_1UA | `AG_POLARITY_POSITIVE | `AG_DRIVER_MODE_HIGH)
`define AG5 (`AG_CHIP_TEMP_MONITOR_OFF | `AG_CURRENT_DRIVE_1UA | `AG_POLARITY_POSITIVE | `AG_DRIVER_MODE_HIGH)
`define AG6 (`AG_CHIP_TEMP_MONITOR_OFF | `AG_CURRENT_DRIVE_1UA | `AG_POLARITY_POSITIVE | `AG_DRIVER_MODE_HIGH)
`define AG7 (`AG_CHIP_TEMP_MONITOR_OFF | `AG_CURRENT_DRIVE_1UA | `AG_POLARITY_POSITIVE | `AG_DRIVER_MODE_HIGH)
`define AG8 (`AG_CHIP_TEMP_MONITOR_OFF | `AG_CURRENT_DRIVE_1UA | `AG_POLARITY_POSITIVE | `AG_DRIVER_MODE_HIGH)
`define AG9 (`AG_CHIP_TEMP_MONITOR_OFF | `AG_CURRENT_DRIVE_1UA | `AG_POLARITY_POSITIVE | `AG_DRIVER_MODE_HIGH)


`define AV0 (`AV_SCALING_FACTOR_16V | `AV_ANALOG_MUX_SELECT_PRESCALER | `AV_CURRENT_MON_SWITCH_OFF | `AV_DIRECT_ANALOG_INPUT_OFF | `AV_PAD_POLARITY_POSITIVE | `AV_PRESCALER_MODE_OPERATIONAL)
`define AV1 (`AV_SCALING_FACTOR_16V | `AV_ANALOG_MUX_SELECT_PRESCALER | `AV_CURRENT_MON_SWITCH_OFF | `AV_DIRECT_ANALOG_INPUT_OFF | `AV_PAD_POLARITY_POSITIVE | `AV_PRESCALER_MODE_OPERATIONAL)
`define AV2 (`AV_SCALING_FACTOR_8V  | `AV_ANALOG_MUX_SELECT_PRESCALER | `AV_CURRENT_MON_SWITCH_OFF | `AV_DIRECT_ANALOG_INPUT_OFF | `AV_PAD_POLARITY_POSITIVE | `AV_PRESCALER_MODE_OPERATIONAL)
`define AV3 (`AV_SCALING_FACTOR_8V  | `AV_ANALOG_MUX_SELECT_PRESCALER | `AV_CURRENT_MON_SWITCH_ON  | `AV_DIRECT_ANALOG_INPUT_OFF | `AV_PAD_POLARITY_POSITIVE | `AV_PRESCALER_MODE_OPERATIONAL)
`define AV4 (`AV_SCALING_FACTOR_4V  | `AV_ANALOG_MUX_SELECT_PRESCALER | `AV_CURRENT_MON_SWITCH_ON  | `AV_DIRECT_ANALOG_INPUT_OFF | `AV_PAD_POLARITY_POSITIVE | `AV_PRESCALER_MODE_OPERATIONAL)
`define AV5 (`AV_SCALING_FACTOR_16V | `AV_ANALOG_MUX_SELECT_DIRECT    | `AV_CURRENT_MON_SWITCH_ON  | `AV_DIRECT_ANALOG_INPUT_ON  | `AV_PAD_POLARITY_POSITIVE | `AV_PRESCALER_MODE_POWERDOWN)
`define AV6 (`AV_SCALING_FACTOR_16V | `AV_ANALOG_MUX_SELECT_PRESCALER | `AV_CURRENT_MON_SWITCH_OFF | `AV_DIRECT_ANALOG_INPUT_OFF | `AV_PAD_POLARITY_POSITIVE | `AV_PRESCALER_MODE_OPERATIONAL)
`define AV7 (`AV_SCALING_FACTOR_16V | `AV_ANALOG_MUX_SELECT_DIRECT    | `AV_CURRENT_MON_SWITCH_ON  | `AV_DIRECT_ANALOG_INPUT_ON  | `AV_PAD_POLARITY_POSITIVE | `AV_PRESCALER_MODE_POWERDOWN)
`define AV8 (`AV_SCALING_FACTOR_16V | `AV_ANALOG_MUX_SELECT_DIRECT    | `AV_CURRENT_MON_SWITCH_ON  | `AV_DIRECT_ANALOG_INPUT_ON  | `AV_PAD_POLARITY_POSITIVE | `AV_PRESCALER_MODE_POWERDOWN)
`define AV9 (`AV_SCALING_FACTOR_16V | `AV_ANALOG_MUX_SELECT_DIRECT    | `AV_CURRENT_MON_SWITCH_ON  | `AV_DIRECT_ANALOG_INPUT_ON  | `AV_PAD_POLARITY_POSITIVE | `AV_PRESCALER_MODE_POWERDOWN)

`define AC0 (`AC_SCALING_FACTOR_16V | `AC_ANALOG_MUX_SELECT_PRESCALER  | `AC_DIRECT_ANALOG_INPUT_OFF | `AC_PAD_POLARITY_POSITIVE | `AC_PRESCALER_MODE_OPERATIONAL)
`define AC1 (`AC_SCALING_FACTOR_16V | `AC_ANALOG_MUX_SELECT_PRESCALER  | `AC_DIRECT_ANALOG_INPUT_OFF | `AC_PAD_POLARITY_POSITIVE | `AC_PRESCALER_MODE_OPERATIONAL)
`define AC2 (`AC_SCALING_FACTOR_16V | `AC_ANALOG_MUX_SELECT_PRESCALER  | `AC_DIRECT_ANALOG_INPUT_OFF | `AC_PAD_POLARITY_POSITIVE | `AC_PRESCALER_MODE_OPERATIONAL)
`define AC3 (`AC_SCALING_FACTOR_16V | `AC_ANALOG_MUX_SELECT_CURRENTAMP | `AC_DIRECT_ANALOG_INPUT_OFF | `AC_PAD_POLARITY_POSITIVE | `AC_PRESCALER_MODE_POWERDOWN)
`define AC4 (`AC_SCALING_FACTOR_16V | `AC_ANALOG_MUX_SELECT_CURRENTAMP | `AC_DIRECT_ANALOG_INPUT_OFF | `AC_PAD_POLARITY_POSITIVE | `AC_PRESCALER_MODE_POWERDOWN)
`define AC5 (`AC_SCALING_FACTOR_16V | `AC_ANALOG_MUX_SELECT_CURRENTAMP | `AC_DIRECT_ANALOG_INPUT_OFF | `AC_PAD_POLARITY_POSITIVE | `AC_PRESCALER_MODE_POWERDOWN)
`define AC6 (`AC_SCALING_FACTOR_16V | `AC_ANALOG_MUX_SELECT_PRESCALER  | `AC_DIRECT_ANALOG_INPUT_OFF | `AC_PAD_POLARITY_POSITIVE | `AC_PRESCALER_MODE_OPERATIONAL)
`define AC7 (`AC_SCALING_FACTOR_16V | `AC_ANALOG_MUX_SELECT_CURRENTAMP | `AC_DIRECT_ANALOG_INPUT_OFF | `AC_PAD_POLARITY_POSITIVE | `AC_PRESCALER_MODE_POWERDOWN)
`define AC8 (`AC_SCALING_FACTOR_16V | `AC_ANALOG_MUX_SELECT_CURRENTAMP | `AC_DIRECT_ANALOG_INPUT_OFF | `AC_PAD_POLARITY_POSITIVE | `AC_PRESCALER_MODE_POWERDOWN)
`define AC9 (`AC_SCALING_FACTOR_16V | `AC_ANALOG_MUX_SELECT_CURRENTAMP | `AC_DIRECT_ANALOG_INPUT_OFF | `AC_PAD_POLARITY_POSITIVE | `AC_PRESCALER_MODE_POWERDOWN)

`define AT0 (`AT_SCALING_FACTOR_16V | `AT_ANALOG_MUX_SELECT_TEMPMON   | `AT_DIRECT_ANALOG_INPUT_OFF | `AT_PRESCALER_MODE_POWERDOWN)
`define AT1 (`AT_SCALING_FACTOR_16V | `AT_ANALOG_MUX_SELECT_PRESCALER | `AT_DIRECT_ANALOG_INPUT_OFF | `AT_PRESCALER_MODE_OPERATIONAL)
`define AT2 (`AT_SCALING_FACTOR_16V | `AT_ANALOG_MUX_SELECT_TEMPMON   | `AT_DIRECT_ANALOG_INPUT_OFF | `AT_PRESCALER_MODE_POWERDOWN)
`define AT3 (`AT_SCALING_FACTOR_16V | `AT_ANALOG_MUX_SELECT_PRESCALER | `AT_DIRECT_ANALOG_INPUT_OFF | `AT_PRESCALER_MODE_OPERATIONAL)
`define AT4 (`AT_SCALING_FACTOR_16V | `AT_ANALOG_MUX_SELECT_PRESCALER | `AT_DIRECT_ANALOG_INPUT_OFF | `AT_PRESCALER_MODE_OPERATIONAL)
`define AT5 (`AT_SCALING_FACTOR_16V | `AT_ANALOG_MUX_SELECT_PRESCALER | `AT_DIRECT_ANALOG_INPUT_OFF | `AT_PRESCALER_MODE_OPERATIONAL)
`define AT6 (`AT_SCALING_FACTOR_16V | `AT_ANALOG_MUX_SELECT_PRESCALER | `AT_DIRECT_ANALOG_INPUT_OFF | `AT_PRESCALER_MODE_OPERATIONAL)
`define AT7 (`AT_SCALING_FACTOR_16V | `AT_ANALOG_MUX_SELECT_PRESCALER | `AT_DIRECT_ANALOG_INPUT_OFF | `AT_PRESCALER_MODE_OPERATIONAL)
`define AT8 (`AT_SCALING_FACTOR_16V | `AT_ANALOG_MUX_SELECT_PRESCALER | `AT_DIRECT_ANALOG_INPUT_OFF | `AT_PRESCALER_MODE_OPERATIONAL)
`define AT9 (`AT_SCALING_FACTOR_16V | `AT_ANALOG_MUX_SELECT_PRESCALER | `AT_DIRECT_ANALOG_INPUT_OFF | `AT_PRESCALER_MODE_OPERATIONAL)

module generate_flash_rom();
 wire [15:0] checksum_int =
              (`VCC_HIGH) + (`VCC_LOW) + (`AV0_HIGH) + (`AV0_LOW) +
              (`AC0_HIGH) + (`AC0_LOW) + (`AT0_HIGH) + (`AT0_LOW) +
              (`AV1_HIGH) + (`AV1_LOW) + (`AC1_HIGH) + (`AC1_LOW) +
              (`AT1_HIGH) + (`AT1_LOW) + (`AV2_HIGH) + (`AV2_LOW) + 
              (`AC2_HIGH) + (`AC2_LOW) + (`AT2_HIGH) + (`AT2_LOW) + 
              (`AV3_HIGH) + (`AV3_LOW) + (`AC3_HIGH) + (`AC3_LOW) + 
              (`AT3_HIGH) + (`AT3_LOW) + (`AV4_HIGH) + (`AV4_LOW) + 
              (`AC4_HIGH) + (`AC4_LOW) + (`AT4_HIGH) + (`AT4_LOW) + 
              (`AV5_HIGH) + (`AV5_LOW) + (`AC5_HIGH) + (`AC5_LOW) + 
              (`AT5_HIGH) + (`AT5_LOW) + (`AV6_HIGH) + (`AV6_LOW) + 
              (`AC6_HIGH) + (`AC6_LOW) + (`AT6_HIGH) + (`AT6_LOW) + 
              (`AV7_HIGH) + (`AV7_LOW) + (`AC7_HIGH) + (`AC7_LOW) + 
              (`AT7_HIGH) + (`AT7_LOW) + (`AV8_HIGH) + (`AV8_LOW) + 
              (`AC8_HIGH) + (`AC8_LOW) + (`AT8_HIGH) + (`AT8_LOW) + 
              (`AV9_HIGH) + (`AV9_LOW) + (`AC9_HIGH) + (`AC9_LOW) + 
              (`AT9_HIGH) + (`AT9_LOW) + (`TINT_HIGH) +(`TINT_LOW) + 
              (`AV0) + (`AC0) + (`AG0) + (`AT0) + 
              (`AV1) + (`AC1) + (`AG1) + (`AT1) + 
              (`AV2) + (`AC2) + (`AG2) + (`AT2) + 
              (`AV3) + (`AC3) + (`AG3) + (`AT3) + 
              (`AV4) + (`AC4) + (`AG4) + (`AT4) + 
              (`AV5) + (`AC5) + (`AG5) + (`AT5) + 
              (`AV6) + (`AC6) + (`AG6) + (`AT6) + 
              (`AV7) + (`AC7) + (`AG7) + (`AT7) + 
              (`AV8) + (`AC8) + (`AG8) + (`AT8) + 
              (`AV9) + (`AC9) + (`AG9) + (`AT9);

  wire [7:0] checksum = ~(checksum_int[7:0]) + 1;
  initial begin
    #1
    $display("%x",checksum);
    $display("%x",`VCC_LOW);
    $display("%x",`VCC_HIGH);
    $display("%x",`AV0_LOW);
    $display("%x",`AV0_HIGH);
    $display("%x",`AC0_LOW);
    $display("%x",`AC0_HIGH);
    $display("%x",`AT0_LOW);
    $display("%x",`AT0_HIGH);
    $display("%x",`AV1_LOW);
    $display("%x",`AV1_HIGH);
    $display("%x",`AC1_LOW);
    $display("%x",`AC1_HIGH);
    $display("%x",`AT1_LOW);
    $display("%x",`AT1_HIGH);
    $display("%x",`AV2_LOW);
    $display("%x",`AV2_HIGH);
    $display("%x",`AC2_LOW);
    $display("%x",`AC2_HIGH);
    $display("%x",`AT2_LOW);
    $display("%x",`AT2_HIGH);
    $display("%x",`AV3_LOW);
    $display("%x",`AV3_HIGH);
    $display("%x",`AC3_LOW);
    $display("%x",`AC3_HIGH);
    $display("%x",`AT3_LOW);
    $display("%x",`AT3_HIGH);
    $display("%x",`AV4_LOW);
    $display("%x",`AV4_HIGH);
    $display("%x",`AC4_LOW);
    $display("%x",`AC4_HIGH);
    $display("%x",`AT4_LOW);
    $display("%x",`AT4_HIGH);
    $display("%x",`AV5_LOW);
    $display("%x",`AV5_HIGH);
    $display("%x",`AC5_LOW);
    $display("%x",`AC5_HIGH);
    $display("%x",`AT5_LOW);
    $display("%x",`AT5_HIGH);
    $display("%x",`AV6_LOW);
    $display("%x",`AV6_HIGH);
    $display("%x",`AC6_LOW);
    $display("%x",`AC6_HIGH);
    $display("%x",`AT6_LOW);
    $display("%x",`AT6_HIGH);
    $display("%x",`AV7_LOW);
    $display("%x",`AV7_HIGH);
    $display("%x",`AC7_LOW);
    $display("%x",`AC7_HIGH);
    $display("%x",`AT7_LOW);
    $display("%x",`AT7_HIGH);
    $display("%x",`AV8_LOW);
    $display("%x",`AV8_HIGH);
    $display("%x",`AC8_LOW);
    $display("%x",`AC8_HIGH);
    $display("%x",`AT8_LOW);
    $display("%x",`AT8_HIGH);
    $display("%x",`AV9_LOW);
    $display("%x",`AV9_HIGH);
    $display("%x",`AC9_LOW);
    $display("%x",`AC9_HIGH);
    $display("%x",`AT9_LOW);
    $display("%x",`AT9_HIGH);
    $display("%x",`TINT_LOW);
    $display("%x",`TINT_HIGH);
    $display("%x",`AV0);
    $display("%x",`AC0);
    $display("%x",`AG0);
    $display("%x",`AT0);
    $display("%x",`AV1);
    $display("%x",`AC1);
    $display("%x",`AG1);
    $display("%x",`AT1);
    $display("%x",`AV2);
    $display("%x",`AC2);
    $display("%x",`AG2);
    $display("%x",`AT2);
    $display("%x",`AV3);
    $display("%x",`AC3);
    $display("%x",`AG3);
    $display("%x",`AT3);
    $display("%x",`AV4);
    $display("%x",`AC4);
    $display("%x",`AG4);
    $display("%x",`AT4);
    $display("%x",`AV5);
    $display("%x",`AC5);
    $display("%x",`AG5);
    $display("%x",`AT5);
    $display("%x",`AV6);
    $display("%x",`AC6);
    $display("%x",`AG6);
    $display("%x",`AT6);
    $display("%x",`AV7);
    $display("%x",`AC7);
    $display("%x",`AG7);
    $display("%x",`AT7);
    $display("%x",`AV8);
    $display("%x",`AC8);
    $display("%x",`AG8);
    $display("%x",`AT8);
    $display("%x",`AV9);
    $display("%x",`AC9);
    $display("%x",`AG9);
    $display("%x",`AT9);
    $display("%x",8'b0);
    $display("%x",8'b0);
    $display("%x",8'b0);
    $display("%x",8'b0);
    $display("%x",8'b0);
    $display("%x",8'b0);
    $display("%x",8'b0);
    $display("%x",8'b0);
    $display("%x",8'b0);
    $display("%x",8'b0);
    $display("%x",8'b0);
    $display("%x",8'b0);
    $display("%x",8'b0);
    $display("%x",8'b0);
    $display("%x",8'b0);
    $display("%x",8'b0);
    $display("%x",8'b0);
    $display("%x",8'b0);
    $display("%x",8'b0);
    $display("%x",8'b0);
    $display("%x",8'b0);
    $display("%x",8'b0);
    $display("%x",8'b0);
  end
endmodule
