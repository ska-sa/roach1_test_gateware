include Makefile.defs

default:
	@echo ""
	@echo "Invalid make option: select one of the following"
	@echo "bits, obuild, sim, build_parameters, clean"
	@echo ""

sim: $(SRC)
	@echo "not implemented"

obuild:
	@if svn st | grep -q "^[^?]" ; then \
	   echo "error: svn not up-to-date"; \
	   false; \
	   fi
	@make -C . bits \
	   RCS_UPTODATE=1 REV_RCS=`svn info|grep Revision |cut -d ' ' -f 2`

bits: build_parameters $(SRC) $(PCFILE) Makefile.defs
	@make -C build bits \
	   PROJ_FILE="../Makefile.defs" \
	   SRC="$(addprefix ../,$(SRC))" PCFILE="$(addprefix ../,$(PCFILE))" \
	   PROJECT=$(PROJECT) TOPLEVEL_MODULE=$(TOPLEVEL_MODULE) \
	   PARTNUM=$(PARTNUM) VINC="$(addprefix ../,$(VINC))" \
	   GEN_DIR=../$(GEN_DIR) \
	   NETLIST_DIRS="$(addprefix  ../,$(NETLIST_DIRS))"
	@cp $(GEN_DIR)/$(PROJECT).jed $(GEN_DIR)/$(PROJECT)_$(REV_MAJOR)_$(REV_MINOR)_$(REV_RCS).jed

build_parameters:
	@make -C support build_parameters \
	   PROJECT=$(PROJECT) REV_MAJOR=$(REV_MAJOR) REV_MINOR=$(REV_MINOR) \
	   REV_RCS=$(REV_RCS) \
	   INCLUDE=../$(VINC) \
	   MODULE_ID=$(MODULE_ID)
	
clean:
	make -C modules clean
	make -C build clean
	rm -rf gen/*

