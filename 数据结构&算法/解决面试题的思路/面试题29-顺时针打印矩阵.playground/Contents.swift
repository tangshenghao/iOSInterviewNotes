
class Solution {
    func spiralOrder(_ matrix: [[Int]]) -> [Int] {
        //此题模拟从外到内一圈一圈模拟
        let rows = matrix.count
        if rows == 0 {
            return []
        }
        let clos = matrix[0].count
        if clos == 0 {
            return []
        }
        
        var start = 0
        var result :[Int] = []
        
        //循环条件是开始的start是不是在圈内
        while (clos > start * 2 && rows > start * 2) {
            
            spiralOrderCore(&result, clos, rows, start, matrix)
            
            start += 1
        }
        
        return result
        
    }
    
    func spiralOrderCore(_ arr: inout [Int], _ clos: Int, _ rows: Int, _ start: Int, _ matrix : [[Int]]) {
        let endX = clos - 1 - start
        let endY = rows - 1 - start
        
        //从左到右移动一行
        for index in start..<endX+1 {
            arr.append(matrix[start][index])
        }
        //从上到下移动一列
        if start < endY {
            for index in start+1..<endY+1 {
                arr.append(matrix[index][endX])
            }
        }
        //从右到左移动一行
        if start < endX && start < endY {
            for index in (start..<endX).reversed() {
                arr.append(matrix[endY][index])
            }
        }
        //从下到上移动一列
        if start < endX && start < endY - 1 {
            for index in (start+1..<endY).reversed() {
                arr.append(matrix[index][start])
            }
        }
    }
}

let solution = Solution.init()
let result = solution.spiralOrder([[1,2,3],[4,5,6],[7,8,9]])

print(result)
