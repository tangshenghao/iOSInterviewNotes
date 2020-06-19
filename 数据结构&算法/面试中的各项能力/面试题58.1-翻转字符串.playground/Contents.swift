class Solution {
    func reverseWords(_ s: String) -> String {
        //如果能用split 和 reversed 的话，实际上直接拆分后逆序循环拼装一下就可以
        let wordArray = s.split(separator: " ")
        var result = ""
        for (index, item) in wordArray.enumerated().reversed() {
            if index == wordArray.count - 1 {
                result = String(item)
            } else {
                result = "\(result) \(item)"
            }
        }
        return result
    }
}

//class Solution {
//    func reverseWords(_ s: String) -> String {
//        //利用翻转，先翻转整个字符串，再按照空格进行翻转拼接
//        //如果可用reversed 和 split 会快一些
//        if s == "" || s == " " {
//            return ""
//        }
//
//        let reString = String(s.reversed())
//
//        let tempStrArray = reString.split(separator: " ")
//        var resultArray:[String] = []
//
//        for itemStr in tempStrArray {
//
//            resultArray.append(String(itemStr.reversed()))
//        }
//
//        var result = ""
//
//        for (index, item) in resultArray.enumerated() {
//            if index == 0 {
//                result = item
//            } else {
//                result = "\(result) \(item)"
//            }
//        }
//
//        return result
//    }
//
//    func reverseWordCore(_ arr : inout [String.Element], _ start: Int, _ end:Int) {
//        var l = start
//        var r = end
//        while l < r {
//            let temp = arr[l]
//            arr[l] = arr[r]
//            arr[r] = temp
//            l += 1
//            r -= 1
//        }
//    }
//}

/*
 //多了很多判断的处理
 class Solution {
     func reverseWords(_ s: String) -> String {
         //利用翻转，先翻转整个字符串，再按照空格进行翻转拼接
         
         if s == "" || s == " " {
             return ""
         }
         
         var strArray = Array(s)
         
         reverseWordCore(&strArray, 0, s.count - 1)
         
         var l = 0
         var r = 0
         for (index, item) in strArray.enumerated() {
             if item != " " {
                 if index == 0 || (index != 0 && strArray[index - 1] == " ") {
                     l = index
                 } else if index == strArray.count - 1 {
                     r = index
                     reverseWordCore(&strArray, l, r)
                 }
             } else {
                 r = index
                 if r - 1 > l && (index > 0 && strArray[index - 1] != " "){
                     reverseWordCore(&strArray, l, r - 1)
                 }
             }
         }
         
         for (index, item) in strArray.enumerated().reversed() {
             if index != 0 && item == strArray[index - 1] && item == " " {
                 strArray.remove(at: index)
             }
         }
         
         if strArray.first == " " {
             strArray.removeFirst()
         }
         if strArray.last == " " {
             strArray.removeLast()
         }
         
         return String(strArray)
     }
     
     func reverseWordCore(_ arr : inout [String.Element], _ start: Int, _ end:Int) {
         var l = start
         var r = end
         while l < r {
             let temp = arr[l]
             arr[l] = arr[r]
             arr[r] = temp
             l += 1
             r -= 1
         }
     }
 }
 */


let solution = Solution.init()
let result = solution.reverseWords("the  sky is blue")
print("result = \(result)")
