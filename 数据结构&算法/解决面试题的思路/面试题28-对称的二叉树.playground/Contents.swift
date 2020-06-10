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
    func isSymmetric(_ root: TreeNode?) -> Bool {
        
        if root == nil {
            return false
        }
        return isSymmetricTwoTreeNode(root, root)
    }
    
    //此题分别判断左右两边节点的反向节点的值是否相等
    // 一级左节点的右节点 和 一级左节点的左节点 比较 类似向下递归
    func isSymmetricTwoTreeNode(_ root1: TreeNode? , _ root2: TreeNode?) -> Bool {
        if root1 == nil && root2 == nil {
            return true
        }
        if root1 == nil || root2 == nil {
            return false
        }
        if root1?.val != root2?.val {
            return false
        }
        return isSymmetricTwoTreeNode(root1?.left, root2?.right) && isSymmetricTwoTreeNode(root1?.right, root2?.left)
    }
}

let solution = Solution.init()

let tree1 = TreeNode.init(1)
let tree2 = TreeNode.init(2)
let tree3 = TreeNode.init(2)
let tree4 = TreeNode.init(3)
let tree5 = TreeNode.init(4)
let tree6 = TreeNode.init(4)
let tree7 = TreeNode.init(3)
tree1.left = tree2
tree1.right = tree3
tree2.left = tree4
tree2.right = tree5
tree3.left = tree6
tree3.right = tree7

let result = solution.isSymmetric(tree1)

print("result = \(result)")
