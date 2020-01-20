#include "deviceposition.cpp"
#include <vector>

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
            for(auto v : node->next){
                clean(v);
            }
            delete node;
        }
        void expand(TreeNode* node, int depth){
            if(depth == 0){
                node->index = leaves;
                leaves++;
            }
            node->calculatenext();
            for(auto p : node->next){
                expand(p, depth - 1);
            }
        }
        double traverse(TreeNode* node, double* estimations){
            if(node->next.size() == 0){
                if(node->index == -1){
                    return node->estimate;
                }
                else{
                    return estimations[node->index];
                }
            }
            double cur;
            if(node->pos.min()) cur = 200;
            else cur = -200;
            for(auto p : node->next){
                double e = traverse(p, estimations);
                if(node->pos.min()){
                    if(e < cur) cur = e;
                }else{
                    if(e > cur) cur = e;
                }
            }
            return cur;
        }
        void leavestoarray(TreeNode* node, Position* p){
            if(node->index != -1){
                p[node->index] = node->pos;
                return;
            }
            for(auto n : node->next){
                leavestoarray(n, p);
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
        double traverse(double* estimations){
            return traverse(root, estimations);
        }
        int getleaves(){
            return leaves;
        }
        ~Tree(){
            clean(root);
        }
};