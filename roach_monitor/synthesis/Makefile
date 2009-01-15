include Makefile.defs

default:
	@echo "not implemented"

$(SYNTH_F): $(SYNTH_SCRIPT)
	@rm -f $@ stdout.log
	synplify -runall $(SYNTH_SCRIPT)
	@echo waiting for synplify to finish
	@while ! (grep -s -q "Return Code" stdout.log) ; do sleep 1; done
	@echo killing synplify
	@/bin/kill -f `ps -W|grep synplify | sed 's/  */ /g'|cut -d ' ' -f 2`
	@! (grep -q "Return Code: 2" stdout.log) 



$(SYNTH_SCRIPT): $(SRC)
	@> $@
	@for i in $(SRC) ; do echo "add_file -verilog \"$$i\"" >> $@; done
	@echo '$(SYNTH_COMMANDS)' | sed -e 's/ *; */\n/g' >> $@

clean:
	rm -rf syntmp/ *.edn *.log *.msg *.areasrr *.map *.sdf *.srd *.srm *.srr *.srs *.tlg *.sdc .recordref backup coreip *.edn *.run_options *.prj *.txt *.pdc *.so *.szr
