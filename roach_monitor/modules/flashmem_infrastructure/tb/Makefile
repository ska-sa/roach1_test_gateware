MODULE=flashmem_infrastructure

VCC=iverilog
VSIM=vvp

FLAGS=-Wall
DEFINES=-DDEBUG -DDESPERATE_DEBUG

GEN_DIR=./gen
SRCDIR=./../hdl
TB_DIR=./hdl

INCLUDE=-I ./include

SRC=$(SRCDIR)/$(MODULE).v
OBJ=$(GEN_DIR)/$(MODULE).o
TB_SRC=$(TB_DIR)/TB_$(MODULE).v
TB_OBJ=$(GEN_DIR)/TB_$(MODULE).o

MSG_FILE=$(GEN_DIR)/msgs.txt

sim: $(MSG_FILE)

$(MSG_FILE): $(TB_OBJ)
	$(VSIM) $^ > $@
	@!(cat $@ | grep FAILED && rm -rf $^)
	@(cat $@ | grep PASSED)

$(TB_OBJ): $(TB_SRC)
	$(VCC) $(INCLUDE) $(FLAGS) $(DEFINES) -o $@ $^

clean:
	rm -Rf $(TB_OBJ) $(OBJ) *.vcd $(MSG_FILE)
