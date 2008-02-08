ifeq ($(VPACKAGE),)
VPACKAGE = MODELSIM
endif

ifeq ($(VPACKAGE),MODELSIM) 
include Makefile.modelsim
else
include Makefile.iverilog
endif

default: sim

