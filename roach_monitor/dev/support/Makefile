include Makefile.defs
build_parameters: $(FLASHROM_F) $(FLASHMEM_F) $(CHEADER_F)

$(CHEADER_F): $(MEMLAYOUT_SCRIPT) $(INCLUDE)/memlayout.v
	$(VCC) -I$(INCLUDE) -DREV_MAJOR=$(REV_MAJOR) -DREV_MINOR=$(REV_MINOR) -DMODULE_ID=$(MODULE_ID) -I build -o a.out $< 
	$(VSIM) a.out > $@
	rm a.out

$(FLASHROM_MEM): $(FROM_SCRIPT) 
	$(VCC) -DREV_MAJOR=$(REV_MAJOR) -DREV_MINOR=$(REV_MINOR) -DMODULE_ID=$(MODULE_ID) -I build -o a.out $< 
	$(VSIM) a.out > $@
	rm a.out
	if [ $$(wc -l $@ |sed -e 's/ .*$$//') -ne 128 ] ; then echo "INCORRECT NUMBER OF LINES IN FLASHROM"; rm $@; false ; fi 
	if [ $$(grep -i '^[0123456789abcdef][0123456789abcdef][^\w]*$$' $@ | wc -l) -ne 128  ] ; then echo "INCORRECT ENTRY IN FLASHROM"; rm $@; false ; fi


$(FLASHROM_F): $(FLASHROM_MEM) $(UFC_SCRIPT)
	./$(UFC_SCRIPT) $< > $@
	
$(FLASHMEM_F):
	cp $(FLASHMEM_EFC) $@

clean:
	rm -rf $(FLASHMEM_F) $(CHEADER_F) $(FLASHROM_MEM)
