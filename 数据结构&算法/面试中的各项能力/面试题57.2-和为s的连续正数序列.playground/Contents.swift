class Solution {
    func findContinuousSequence(_ target: Int) -> [[Int]] {
        
        if target < 3 {
            return []
        }
        
        //使用滑动窗口  移动右部分来滑动
        var result:[[Int]] = []
        var i = 1

        var sum = 1
        for j in 2..<target {
            sum += j
            
            while sum > target {
                sum -= i
                i += 1
            }
            
            if i > (target / 2) + 1 {
                break
            }
            
            if sum == target {
                var tempArr:[Int] = []
                for tempNum in i..<j+1 {
                    tempArr.append(tempNum)
                }
                result.append(tempArr)
            }
        }
        return result
    }
}

/*
 //从左边移动左指针 滑动窗口 会对无效的组合重复计算
 //比如 12345 i=1 j=5 和是15  如果接下来用i=2继续计算 2345 和 345 和 45 都是无效计算 因为在j不变的情况下，移动左边，只会小于tagert
 class Solution {
     func findContinuousSequence(_ target: Int) -> [[Int]] {
         
         if target < 3 {
             return []
         }
         
         //使用滑动窗口
         var result:[[Int]] = []
         var i = 1
         var j = 2
         while i <= target && i + j <= target {
             var tempArr:[Int] = [i]
             var tempSum = i
             while tempSum + j <= target {
                 tempArr.append(j)
                 tempSum = tempSum + j
                 if tempSum == target {
                     result.append(tempArr)
                     break
                 }
                 j += 1
             }
             i += 1
             j = i + 1
         }
         return result
     }
 }
 */


let solution = Solution.init()
let result = solution.findContinuousSequence(15)
print("result = \(result)")

