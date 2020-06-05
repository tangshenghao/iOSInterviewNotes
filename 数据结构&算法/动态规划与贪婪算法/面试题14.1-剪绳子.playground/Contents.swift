class Solution {
    
    //这里先用动态规划来处理
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
        
        //动态规划。从上往下分析：n长度的绳子，在1～n-1之间的位置剪了一刀i
        //那此时最优的乘积为0～i和i～n的最优解的乘积。
        //那从下从上去处理 f(n) = Max(f(i) * f(n-i)) i的值需要去遍历
        //i只需要从1遍历到中间即可。因为后半部分剪了和前半部分剪了是一样的
        
        //需要初始化一个数组来存储每个n的最优乘积
        //1、2、3可以当成独立一段且比不剪大所以初始值为1、2、3
        //4开始就是剪的比不剪的大，因此只初始化0-3。
        var result:[Int] = [0, 1, 2, 3]
        for index in 4..<n+1 {
            var maxCount = 0
            /*
             此处考虑2开始为切点，是因为从4开始1 * f(n - 1)的最优
             会比2 * f(n - 2)的最优小，所以直接从2开始，省略一次计算也可以
             而且从1开始剪，就相当于认为存在f(n)的最优乘积和f(n-1)的最优乘积
             一样，根据规律来看不会存在该种情况，所以可以省略掉从1开始剪的情况
             */
            for i in 2..<index/2+1 {
                let temp = result[i] * result[index-i]
                if temp > maxCount {
                    maxCount = temp
                }
            }
            result.append(maxCount % 1000000007)
        }
        return result[n]
    }
}

let solution = Solution.init()
let result = solution.cuttingRope(500)
print("result == \(result)")

