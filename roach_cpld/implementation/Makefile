include Makefile.defs

bits: $(PROJECT).jed 

#NGC
$(PROJECT).ngd: $(NETLIST) $(PCFILE) $(PROJ_FILE)
	$(NGDBUILD) $(addprefix -sd ,$(NETLIST_DIRS)) -uc $(PCFILE) -p $(PARTNUM) $(NGDBUILD_FLAGS) $< $@ >& ngdbuild.log


#CPLD COMMANDS
$(PROJECT).vm6: $(PROJECT).ngd
	$(CPLDFIT) $(CPLDFIT_FLAGS) -p $(PARTNUM) $< >& cpldfit.log
	$(TAEGINE) -f $(PROJECT) $(TAENGINE_FLAGS) >& taegine.log

$(PROJECT).jed: $(PROJECT).vm6
	$(HPREP6) -i $< $(HPREP6_FLAGS) >& hprep6.log


#MISC

clean:
	rm -rf *.log *.srp *.ngr *.ngc xst *.lso *.blc *.bld *.xml *.chk *.cxt *.gyd *.jed *.mfd *.ngd *.pad *.csv *.pnx *.rpt *.vm6 *.lst *.err *.cmd *.xst *.prj *.par *.pcf *.xpi *.unroutes *.txt *.ngm *.bit *.drc *.bgn *.ncd *.mrp tmpscript *.sig *.prm *.mcs *.map *.dat *.tspec *.phd *.tim *.data *.mod *.xrpt xlnx_auto*

