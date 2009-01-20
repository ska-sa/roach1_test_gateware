include Makefile.defs
build_parameters: $(INCLUDE)/build_parameters.v $(FLASHROM_F) $(FLASHMEM_F) $(CHEADER_F)

$(INCLUDE)/build_parameters.v: ../Makefile.defs
	@echo "\`ifndef BUILD_PARAMETERS_H" > $@ 
	@echo "\`define BUILD_PARAMETERS_H" >> $@
	@echo "\`define REV_MAJOR    16'd$(REV_MAJOR)" >> $@
	@echo "\`define REV_MINOR    16'd$(REV_MINOR)" >> $@
	@echo "\`define REV_RCS      16'd$(REV_RCS)" >> $@
	@echo "\`define RCS_UPTODATE 16'd$(RCS_UPTODATE)" >> $@
	@echo "\`endif" >> $@


$(CHEADER_F): $(MEMLAYOUT_SCRIPT) $(INCLUDE)/memlayout.v
	$(VCC) -I$(INCLUDE) -DREV_MAJOR=$(REV_MAJOR) -DREV_MINOR=$(REV_MINOR) -DMODULE_ID=$(MODULE_ID) -I build -o a.out $< 
	@$(VSIM) a.out > $@
	@rm a.out

$(FLASHROM_MEM): $(FROM_SCRIPT) 
	$(VCC) -DREV_MAJOR=$(REV_MAJOR) -DREV_MINOR=$(REV_MINOR) -DMODULE_ID=$(MODULE_ID) -I build -o a.out $< 
	@$(VSIM) a.out > $@
	@rm a.out
	@if [ $$(wc -l $@ |sed -e 's/ .*$$//') -ne 128 ] ; then echo "INCORRECT NUMBER OF LINES IN FLASHROM"; rm $@; false ; fi 
	@if [ $$(grep -i '^[0123456789abcdef][0123456789abcdef][^\w]*$$' $@ | wc -l) -ne 128  ] ; then echo "INCORRECT ENTRY IN FLASHROM"; rm $@; false ; fi


$(FLASHROM_F): $(FLASHROM_MEM) $(UFC_SCRIPT)
	./$(UFC_SCRIPT) $< > $@

clean:
	rm -rf *.h *.ufc *.mem
