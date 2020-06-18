
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
    func kthLargest(_ root: TreeNode?, _ k: Int) -> Int {
        //使用反向中序遍历即可找到第K大的值
        if k <= 0 || root == nil {
            return 0
        }
        var tempK = k
        return kthLargestCore(root, &tempK)
    }
    
    func kthLargestCore(_ root: TreeNode?, _ k: inout Int) -> Int {
        var tempValue = Int.min
        if root?.right != nil {
            tempValue = kthLargestCore(root?.right, &k)
        }
        
        if tempValue == Int.min {
            
            if k == 1 {
                tempValue = root?.val ?? Int.min
                return tempValue
            }
            
            k -= 1
        }
        
        if root?.left != nil && tempValue == Int.min {
            tempValue = kthLargestCore(root?.left, &k)
        }
        
        return tempValue
    }
}


let node1 = TreeNode.init(3)
let node2 = TreeNode.init(1)
let node3 = TreeNode.init(4)
let node4 = TreeNode.init(2)
node1.left = node2
node1.right = node3
node2.right = node4

let solution = Solution.init()
let result = solution.kthLargest(node1, 2)
print("result = \(result)")
