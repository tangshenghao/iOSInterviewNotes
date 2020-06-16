class Solution {
    func minNumber(_ nums: [Int]) -> String {
        // Int数组转变为String数组
        var numsToStringArray: [String] = []

        for num in nums {
            numsToStringArray.append("\(num)")
        }

        // 对String数组进行排序
        numsToStringArray.sort{$0 + $1 < $1 + $0}

        var res = ""
        for str in numsToStringArray {
            res += str
        }
        return res
    }
}

let solution = Solution.init()
let result = solution.minNumber([3,30,34,5,9])
print("result = \(result)")
