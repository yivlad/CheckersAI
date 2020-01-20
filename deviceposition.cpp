#define WHITE_KING 'K'
#define BLACK_KING 'Q'

#include <iostream>
#include <fstream>

class Position{
    private:
        char board[8][8];
        char move;
        void endMove(){
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
        void getPossibleJumps(int i, int j, int prevDirection, Position* p, int* n){
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
        bool hasPossibleJumps(int i, int j){
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
        void getPossibleMoves(Position* p, int* n){
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
        bool hasPossibleMoves(){
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
        void getPossibleJumps(Position* p, int* n){
            for(int i = 0; i < 8; i++){
                for(int j = 0; j < 8; j++){
                    getPossibleJumps(i, j, -1, p, n);
                }
            }
        }
    public:
        Position(char board[8][8], char move){
            for(int x = 0; x < 8; x++){
                for(int y = 0; y < 8; y++){
                    this->board[x][y] = board[x][y];
                }
            }
            this->move = move;
        }
        Position(const Position& another){
            for(int x = 0; x < 8; x++){
                for(int y = 0; y < 8; y++){
                    this->board[x][y] = another.board[x][y];
                }
            }
            this->move = another.move;
        }
        bool min(){
            if(move == 'B') return true;
            return false;
        }
        void getPossiblePositions(Position* p, int* n){
            this->getPossibleJumps(p, n);
            if(*n != 0) return;
            this->getPossibleMoves(p, n);
        }
        bool hasPossiblePositions(){
            for(int i = 0; i < 8; i++){
                for(int j = 0; j < 8; j++){
                    if(hasPossibleJumps(i, j)) return true;
                }
            }
            if(hasPossibleMoves()) return true;
            return false;
        }
        double evaluate(){
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
        friend std::ostream& operator<<(std::ostream& out, const Position& p){
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

double minimax(Position pos, int depth){
    double heuristic = pos.evaluate();
    if(heuristic == 100 || heuristic == -100 || depth == 0) return heuristic;
    Position* p = (Position*) malloc(50 * sizeof(Position));
    int n = 0;
    pos.getPossiblePositions(p, &n);
    double cur;
    if(pos.min()) cur = 200;
    else cur = -200;
    for(int i = 0; i < n; i++){
        double e = minimax(p[i], depth - 1);
        if(pos.min()){
            if(e < cur) cur = e;
        }else{
            if(e > cur) cur = e;
        }
    }
    free(p);
    return cur;
}

int main()
{
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
    Position* p = (Position*) malloc(50 * sizeof(Position));
    int n = 0;
    pos.getPossiblePositions(p, &n);
    int index = -1;
    double cur;
    if(pos.min()) cur = 200;
    else cur = -200;
    for(int i = 0; i < n; i++){
        double e = minimax(p[i], 6);
        if(pos.min()){
            if(e < cur) {
                cur = e;
                index = i;
            }
        }else{
            if(e > cur) {
                cur = e;
                index = i;
            }
        }
    }
    Position best = p[index];
    std::ofstream output;
    output.open("output.txt");
    output << best << std::endl;
    free(p);
    return EXIT_SUCCESS;
}