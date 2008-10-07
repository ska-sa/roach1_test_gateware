MODULE=sys_block

SRCDIR=../hdl
TBDIR=./hdl
GENDIR=./gen

TB_OBJ=$(GENDIR)/TB_$(MODULE).o
TB_SRC=$(TBDIR)/TB_$(MODULE).v
OBJ=$(GENDIR)/$(MODULE).o
SRC=$(SRCDIR)/$(MODULE).v
MSG_FILE=$(GENDIR)/msgs.txt

VCC=iverilog
INCLUDE=-I $(SRCDIR)
FLAGS=-Wall
DEFINES=-DSIMULATION
DEFINES+=-DDEBUG
DEFINES+=-DDESPERATE_DEBUG

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
	rm -Rf ./$(GENDIR)/*
