class Solution {
    func lastRemaining(_ n: Int, _ m: Int) -> Int {
        
        //使用数学+迭代
        if n < 1 || m < 1 {
            return -1
        }
        
        var f = 0
        for i in 2...n {
            f = (f + m) % i
        }
        
        return f
    }
}

let solution = Solution.init()
let result = solution.lastRemaining(5, 3)
print("result = \(result)")
