
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
    func mirrorTree(_ root: TreeNode?) -> TreeNode? {
        //此题递归所有有子节点的节点 然后交换左右子节点
        if root == nil {
            return nil
        }
        if root?.left != nil || root?.right != nil {
            //交换位置
            let tempNode = root?.left
            root?.left = root?.right
            root?.right = tempNode
            
            mirrorTree(root?.left)
            mirrorTree(root?.right)
        }
        return root
    }
}

let solution = Solution.init()

let tree1 = TreeNode.init(4)
let tree2 = TreeNode.init(2)
let tree3 = TreeNode.init(7)
let tree4 = TreeNode.init(1)
let tree5 = TreeNode.init(3)
let tree6 = TreeNode.init(6)
let tree7 = TreeNode.init(9)
tree1.left = tree2
tree1.right = tree3
tree2.left = tree4
tree2.right = tree5
tree3.left = tree6
tree3.right = tree7

let result = solution.mirrorTree(tree1)

print(result?.left?.val)

