
public class ListNode {
    public var val: Int
    public var next: ListNode?
    public init(_ val: Int) {
        self.val = val
        self.next = nil
    }
}


class Solution {
    //此题采用双指针 - 双方同时向前走，走到尽头，走对方的路，总会相遇，相遇的地方就是共同走过的路的起始点
    //总会相遇是因为，分为3段路，x，y和共用的z。
    //x + z + y = y + z + x
    func getIntersectionNode(_ headA: ListNode?, _ headB: ListNode?) -> ListNode? {
        if headA == nil || headB == nil {
            return nil
        }
        var index1 = headA
        var index2 = headB
        
        while index1 !== index2 {
            if index1 != nil {
                index1 = index1?.next
            } else {
                index1 = headB
            }
            
            if index2 != nil {
                index2 = index2?.next
            } else {
                index2 = headA
            }
        }
        return index1
    }
}

let node1 = ListNode.init(1)
let node2 = ListNode.init(2)
let node3 = ListNode.init(3)
let node4 = ListNode.init(4)
let node5 = ListNode.init(5)
let node6 = ListNode.init(6)
let node7 = ListNode.init(7)
let node8 = ListNode.init(8)
node1.next = node2
node2.next = node6
node6.next = node7
node7.next = node8

node3.next = node4
node4.next = node5
node5.next = node6

let solution = Solution.init()
let result = solution.getIntersectionNode(node1, node3)
print("result = \(result?.val ?? -99)")
