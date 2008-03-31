include Makefile.defs

default:
	@echo ""
	@echo "Invalid make option: select one of the following"
	@echo "bits, sim, build_parameters, clean"
	@echo ""

sim: $(SRC)
	@echo "not implemented"

bits: build_parameters $(SRC) $(PCFILE) Makefile.defs
	@rm -f ./$(GEN_DIR)/{*.bit,*.jed}
	@make -C build bits \
	   PROJ_FILE="../Makefile.defs" \
	   SRC="$(addprefix ../,$(SRC))" PCFILE="$(addprefix ../,$(PCFILE))" \
	   PROJECT=$(PROJECT) TOPLEVEL_MODULE=$(TOPLEVEL_MODULE) \
	   PARTNUM=$(PARTNUM) VINC="$(addprefix ../,$(VINC))" \
	   GEN_DIR=../$(GEN_DIR) \
	   NETLIST_DIRS="$(addprefix  ../,$(NETLIST_DIRS))"

build_parameters:
	@make -C support build_parameters \
	   PROJECT=$(PROJECT) REV_MAJOR=$(REV_MAJOR) REV_MINOR=$(REV_MINOR) \
	   REV_RCS="0" MAKEDEFS=../Makefile.defs INCDIR=../$(VINC)\
	   BOARD_ID=$(BOARD_ID) C_HEADER=../$(GEN_DIR)/$(PROJECT)_$(REV_MAJOR).h
	
clean:
	make -C modules clean
	make -C build clean
	make -C build_parameters clean INCDIR=../$(VINC) GENDIR=../$(GEN_DIR)
	rm -rf gen/*

