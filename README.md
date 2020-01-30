# Checkers AI

This project consists of two parts: CPU and GPU via CUDA framework CheckersAI.

## Getting started

Running Makefile will produce two output executable files - "cpu" and "gpu". Both of them use "input.txt" file to get input. Example of "input.txt" is provided in project folder. Input should be a valid checkers position, such as:\
W\
\#B#B#B#B\
B#B#B#B#\
\#B#B#B#B\
\########\
\########\
W#W#W#W#\
\#W#W#W#W\
W#W#W#W#\
\- a valid start position. First letter denotes whose turn it is - W for white and B for black. Empty cells are marked by #(hashtag), white pieces - W, black pieces - B, white king - K, black king - Q.
Both "cpu" and "gpu" executables produce "output.txt" as an output, where the best found move will be presented in form of position after this move.


### How it works

CPU version uses simple minimax algorithm.
GPU version is a bit modified minimax. First levels of minimax game tree are built on host, with leaves at the bottom. Kernel takes every leaf and treats it like start position for every thread to obtain evaluations of all leaves. Every thread evaluates given position by building own minimax tree, going several levels down the tree and then calculating heuristic evalutaion of positions in leaves. After every leaf in host gametree is evaluated by kernel, host traverses its gametree upwards and gets evaluations of positions that are one move away from starting position, and takes the best one. 