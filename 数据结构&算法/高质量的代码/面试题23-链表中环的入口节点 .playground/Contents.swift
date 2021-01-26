

public class ListNode {
    public var val: Int
    public var next: ListNode?
    public init(_ val: Int) {
        self.val = val
        self.next = nil
    }
}

class Solution {
    func detectCycle(_ head: ListNode?) -> ListNode? {
        // 很奇怪找不到23题 leetcode找不到了
        // 类似的在算法库里有一道 142. 环形链表 II
        if head == nil {
            return nil
        }
        
        // 快慢指针确定存在环
        var fastNode = head
        var slowNode = head
        while fastNode?.next != nil && fastNode?.next?.next != nil {
            fastNode = fastNode?.next?.next
            slowNode = slowNode?.next
            if fastNode === slowNode {
                break
            }
        }
        if fastNode?.next == nil || fastNode?.next?.next == nil {
            return nil
        }
        // 将一个指针从头开始走 与当前相遇的位置的指针 同时按一步的频率向前走
        // 再相遇的地方即为入口
        fastNode = head
        while fastNode !== slowNode {
            fastNode = fastNode?.next
            slowNode = slowNode?.next
        }
        return fastNode
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
nodeSix.next = nodeFour

let solution = Solution.init()
let result = solution.detectCycle(nodeOne)
print("result = \(result?.val ?? -1)")

