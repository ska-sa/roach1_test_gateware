create_clock  -name {infrastructure_inst/clock/RCOSC1:CLKOUT} -period 10.000 -waveform { 0.000 5.000 }  { infrastructure_inst/clock/RCOSC1:CLKOUT }
create_generated_clock  -name { infrastructure_inst/clock/clkdivdly_inst:GL } -divide_by 3  -source { infrastructure_inst/clock/RCOSC1:CLKOUT } { infrastructure_inst/clock/clkdivdly_inst:GL  } 
