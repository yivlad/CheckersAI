CC=g++
CFLAGS= -Wall

all: cpu deviceposition
cpu: cpu.cpp
	${CC} ${CFLAGS} -o cpu cpu.cpp
deviceposition: deviceposition.cpp
	${CC} ${CFLAGS} -o deviceposition deviceposition.cpp