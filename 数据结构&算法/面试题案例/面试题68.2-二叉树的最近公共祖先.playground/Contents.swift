
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
        //p 和 q 在 root 的子树中，且分列 root 的 异侧（即分别在左、右子树中）；
        //p=root ，且 q 在 root 的左或右子树中；
        //q=root ，且 p 在 root 的左或右子树中；

        //递归对二叉树进行后序遍历，当遇到节点 p 或 q 时返回。从底至顶回溯，当节点 p, q 在节点 root 的异侧时，节点 root 即为最近公共祖先，则向上返回 root

        
        if root == nil {
            return nil
        }
        
        if root === p || root === q {
            return root
        }
        
        let left = lowestCommonAncestor(root?.left, p, q)
        let right = lowestCommonAncestor(root?.right, p, q)
        
        if left != nil && right != nil {
            return root
        }
        return left != nil ? left : right
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
             if(root == NULL)return NULL;
             if(root == p||root == q)return root;
             TreeNode* left = lowestCommonAncestor(root->left, p, q);
             TreeNode* right = lowestCommonAncestor(root->right, p, q);
             if(left && right)return root;
             return left ? left : right; // 只有一个非空则返回该指针，两个都为空则返回空指针
         }
 };

 */
