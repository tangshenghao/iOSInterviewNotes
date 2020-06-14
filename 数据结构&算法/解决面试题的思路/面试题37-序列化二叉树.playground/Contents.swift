

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


class Codec {
    
    var serializeStr = ""
    //此题先中序遍历，将节点值转成字符串，以“,”隔开，得到序列化的值
    func serialize(_ root: TreeNode?) -> String {
        
        if root == nil {
            return ""
        }
        
        stringBuild(root)
        
        if serializeStr.count > 0 {
            let endIndex = serializeStr.index(serializeStr.startIndex, offsetBy: serializeStr.count - 1)
            serializeStr = String(serializeStr[serializeStr.startIndex..<endIndex])
        }
        
        return serializeStr
    }
    
    func stringBuild(_ root: TreeNode?) {
        if root == nil {
            serializeStr.append("$")
            serializeStr.append(",")
        } else {
            serializeStr.append(String(root!.val))
            serializeStr.append(",")
            
            stringBuild(root?.left)
            stringBuild(root?.right)
        }
    }
    //然后编回的时候，先通过","得到数组。
    //再通过中序遍历数组，组成二叉树
    func deserialize(_ data: String) -> TreeNode? {
        if data == "" {
            return nil
        }
        
        var stringList:Array<Substring> = data.split(separator: ",")
        
        return treeBuild(&stringList)
    }
    
    func treeBuild(_ arr: inout Array<Substring>) -> TreeNode? {
        
        let val = arr.removeFirst()
        if val == "$" {
            return nil
        } else {
            let node = TreeNode.init(Int(String(val))!)
            node.left = treeBuild(&arr)
            node.right = treeBuild(&arr)
            return node
        }
    }
}

// Your Codec object will be instantiated and called as such:

let tree1 = TreeNode.init(1)
let tree2 = TreeNode.init(2)
let tree3 = TreeNode.init(3)
let tree4 = TreeNode.init(4)
let tree5 = TreeNode.init(5)
tree1.left = tree2
tree1.right = tree3
tree3.left = tree4
tree3.right = tree5

var codec = Codec()

print("\(codec.deserialize(codec.serialize(tree1))?.val ?? -99)")

/*
//下面是C++的解法

 class Codec {
 public:

     // Encodes a tree to a single string.
     string serialize(TreeNode* root) {
         ostringstream out;
         queue<TreeNode*> q;
         q.push(root);
         while (!q.empty()) {
             TreeNode* tmp = q.front();
             q.pop();
             if (tmp) {
                 out<<tmp->val<<" ";
                 q.push(tmp->left);
                 q.push(tmp->right);
             } else {
                 out<<"null ";
             }
         }
         return out.str();
     }

     // Decodes your encoded data to tree.
     TreeNode* deserialize(string data) {
         istringstream input(data);
         string val;
         vector<TreeNode*> vec;
         while (input >> val) {
             if (val == "null") {
                 vec.push_back(NULL);
             } else {
                 vec.push_back(new TreeNode(stoi(val)));
             }
         }
         int j = 1;
         for (int i = 0; j < vec.size(); ++i) {
             if (vec[i] == NULL) continue;
             if (j < vec.size()) vec[i]->left = vec[j++];
             if (j < vec.size()) vec[i]->right = vec[j++];
         }
         return vec[0];
     }
 };
 
*/
