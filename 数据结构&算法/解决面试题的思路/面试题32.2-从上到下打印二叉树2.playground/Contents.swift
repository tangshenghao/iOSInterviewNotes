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
        var tempQueue:[TreeNode?] = []
        
        //此题需要用到辅助队列
        //先将节点加入队列中，然后将队头的数值加入到数组中，然后删除队列
        //然后将左右子节点加入队列中
        
        //多出两个变量，一个是该层中还没有打印的节点数
        //另一个是下一层节点的数目
        //每次还没有打印的节点数为0时，则将下一层的数目赋值给还没有打印的节点数
        tempQueue.append(root)
        
        var nextLever = 0
        var toBeAppend = 1
        var tempArray:[Int] = []
        while tempQueue.count > 0 {
            let temp = tempQueue.first!
            if let tempVal = temp?.val {
                tempArray.append(tempVal)
            }
            if temp?.left != nil {
                tempQueue.append(temp?.left)
                nextLever += 1
            }
            if temp?.right != nil {
                tempQueue.append(temp?.right)
                nextLever += 1
            }
            tempQueue.removeFirst()
            toBeAppend -= 1
            if toBeAppend == 0 {
                result.append(tempArray)
                tempArray = []
                toBeAppend = nextLever
                nextLever = 0
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
