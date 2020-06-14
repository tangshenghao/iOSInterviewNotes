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
    //此题用回溯法。前序遍历所有节点
    //到叶节点时判断是否符合条件
    func pathSum(_ root: TreeNode?, _ sum: Int) -> [[Int]] {
        
        if root == nil {
            return []
        }
        
        var result:[[Int]] = []
        var pathArray:[Int] = []
        
        
        
        pathSumCore(root, sum, &pathArray, &result)
        
        return result
        
    }
    
    func pathSumCore(_ root: TreeNode?, _ sum: Int, _ pathArr: inout [Int], _ result: inout [[Int]]) {
        
        let rootVal = root?.val
        pathArr.append(rootVal!)
        
        if root?.left == nil && root?.right == nil {
            var tempSum = 0
            for item in pathArr {
                tempSum += item
            }
            
            if tempSum == sum {
                result.append(pathArr)
            }
            return
        }
        
        if root?.left != nil {
            pathSumCore(root?.left, sum, &pathArr, &result)
            pathArr.removeLast()
        }
        
        if root?.right != nil {
            pathSumCore(root?.right, sum, &pathArr, &result)
            pathArr.removeLast()
        }
    }
}

let tree1 = TreeNode.init(5)
let tree2 = TreeNode.init(4)
let tree3 = TreeNode.init(8)
let tree4 = TreeNode.init(11)
let tree5 = TreeNode.init(13)
let tree6 = TreeNode.init(4)
let tree7 = TreeNode.init(7)
let tree8 = TreeNode.init(2)
let tree9 = TreeNode.init(5)
let tree10 = TreeNode.init(1)

tree1.left = tree2
tree1.right = tree3
tree2.left = tree4
tree4.left = tree7
tree4.right = tree8
tree3.left = tree5
tree3.right = tree6
tree6.left = tree9
tree6.right = tree10

let solution = Solution.init()
let result = solution.pathSum(tree1, 22)

print("result = \(result)")
