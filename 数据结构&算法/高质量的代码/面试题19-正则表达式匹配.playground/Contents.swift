class Solution {
    func isMatch(_ s: String, _ p: String) -> Bool {
        //使用动态规划
        //转换为char数组
        let chars1 = Array(s), chars2 = Array(p)
        let n1 = chars1.count, n2 = chars2.count
        //如果p是空字符串 则如果s也是空字符串的话匹配成功 否则匹配失败
        if n2 == 0 { return n1 == 0 }
        //定义一个二维数组存放bool值
        var dp = [[Bool]](repeating: [Bool](repeating: false, count: n2+1), count: n1+1)
        //dp[0][0]一定是true，因为s为空且p也为空的时候一定是匹配的；
        //dp[1][0]一定是false，因为s有一个字符但是p为空的时候一定是不匹配的。
        //这个boolean类型的dp数组的大小应该是dp[s.length+1][p.length+1]，因为我们不仅仅要分别
        //取出s和p的所有元素，还要表示分别取s和p的0个元素时候(都为空)的情况。
        //当写到dp[s.length][p.length]的时候，我们就得到了最终s和p的匹配情况。
        //dp[1][0]~dp[s.length][0]这一列都是false，因为s不为空但是p为空一定不能匹配。
        dp[0][0] = true
        for j in 2..<n2+1 {
            dp[0][j] = chars2[j-1] == "*" && dp[0][j-2]
        }
        for i in 1..<n1+1 {
            for j in 1...n2 {
                if chars2[j-1] == "*" {
                    dp[i][j] = dp[i][j-2] || (dp[i-1][j] && (chars2[j-2] == chars1[i-1] || chars2[j-2] == ".") )
                } else if chars2[j-1] == chars1[i-1] || chars2[j-1] == "." {
                    dp[i][j] = dp[i-1][j-1]
                }
            }
        }
        return dp[n1][n2]
    }
}


let solution = Solution.init()
let result = solution.isMatch("aa", "a*")
print("result = \(result)")

