MODULE=v5c_infrastructure

SRCDIR=../hdl
TBDIR=./hdl
GENDIR=./gen
INC_DIR=./include

TB_OBJ=$(GENDIR)/TB_$(MODULE).o
TB_SRC=$(TBDIR)/TB_$(MODULE).v
OBJ=$(GENDIR)/$(MODULE).o
SRC=$(SRCDIR)/$(MODULE).v $(TBDIR)/IBUF.v $(TBDIR)/OBUFE.v
MSG_FILE=$(GENDIR)/msgs.txt

VCC=iverilog
INCLUDE=-I ./$(INC_DIR) -I ./$(SRCDIR)
FLAGS=-Wall
DEFINES=-DIVERILOG
DEFINES+=-DSIMULATION
DEFINES+=-DDEBUG
DEFINES+=-DDESPERATE_DEBUG
DEFINES+=-DIVERILOG_060807DEV_WORKAROUND

VSIM=vvp

sim: $(MSG_FILE)

$(MSG_FILE): $(OBJ) $(TB_OBJ)
	$(VSIM) $(TB_OBJ) > $@
	@!(cat $@ | grep FAILED && rm -rf $^)
	@(cat $@ | grep PASSED)

$(OBJ): $(SRC)
	$(VCC) $(INCLUDE) $(FLAGS) $(DEFINES) -o $@ $^

$(TB_OBJ): $(TB_SRC) $(SRC)
	$(VCC) $(INCLUDE) $(FLAGS) $(DEFINES) -o $@ $^

clean:
	rm -Rf ./$(GENDIR)/* *.vcd
