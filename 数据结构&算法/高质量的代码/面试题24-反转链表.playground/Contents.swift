

public class ListNode {
    public var val: Int
    public var next: ListNode?
    public init(_ val: Int) {
        self.val = val
        self.next = nil
    }
}

class Solution {
    func reverseList(_ head: ListNode?) -> ListNode? {
        
        // 迭代法
        if (head == nil) {
            return nil
        }
        
        var preNode: ListNode? = nil
        var curNode = head
        while curNode != nil {
            let tempNode = curNode?.next
            curNode?.next = preNode
            preNode = curNode
            curNode = tempNode
        }
        return preNode
        
        // 递归法
//        if head?.next == nil {
//            return head
//        }
//        
//        var result = reverseList(head?.next)
//        head?.next?.next = head
//        head?.next = nil
//        return result
    }
}

let nodeOne = ListNode.init(1)
let nodeTwo = ListNode.init(2)
let nodeThree = ListNode.init(3)
let nodeFour = ListNode.init(4)
let nodeFive = ListNode.init(5)
let nodeSix = ListNode.init(6)
nodeOne.next = nodeTwo
nodeTwo.next = nodeThree
nodeThree.next = nodeFour
nodeFour.next = nodeFive
nodeFive.next = nodeSix

let solution = Solution.init()
let result = solution.reverseList(nodeOne)
print("result = \(result?.val ?? -1)")

