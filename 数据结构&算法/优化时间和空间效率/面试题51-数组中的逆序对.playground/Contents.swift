class Solution {
    //此题采用归并排序
    func reversePairs(_ nums: [Int]) -> Int {
        if nums.count < 2 {
            return 0
        }
        var array = nums
        var tempArray = Array(repeating: 0, count: nums.count)
        let result = reversePairs(nums: &array, begin: 0, end: nums.count,tempArray:&tempArray)
        
        return result
    }
    
    fileprivate func reversePairs(nums:inout [Int], begin:Int, end:Int, tempArray:inout [Int]) -> Int{
        
        if end - begin <= 1  {
            return 0
        }
        
        let mid = (begin + end) >> 1
        
        let l = reversePairs(nums: &nums, begin: begin, end: mid,tempArray: &tempArray)
        let r = reversePairs(nums: &nums, begin: mid, end: end,tempArray: &tempArray)
        if nums[mid - 1] <= nums[mid] {
            return l + r
        }
        
        let m = merge(nums: &nums, begin: begin, mid: mid, end: end,tempArray: &tempArray)
        return l + r + m
    }
    
    @discardableResult
    func merge(nums:inout [Int], begin:Int, mid:Int, end:Int, tempArray:inout [Int]) -> Int {
        
        //        let tempArray = nums[begin..<mid]
        let countLeft = mid - begin
        for i in begin..<mid{
            tempArray[i] = nums[i]
        }
        
        var s1 = begin
        var s2 = mid
        var index = begin
        var count = 0
        while s1 < mid {
            if  s2 < end && tempArray[s1] > nums[s2]  {
                nums[index] = nums[s2]
                s2 += 1
                count += countLeft - (s1-begin)
            }else {
                nums[index] = tempArray[s1]
                s1 += 1
                
            }
            
            //            if  s2 >= end || tempArray[s1] <= nums[s2]  {
            //                nums[index] = tempArray[s1]
            //                s1 += 1
            //            }else {
            //                nums[index] = nums[s2]
            //                s2 += 1
            //                count += tempArray.count - (s1-begin)
            //            }
            index += 1
        }
        
        return count
    }
}

let solution = Solution.init()
let result = solution.reversePairs([7,5,6,4])
print("result = \(result)")
