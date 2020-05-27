class Solution {
    func replaceSpace(_ s: String) -> String {
        var result = ""
        for c in s {
            if c == " " {
                result.append("%20")
            } else {
                result.append(c)
            }
        }
        return result
    }
}

let solution = Solution.init()
let result = solution.replaceSpace("hahah hahah haha")
print("result = \(result)")

//PS：在剑指内该题是需要先遍历一遍字符串，找出空格数量，然后用双指针从尾部进行添加%20和移动，当两个指针相遇时说明已添加完，则返回结果
