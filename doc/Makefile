
CC = gcc
CFLAG = -g -o

OBJ = test_read.o test_queue.o

all : ${OBJ}


%.o : %.c
	${CC} ${CFLAG} $@ $<

clean :
	rm -rf *.o* *.dSYM


