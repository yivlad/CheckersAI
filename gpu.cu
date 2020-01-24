#define WHITE_KING 'K'
#define BLACK_KING 'Q'
#define CPU_depth 4
#define GPU_depth 3

#include <iostream>
#include <fstream>
#include <vector>
#include <cuda_runtime.h>
#include <helper_cuda.h>
#include <helper_functions.h>

class Position{
private:
    char board[8][8];
    char move;
    __device__ __host__ void endMove(){
        for(int i = 0; i < 8; i++){
            for(int j = 0; j < 8; j++){
                if(board[i][j] == 'T') board[i][j] = '#';
            }
        }
        for(int j = 0; j < 8; j++){
            if(board[0][j] == 'W') board[0][j] = WHITE_KING;
            if(board[7][j] == 'B') board[7][j] = BLACK_KING;
        }
        move = move == 'W' ? 'B' : 'W';
    }
    __device__ __host__ void getPossibleJumps(int i, int j, int prevDirection, Position* p, int* n){
        char rival = move == 'W' ? 'B' : 'W';
        char king = move == 'W' ? WHITE_KING : BLACK_KING;
        char rivalking = king == WHITE_KING ? BLACK_KING : WHITE_KING;
        if(board[i][j] == move){
            if(move == 'W' && i == 0) board[i][j] = WHITE_KING;
            if(move == 'B' && i == 7) board[i][j] = BLACK_KING;
            for(int direction = 0; direction < 4; direction++){
                int stepi = ((direction & 1) << 1) - 1,
                    stepj =  (((direction >> 1) & 1) << 1) - 1;
                if(i + 2 * stepi > -1 && j + 2 * stepj > -1 && 
                    i + 2 * stepi < 8 && j + 2 * stepj < 8 &&
                    board[i + 2 * stepi][j + 2 * stepj] == '#'){
                    if(board[i + stepi][j + stepj] == rival || 
                        board[i + stepi][j +stepj] == rivalking){
                        Position branch = *this;
                        branch.board[i][j] = '#';
                        branch.board[i + 2 * stepi][j + 2 * stepj] = move;
                        branch.board[i + stepi][j + stepj] = 'T';
                        int currentN = *n;
                        branch.getPossibleJumps(i + 2 * stepi, j + 2 * stepj, direction, p, n);
                        if(currentN == *n){
                            branch.endMove();
                            p[*n] = branch;
                            (*n)++;
                        }
                    }
                }
            }
        }
        int opposite = 3 - prevDirection;
        if(board[i][j] == king){
            for(int direction = 0; direction < 4; direction++){
                if(direction == opposite) continue;
                int stepi = ((direction & 1) << 1) - 1,
                    stepj =  (((direction >> 1) & 1) << 1) - 1;
                int ri = i + stepi, rj = j + stepj;
                while(ri > -1 && ri < 8 && rj > -1 && rj < 8 && board[ri][rj] == '#')
                {
                    ri += stepi;
                    rj += stepj;
                }
                if(!(ri > -1 && ri < 8 && rj > -1 && rj < 8)) continue;
                if(board[ri][rj] != rival && board[ri][rj] != rivalking){
                    continue;
                }
                int ki = ri + stepi, kj = rj + stepj;
                while(ki > -1 && ki < 8 && kj > -1 && kj < 8 && board[ki][kj] == '#')
                {
                    Position branch = *this;
                    branch.board[i][j] = '#';
                    branch.board[ki][kj] = king;
                    branch.board[ri][rj] = 'T';
                    int currentN = *n;
                    branch.getPossibleJumps(i + 2 * stepi, j + 2 * stepj, direction, p, n);
                    if(currentN == *n){
                        branch.endMove();
                        p[*n] = branch;
                        (*n)++;
                    }
                    ki += stepi;
                    kj += stepj;
                }
            }
        }
    }
    __device__ __host__ bool hasPossibleJumps(int i, int j){
        char rival = move == 'W' ? 'B' : 'W';
        char king = move == 'W' ? WHITE_KING : BLACK_KING;
        char rivalking = king == WHITE_KING ? BLACK_KING : WHITE_KING;
        if(board[i][j] == move){
            if(move == 'W' && i == 0) board[i][j] = WHITE_KING;
            if(move == 'B' && i == 7) board[i][j] = BLACK_KING;
            for(int direction = 0; direction < 4; direction++){
                int stepi = ((direction & 1) << 1) - 1,
                    stepj =  (((direction >> 1) & 1) << 1) - 1;
                if(i + 2 * stepi > -1 && j + 2 * stepj > -1 && 
                    i + 2 * stepi < 8 && j + 2 * stepj < 8 &&
                    board[i + 2 * stepi][j + 2 * stepj] == '#'){
                    if(board[i + stepi][j + stepj] == rival || 
                        board[i + stepi][j +stepj] == rivalking){
                            return true;
                    }
                }
            }
        }
        if(board[i][j] == king){
            for(int direction = 0; direction < 4; direction++){
                int stepi = ((direction & 1) << 1) - 1,
                    stepj =  (((direction >> 1) & 1) << 1) - 1;
                int ri = i + stepi, rj = j + stepj;
                while(ri > -1 && ri < 8 && rj > -1 && rj < 8 && board[ri][rj] == '#')
                {
                    ri += stepi;
                    rj += stepj;
                }
                if(!(ri > -1 && ri < 8 && rj > -1 && rj < 8)) continue;
                if(board[ri][rj] != rival && board[ri][rj] != rivalking){
                    continue;
                }
                int ki = ri + stepi, kj = rj + stepj;
                if(ki > -1 && ki < 8 && kj > -1 && kj < 8 && board[ki][kj] == '#')
                {
                    return true;
                }
            }
        }
        return false;
    }
    __device__ __host__ void getPossibleMoves(Position* p, int* n){
        int direction = move == 'W' ? -1: 1;
        for(int i = 0; i < 8; i++){
            for(int j = 0; j < 8; j++){
                if(board[i][j] == move){
                    if(i + direction < 8 && i + direction > -1){
                        if(j - 1 > 0 && board[i + direction][j - 1] == '#'){
                            Position branch = *this;
                            branch.board[i][j] = '#';
                            branch.board[i + direction][j - 1] = move;
                            branch.endMove();
                            p[*n] = branch;
                            (*n)++;
                        }
                        if(j + 1 < 8 && board[i + direction][j + 1] == '#'){
                            Position branch = *this;
                            branch.board[i][j] = '#';
                            branch.board[i + direction][j + 1] = move;
                            branch.endMove();
                            p[*n] = branch;
                            (*n)++;
                        }
                    }
                }
            }
        }
        char king = move == 'W' ? WHITE_KING : BLACK_KING;
        for(int i = 0; i < 8; i++){
            for(int j = 0; j < 8; j++){
                if(board[i][j] == king){
                    for(direction = 0; direction < 4; direction++){
                        int stepi = ((direction & 1) << 1) - 1,
                            stepj =  (((direction >> 1) & 1) << 1) - 1;
                        int x = i + stepi, y = j + stepj;
                        while(x > -1 && x < 8 && y > -1 && y < 8 && board[x][y] == '#'){
                            Position branch = *this;
                            branch.board[i][j] = '#';
                            branch.board[x][y] = king;
                            branch.endMove();
                            p[*n] = branch;
                            (*n)++;
                            x += stepi;
                            y += stepj;
                        }
                    }
                }
            }
        }
    }
    __device__ __host__ bool hasPossibleMoves(){
        int direction = move == 'W' ? -1: 1;
        for(int i = 0; i < 8; i++){
            for(int j = 0; j < 8; j++){
                if(board[i][j] == move){
                    if(i + direction < 8 && i + direction > -1){
                        if(j - 1 > 0 && board[i + direction][j - 1] == '#'){
                            return true;
                        }
                        if(j + 1 < 8 && board[i + direction][j + 1] == '#'){
                            return true;
                        }
                    }
                }
            }
        }
        char king = move == 'W' ? WHITE_KING : BLACK_KING;
        for(int i = 0; i < 8; i++){
            for(int j = 0; j < 8; j++){
                if(board[i][j] == king){
                    for(direction = 0; direction < 4; direction++){
                        int stepi = ((direction & 1) << 1) - 1,
                            stepj =  (((direction >> 1) & 1) << 1) - 1;
                        int x = i + stepi, y = j + stepj;
                        if(x > -1 && x < 8 && y > -1 && y < 8 && board[x][y] == '#'){
                            return true;
                        }
                    }
                }
            }
        }
        return false;
    }
    __device__ __host__ void getPossibleJumps(Position* p, int* n){
        for(int i = 0; i < 8; i++){
            for(int j = 0; j < 8; j++){
                getPossibleJumps(i, j, -1, p, n);
            }
        }
    }
public:
    __host__ Position(char board[8][8], char move){
        for(int x = 0; x < 8; x++){
            for(int y = 0; y < 8; y++){
                this->board[x][y] = board[x][y];
            }
        }
        this->move = move;
    }
    __device__ __host__ Position(const Position& another){
        for(int x = 0; x < 8; x++){
            for(int y = 0; y < 8; y++){
                this->board[x][y] = another.board[x][y];
            }
        }
        this->move = another.move;
    }
    __device__ __host__ bool min(){
        if(move == 'B') return true;
        return false;
    }
    __device__ __host__ void getPossiblePositions(Position* p, int* n){
        *n = 0;
        this->getPossibleJumps(p, n);
        if(*n != 0) return;
        this->getPossibleMoves(p, n);
    }
    __device__ __host__ bool hasPossiblePositions(){
        for(int i = 0; i < 8; i++){
            for(int j = 0; j < 8; j++){
                if(hasPossibleJumps(i, j)) return true;
            }
        }
        if(hasPossibleMoves()) return true;
        return false;
    }
    __device__ __host__ double evaluate(){
        if(!hasPossiblePositions()){
            if(move == 'W') return -100;
            else return 100;
        }
        bool f = false;
        for(int i = 0; i < 8; i++){
            for(int j = 0; j < 8; j++){
                if(board[i][j] == 'W' || board[i][j] == WHITE_KING) f = true;
            }
        }
        if(!f) return -100;
        f = false;
        for(int i = 0; i < 8; i++){
            for(int j = 0; j < 8; j++){
                if(board[i][j] == 'B' || board[i][j] == BLACK_KING) f = true;
            }
        }
        if(!f) return 100;
        double balance = 0;
        for(int i = 0; i < 8; i++){
            for(int j = 0; j < 8; j++){
                char p = board[i][j];
                if(p == 'W'){
                    double coeff = 1;
                    if(j == 0 || j == 7){
                        coeff *= 0.9;
                    }
                    if(i == 6){
                        coeff *= 1.5;
                    }
                    balance += coeff * 1;
                }
                if(p == 'B'){
                    double coeff = 1;
                    if(j == 0 || j == 7){
                        coeff *= 0.9;
                    }
                    if(i == 1){
                        coeff *= 1.5;
                    }
                    balance += coeff * (-1);
                }
                if(p == WHITE_KING) balance += 3.5;
                if(p == BLACK_KING) balance -= 3.5;
            }
        }
        return balance;
    }
    __host__ friend std::ostream& operator<<(std::ostream& out, const Position& p){
        out << p.move << std::endl;
        for(int i = 0; i < 8; i++){
            for(int j = 0; j < 8; j++){
                out << p.board[i][j];
            }
            out << std::endl;
        }
        return out;
    }
};

class TreeNode {
public:
    Position pos;
    double estimate;
    int index;
    std::vector<TreeNode*> next;
    TreeNode(Position pos) : pos(pos) {
        index = -1;
    }
    void calculatenext(){
        estimate = pos.evaluate();
        if(estimate == 100 || estimate == -100) return;
        Position* p = (Position*) malloc(50 * sizeof(Position));
        int n = 0;
        pos.getPossiblePositions(p, &n);
        for(int i = 0; i < n; i++){
            next.push_back(new TreeNode(p[i]));
        }
        free(p);
    }
};

class Tree{
private:
    int leaves; 
    TreeNode* root;
    void clean(TreeNode* node){
        for(int i =0; i < node->next.size(); i++){
            clean(node->next[i]);
        }
        delete node;
    }
    void expand(TreeNode* node, int depth){
        if(depth == 0){
            node->index = leaves;
            leaves++;
            return;
        }
        node->calculatenext();
        for(int i =0; i < node->next.size(); i++){
            expand(node->next[i], depth - 1);
        }
    }
    void traverse(TreeNode* node, double* estimations){
        if(node->next.size() == 0){
            if(node->index != -1){
                node->estimate = estimations[node->index];
            }
            return;
        }
        double cur;
        if(node->pos.min()) cur = 200;
        else cur = -200;
        for(int i = 0; i < node->next.size(); i++){
            TreeNode* p = node->next[i];
            traverse(p, estimations);
            double e = p->estimate;
            if(node->pos.min()){
                if(e < cur) cur = e;
            }else{
                if(e > cur) cur = e;
            }
        }
        node->estimate = cur;
    }
    void leavestoarray(TreeNode* node, Position* p){
        if(node->index != -1){
            p[node->index] = node->pos;
            return;
        }
        for(int i = 0; i < node->next.size(); i++){
            leavestoarray(node->next[i], p);
        }
    }
public:
    Tree(Position pos, int depth){
        root = new TreeNode(pos);
        leaves = 0;
        expand(root, depth);
    }
    void leavestoarray(Position* p){
        leavestoarray(root, p);
    }
    void traverse(double* estimations){
        traverse(root, estimations);
    }
    int getleaves(){
        return leaves;
    }
    Position bestmove(){
        int index = -1;
        if(root->pos.min()){
            double min = 200;
            for(int i = 0; i < root->next.size(); i++){
                if(root->next[i]->estimate < min){
                    min = root->next[i]->estimate;
                    index = i;
                }
            }
        }
        else
        {
            double max = -200;
            for(int i = 0; i < root->next.size(); i++){
                if(root->next[i]->estimate > max){
                    max = root->next[i]->estimate;
                    index = i;
                }
            }
        }
        return root->next[index]->pos;
    }
    ~Tree(){
        clean(root);
    }
};

class MinimaxStackNode {
public:
    int max, cur;
    double* estimates;
    Position* positions;
    __device__ MinimaxStackNode() {
        positions = (Position*) malloc(50 * sizeof(Position));
        estimates = (double*) malloc(50 * sizeof(double));
    }
    __device__ ~MinimaxStackNode(){
        free(positions);
        free(estimates);
    }
};

__device__ double minimax(Position* pos){
    MinimaxStackNode stack[GPU_depth];
    pos->getPossiblePositions(stack[0].positions, &stack[0].max);
    stack[0].cur = 0;
    int current_node = 0;
    while(current_node >= 0){
        if(stack[current_node].cur < stack[current_node].max){
            int i = stack[current_node].cur;
            double heuristic = stack[current_node].positions[i].evaluate();
            if(current_node < GPU_depth - 1 && heuristic != 100 && heuristic != -100){
                stack[current_node].positions[i].getPossiblePositions(stack[current_node + 1].positions, &stack[current_node + 1].max);
                stack[current_node + 1].cur = 0;
                current_node++;
            }
            else{
                stack[current_node].estimates[i] = heuristic;
                stack[current_node].cur++;
            }
        }else{
            current_node--;
            if(current_node < 0) break;
            if(stack[current_node].positions[stack[current_node].cur].min()){
                double min = 200;
                for(int i = 0; i < stack[current_node + 1].max; i++){
                    if(stack[current_node + 1].estimates[i] < min){
                        min = stack[current_node + 1].estimates[i];
                    }
                }
                stack[current_node].estimates[stack[current_node].cur] = min;
            }
            else{
                double max = -200;
                for(int i = 0; i < stack[current_node + 1].max; i++){
                    if(stack[current_node + 1].estimates[i] > max){
                        max = stack[current_node + 1].estimates[i];
                    }
                }
                stack[current_node].estimates[stack[current_node].cur] = max;
            }
            stack[current_node].cur++;
        }
    }
    if(pos->min()){
        double min = 200;
        for(int i = 0; i < stack[0].max; i++){
            if(stack[0].estimates[i] < min){
                min = stack[0].estimates[i];
            }
        }
        return min;
    }
    else{
        double max = -200;
        for(int i = 0; i < stack[0].max; i++){
            if(stack[0].estimates[i] > max){
                max = stack[0].estimates[i];
            }
        }
        return max;
    }
}

__global__ void checkers_kernel(Position* d_p, double* d_e, int n){
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    if(index < n){
        d_e[index] = minimax(d_p + index);
    }
}

int main(){
    std::ifstream input;
    input.open("input.txt");
    char board[8][8];
    char move;
    move = input.get();
    input.ignore();
    for(int i = 0; i < 8; i++){
        for(int j = 0; j < 8; j++){
            board[i][j] = input.get();
        }
        input.ignore(1);
    }
    input.close();
    Position pos(board, move);
    double heuristic = pos.evaluate();
    if(heuristic == 100){
        std::cout << "White wins!" << std::endl;
        return EXIT_SUCCESS;
    }
    if(heuristic == -100){
        std::cout << "Black wins!" << std::endl;
        return EXIT_SUCCESS;
    }
    Tree gametree(pos, CPU_depth);
    int l = gametree.getleaves();
    Position* p = (Position*) malloc(sizeof(Position) * l);
    double* h_e;
    h_e = (double*) malloc(sizeof(double) * l);
    gametree.leavestoarray(p);
    Position* d_p;
    double* d_e;
    checkCudaErrors(cudaDeviceSetLimit(cudaLimitStackSize, 1024 * 4));
    checkCudaErrors(cudaDeviceSetLimit(cudaLimitMallocHeapSize, 1024 * 1024 * 512));
    checkCudaErrors(cudaMalloc((void**)&d_p, sizeof(Position) * l));
    checkCudaErrors(cudaMalloc((void**)&d_e, sizeof(double) * l));
    checkCudaErrors(cudaMemcpy(d_p, p, sizeof(Position) * l, cudaMemcpyHostToDevice));
    int threads = 64;
    int blocks = l / threads;
    if(l % threads != 0) blocks++;
    checkers_kernel<<<blocks, threads>>>(d_p, d_e, l);
    cudaDeviceSynchronize();
    checkCudaErrors(cudaMemcpy(h_e, d_e, sizeof(double) * l, cudaMemcpyDeviceToHost));
    cudaFree(d_e);
    cudaFree(d_p);
    gametree.traverse(h_e);
    Position best = gametree.bestmove();
    std::ofstream output;
    output.open("output.txt");
    output << best << std::endl;
    output.close();
    free(p);
    free(h_e);
    return EXIT_SUCCESS;
}