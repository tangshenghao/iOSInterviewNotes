class Solution {
    func numWays(_ n: Int) -> Int {
        if (n < 2) {
            return 1
        }
        if (n == 2) {
            return 2
        }
        var temp1 : Int = 1
        var temp2 : Int = 2
        var result : Int = 3
        for _ in 3..<n+1 {
            result = (temp1 + temp2) % 1000000007
            temp1 = temp2
            temp2 = result
        }
        return result
    }
}

let solution = Solution.init()
print("result = \(solution.numWays(5))")
