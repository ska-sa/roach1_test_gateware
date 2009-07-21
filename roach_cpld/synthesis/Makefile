include Makefile.defs

netlist: $(PROJECT).ngc

$(PROJECT).xst: $(PROJ_FILE) Makefile.defs
	@echo '$(XST_ARGS)' | sed -e 's/, /\n/g' > $(PROJECT).xst

$(PROJECT).prj: $(PROJ_FILE) $(SRC)
	@> $@
	@for I in $(SRC) ; do \
	   if echo $$I | grep -q "\.vhd" ; then \
	     echo "vhdl work $$I" >> $@; \
	   else \
	     echo "verilog work $$I" >> $@; \
	   fi \
	 done

$(PROJECT).ngc: $(PROJECT).xst $(PROJECT).prj		
	$(XST) -ifn $(PROJECT).xst >& xst.log

clean:
	rm -rf *.log *.srp *.ngr *.ngc xst *.lso *.blc *.bld *.xml *.chk *.cxt *.gyd *.jed *.mfd *.ngd *.pad *.csv *.pnx *.rpt *.vm6 *.lst *.err *.cmd *.xst *.prj *.par *.pcf *.xpi *.unroutes *.txt *.ngm *.bit *.drc *.bgn *.ncd *.mrp tmpscript *.sig *.prm *.mcs *.map *.dat *.tspec *.phd *.tim *.data *.mod *.xrpt xlnx_auto*

