

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
        
        if head == nil {
            return nil
        }
        
        //用两个指针指，h1开始指向头节点，h2作为前一个节点
        var h1 = head
        var h2:ListNode? = nil
        //如果h1的下一个节点不为空
        while h1?.next != nil {
            let tmp = h1?.next
            h1?.next = h2
            //两个指针向前移动
            h2 = h1
            h1 = tmp
        }
        //最后头节点要指回
        h1?.next = h2
        
        return h1
        
        //此处是根据书本写的三个指针，分别指向前、中、后
//        var preNode: ListNode? = nil
//        var midNode = head
//        var behindNode: ListNode? = nil
//
//        while midNode != nil {
//            let tempNode = midNode?.next
//            if tempNode == nil {
//                behindNode = midNode
//            }
//            midNode?.next = preNode
//            preNode = midNode
//            midNode = tempNode
//        }
//        return behindNode
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

