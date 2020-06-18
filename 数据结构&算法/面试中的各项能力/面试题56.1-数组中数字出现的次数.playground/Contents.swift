class Solution {
    func singleNumbers(_ nums: [Int]) -> [Int] {
        //使用两个数字异或之后会变成0的特性
        //先全部异或一边。最后得出的数字，是两个不同数字的异或
        //此时找出这个结果的，出现1的位置。
        //然后将所有的树按这个位置1或者0分为两份数组
        //然后再这两个数组异或，即可以得出两个唯一的数
        if nums.count == 0 {
            return []
        }
        var temp = 0
        for num in nums {
            temp ^= num
        }
        var n = 1
        while (temp & n) == 0 {
            n <<= 1
        }
        
        var a = 0
        var b = 0
        for num in nums {
            if num & n != 0 {
                a ^= num
            } else {
                b ^= num
            }
        }
        return [a, b]
    }
}

let solution = Solution.init()
let result = solution.singleNumbers([4, 1, 4, 6])
print(result)
