MODULE=debouncer
INCLUDE=-I ../../include
VCC=iverilog
FLAGS=-Wall
DEFINES=-DDEBUG -DDESPERATE_DEBUG
VSIM=vvp

SRCDIR=./../hdl
SRC=$(SRCDIR)/$(MODULE).v
OBJ=$(GEN_DIR)/$(MODULE).o
GEN_DIR=./gen
TB_DIR=./hdl
TB_SRC=$(TB_DIR)/TB_$(MODULE).v
TB_OBJ=$(GEN_DIR)/TB_$(MODULE).o

MSG_FILE=$(GEN_DIR)/msgs.txt

sim: $(MSG_FILE)

$(MSG_FILE): $(TB_OBJ)
	$(VSIM) $^ > $@
	@!(cat $@ | grep FAILED && rm -rf $^)
	@(cat $@ | grep PASSED)

$(TB_OBJ): $(TB_SRC) $(SRC)
	$(VCC) $(INCLUDE) $(FLAGS) $(DEFINES) -o $@ $^

clean:
	rm -Rf $(TB_OBJ) $(OBJ) *.vvp $(MSG_FILE)
