build_parameters: $(VINC)/build_parameters.v

$(VINC)/build_parameters.v: $(PROJ_FILE)
	@echo "\`ifndef BUILD_PARAMETERS_H" > $@ 
	@echo "\`define BUILD_PARAMETERS_H" >> $@
	@echo "\`define REV_MAJOR 16'd$(REV_MAJOR)" >> $@
	@echo "\`define REV_MINOR 16'd$(REV_MINOR)" >> $@
	@echo "\`define REV_RCS   16'd$(REV_RCS)" >> $@
	@echo "\`endif" >> $@

clean:
