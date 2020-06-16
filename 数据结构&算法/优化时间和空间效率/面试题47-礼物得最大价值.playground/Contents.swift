class Solution {
    /*
     二维的动态规划：一次for循环时间复杂度：m * n,空间复杂度m*n,
     求出所有的最大值：[
     [1,3,1],
     [1,5,1],
     [4,2,1]]
     某一个的最大值就是取位置[m-1][n]和[m][n-1]的大的哪一个，因此，变换过后
     [
     [1,4,5],
     [2,9,10],
     [4,11,12]]因此右下角的是11 + 原值1 = 12
     */
    func maxValue(_ grid: [[Int]]) -> Int {
        if grid.count == 0 || grid[0].count == 0 {
            return 0
        }
        let m = grid.count
        let n = grid[0].count
        var maxList:[[Int]] = Array.init(repeating: Array.init(repeating: 0, count: n), count: m)
        for i in 0..<m {
            for j in 0..<n {
                if i == 0 {
                    maxList[0][j] = grid[0][j] + (j > 0 ? maxList[0][j - 1] : 0)
                }else {
                    maxList[i][j] = grid[i][j] + (j > 0 ? max(maxList[i - 1][j], maxList[i][j - 1]) : maxList[i - 1][0])
                }
            }
        }
        return maxList[m - 1][n - 1]
        
    }
}

let solution = Solution.init()
let result = solution.maxValue([ [1,3,1], [1,5,1], [4,2,1] ])
print("result = \(result)")
