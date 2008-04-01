MODULES=$(addsuffix .dummy,$(shell ls | grep -v Makefile))

sim: $(MODULES)

%.dummy:
	@test -d $(basename $@) || ( echo "sim error: no such directory" && false )
	$(MAKE) -C $(basename $@)/tb

#sim:
#	@for I in `ls | grep -v Makefile` ; do \
#           if ! echo $(BLACKLIST) | grep -q $$I ; then \
#             make -C $$I/tb sim || exit 1; \
#           fi \
#         done

clean:
	@for I in `ls | grep -v Makefile` ; do \
           if ! echo $(BLACKLIST) | grep -q $$I ; then \
             $(MAKE) -C $$I/tb clean || exit 1; \
           fi \
         done

