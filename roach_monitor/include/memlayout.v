`ifndef RM_MEM_LAYOUT
`define RM_MEM_LAYOUT

//0
`define MEM_SYSCONF_A  16'h0
`define MEM_SYSCONF_H  16'h3F
//1
`define MEM_FROM_A     16'h40
`define MEM_FROM_H     16'hBF
//2
`define MEM_ACM_A      16'hC0
`define MEM_ACM_H      16'h13F
//3
`define MEM_ADC_A      16'h140
`define MEM_ADC_H      16'h17F
//4
`define MEM_LEVCHK_A   16'h180
`define MEM_LEVCHK_H   16'h23F
//5
`define MEM_VALS_A     16'h240
`define MEM_VALS_H     16'h27F
//6
`define MEM_PWRMAN_A   16'h280  
`define MEM_PWRMAN_H   16'h2BF
//7
`define MEM_IRQC_A     16'h2C0
`define MEM_IRQ_H      16'h2FF
//8
`define MEM_FANC_A     16'h300
`define MEM_FANC_H     16'h33F
//9
`define MEM_GPIO_A   16'h340
`define MEM_GPIO_H   16'h37F
//10
`define MEM_FLASHMEM_A 16'h3C0
`define MEM_FLASHMEM_H 16'hFFFF

`endif
