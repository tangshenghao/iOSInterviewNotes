class Solution {
    func majorityElement(_ nums: [Int]) -> Int {
        
        //此题采用投票算法
        //不同的两个数字去掉后，遗留下来的数一定是超过一半的数
        
        if nums.count == 0 {
            return -1
        }
        
        var result = nums[0]
        var showCount = 0
        
        
        for value in nums {
            if result == value {
                showCount += 1
            } else {
                showCount -= 1
            }
            
            if showCount == 0 {
                result = value
                showCount = 1
            }
        }
        return result
    }
}

let solution = Solution.init()
let result = solution.majorityElement([1, 2, 3, 2, 2, 2, 5, 4, 2])
print("\(result)")
