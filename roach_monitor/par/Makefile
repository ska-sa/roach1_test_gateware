include Makefile.defs

$(BIT_FILE): $(PROG_SCRIPT) $(FLASHROM_UFC)
	$(PAR_BIN) SCRIPT:$(PROG_SCRIPT) > $(PROG_MSGS)

$(PAR_F): $(PAR_SCRIPT) $(CONSTRAINTS_P) $(CONSTRAINTS_T)
	$(PAR_BIN) SCRIPT:$(PAR_SCRIPT) > $(PAR_MSGS)
	@grep -q "TIMER: Max delay timing requirements have been met." $(PAR_MSGS) || echo "Warning: Timing not met"

$(PROG_SCRIPT): $(PAR_F) 
	@echo "$(PROG_COMMANDS)" | sed -e 's/ *; */\n/g' > $@

$(PAR_SCRIPT): $(SYNTH_F)
	@echo '$(PAR_COMMANDS)' | sed -e 's/ *; */\n/g' > $@

clean:
	rm -rf *.dtf/ *.tmp *.lok *.map *.ufcc *.rpt *.txt *.tcl *.log *.stp *.depends *.pdb *.adb *.ini *.efc1
