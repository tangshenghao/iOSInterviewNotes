class Solution {
    func fib(_ n: Int) -> Int {
        if (n == 0) {
            return 0
        }
        if (n == 1) {
            return 1
        }
        var temp1 : Int = 0
        var temp2 : Int = 1
        var result : Int = 0
        for _ in 2..<n+1 {
            result = (temp1 + temp2) % 1000000007
            temp1 = temp2
            temp2 = result
        }
        return result
    }
}

let solution = Solution.init()
print("result = \(solution.fib(40))")
