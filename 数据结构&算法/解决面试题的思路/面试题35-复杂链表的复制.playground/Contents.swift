
public class Node {
    public var val: Int
    public var next: Node?
    public var random: Node?
    public init(_ val: Int) {
        self.val = val
        self.next = nil
        self.random = nil
    }
}


class Solution {
    func copyRandomList(_ head: Node?) -> Node? {
        //此处分三步
        
        //第一步先将自己复制到自己后面 a->a'->b->b'
        cloneNodes(head)
        //第二步将奇数的random赋值到a‘的random上
        connectRandom(head)
        //第三步拆掉奇数的节点，重组链表
        let result = reConnectNodes(head)
        
        return result
    }
    
    func cloneNodes(_ head: Node?) {
        var node = head
        while node != nil {
            let cloneNode = Node.init(0)
            cloneNode.next = node?.next
            cloneNode.val = node?.val ?? 0
            node?.next = cloneNode
            node = cloneNode.next
        }
    }
    
    func connectRandom(_ head: Node?) {
        var node = head
        while node != nil {
            let cloneNode = node?.next
            if node?.random != nil {
                cloneNode?.random = node?.random?.next
            }
            node = cloneNode?.next
        }
    }
    
    func reConnectNodes(_ head: Node?) -> Node? {
        var node = head
        var cloneHead:Node? = nil
        var cloneNode:Node? = nil
        
        if node != nil {
            cloneHead = node?.next
            cloneNode = node?.next
            node?.next = cloneNode?.next
            node = node?.next
        }
        
        while node != nil {
            cloneNode?.next = node?.next
            cloneNode = cloneNode?.next
            node?.next = cloneNode?.next
            node = node?.next
        }
        
        return cloneHead
    }
    
}


let node1 = Node.init(7)
let node2 = Node.init(3)
let node3 = Node.init(1)

node1.next = node2
node2.next = node3

node1.random = node3
node3.random = node1

let solution = Solution.init()
let result = solution.copyRandomList(node1)
print("result = \(result)")


//以下是C++解法
/*

class Node {
public:
    int val;
    Node* next;
    Node* random;
    
    Node(int _val) {
        val = _val;
        next = NULL;
        random = NULL;
    }
};

class Solution {
public:
    Node* copyRandomList(Node* head) {
        CloneNodes(head);
        ConnectRandomNodes(head);
        return reConnectNodes(head);
    }

    void CloneNodes(Node* head) {
        Node* node = head;
        while(node != nullptr) {
            Node* cloneNode = new Node(0);
            cloneNode->val = node->val;
            cloneNode->next = node->next;
            cloneNode->random = nullptr;

            node->next = cloneNode;
            node = cloneNode->next;
        }
    }

    void ConnectRandomNodes(Node* head) {
        Node* node = head;
        while (node != nullptr) {
            Node* clone = node->next;
            if (node->random != nullptr) {
                clone->random = node->random->next;
            }
            node = clone->next;
        }
    }

    Node* reConnectNodes(Node* head) {
        Node* node = head;
        Node* cloneHead = nullptr;
        Node* cloneNode = nullptr;

        if (node != nullptr) {
            cloneHead = node->next;
            cloneNode = node->next;
            node->next = cloneNode->next;
            node = node->next;
        }

        while (node != nullptr) {
            cloneNode->next = node->next;
            cloneNode = cloneNode->next;
            node->next = cloneNode->next;
            node = node->next;
        }

        return cloneHead;
    }

};

 */
