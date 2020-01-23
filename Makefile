CC=g++
CFLAGS= -Wall
NVCC=/opt/cuda/bin/nvcc
NFLAGS= --cudart static --relocatable-device-code=false -gencode arch=compute_35,code=compute_35 -gencode arch=compute_35,code=sm_35 -lineinfo -link

all: cpu gpu
cpu: cpu.cpp
	${CC} ${CFLAGS} -o cpu cpu.cpp
gpu: gpu.cu
	${NVCC} ${NFLAGS} -I/opt/cuda/samples/common/inc/ -o gpu gpu.cu