
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
    func buildTree(_ preorder: [Int], _ inorder: [Int]) -> TreeNode? {
        return buildTreeCore(0, preorder.count - 1, 0, inorder.count - 1, preorder, inorder)
    }
    
    func buildTreeCore(_ preLeft: Int, _ preRight: Int, _ inLeft: Int, _ inRight: Int, _ preorder: [Int], _ inorder: [Int]) -> TreeNode? {
        // 当仅有一个数时直接返回一个结点
        if preLeft == preRight {
            let node = TreeNode(preorder[preLeft])
            return node
        } else if preLeft > preRight || inLeft > inRight {
            // 当位置超过时返回nil
            return nil
        }
        // 前序第一个节点为根节点
        let firstVal = preorder[preLeft]
        let firstNode = TreeNode(firstVal)
        
        // 寻找中序中的根位置
        var inLeftIndex = inLeft
        var inMidIndex = -1
        while inLeftIndex <= inRight {
            if inorder[inLeftIndex] == firstVal {
                inMidIndex = inLeftIndex
                break
            }
            inLeftIndex += 1
        }
        if (inMidIndex == -1) {
            return nil
        }
        
        // 左部分递归
        let leftNode = self.buildTreeCore(preLeft + 1, preLeft + (inMidIndex - inLeft), inLeft, inLeft + (inMidIndex - inLeft) - 1, preorder, inorder)
        // 右部分递归
        let rightNode = self.buildTreeCore(preRight - (inRight - inMidIndex) + 1, preRight, inRight - (inRight - inMidIndex) + 1 , inRight, preorder, inorder)
        
        firstNode.left = leftNode
        firstNode.right = rightNode
        return firstNode
    }
}

let solution = Solution.init()
let result = solution.buildTree([3,9,20,15,7],
[9,3,15,20,7])
//print("result = \(String(describing: result?.val))")
