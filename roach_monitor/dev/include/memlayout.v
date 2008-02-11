`ifndef RM_MEM_LAYOUT
`define RM_MEM_LAYOUT

`define MEM_SYSCONF_A  16'h0
`define MEM_SYSCONF_H  16'h3F
`define MEM_FROM_A     16'h40
`define MEM_FROM_H     16'hBF
`define MEM_ACM_A      16'hC0
`define MEM_ACM_H      16'h13F
`define MEM_ADC_A      16'h140
`define MEM_ADC_H      16'h17F
`define MEM_LEVCHK_A   16'h180
`define MEM_LEVCHK_H   16'h1FF
`define MEM_VALS_A     16'h200
`define MEM_VALS_H     16'h23F
`define MEM_PWRMAN_A   16'h240  
`define MEM_PWRMAN_H   16'h27F
`define MEM_IRQC_A     16'h280
`define MEM_IRQ_H      16'h2BF
`define MEM_FANC_A     16'h2C0
`define MEM_FANC_H     16'h2FF
`define MEM_BUSMON_A   16'h300
`define MEM_BUSMON_H   16'h33F
`define MEM_FLASHMEM_A 16'h3C0
`define MEM_FLASHMEM_H 16'hFFFF

`endif
