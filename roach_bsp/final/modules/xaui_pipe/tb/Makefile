MODULE=xaui_pipe

VCC=iverilog
VSIM=vvp

SRCDIR=../hdl
TBDIR=./hdl
GENDIR=./gen

TB_OBJ=$(GENDIR)/TB_$(MODULE).o
TB_SRC=$(TBDIR)/TB_$(MODULE).v
OBJ=$(GENDIR)/$(MODULE).o
SRC=$(SRCDIR)/$(MODULE).v $(SRCDIR)/xaui_v7_2.v $(SRCDIR)/xaui_fifo.v $(SRCDIR)/transfer_engine.v $(SRCDIR)/xaui_controller.v $(SRCDIR)/xaui_wb_attach.v
MSG_FILE=$(GENDIR)/msgs.txt

INCLUDE=-I $(SRCDIR)
FLAGS=-Wall
DEFINES=-DIVERILOG
DEFINES+=-DSIMULATION
DEFINES+=-DDEBUG
DEFINES+=-DDESPERATE_DEBUG
DEFINES+=-DIVERILOG_060807DEV_WORKAROUND



sim: $(MSG_FILE)

$(MSG_FILE): $(TB_OBJ) 
	$(VSIM) $(TB_OBJ) > $@
	@!(cat $@ | grep FAILED && rm -rf $^)
	@(cat $@ | grep PASSED)

#$(TB_OBJ): $(TB_SRC) $(SRC)
$(TB_OBJ): $(TB_SRC) $(SRC)
	$(VCC) $(INCLUDE) $(FLAGS) $(DEFINES) -o $@ $^

clean:
	rm -Rf ./$(GENDIR)/*
