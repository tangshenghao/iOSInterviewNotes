
public class ListNode {
    public var val: Int
    public var next: ListNode?
    public init(_ val: Int) {
        self.val = val
        self.next = nil
    }
}

class Solution {
    func mergeTwoLists(_ l1: ListNode?, _ l2: ListNode?) -> ListNode? {
        
        //此题是双指针分别从头开始比较
        //如果一方是空，则返回另一方
        if l1 == nil {
            return l2
        } else if l2 == nil {
            return l1
        }
        
        //比较两个指针的较小一方然后赋值到headNode
        //接着递归，小的一方传入next作为参数
        var headNode:ListNode? = nil
        
        guard let l1value = l1?.val else {
            return headNode
        }
        guard let l2value = l2?.val else {
            return headNode
        }
        if l1value <= l2value {
            headNode = l1
            headNode?.next = mergeTwoLists(l1?.next, l2)
        } else {
            headNode = l2
            headNode?.next = mergeTwoLists(l1, l2?.next)
        }
        return headNode
    }
}

let nodeOne1 = ListNode.init(1)
let nodeTwo1 = ListNode.init(2)
let nodeThree1 = ListNode.init(4)
let nodeOne2 = ListNode.init(1)
let nodeTwo2 = ListNode.init(3)
let nodeThree2 = ListNode.init(4)
nodeOne1.next = nodeTwo1
nodeTwo1.next = nodeThree1
nodeOne2.next = nodeTwo2
nodeTwo2.next = nodeThree2


let solution = Solution.init()
let result = solution.mergeTwoLists(nodeOne1, nodeOne2)
print("result = \(result?.val ?? -1) ")
