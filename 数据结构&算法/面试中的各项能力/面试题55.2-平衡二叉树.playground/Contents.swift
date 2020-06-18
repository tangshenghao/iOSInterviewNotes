
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
    func isBalanced(_ root: TreeNode?) -> Bool {
        //用后序排序，比较两边节点的深度。
        var depth = 0
        return isBalancedCore(root, &depth)
    }
    
    func isBalancedCore(_ root: TreeNode?, _ depth: inout Int) -> Bool {
        if root == nil {
            depth = 0
            return true
        }
        
        var left = 0
        var right = 0
        if isBalancedCore(root?.left, &left) && isBalancedCore(root?.right, &right) {
            let diff = left - right
            if diff <= 1 && diff >= -1 {
                depth = 1 + (left > right ? left : right)
                return true
            }
        }
        return false
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
let result = solution.isBalanced(node1)
print("result = \(result)")
