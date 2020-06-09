

public class ListNode {
    public var val: Int
    public var next: ListNode?
    public init(_ val: Int) {
        self.val = val
        self.next = nil
    }
}

class Solution {
    func getKthFromEnd(_ head: ListNode?, _ k: Int) -> ListNode? {
        
        //该题通过双指针，先让一个前指针先走K步。
        //然后将另外一个后指针指向头部
        //同时向后移动，当前指针碰到nil时，返回后指针
        if head == nil || k <= 0 {
            return nil
        }
        
        var fastNode = head
        for index in 0..<k {
            
            fastNode = fastNode?.next
            if fastNode == nil && index != k-1 {
                return nil
            }
        }
        
        var slowNode = head
        while fastNode != nil {
            fastNode = fastNode?.next
            slowNode = slowNode?.next
        }
        return slowNode
    }
}

let nodeOne = ListNode.init(1)
let nodeTwo = ListNode.init(2)
let nodeThree = ListNode.init(3)
let nodeFour = ListNode.init(4)
let nodeFive = ListNode.init(5)
nodeOne.next = nodeTwo
nodeTwo.next = nodeThree
nodeThree.next = nodeFour
nodeFour.next = nodeFive

let solution = Solution.init()
let result = solution.getKthFromEnd(nodeOne, 1)?.val
print("result = \(result ?? -1)")

