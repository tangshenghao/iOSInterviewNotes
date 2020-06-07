
class Solution {
    func hammingWeight(_ n: Int) -> Int {
        
        //此题使用 n-1 & n 去移除最右边的1.保持左边的不动
        //例如： n = 1100 , n - 1 = 1011 , 与操作后变成 1000
        //1000与1100 差别一个1。即可计算出
        
        var oneCount = 0
        var temp = n
        while (temp != 0) {
            oneCount += 1
            temp = (temp - 1) & temp
        }
        
        return oneCount
    }
}

let solution = Solution.init()
let result = solution.hammingWeight(7)
print("result = \(result)")

//同时延展判断n是不是等于2的整数次方也是n与n-1.如果为0.则为2的整数次方
//计算m和n之间的需要改变几位也一样。先求这两个数的异或，再求出现1的次数
