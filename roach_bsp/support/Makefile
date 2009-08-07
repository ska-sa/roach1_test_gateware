VCC=iverilog
VSIM=vvp

PARAM_V=$(INCDIR)/build_parameters.v

DEFINES=-DREV_MAJOR=\"$(REV_MAJOR)\" \
        -DREV_MINOR=\"$(REV_MINOR)\" \
        -DREV_RCS=\"$(REV_RCS)\" \
        -DRCS_UPTODATE=\"$(RCS_UPTODATE)\" \

pre_support:

post_support:

build_parameters: $(PARAM_V)

$(PARAM_V): gen_build_parameters.v $(MAKEDEFS)
	$(VCC) $(DEFINES) $<
	@$(VSIM) a.out > $@
	@rm a.out

clean:
	rm -f $(PARAM_V)
