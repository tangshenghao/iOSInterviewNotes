

public class ListNode {
    public var val: Int
    public var next: ListNode?
    public init(_ val: Int) {
        self.val = val
        self.next = nil
    }
}

class Solution {
    //此题leetcode上面略微不同，因为没有给删除的节点的指针。
    //所有还是得循环遍历去找到对应的值
    //如果下个节点值是要删除的值
    //则将当前节点的next指向next.next
    //========
    //在书上如果指定了删除的节点，则只要将要删除
    //节点的下一个节点的value和next都赋值到当前节点即可
    //========
    func deleteNode(_ head: ListNode?, _ val: Int) -> ListNode? {
        var p = head
        if head?.val == val{
            return head?.next
        }
        while p != nil{
            if p?.next?.val == val{
                p?.next = p?.next?.next
                return head
            } else {
                p = p?.next
            }
        }
        return head
    }
}

let nodeOne = ListNode.init(4)
let nodeTwo = ListNode.init(5)
let nodeThree = ListNode.init(1)
let nodeFour = ListNode.init(9)
nodeOne.next = nodeTwo
nodeTwo.next = nodeThree
nodeThree.next = nodeFour

let solution = Solution.init()
let result = solution.deleteNode(nodeOne, 5)
print("result = \(result?.next?.val ?? 0)")

