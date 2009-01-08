create_clock  -name {infrastructure_inst/rcclock/RCOSC1:CLKOUT} -period 10.000 -waveform { 0.000 5.000 }  { infrastructure_inst/rcclock/RCOSC1:CLKOUT }

create_generated_clock  -name {infrastructure_inst/clocks/PLL_inst:GLB} -divide_by 95  -multiply_by 38  -source { infrastructure_inst/clocks/PLL_inst:CLKA }  { infrastructure_inst/clocks/PLL_inst:GLB }
