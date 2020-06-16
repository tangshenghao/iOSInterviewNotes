class Solution {
    //使用动态规划，滚动数组求得结果
    func translateNum(_ num: Int) -> Int {
        let src = "\(num)"
        var p = 0,q = 0,r = 1
        for i in 0..<src.count {
            p = q
            q = r
            r = 0
            r += q
            if i == 0 {
                continue
            }
            let si = src.index(src.startIndex, offsetBy: i-1)
            let ei = src.index(src.startIndex, offsetBy: i)
            let pre = Int("\(src[si...ei])")!
            if pre>=10 && pre<=25 {
                r += p
            }
        }
        return r
    }
}

let solution = Solution.init()
let result = solution.translateNum(1234)
print("result = \(result)")
