
class Solution {
    func exchange(_ nums: [Int]) -> [Int] {
        //该题目通过双指针左右向中间移动。
        //如果左指针发现偶数则停下
        //如果右指针发现奇数则停下
        //然后进行交换
        if nums.count <= 1 {
            return nums
        }
        var leftIndex = 0
        var rightIndex = nums.count - 1
        var result = nums
        while leftIndex < rightIndex {
            while leftIndex < rightIndex && !isEven(nums[leftIndex])  {
                leftIndex += 1
            }
            while leftIndex < rightIndex && isEven(nums[rightIndex]) {
                rightIndex -= 1
            }
            (result[leftIndex], result[rightIndex]) = (result[rightIndex], result[leftIndex])
            leftIndex += 1
            rightIndex -= 1
        }
        
        return result
    }
    
    func isEven(_ num: Int) -> Bool {
        return num % 2 == 0
    }
}


let solution = Solution.init()
let result =  solution.exchange([1, 2, 3, 4])
print("result = \(result)")
