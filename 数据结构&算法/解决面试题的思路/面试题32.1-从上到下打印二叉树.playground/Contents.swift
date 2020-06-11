
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
    func levelOrder(_ root: TreeNode?) -> [Int] {
        
        if root == nil {
            return []
        }
        
        var result:[Int] = []
        var tempQueue:[TreeNode?] = []
        
        //此题需要用到辅助队列
        //先将节点加入队列中，然后将队头的数值加入到数组中，然后删除队列
        //然后将左右子节点加入队列中
        tempQueue.append(root)
        
        while tempQueue.count > 0 {
            let temp = tempQueue.first!
            tempQueue.removeFirst()
            if let tempVal = temp?.val {
                result.append(tempVal)
            }
            if temp?.left != nil {
                tempQueue.append(temp?.left)
            }
            if temp?.right != nil {
                tempQueue.append(temp?.right)
            }
        }
        return result
    }
}

let tree1 = TreeNode.init(3)
let tree2 = TreeNode.init(9)
let tree3 = TreeNode.init(20)
let tree4 = TreeNode.init(15)
let tree5 = TreeNode.init(7)
let tree6 = TreeNode.init(8)
tree1.left = tree2
tree1.right = tree3
tree3.left = tree4
tree3.right = tree5
tree2.left = tree6

let solution = Solution.init()
print("\(solution.levelOrder(tree1))")
