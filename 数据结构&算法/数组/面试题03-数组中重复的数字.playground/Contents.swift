class Solution {
    func findRepeatNumber(_ nums: [Int]) -> Int {
        // 原地交换方式
        var varNums = nums;
        var index = 0
        while index < varNums.count {
            let value = varNums[index];
            // 如果当前值不和下标一致
            if value != index {
                // 判断值是否已经在指定的位置上
                if (varNums[value] == value) {
                    // 重复将结果返回
                    return value
                } else {
                    // 如果还没在指定位置上则交换
                    varNums.swapAt(value, index)
                }
            } else {
                index += 1
            }
        }
        return -1
    }
}


let solution = Solution.init()
let result = solution.findRepeatNumber([2, 3, 1, 0, 2, 5, 3])
print("result = \(result)")

