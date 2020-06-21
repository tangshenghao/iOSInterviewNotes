class Solution {
    func maxProfit(_ prices: [Int]) -> Int {
        //动态规划 - 第N天的最大利润等于前N-1天最大利润和第N天卖出的最大利润的最大值
        //dp[n] = max(dp[n-1], princes[n]) - min(prices[0:n]))
        if prices.count == 0 {
            return 0
        }
        var buy = prices.first!
        var maxGap = 0
        for p in prices {
            buy = min(p, buy)
            maxGap = max(maxGap, p - buy)
        }
        
        return maxGap
    }
}

let solution = Solution.init()
let result = solution.maxProfit([7,1,5,3,6,4])
print("result = \(result)")
