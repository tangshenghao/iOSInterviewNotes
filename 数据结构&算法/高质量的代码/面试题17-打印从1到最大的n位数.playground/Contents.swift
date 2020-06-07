class Solution {
    func printNumbers(_ n: Int) -> [Int] {
        
        //该题如果在范围n比较小时候，可以取10的n次方，得到值去循环插入数组即可
        //但其实是要考察大数的处理
        //当n越来越大的时候, 里面的数值怎么处理
        //是需要用到字符串去表示数值
        //同时往上加1也是使用字符串一位一位处理
        //但该题其实是要[Int]形式，所以内部的值还是得为Int范围
        if n <= 0 {
            return []
        }
        
        var count = 1
        var temp = 0
        while temp < n {
            count *= 10
            temp += 1
        }
        var result:[Int] = []
        for index in 1..<count {
            result.append(index)
        }
        return result
    }
}

let solution = Solution.init()
let result = solution.printNumbers(2)
print(result)
