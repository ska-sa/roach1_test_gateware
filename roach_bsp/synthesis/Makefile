include Makefile.defs

netlist: $(NETLIST)

#XST FILES

$(PROJECT).xst:
	@echo '$(XST_ARGS)' | sed -e 's/, /\n/g' > $(PROJECT).xst

$(PROJECT).prj: $(PROJ_FILE) $(PROJECT).xst
	@> $@
	@for I in $(SRC) ; do \
	   if echo $$I | grep -q "\.vhd" ; then \
	     echo "vhdl work $$I" >> $@; \
	   else \
	     echo "verilog work $$I" >> $@; \
	   fi \
	 done

#FPGA/CPLD COMMANDS
$(NETLIST): $(SRC) $(PROJECT).xst $(PROJECT).prj		
	$(XST) -ifn $(PROJECT).xst >& xst.log
	@cp $(PROJECT).ngc $@

clean:
	rm -rf *.log *.srp *.ngr *.ngc xst *.lso *.blc *.bld *.xml *.chk *.cxt *.gyd *.jed *.mfd *.ngd *.pad *.csv *.pnx *.rpt *.vm6 *.lst *.err *.cmd *.xst *.prj *.par *.pcf *.xpi *.unroutes *.txt *.ngm *.bit *.drc *.bgn *.ncd *.mrp tmpscript *.sig *.prm *.mcs *.map *.dat *.tspec *.phd *.tim *.data *.mod *.msk *.twr *.xrpt *.ptwx *_xdb *.twx *.ise *.bin

