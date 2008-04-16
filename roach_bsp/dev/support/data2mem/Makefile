include Makefile.defs

BMM_PROTOTYPE = prototype.bmm
BMM_INT       = int.bmm

GEN_BMM_BIN   = ./gen_bmm.sh
DATA2MEM_BIN  = data2mem-9.2

download.bit: $(DOWNLOAD_BIT)

$(DOWNLOAD_BIT): $(BITFILE) $(NCDFILE)
	$(GEN_BMM_BIN) $(BMM_PROTOTYPE) $(BMM_INT) $(BRAM_TAG) $(NCDFILE) $(MLOW) $(MHIGH)
	$(DATA2MEM_BIN) -bm $(BMM_INT) -bt $(BITFILE) -bd $(ELF_FILE) tag $(BRAM_TAG) -o b $@
clean:
	rm -f *.xdl $(BMM_INT)
