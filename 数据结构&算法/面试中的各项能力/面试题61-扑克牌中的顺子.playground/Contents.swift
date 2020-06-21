class Solution {
    func isStraight(_ nums: [Int]) -> Bool {
        if nums.count < 2 {
            return false
        }
        
        let tempNums = nums.sorted()
        
        //统计0的数量
        var zeroCount = 0
        for num in tempNums {
            if num == 0 {
                zeroCount += 1
            }
        }
        
        //统计间隔的数量
        var gapCount = 0
        var small = zeroCount
        var big = small + 1
        while big < tempNums.count {
            if tempNums[small] == tempNums[big] {
                return false
            }
            
            gapCount += tempNums[big] - tempNums[small] - 1
            small = big
            big += 1
            
        }
        return gapCount > zeroCount ? false : true
    }
}


let solution = Solution.init()
let result = solution.isStraight([0, 0, 1, 5, 3])
print("result = \(result)")
