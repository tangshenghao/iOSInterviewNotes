class Solution {
    func twoSum(_ nums: [Int], _ target: Int) -> [Int] {
        if nums.count == 0 {
            return []
        }
        
        //因为是有序的 可以利用双指针  空间复杂度为O(1)
        var left = 0
        var right = nums.count - 1
        while left < right {
            
            if nums[left] + nums[right] == target {
                return [nums[left], nums[right]]
            } else if nums[left] + nums[right] < target {
                left += 1
            } else {
                right -= 1
            }
        }
        
        return []
    }
}

/*
 //下面这种采用类哈希表的字典来保存 时间复杂度和空间复杂度都是O（n）
 class Solution {
     func twoSum(_ nums: [Int], _ target: Int) -> [Int] {
         if nums.count == 0 {
             return []
         }
         
         var map:[Int: Int] = [:]
         
         for num in nums {

             if let value = map[num] {
                 return [num, value]
             } else {
                 map.updateValue(num, forKey: target - num)
             }
         }
         
         return []
     }
 }
 */



let solution = Solution.init()
let result = solution.twoSum([2, 3, 1, 0, 2, 5, 3], 6)
print("result = \(result)")
