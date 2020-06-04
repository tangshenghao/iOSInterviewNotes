class Solution {
    func minArray(_ numbers: [Int]) -> Int {
        
        if numbers.count == 0 {
            return -1
        }
        
        if numbers.count == 1 {
            return numbers[0]
        }
        //将第一个mid用最左边值来做赋值，避免本来就是一个排好序的数组
        var left = 0
        var right = numbers.count - 1
        var midIndex = left
        //当左边的值大于右边时，说明还在循环中
        while numbers[left] >= numbers[right] {
            //当剩下两个值时，有一个一定是最小值
            if (right - left) == 1 {
                return numbers[left] < numbers[right] ? numbers[left] : numbers[right]
            }
            //取中间
            midIndex = (right + left) / 2
            
            //如果三方相等 则需要进行顺序查找
            if numbers[left] == numbers[midIndex] && numbers[midIndex] == numbers[right] {
                return orderCheck(numbers, left: left, right: right)
            }
            
            //如果左边大于中间，则说明最小值一定在左侧
            if numbers[left] > numbers[midIndex] {
                right = midIndex
            } else {
            //如果不是，则说明最小值一定在右侧
                left = midIndex
            }
        }
        return numbers[midIndex]
    }
    
    func orderCheck(_ arr: [Int], left: Int, right:Int) -> Int {
        
        var result = arr[left]
        for i in (left+1)..<right+1 {
            if result > arr[i] {
                result = arr[i]
                break
            }
        }
        return result
    }
}


//二分查找
let solution = Solution.init()
let result = solution.minArray([3,4,5,1,2])
print("\(result)")


