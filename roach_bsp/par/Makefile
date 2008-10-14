include Makefile.defs

bits: $(if $(IS_CPLD),$(PROJECT).jed,$(PROJECT).bit) 

$(PROJECT).ngd: $(NETLIST) $(PCFILE)
	$(NGDBUILD) $(addprefix -sd ,$(NETLIST_DIRS)) -uc $(PCFILE) -p $(PARTNUM) $(NGDBUILD_FLAGS) $< $@ >& ngdbuild.log

#FPGA COMMANDS

$(PROJECT).pcf: $(PROJECT).ngd
	$(MAP_ENV) $(MAP) $(MAP_FLAGS) -p $(PARTNUM) -o $(PROJECT)_map.ncd $< $@ >& map.log
	@./gen_util_report.sh $(PROJECT)_map.mrp > util_report.csv

$(PROJECT).ncd: $(PROJECT).pcf
	$(PAR_ENV) $(PAR) $(PAR_FLAGS) $(PROJECT)_map.ncd $@ $^ >& par.log

$(PROJECT).twr: $(PROJECT).ncd
	$(TRCE) $(TRCE_FLAGS) -o $@ $^ >& trce.log
	@(grep -q "Timing errors: 0" $@ || echo "warning: timing errors in design")

$(PROJECT).bit: $(PROJECT).twr 
	$(BITGEN) $(BITGEN_FLAGS) $(PROJECT).ncd $@ >& bitgen.log


#CPLD COMMANDS
$(PROJECT).vm6: $(PROJECT).ngd
	$(CPLDFIT) $(CPLDFIT_FLAGS) -p $(PARTNUM) $< >& cpldfit.log
	$(TAEGINE) -f $(PROJECT) $(TAENGINE_FLAGS) >& taegine.log

$(PROJECT).jed: $(PROJECT).vm6
	$(HPREP6) -i $< $(HPREP6_FLAGS) >& hprep6.log
	@cp $@ $(GEN_DIR)/$@


#MISC

clean:
	rm -rf *.log *.srp *.ngr *.ngc xst *.lso *.blc *.bld *.xml *.chk *.cxt *.gyd *.jed *.mfd *.ngd *.pad *.csv *.pnx *.rpt *.vm6 *.lst *.err *.cmd *.xst *.prj *.par *.pcf *.xpi *.unroutes *.txt *.ngm *.bit *.drc *.bgn *.ncd *.mrp tmpscript *.sig *.prm *.mcs *.map *.dat *.tspec *.phd *.tim *.data *.mod *.msk *.twr *.xrpt *.ptwx *_xdb *.twx *.ise *.bin *.csv

