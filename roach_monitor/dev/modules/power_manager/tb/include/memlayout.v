`define ADDR_WIDTH 16
`define DATA_WIDTH 16

/* Address Map -- handle me with care */

`define FROM_A 16'd0
`define FROM_L 16'd128

`define ACM_A (`FROM_A + `FROM_L)
`define ACM_L 16'd256

`define ALC_A (`ACM_A + `ACM_L)
`define ALC_L 16'd163

`define PC_A (`ALC_A + `ALC_L)
`define PC_L 16'd6

`define IRQC_A (`PC_A + `PC_L)
`define IRQC_L 16'd3

`define BUSMON_A (`IRQC_A + `IRQC_L)
`define BUSMON_L 16'd8

`define AP_A (`BUSMON_A + `BUSMON_L)
`define AP_L 16'd2

`ifndef FINAL_DESIGN 
`define TESTMOD_A (`AP_A + `AP_L)
`define TESTMOD_L 16'd128
`endif

`define FLASH_A (16'd1024 -  16'd3)
`define FLASH_L (16'd64512 + 16'd3)

/* Offsets within FlashROM */
`define FROM_BID_A `FROM_A 
`define FROM_BID_L 16'd10

`define FROM_REV_A (`FROM_BID_A + `FROM_BID_L)
`define FROM_REV_L 16'd10

`define FROM_LEVELS_A (`FROM_REV_A + `FROM_REV_L)
`define FROM_LEVELS_L 16'd64

`define FROM_ACMDATA_A (`FROM_LEVELS_A + `FROM_LEVELS_L)
`define FROM_ACMDATA_L 16'd40
/* Offsets within ACM */
`define ACM_AQUADS_A  (`ACM_A + 16'b1)
`define ACM_AQUADS_L  16'd40
/* Offsets within Analogue Level Checker */
`define ALC_FAULTVAL_A `ALC_A
`define ALC_FAULTVAL_L 16'd2

`define ALC_HARDLEVEL_A (`ALC_FAULTVAL_A + `ALC_FAULTVAL_L)
`define ALC_HARDLEVEL_L 16'd64

`define ALC_SOFTLEVEL_A (`ALC_HARDLEVEL_A + `ALC_HARDLEVEL_L)
`define ALC_SOFTLEVEL_L 16'd64

`define ALC_ADC_VALUE_A (`ALC_SOFTLEVEL_A + `ALC_SOFTLEVEL_L)
`define ALC_ADC_VALUE_L 16'd32

`define ALC_RBUFF_A (`ALC_ADC_VALUE_A + `ALC_ADC_VALUE_L)
`define ALC_RBUFF_L 16'b1

/* Offsets within Power Controller */
`define PC_SHUTDOWN_A `PC_A
`define PC_SHUTDOWN_L 16'd1

`define PC_CHASSIS_ALERT_A (`PC_SHUTDOWN_A + `PC_SHUTDOWN_L)
`define PC_CHASSIS_ALERT_L 16'd1

`define PC_CRASH_A (`PC_CHASSIS_ALERT_A + `PC_CHASSIS_ALERT_L)
`define PC_CRASH_L 16'd1

`define PC_WATCHDOG_A (`PC_CRASH_A + `PC_CRASH_L)
`define PC_WATCHDOG_L 16'd1

`define PC_GA_A (`PC_WATCHDOG_A + `PC_WATCHDOG_L)
`define PC_GA_L 16'd1

`define PC_PD_A (`PC_GA_A + `PC_GA_L)
`define PC_PD_L 16'd1

`define PC_POWERUP_A (`PC_PD_A + `PC_PD_L)
`define PC_POWERUP_L 16'd1

/* Offsets within IRQ Controller */
`define IRQC_FLAG_A `IRQC_A
`define IRQC_FLAG_L 16'd1

`define IRQC_USER_A (`IRQC_FLAG_A + `IRQC_FLAG_L)
`define IRQC_USER_L 16'd1

`define IRQC_MASK_A (`IRQC_USER_A + `IRQC_USER_L)
`define IRQC_MASK_L 16'd1

/* Offsets within Bus Monitor */

`define BUSMON_ADDR_A (`BUSMON_A)
`define BUSMON_ADDR_L 16'd1

`define BUSMON_CMND_A (`BUSMON_ADDR_A + `BUSMON_ADDR_L)
`define BUSMON_CMND_L 16'd1

`define BUSMON_DATA_A (`BUSMON_CMND_A + `BUSMON_CMND_L)
`define BUSMON_DATA_L 16'd1

`define BUSMON_COUNT_A (`BUSMON_DATA_A + `BUSMON_DATA_L)
`define BUSMON_COUNT_L 16'd1

`define BUSMON_CADDR_A (`BUSMON_COUNT_A + `BUSMON_COUNT_L)
`define BUSMON_CADDR_L 16'd1

`define BUSMON_CCMND_A (`BUSMON_CADDR_A + `BUSMON_CADDR_L)
`define BUSMON_CCMND_L 16'd1

`define BUSMON_CDATA_A (`BUSMON_CCMND_A + `BUSMON_CCMND_L)
`define BUSMON_CDATA_L 16'd1

`define BUSMON_OPCNT_A (`BUSMON_CDATA_A + `BUSMON_CDATA_L)
`define BUSMON_OPCNT_L 16'd1

/* Offsets within Address Protector */

`define AP_ADDR_A (`AP_A)
`define AP_ADDR_L 16'd1

`define AP_CMND_A (`AP_ADDR_A + `AP_ADDR_L)
`define AP_CMND_L 16'd1

/* Offsets within Flash Memory */
`define FLASH_DEBUG_L 16'd8 
`define FLASH_DEBUG_A (`FLASH_A - `FLASH_DEBUG_L)

`define FLASH_DEBUG_WRITE_COUNT_A (`FLASH_DEBUG_A)
`define FLASH_DEBUG_WRITE_COUNT_L 16'd1
`define FLASH_DEBUG_READ_COUNT_A (`FLASH_DEBUG_A + 16'd1)
`define FLASH_DEBUG_READ_COUNT_L 16'd1
`define FLASH_DEBUG_PROG_COUNT_A (`FLASH_DEBUG_A + 16'd2 )
`define FLASH_DEBUG_PROG_COUNT_L 16'd1
`define FLASH_DEBUG_WRITE_FAIL_COUNT_A (`FLASH_DEBUG_A + 16'd3)
`define FLASH_DEBUG_WRITE_FAIL_COUNT_L 16'd1
`define FLASH_DEBUG_READ_FAIL_COUNT_A (`FLASH_DEBUG_A + 16'd4)
`define FLASH_DEBUG_READ_FAIL_COUNT_L 16'd1
`define FLASH_DEBUG_PROG_FAIL_COUNT_A (`FLASH_DEBUG_A + 16'd5)
`define FLASH_DEBUG_PROG_FAIL_COUNT_L 16'd1
`define FLASH_DEBUG_WRITE_TRANS_COUNT_A (`FLASH_DEBUG_A + 16'd6)
`define FLASH_DEBUG_WRITE_TRANS_COUNT_L 16'd1
`define FLASH_DEBUG_READ_TRANS_COUNT_A (`FLASH_DEBUG_A + 16'd7)
`define FLASH_DEBUG_READ_TRANS_COUNT_L 16'd1

`define FLASH_PAGE_STATUS_A (`FLASH_A)
`define FLASH_PAGE_STATUS_L 16'd1

`define FLASH_STATUS_A (`FLASH_PAGE_STATUS_A + `FLASH_PAGE_STATUS_L)
`define FLASH_STATUS_L 16'd1

`define FLASH_DIRTY_PAGE_A (`FLASH_STATUS_A + `FLASH_STATUS_L)
`define FLASH_DIRTY_PAGE_L 16'd1

`define FLASH_DATA_A (`FLASH_DIRTY_PAGE_A + `FLASH_DIRTY_PAGE_L)
`define FLASH_DATA_L (16'd64512)
