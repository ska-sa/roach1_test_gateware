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
	@make -C implementation bits \
	   PROJ_FILE="../Makefile.defs" \
	   PCFILE="$(addprefix ../,$(PCFILE))" \
	   PARTNUM=$(PARTNUM) \
	   PROJECT=$(PROJECT) \
	   NETLIST="../synthesis/$(PROJECT).ngc" \
	   NETLIST_DIRS="$(addprefix  ../,$(NETLIST_DIRS))"
	@cp implementation/$(PROJECT).jed gen/$(PROJECT)_$(REV_MAJOR)_$(REV_MINOR)_$(REV_RCS).jed

synth: build_parameters
	@make -C synthesis netlist \
	   PROJ_FILE="../Makefile.defs" \
	   SRC="$(addprefix ../,$(SRC))" \
	   PROJECT=$(PROJECT) \
	   TOPLEVEL_MODULE=$(TOPLEVEL_MODULE) \
	   PARTNUM=$(PARTNUM) \
	   VINC="$(addprefix ../,$(VINC))"
	@cp synthesis/$(PROJECT).ngc netlist/$(PROJECT)_$(REV_MAJOR)_$(REV_MINOR)_$(REV_RCS).ngc

build_parameters:
	@make -C support build_parameters \
	   PROJECT=$(PROJECT) \
		 REV_MAJOR=$(REV_MAJOR) \
		 REV_MINOR=$(REV_MINOR) \
	   REV_RCS=$(REV_RCS) \
		 RCS_UPTODATE=$(RCS_UPTODATE) \
		 VINC=../$(VINC) \
	   PROJ_FILE="../Makefile.defs"

clean:
	make -C synthesis clean
	make -C implementation clean
	make -C support clean
	rm -rf gen/*
	rm -rf netlist/*

