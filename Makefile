CC=g++
CFLAGS= -Wall
NVCC=/opt/cuda/bin/nvcc
NFLAGS= --cudart static --relocatable-device-code=false -gencode arch=compute_20,code=compute_20 -gencode arch=compute_20,code=sm_20 -lineinfo -link 

all: cpu gpu
cpu: cpu.cpp
	${CC} ${CFLAGS} -o cpu cpu.cpp
gpu: gpu.cu
	${NVCC} ${NFLAGS} -I/opt/cuda/samples/common/inc/ -o gpu gpu.cu