CC = $(CROSS_COMPILE)gcc
CFLAGS = -Wall
CFLAGS += -DDEBUG -ggdb
INC = -Ikatcp
LIB = -Lkatcp -lkatcp
RM = rm -f

EXE = client

$(EXE): client.c
	$(CC) $(CFLAGS) $(INC) -o $@ $^ $(LIB)

clean: 
	$(RM) $(EXE)
