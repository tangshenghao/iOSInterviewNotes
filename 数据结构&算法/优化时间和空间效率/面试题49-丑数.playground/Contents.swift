class Solution {
    //此题采用一个数组记录下，按顺序排好的丑数
    //因为到某个丑数的下一个丑数，一定是之前某个丑数的2倍、3倍或5倍
    //所以每次记录下一个丑数时，找到比当前丑数大的第一个丑数。
    //比较2、3、5倍的第一个丑数的最小值即是数组中下一个丑数
    
    //实际上不用每次都数组位置之前数都算一遍。只需要从上次记录的位置再接着往下就好
    func nthUglyNumber(_ n: Int) -> Int {
        if n <= 0 {
            return 0
        }
        
        var uglyNums:[Int] = Array.init(repeating: 0, count: n)
        
        uglyNums[0] = 1
        
        var nextIndex = 1
        
        var uglyNumMul2 = 1
        var uglyNumMul2Index = 0
        
        var uglyNumMul3 = 1
        var uglyNumMul3Index = 0
        
        var uglyNumMul5 = 1
        var uglyNumMul5Index = 0
        
        while nextIndex < n {
            let minVal = minNum(uglyNumMul2 * 2, uglyNumMul3 * 3, uglyNumMul5 * 5)
            uglyNums[nextIndex] = minVal
            while uglyNumMul2 * 2 <= uglyNums[nextIndex] {
                uglyNumMul2Index += 1
                uglyNumMul2 = uglyNums[uglyNumMul2Index]
            }
            while uglyNumMul3 * 3 <= uglyNums[nextIndex] {
                uglyNumMul3Index += 1
                uglyNumMul3 = uglyNums[uglyNumMul3Index]
            }
            while uglyNumMul5 * 5 <= uglyNums[nextIndex] {
                uglyNumMul5Index += 1
                uglyNumMul5 = uglyNums[uglyNumMul5Index]
            }
            
            nextIndex += 1
        }
        let result = uglyNums[nextIndex - 1]
        return result
    }
    
    func minNum(_ num1: Int ,_ num2: Int,_ num3: Int) -> Int {
        let min1 = min(num1, num2)
        let min2 = min(min1, num3)
        return min2
    }
    
    /*
     //以下超出时间限制
     func nthUglyNumber(_ n: Int) -> Int {
         if n <= 0 {
             return 0
         }
         
         var number = 0
         var uglyFound = 0
         while uglyFound < n {
             number += 1
             if isUglyNumber(number) {
                 uglyFound += 1
             }
         }
         return number
     }
     
     func isUglyNumber(_ n:Int) -> Bool {
         var num = n
         while num % 2 == 0 {
             num /= 2
         }
         while num % 3 == 0 {
             num /= 3
         }
         while num % 5 == 0 {
             num /= 5
         }
         return num == 1
     }
     */
    
}

let solution = Solution.init()
let result = solution.nthUglyNumber(11)
print("result = \(result)")
