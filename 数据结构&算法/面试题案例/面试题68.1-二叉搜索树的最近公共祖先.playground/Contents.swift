
public class TreeNode {
    public var val: Int
    public var left: TreeNode?
    public var right: TreeNode?
    public init(_ val: Int) {
        self.val = val
        self.left = nil
        self.right = nil
    }
}


class Solution {
    func lowestCommonAncestor(_ root: TreeNode?, _ p: TreeNode?, _ q: TreeNode?) -> TreeNode? {
        //因为是二叉搜索树，所以中间节点比左边大、比右边小
        //所以输入的两个节点的值 来判断
        //如果是其中一个值是循环到的根节点，说明说该节点
        //如果循环到的节点大于输入的两个节点，则说明在左侧，继续往左侧查找
        //如果循环到的节点小于输入的两个节点，则说明在右侧，继续往右侧查找
        if root == nil || p == nil || q == nil {
            return nil
        }
        var result = root
        while result != nil {
            
            if (result!.val > p!.val && result!.val < q!.val) || (result!.val < p!.val && result!.val > q!.val) || result!.val == p!.val || result!.val == q!.val {
                break
            }
            
            if result!.val > p!.val && result!.val > q!.val {
                result = result?.left
            }
            
            if result!.val < p!.val && result!.val < q!.val {
                result = result?.right
            }
            
        }
        return result
    }
}

let node1 = TreeNode.init(6)
let node2 = TreeNode.init(2)
let node3 = TreeNode.init(8)
let node4 = TreeNode.init(0)
let node5 = TreeNode.init(4)
let node6 = TreeNode.init(3)
let node7 = TreeNode.init(5)
let node8 = TreeNode.init(7)
let node9 = TreeNode.init(0)

node1.left = node2
node2.left = node4
node1.right = node3
node2.right = node5
node5.left = node6
node5.right = node7
node3.left = node8
node3.right = node9

let solution = Solution.init()
let result = solution.lowestCommonAncestor(node1, node6, node7)

print("result = \(result?.val ?? -1)")

/*
 //C++的解法
 class Solution {
 public:
     TreeNode* lowestCommonAncestor(TreeNode* root, TreeNode* p, TreeNode* q) {
             if(root == NULL || (root->left == NULL && root->right == NULL)) return NULL;
             while (root) {
                 if((root->val > p->val && root->val < q->val) || (root->val < p->val && root->val > q->val) || root->val == p->val || root->val == q->val) return root;

                 if(root->val > p->val && root->val > q->val) root = root->left;
                 if(root->val < p->val && root->val < q->val) root = root->right;
             }
             return root;
         }
 };

 */
