class Solution {
    func verifyPostorder(_ postorder: [Int]) -> Bool {
        
        if postorder.count < 3 {
            return true
        }
        
        //该题 数组最后一个数为根节点
        //并且搜索树，数组中第一个比根节点大的为右部分的开头
        //如果后面还有比根节点小的值 则为错误
        //然后将左部分右部分作为新的搜索树进行递归调用
        //最后得到结果
        
        let rootVal = postorder.last!
        var rightIndex = postorder.count - 1
        //找出右部分的起始位
        for i in 0..<postorder.count-1 {
            if postorder[i] > rootVal {
                rightIndex = i
                break
            }
        }
        
        //判断右部分有没有小于根节点的数
        for i in rightIndex..<postorder.count {
            if postorder[i] < rootVal {
                return false
            }
        }
        
        //如果存在左部分
        if rightIndex > 0 {
            var left:[Int] = []
            for i in 0..<rightIndex {
                left.append(postorder[i])
            }
            let leftResult = verifyPostorder(left)
            if leftResult == false {
                return false
            }
        }
        
        //如果存在右部分
        if rightIndex < postorder.count - 1 {
            var right:[Int] = []
            for i in rightIndex..<postorder.count-1 {
                right.append(postorder[i])
            }
            let rightReSult = verifyPostorder(right)
            if rightReSult == false {
                return false
            }
        }
        return true
    }
}

let solution = Solution.init()
let result = solution.verifyPostorder([1,6,3,2,5])
print("result = \(result)")
