VCC=iverilog
VSIM=vvp

PARAM_V=$(INCDIR)/build_parameters.v

build_parameters: $(PARAM_V)

$(PARAM_V): gen_build_parameters.v $(MAKEDEFS)
	@$(VCC) $<
	@$(VSIM) a.out > $@
	@rm a.out

clean:
	rm -f $(PARAM_V)
