include Makefile.defs

default:
	@echo ""
	@echo "Invalid make option: select one of the following"
	@echo "bits, sim, build_parameters, clean"
	@echo ""

sim: $(SRC)
	@echo "not implemented"

bits: build_parameters
	@make -C build bits \
	   PROJ_FILE="../Makefile.defs" \
	   SRC="$(addprefix ../,$(SRC))" PCFILE="$(addprefix ../,$(PCFILE))" \
	   PROJECT=$(PROJECT) TOPLEVEL_MODULE=$(TOPLEVEL_MODULE) \
	   PARTNUM=$(PARTNUM) VINC="$(addprefix ../,$(VINC))" \
	   GEN_DIR=../$(GEN_DIR) \
	   NETLIST_DIRS="$(addprefix  ../,$(NETLIST_DIRS))"
	cp build/$(PROJECT).bit gen/$(PROJECT)_$(REV_MAJOR)_$(REV_MINOR).bit

build_parameters:
	@make -C support build_parameters \
	   PROJECT=$(PROJECT) REV_MAJOR=$(REV_MAJOR) REV_MINOR=$(REV_MINOR) \
	   REV_RCS="0" MAKEDEFS=../Makefile.defs INCDIR=../$(VINC)\
	   BOARD_ID=$(BOARD_ID) C_HEADER=../$(GEN_DIR)/$(PROJECT)_$(REV_MAJOR).h

data2mem: bits
	@make -C support/data2mem download.bit \
	   DOWNLOAD_BIT=../../$(GEN_DIR)/download.bit \
	   BITFILE=../../build/$(PROJECT).bit NCDFILE=../../build/$(PROJECT).ncd
	   
	   
	
clean:
	make -C modules clean
	make -C build clean
	make -C support clean INCDIR=../$(VINC) GENDIR=../$(GEN_DIR)
	rm -rf gen/*

