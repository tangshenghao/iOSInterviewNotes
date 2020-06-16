class Solution {
    func maxSubArray(_ nums: [Int]) -> Int {
        
        
        //此题判断如果前面的数累加出现等于0或者小于0的情况，则当前循环到的数就是比之前所有数累加都大
        //如果前面的数累加大于0的话，说明当前这个数也可以继续往下加。
        //每次得到的数判断更新最大值
        
        if nums.count == 0 {
            return 0
        }
        if nums.count == 1 {
            return nums[0]
        }
        
        var result = Int.min
        var tempSum = 0
        for num in nums {
            
            if tempSum <= 0 {
                tempSum = num
            } else {
                tempSum += num
            }
            
            if tempSum > result {
                result = tempSum
            }
        }
        
        return result
    }
}

let solution = Solution.init()
let result = solution.maxSubArray([-2,1,-3,4,-1,2,1,-5,4])
print("result = \(result)")
