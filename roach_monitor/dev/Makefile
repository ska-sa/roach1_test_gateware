include Makefile.defs


default:
	@echo ""
	@echo "Invalid make option: select one of the following"
	@echo "sim, build_parameters, synth, par, bits, clean"
	@echo ""


sim: $(SRC)
	@make -C $(MODULES_DIR) sim

build_parameters: 
	make -C $(SUPPORT_DIR) build_parameters \
		MODULE_ID=$(MODULE_ID) \
		REV_MAJOR=$(REV_MAJOR) \
		REV_MINOR=$(REV_MINOR) \
		INCLUDE=../$(INCLUDE_DIR) \
		FLASHROM_F=$(FLASHROM_F) \
		FLASHMEM_F=$(FLASHMEM_F) \
		CHEADER_F=$(CHEADER_F)
	cp $(SUPPORT_DIR)/$(CHEADER_F) $(GEN_DIR)/$(CHEADER_F)

# Synthesis
synth: $(GEN_DIR)/$(SYNTH_FILE)

$(GEN_DIR)/$(SYNTH_FILE): $(SRC) build_parameters
	@make -C $(SYNTH_DIR) $(SYNTH_FILE) \
		PROJECT=$(PROJECT) \
		TOPLEVEL=$(TOPLEVEL) \
		SRC="$(addprefix ../,$(SRC))" \
		INCLUDE="$(addprefix ../,$(INCLUDE_DIR))"
	@cp $(SYNTH_DIR)/$(SYNTH_FILE) $(GEN_DIR)/$(SYNTH_FILE)

# PAR

bits: $(GEN_DIR)/$(BIT_FILE)

$(GEN_DIR)/$(BIT_FILE): synth
	@make -C $(PAR_DIR) $(BIT_FILE) \
		FLASHROM_UFC=../$(SUPPORT_DIR)/$(FLASHROM_F) \
		FLASHMEM_EFC=../$(SUPPORT_DIR)/$(FLASHMEM_F) \
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
	make -C $(MODULES_DIR) clean 
	make -C $(SYNTH_DIR) clean \
		PROJECT=$(PROJECT)
	make -C $(SUPPORT_DIR) clean \
		FLASHROM_F=$(FLASHROM_F) \
		FLASHMEM_F=$(FLASHMEM_F) \
		CHEADER_F=$(CHEADER_F)
	rm -rf ./$(GEN_DIR)/$(SYNTH_FILE)
	rm -rf ./$(GEN_DIR)/$(BIT_FILE)
	rm -rf ./$(GEN_DIR)/$(CHEADER_F)
