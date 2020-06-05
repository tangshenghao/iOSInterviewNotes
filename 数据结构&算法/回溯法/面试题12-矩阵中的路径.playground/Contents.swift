class Solution {
    //使用回溯法，从每个点去递归的上下左右移动
    //如果发现不能移动到或者已经移动过的则返回，并将其走过的路重置，回到上一轮的状态
    func exist(_ board: [[Character]], _ word: String) -> Bool {
        
        //先计算行和列
        let rows = board.count
        var clos = 0
        if rows > 0 {
            clos = board[0].count
        }
        if rows == 0 || clos == 0 {
            return false
        }
        
        var visitArray = Array.init(repeating: 0, count: clos * rows)
        //其实使用数字即可验证。因为当匹配字符的时候才数字加1。当数字与word的长度一致时一定是匹配到了
        var pathString = ""
        //循环所有节点去查是否有对应文字
        for (i, value) in board.enumerated() {
            for (j, _) in value.enumerated() {
                if checkWord(board, word, rows, clos, i, j, &pathString, &visitArray) {
                    return true
                }
            }
        }
        
        return false
    }
    
    //查找是否能匹配到word
    func checkWord(_ board: [[Character]], _ word: String, _ rows: Int, _ clos:Int, _ nRow:Int, _ nClo:Int, _ pathString:inout String, _ visitArray:inout [Int]) -> Bool {
        if pathString == word  {
            return true
        }
        
        var result = false
        if nRow >= 0 && nClo >= 0 && nRow < rows && nClo < clos && visitArray[nRow * clos + nClo] == 0 {
            let valueChar = board[nRow][nClo]
            let tempChar1 = word.index(word.startIndex, offsetBy: pathString.count)
            let tempChar2 = word.index(word.startIndex, offsetBy: pathString.count + 1)
            let subChar = word[tempChar1..<tempChar2]
            if valueChar.description == subChar {
                
                visitArray[nRow * clos + nClo] = 1
                pathString.append(valueChar)
                //左右上下
                result = checkWord(board, word, rows, clos, nRow, nClo-1, &pathString, &visitArray) || checkWord(board, word, rows, clos, nRow, nClo+1, &pathString, &visitArray) || checkWord(board, word, rows, clos, nRow-1, nClo, &pathString, &visitArray) || checkWord(board, word, rows, clos, nRow+1, nClo, &pathString, &visitArray)
                if !result {
                    pathString.removeLast()
                    visitArray[nRow * clos + nClo] = 0
                }
            }
        }
        
        return result
    }
}


let solution = Solution.init()
let result = solution.exist([["C","A","A"],["A","A","A"],["B","C","D"]],
"AAB")
print("result = \(result)")
