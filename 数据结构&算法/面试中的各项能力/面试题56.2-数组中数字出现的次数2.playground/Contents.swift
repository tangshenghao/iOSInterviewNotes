
class Solution {
    func singleNumber(_ nums: [Int]) -> Int {
        //通过计算各位中出现的1的位数，然后余3得出结果
        var counts = Array(repeating: 0, count: 32)
        for num in nums {
            var num = num
            for j in 0..<32 {
                counts[j] += num & 1
                num >>= 1
            }
        }
            var res = 0, m = 3
            for i in 0..<32 {
            res <<= 1
            res |= counts[31 - i] % m
        }
        return res
    }
}

/*
 //有限状态自动机
 class Solution {
     func singleNumber(_ nums: [Int]) -> Int {
         var a = 0, b = 0
         for num in nums {
             a = a ^ num & ~b
             b = b ^ num & ~a
         }
         return a
     }
 }
 */




/*
 class Solution {
     func singleNumber(_ nums: [Int]) -> Int {
         //用一个Int：Int字典
         var dict: [Int: Int] = [:]
         
         //对数组遍历，有一个数就计数
         for num in nums {
             if let count = dict[num] {
                 dict[num] = count + 1
             } else {
                 dict.updateValue(1, forKey: num)
             }
         }
         
         //遍历字典
         for val in dict {
             if val.value == 1 {
                 return val.key
             }
         }
         return -1
     }
 }
 */


let solution = Solution.init()
let result = solution.singleNumber([9,1,7,9,7,9,7])
print("result = \(result)")
