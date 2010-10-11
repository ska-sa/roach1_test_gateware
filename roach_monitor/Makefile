include Makefile.defs


default:
	@echo ""
	@echo "Invalid make option: select one of the following"
	@echo "sim, bits, build, build_parameters, synth, par, clean"
	@echo ""


sim: $(SRC)
	@make -C $(MODULES_DIR) sim

build:
	@if svn st | grep -q "^[^?]" ; then \
	   echo "error: svn not up-to-date"; \
	   false; \
	   fi
	@echo "Updating RCS"
	@svn up
	@rm -f ./$(INCLUDE_DIR)/build_parameters.v
	@make -C . bits \
	   RCS_UPTODATE=1 REV_RCS=`svn info|grep Revision |cut -d ' ' -f 2`

build_parameters: 
	@make -C $(SUPPORT_DIR) build_parameters \
		MODULE_ID=$(MODULE_ID) \
		REV_MAJOR=$(REV_MAJOR) \
		REV_MINOR=$(REV_MINOR) \
		REV_RCS=$(REV_RCS) \
		RCS_UPTODATE=$(RCS_UPTODATE) \
		INCLUDE=../$(INCLUDE_DIR) \
		FLASHROM_F=$(FLASHROM_F) \
		CHEADER_F=$(CHEADER_F)
	@cp $(SUPPORT_DIR)/$(CHEADER_F) $(GEN_DIR)/$(CHEADER_F)
	@cp $(SUPPORT_DIR)/$(FLASHROM_F) $(GEN_DIR)/$(FLASHROM_F)

# Synthesis
synth: $(GEN_DIR)/$(SYNTH_FILE)

$(GEN_DIR)/$(SYNTH_FILE): $(SRC) build_parameters
	@make -C $(SYNTH_DIR) $(SYNTH_FILE) \
		PROJECT=$(PROJECT) \
		TOPLEVEL=$(TOPLEVEL) \
		SRC="$(addprefix ../,$(SRC))" \
		INCLUDE="$(addprefix ../,$(INCLUDE_DIR))"
	@if [ $(GEN_DIR)/$(SYNTH_FILE) -ot $(SYNTH_DIR)/$(SYNTH_FILE) ] ; then \
	cp $(SYNTH_DIR)/$(SYNTH_FILE) $(GEN_DIR)/$(SYNTH_FILE); fi
	@if [ ! -e $(GEN_DIR)/$(SYNTH_FILE) ] ; then \
	cp $(SYNTH_DIR)/$(SYNTH_FILE) $(GEN_DIR)/$(SYNTH_FILE); fi

# PAR

bits: $(GEN_DIR)/$(BIT_FILE)

$(GEN_DIR)/$(BIT_FILE): synth
	@make -C $(PAR_DIR) $(BIT_FILE) \
		FLASHROM_UFC=../$(SUPPORT_DIR)/$(FLASHROM_F) \
		SYNTH_F=../$(GEN_DIR)/$(SYNTH_FILE) \
		CONSTRAINTS_P=../$(CONSTRAINTS_P) \
		CONSTRAINTS_T=../$(CONSTRAINTS_T) \
		PROJECT=$(PROJECT) \
		BIT_FILE=$(BIT_FILE)
	@cp $(PAR_DIR)/$(BIT_FILE) $(GEN_DIR)/$(BIT_FILE)

clean:
	make -C $(PAR_DIR) clean \
		PROJECT=$(PROJECT) \
		BIT_FILE=$(BIT_FILE)
	make -C $(SYNTH_DIR) clean \
		PROJECT=$(PROJECT)
	make -C $(SUPPORT_DIR) clean \
		FLASHROM_F=$(FLASHROM_F) \
		FLASHMEM_F=$(FLASHMEM_F) \
		CHEADER_F=$(CHEADER_F)
	rm -rf ./$(GEN_DIR)/*
