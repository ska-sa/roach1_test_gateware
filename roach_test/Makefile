include Makefile.defs

default:
	@echo ""
	@echo "Invalid make option: select one of the following"
	@echo "synth, build_parameters, build, clean"
	@echo ""

build:
	@if svn st | grep -q "^[^?]" ; then \
		echo "error: svn not up-to-date"; \
		false; \
	fi
	@touch Makefile.defs
	@svn update
	@make -C . synth RCS_UPTODATE=1 REV_RCS=`svn info|grep Revision |cut -d ' ' -f 2`

sim: $(SRC)
	@echo "not implemented"

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
	@true


clean:
	make -C synthesis clean
	rm -rf gen/*
	rm -rf netlist/*

