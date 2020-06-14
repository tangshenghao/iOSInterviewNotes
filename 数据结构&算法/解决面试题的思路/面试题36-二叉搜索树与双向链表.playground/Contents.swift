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

public class DoublyListNode {
  public var val: Int
  public var left: DoublyListNode?
  public var right: DoublyListNode?
  public init(_ val: Int) {
      self.val = val
      self.left = nil
      self.right = nil
  }
}

class Solution {
    
    var cur:TreeNode? = nil
    var pre:TreeNode? = nil
    var curListNode:DoublyListNode? = nil
    var preListNode:DoublyListNode? = nil
    
    func treeToDoublyList(_ root: TreeNode?) -> DoublyListNode? {
        
        if root == nil {
            return nil
        }
        
        //此题解法为中序遍历然后用pre记前一个节点，然后cur记当前节点
        //先递归到最左子节点，然后处理pre和cur的值
        //最后递归最右子节点
        //使用dummyhead来指向真正的head节点
        
        let dummyHead = TreeNode.init(0)
        dummyHead.right = root
        pre = dummyHead
        
        let dummyListHead = DoublyListNode.init(0)
        preListNode = dummyListHead
        
        convertNode(root)
        
        dummyListHead.right?.left = curListNode
        curListNode?.right = dummyListHead.right

        
        return dummyListHead.right
    }
    
    func convertNode(_ root: TreeNode?) {
        
        if root == nil {
            return
        }
        
        convertNode(root?.left)
        
        cur = root
        pre?.right = cur
        cur?.left = pre
        pre = root
        
        curListNode = DoublyListNode.init(root!.val)
        preListNode?.right = curListNode
        curListNode?.left = preListNode
        preListNode = curListNode
        
        convertNode(root?.right)
    }
}

let tree1 = TreeNode.init(4)
let tree2 = TreeNode.init(2)
let tree3 = TreeNode.init(1)
let tree4 = TreeNode.init(3)
let tree5 = TreeNode.init(5)

tree1.left = tree2
tree1.right = tree5
tree2.left = tree3
tree2.right = tree4

let solution = Solution.init()
var result = solution.treeToDoublyList(tree1)

print("val = \(result?.val ?? -99)  left = \(result?.left?.val ?? -99)  right = \(result?.right?.val ?? -99)"  )



/*
//以下是C++解法
class Solution {
public:
    Node* pre = NULL, *cur = NULL, *head = NULL;

    Node* treeToDoublyList(Node* root) {
        if (!root) return root;

        Node* dummyHead = new Node;
        dummyHead->right = root;
        pre = dummyHead;

        convertNode(root);

        dummyHead->right->left = cur;
        cur->right = dummyHead -> right;

        return dummyHead->right;
    }

    void convertNode(Node* pNode) {
        if (pNode == nullptr) {
            return;
        }

        convertNode(pNode->left);

        cur = pNode;
        pre->right = cur;
        cur->left = pre;
        pre = pNode;

        convertNode(pNode->right);
    }
};
*/
