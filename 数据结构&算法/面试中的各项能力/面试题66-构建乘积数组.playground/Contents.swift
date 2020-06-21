class Solution {
    func constructArr(_ a: [Int]) -> [Int] {
        if a.count < 2 {
            return a
        }
        
        //计算左三角和右三角
        var result = Array<Int>.init(repeating: 1, count: a.count)
        var left = 1
        for i in 0..<a.count {
            result[i] = left
            left *= a[i]
        }
        
        var right = 1
        for i in (0..<a.count).reversed() {
            result[i] *= right
            right *= a[i]
        }
        return result
    }
}


let solution = Solution.init()
let result = solution.constructArr([1,2,3,4,5])
print("result = \(result)")
