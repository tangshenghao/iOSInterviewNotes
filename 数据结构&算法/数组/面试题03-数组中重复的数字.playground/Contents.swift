class Solution {
    func findRepeatNumber(_ nums: [Int]) -> Int {
        var tempNums = nums
        
        for index in 0..<tempNums.count {
            let value = tempNums[index]
            if value == index {
                //如果当前已经是对的位置则继续
                continue
            } else {
                let result = replaceValueToRIndex(&tempNums, currentIndex: index)
                if result == -1 {
                    //如果交换后位置一致则继续
                    continue
                } else {
                    return result
                }
            }
        }
        return -1
    }
    
    func replaceValueToRIndex(_ nums: inout [Int], currentIndex: Int) -> Int {
        
        let value = nums[currentIndex]
        let temp = nums[value]
        if value == temp {
            //如果当前数和对应下标的数一致，则说明该数该数是一样的数
            return value
        } else {
            nums[currentIndex] = temp
            nums[value] = value
            if temp == currentIndex {
                return -1
            } else {
                return replaceValueToRIndex(&nums, currentIndex: currentIndex)
            }
        }
    }
}


let solution = Solution.init()
let result = solution.findRepeatNumber([2, 3, 1, 0, 2, 5, 3])
print("result = \(result)")

