class Solution {
    //使用 && 和 || 的特性 可以在前半部分判断后就不会继续往后判断的特性停止递归
    var result = 0
    func sumNums(_ n: Int) -> Int {
        n > 0 && sumNums(n - 1) > 0
        result += n
        return result
    }
}

let solution = Solution.init()
let result = solution.sumNums(3)
print(result)
