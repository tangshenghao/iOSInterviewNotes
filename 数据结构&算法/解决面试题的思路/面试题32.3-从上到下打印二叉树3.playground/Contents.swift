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
    func levelOrder(_ root: TreeNode?) -> [[Int]] {
        
        if root == nil {
            return []
        }
        
        var result:[[Int]] = []
        var tempQueue:[[TreeNode?]] = [[],[]]
        
        //此题需要用到两个辅助栈
        //先将节点加入队列中，然后将队头的数值加入到数组中，然后删除队列
        //奇数层按左右子节点顺序加入队列中，偶数层按右左顺序
        
        //多出两个变量，一个是表示当前层数时奇数还是偶数用
        //另一个是用于切换栈的标识
        
        var current = 0
        var next = 1
        var tempArray:[Int] = []
        
        tempQueue[current].append(root)
        
        while tempQueue[0].count > 0 || tempQueue[1].count > 0 {
            let temp = tempQueue[current].last!
            tempQueue[current].removeLast()
            if let tempVal = temp?.val {
                tempArray.append(tempVal)
            }
            if current == 0 {
                if temp?.left != nil {
                    tempQueue[next].append(temp?.left)
                }
                if temp?.right != nil {
                    tempQueue[next].append(temp?.right)
                }
            } else {
                if temp?.right != nil {
                    tempQueue[next].append(temp?.right)
                }
                if temp?.left != nil {
                    tempQueue[next].append(temp?.left)
                }
                
            }
            
            if tempQueue[current].count == 0 {
                result.append(tempArray)
                tempArray = []
                next = 1 - next
                current = 1 - current
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

tree1.left = tree2
tree1.right = tree3
tree3.left = tree4
tree3.right = tree5

let solution = Solution.init()
print("\(solution.levelOrder(tree1))")
