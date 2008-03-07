MODULE=crc_generic
INC_DIR=./include

OBJ=$(MODULE).o
SRC=$(MODULE).v

VCC=iverilog
INCLUDE=-I .
FLAGS=-Wall
DEFINES=-DSIMULATION

VSIM=vvp

default: $(SRC)
	@$(VCC) $(INCLUDE) $(FLAGS) $(DEFINES) -o $(OBJ) $^
	@$(VSIM) $(OBJ)
	@rm $(OBJ)
