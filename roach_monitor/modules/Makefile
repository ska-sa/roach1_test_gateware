include Makefile.defs
sim:
	@for I in `ls | grep -v Makefile` ; do \
           if ! echo $(BLACKLIST) | grep -q $$I ; then \
             make -C $$I/tb sim || exit 1; \
           fi \
         done
clean:
	@for I in `ls | grep -v Makefile` ; do \
           if ! echo $(BLACKLIST) | grep -q $$I ; then \
             VPACKAGE=MODELSIM make -C $$I/tb clean || exit 1; \
             VPACKAGE=IVERILOG make -C $$I/tb clean || exit 1; \
           fi \
         done

