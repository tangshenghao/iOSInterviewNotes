class Solution {
    func lengthOfLongestSubstring(_ s: String) -> Int {
        // 用滑动的窗口, 窗口里面都是不重复的子串, 最后窗口最大长度, 就是无重复子串的长度
        var set = Set<Character>()
        
        // 用left和right来记录当前子串的区间
        var ret = 0
        var left = 0
        let sArr = Array(s)
        
        for right in 0 ..< s.count {
            while set.contains(sArr[right]) {
                // 窗口左边缩小一格
                set.remove(sArr[left])
                left = left + 1
            }
            set.insert(sArr[right])
            if set.count > ret {
                ret = set.count
            }
        }
        return ret
    }
}

let solution = Solution.init()
let result = solution.lengthOfLongestSubstring("asdhadnqwe")
print("result = \(result)")
