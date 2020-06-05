class Solution {
    func cuttingRope(_ n: Int) -> Int {
        //前几位先将结果固定
        if n < 2 {
            return 0
        }
        if n == 2 {
            return 1
        }
        if n == 3 {
            return 2
        }
        
        //此题因为n的范围变大了，使用动态规划i切割最优解的话乘积会溢出
        //因此不能使用动态规划
        //使用贪心算法
        //思考当n>=5时，3(n-3)>=2(n-2)。
        //当剩余绳子大于等于5的长度时，我们尽可能的剪成3的段
        //为什么是大于等于5，因为当剩余4的时候，4是最大，可以不继续剪了
        
        //计算能剪多少次3的长度
        var num3Count = n/3
        //判断最后剩余的那段是不是4 如果是4则最后一次3不用剪
        if ((n - num3Count * 3) == 1) {
            num3Count -= 1
        }
        
        let num2Count = (n - 3 * num3Count) / 2
        
        
        var result = 1
        for _ in 0..<num3Count {
            result = (3 * result) % 1000000007
        }
        
        for _ in 0..<num2Count {
            result = (2 * result) % 1000000007
        }
        
        return result
    }
}

let solution = Solution.init()
let result = solution.cuttingRope(58)
print("result = \(result)")
