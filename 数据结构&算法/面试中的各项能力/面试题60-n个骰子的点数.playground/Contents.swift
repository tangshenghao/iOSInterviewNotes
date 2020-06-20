class Solution {
    func twoSum(_ n: Int) -> [Double] {
        //使用动态规划循环求解
        if n == 0 {
            return []
        }
        
        var result: [Double] = Array.init(repeating: 1/6, count: 6)
        if n == 1 {
            return result
        }
        for index in 2...n {
            var temp: [Double] = Array.init(repeating: 0, count: 5 * index + 1)
            for j in 0..<result.count {
                for x in 0..<6 {
                    temp[j+x] += result[j] / 6
                }
            }
            result = temp
        }
        return result
        
    }
}

let solution = Solution.init()
let result = solution.twoSum(2)
print(result)
