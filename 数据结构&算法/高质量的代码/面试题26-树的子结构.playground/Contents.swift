

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
    func isSubStructure(_ A: TreeNode?, _ B: TreeNode?) -> Bool {
        var result = false
        //此题遍历所有的A节点去判断是否与B相等
        if A != nil && B != nil {
            //根节点
            if A?.val == B?.val {
                result = tree1HaveTree2(A, B)
            }
            //左节点
            if !result {
                result = isSubStructure(A?.left, B)
            }
            //右节点
            if !result {
                result = isSubStructure(A?.right, B)
            }
        }
        
        return result
    }
    
    func tree1HaveTree2(_ A: TreeNode?, _ B: TreeNode?) -> Bool {
        //当B为空时，说明已经匹配完
        if B == nil {
            return true
        }
        //当A为空时，B没有为空，说明没有匹配完
        if A == nil {
            return false
        }
        //对应的值不同
        if A?.val != B?.val {
            return false
        }
        //继续往左右遍历
        return tree1HaveTree2(A?.left, B?.left) && tree1HaveTree2(A?.right, B?.right)
    }
}

let solution = Solution.init()

let tree1 = TreeNode.init(3)
let tree2 = TreeNode.init(4)
let tree3 = TreeNode.init(5)
let tree4 = TreeNode.init(1)
let tree5 = TreeNode.init(2)
tree1.left = tree2
tree1.right = tree3
tree2.left = tree4
tree2.right = tree5

let tree11 = TreeNode.init(4)
let tree12 = TreeNode.init(1)
tree11.left = tree12

print("result = \(solution.isSubStructure(tree1, tree11))")







