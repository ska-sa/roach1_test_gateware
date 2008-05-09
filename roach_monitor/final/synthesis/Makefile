include Makefile.defs


default:
	@echo "not implemented"

$(SYNTH_F): $(SYNTH_SCRIPT)
	rm -f $@
	synplify $(SYNTH_SCRIPT) && test -f $@

$(SYNTH_SCRIPT): $(SRC)
	@> $@
	@for i in $(SRC) ; do echo "add_file -verilog \"$$i\"" >> $@; done
	@echo '$(SYNTH_COMMANDS)' | sed -e 's/ *; */\n/g' >> $@

clean:
	rm -rf $(SYNTH_F) $(SYNTH_SCRIPT)
	rm -rf syntmp/ *.log *.msg *.areasrr *.map *.sdf *.srd *.srm *.srr *.srs *.tlg *.sdc .recordref backup coreip *.edn *.run_options *.prj *.txt
