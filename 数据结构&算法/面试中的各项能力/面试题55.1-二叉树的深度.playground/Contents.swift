

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
    func maxDepth(_ root: TreeNode?) -> Int {
        //递归寻找左右两边子树的深度，较大一边 + 1就是当前节点的深度。
        //从下至上回到根节点求出最大深度
        if root == nil {
            return 0
        }
        
        let leftDepth = maxDepth(root?.left)
        let rightDepth = maxDepth(root?.right)
        
        return (leftDepth > rightDepth) ? leftDepth + 1 : rightDepth + 1
    }
}

let node1 = TreeNode.init(3)
let node2 = TreeNode.init(1)
let node3 = TreeNode.init(2)
let node4 = TreeNode.init(4)
let node5 = TreeNode.init(5)
node1.left = node2
node1.right = node3
node3.left = node4
node3.right = node5

let solution = Solution.init()
let result = solution.maxDepth(node1)
print("result = \(result)")
