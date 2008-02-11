MODULE=irq_controller

VCC=iverilog
VSIM=vvp

INCLUDE_DIR=../hdl
SRC_DIR=../hdl
TB_DIR=./hdl
GEN_DIR=./gen

INCLUDE=-I $(INCLUDE_DIR)
FLAGS=-Wall
DEFINES=-DDEBUG 
DEFINES+=-DDESPERATE_DEBUG

SRC=$(SRC_DIR)/$(MODULE).v
TB_SRC=$(TB_DIR)/TB_$(MODULE).v
OBJ=$(GEN_DIR)/$(MODULE).o
TB_OBJ=$(GEN_DIR)/TB_$(MODULE).o

MSG_FILE=$(GEN_DIR)/msgs.txt

sim: $(MSG_FILE)

$(MSG_FILE): $(TB_OBJ)
	$(VSIM) $^ > $@
	@!(cat $@ | grep FAILED && rm -rf $^)
	@(cat $@ | grep PASSED)

$(OBJ): $(SRC)
	$(VCC) $(INCLUDE) $(FLAGS) $(DEFINES) -o $@ $^

$(TB_OBJ): $(TB_SRC) $(SRC)
	$(VCC) $(INCLUDE) $(FLAGS) $(DEFINES) -o $@ $^

clean:
	rm -rf $(TB_OBJ) $(OBJ) $(MSG_FILE)
