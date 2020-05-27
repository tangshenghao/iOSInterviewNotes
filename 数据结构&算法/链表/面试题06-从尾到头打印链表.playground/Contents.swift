
public class ListNode {
    public var val: Int
    public var next: ListNode?
    public init(_ val: Int) {
        self.val = val
        self.next = nil
    }
}

class Solution {
    func reversePrint(_ head: ListNode?) -> [Int] {
        if let headNode = head {
            //使用递归
            var result = self.reversePrint(headNode.next)
            result.append(headNode.val)
            return result
        } else {
            return []
        }
    }
}

let soluton = Solution.init()

let nodeOne = ListNode.init(1)
let nodeTwo = ListNode.init(2)
let nodeThree = ListNode.init(3)

nodeOne.next = nodeTwo
nodeTwo.next = nodeThree

let result = soluton.reversePrint(nodeOne)

print("result = \(result)")

//栈的思维，先进后出。关联使用递归方式
