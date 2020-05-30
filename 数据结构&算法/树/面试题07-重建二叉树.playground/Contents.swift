
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
        
        if preorder.count == 0 {
            return nil
        }
        //用map来存储中序中的位置和值
        var map = [Int : Int]()
        for (i, value) in inorder.enumerated() {
            map[value] = i
        }
        
        var resultTreeNode = TreeNode.init(preorder[0])
        self.findchildNodeTree(preorder, inorder, rootTreeNode: &resultTreeNode, preStart: 0, preEnd: preorder.count - 1, inStart: 0, inEnd: inorder.count - 1, map: map)
        
        return resultTreeNode
    }
    
    func findchildNodeTree(_ preorder: [Int], _ inorder: [Int], rootTreeNode : inout TreeNode, preStart: Int, preEnd: Int, inStart: Int, inEnd: Int, map: [Int: Int]) {
        if preStart >= preEnd {
            return
        }
        
        //根节点在中序中的下标
        guard let rootIndex = map[preorder[preStart]] else { return }
        //左部分长度
        let leftCount = rootIndex - inStart
        if leftCount > 0 {
            //前序的最开始后的1位为左节点
            var leftTreeNode = TreeNode.init(preorder[preStart + 1])
            rootTreeNode.left = leftTreeNode
            //将前序和中序的左部分位置传入继续递归
            self.findchildNodeTree(preorder, inorder, rootTreeNode: &leftTreeNode, preStart: preStart + 1, preEnd: preStart + leftCount, inStart: inStart, inEnd: rootIndex - 1, map: map)
        }
        //右部分长度
        let rightCount = inEnd - rootIndex
        if rightCount > 0 {
            //前序的右部分第一个为右节点
            var rightTreeNode = TreeNode.init(preorder[preEnd - rightCount + 1])
            rootTreeNode.right = rightTreeNode
            //将前序和中序的右部分位置传入继续递归
            self.findchildNodeTree(preorder, inorder, rootTreeNode: &rightTreeNode, preStart: preEnd - rightCount + 1, preEnd: preEnd, inStart: rootIndex + 1, inEnd: inEnd, map: map)
        }
    }
}

let solution = Solution.init()
let result = solution.buildTree([3,9,20,15,7],
[9,3,15,20,7])
//print("result = \(String(describing: result?.val))")
