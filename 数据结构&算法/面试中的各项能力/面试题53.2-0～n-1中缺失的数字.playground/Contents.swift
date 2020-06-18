class Solution {
    func missingNumber(_ nums: [Int]) -> Int {
        //用二分法查找，因为正常情况下下标都会与值相等。
        //当出现下标和值不相等时，找到第一个出现
        //不相等的值的下标。就是缺失的那个数。
        //用二分法，找到与下标相差1的位置，
        //然后判断左边是否是正常的，如果正常，则当前这个下标就是缺失的数
        if nums.count == 0 {
            return -1
        }
        var left = 0
        var right = nums.count - 1
        var missNum = -1
        while left <= right {
            
            let mid = (left + right) / 2
            
            if nums[mid] == mid {
                left = mid + 1
                if left == nums.count {
                    missNum = nums.count
                }
            } else if nums[mid] != mid {
                if ((mid > 0 && nums[mid - 1] == mid - 1) || mid == 0) {
                    missNum = mid
                    break
                } else {
                    right = mid - 1
                }
            }
        }
        return missNum
    }
}

let solution = Solution.init()
let result = solution.missingNumber([0])
print("result = \(result)")
