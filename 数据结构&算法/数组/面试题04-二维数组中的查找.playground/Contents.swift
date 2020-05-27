class Solution {
    func findNumberIn2DArray(_ matrix: [[Int]], _ target: Int) -> Bool {
        
        let row = matrix.count
        let column = row > 0 ? matrix[0].count : 0
        var rowIndex = row - 1
        var columnIndex = 0
        //边界判断
        if column == 0 {
            return false
        }
        //如果小于最左上角的数字则直接返回
        if target < matrix[0][0] {
            return false
        }
        //从左下角开始查找
        while rowIndex >= 0 && columnIndex < column {
            
            if target == matrix[rowIndex][columnIndex] {
                //相同则返回
                return true
            } else if target > matrix[rowIndex][columnIndex] {
                //如果大于则往右移动
                columnIndex += 1
            } else {
                //如果小于则往上移动
                rowIndex -= 1
            }
        }
        return false
    }
}

let solution = Solution.init()
let result = solution.findNumberIn2DArray([[1,   4,  7, 11, 15],[2,   5,  8, 12, 19],[3,   6,  9, 16, 22],[10, 13, 14, 17, 24],[18, 21, 23, 26, 30]], 5)
print("result = \(result)")
