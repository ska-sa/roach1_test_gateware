include Makefile.defs

default:
	@echo ""
	@echo "Invalid make option: select one of the following"
	@echo "bits, synth, build_parameters, build, clean"
	@echo ""

build:
	@if svn st | grep -q "^[^?]" ; then \
		echo "error: svn not up-to-date"; \
		false; \
	fi
	@touch Makefile.defs
	@svn update
	@make -C . bits RCS_UPTODATE=1 REV_RCS=`svn info|grep Revision |cut -d ' ' -f 2`

sim: $(SRC)
	@echo "not implemented"

bits: synth
	@make -C par bits \
	   PROJ_FILE="../Makefile.defs" \
	   PCFILE="$(addprefix ../,$(PCFILE))" \
	   PROJECT=$(PROJECT) \
	   PARTNUM=$(PARTNUM) \
	   GEN_DIR=../$(GEN_DIR) \
	   NETLIST="../$(NETLIST_DIR)/$(PROJECT).ngc" \
	   NETLIST_DIRS="$(addprefix  ../,$(NETLIST_DIRS))"
	@cp par/$(PROJECT).bit gen/$(PROJECT)_$(REV_MAJOR)_$(REV_MINOR)_$(REV_RCS).bit
	@cp par/$(PROJECT).bin gen/$(PROJECT)_$(REV_MAJOR)_$(REV_MINOR)_$(REV_RCS).bin

synth: build_parameters
	@make -C synthesis netlist \
	   NETLIST="../$(NETLIST_DIR)/$(PROJECT).ngc" \
	   PROJ_FILE="../Makefile.defs" \
	   SRC="$(addprefix ../,$(SRC))" \
	   PROJECT=$(PROJECT) \
	   TOPLEVEL_MODULE=$(TOPLEVEL_MODULE) \
	   PARTNUM=$(PARTNUM) \
	   VINC="$(addprefix ../,$(VINC))" \
	   GEN_DIR=../$(NETLIST_DIR)

build_parameters:
	@make -C support build_parameters \
	   PROJECT=$(PROJECT) REV_MAJOR=$(REV_MAJOR) REV_MINOR=$(REV_MINOR) \
	   REV_RCS=$(REV_RCS) RCS_UPTODATE=$(RCS_UPTODATE) \
	   MAKEDEFS=../Makefile.defs INCDIR=../$(VINC)\
	   BOARD_ID=$(BOARD_ID) C_HEADER=../$(GEN_DIR)/$(PROJECT)_$(REV_MAJOR).h

clean:
	#make -C modules clean
	make -C synthesis clean
	make -C par clean
	make -C support clean INCDIR=../$(VINC) GENDIR=../$(GEN_DIR)
	rm -rf gen/*
	rm -rf netlist/*

