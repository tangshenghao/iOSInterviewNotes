class Solution {
    func reverseLeftWords(_ s: String, _ n: Int) -> String {
        //使用swift语法特性
        if s.count == 0 || n <= 0 {
            return s
        }
        if (n > s.count) {
            return s
        }
        let index = s.index(s.startIndex, offsetBy: n)
        return String(s[index..<s.endIndex]) + String(s[..<index])
    }
}

let solution = Solution.init()
let result = solution.reverseLeftWords("abcdefg", 3)
print("result = \(result)")


/*
 //以下是正规解法
 class Solution {
     func reverseLeftWords(_ s: String, _ n: Int) -> String {
         
         //执行两次翻转，先分开翻转，再全部翻转 abasd  2翻转  -> ba dsa -> asdab
         
         if s.count == 0 || n <= 0 {
             return s
         }
         
         var strArray = Array(s)
         
         if n < s.count {
             reverseString(&strArray, 0, n - 1)
             reverseString(&strArray, n, s.count - 1)
         }
         
         reverseString(&strArray, 0, s.count - 1)
         
         return String(strArray)
         
     }
     
     func reverseString(_ arr: inout [String.Element], _ start: Int, _ end: Int) {
         var l = start
         var r = end
         while l < r {
             (arr[l], arr[r]) = (arr[r], arr[l])
             l += 1
             r -= 1
         }
     }
 }
 */
