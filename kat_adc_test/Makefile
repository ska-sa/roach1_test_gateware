MKBOF=/usr/local/bin/mkbof
build:
	@echo -e "run bits\nexit" > edk.tcl
	edk-10.1 -nw -scr edk.tcl system.xmp
	mkbof -t 3 -o implementation/system.bof -s core_info.tab implementation/system.bin 

clean:
	rm -rf *.log *.tcl platgen* synthesis ppc405* *.make hdl implementation __xps
