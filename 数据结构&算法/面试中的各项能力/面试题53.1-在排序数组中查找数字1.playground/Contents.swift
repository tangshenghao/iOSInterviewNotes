class Solution {
    func search(_ nums: [Int], _ target: Int) -> Int {
        
        if nums.count == 0 {
            return 0
        }
        
        var result = 0
        //找出第一个出现的位置
        let firstK = findFirstK(nums, target, 0, nums.count - 1)
        //找出最后一个出现的位置
        let endK = findEndK(nums, target, 0, nums.count - 1)
        //如果都有返回值，则相减得到结果
        if firstK != -1 && endK != -1 {
            result = endK - firstK + 1
        }
        return result
    }
    
    func findFirstK(_ nums: [Int], _ target: Int, _ start: Int, _ end: Int) -> Int {
        var tempStart = start
        var tempEnd = end
        
        if start > end {
            return -1
        }
        let mid = (start + end) / 2
        let midValue = nums[mid]
        if midValue == target {
            //往左走
            if ((mid > 0 && nums[mid - 1] != target) || mid == 0 ) {
                return mid
            } else {
                tempEnd = mid - 1
            }
        } else if (midValue > target) {
            tempEnd = mid - 1
        } else {
            tempStart = mid + 1
        }
        return findFirstK(nums, target, tempStart, tempEnd)
    }
    
    func findEndK(_ nums: [Int], _ target: Int, _ start: Int, _ end: Int) -> Int {
        var tempStart = start
        var tempEnd = end
        
        if start > end {
            return -1
        }
        let mid = (start + end) / 2
        let midValue = nums[mid]
        if midValue == target {
            //往右走
            if ((mid < nums.count - 1 && nums[mid + 1] != target) || mid == nums.count - 1 ) {
                return mid
            } else {
                tempStart = mid + 1
            }
        } else if (midValue < target) {
            tempStart = mid + 1
        } else {
            tempEnd = mid - 1
        }
        return findEndK(nums, target, tempStart, tempEnd)
    }
}

let solution = Solution.init()
let result = solution.search([5,7,7,8,8,10], 8)
print("result == \(result)")

/*
 //直接循环可以通过检验，但时间复杂度为O(n)
 class Solution {
     func search(_ nums: [Int], _ target: Int) -> Int {

         var result = 0
         for num in nums {
             if (num == target) {
                 result += 1
             }
         }
         return result
     }
 }
 */
