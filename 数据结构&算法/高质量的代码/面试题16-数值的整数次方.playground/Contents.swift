class Solution {
    func myPow(_ x: Double, _ n: Int) -> Double {
        
        // 如果n是偶数，则a的n次方等于a的n/2次方再乘以a的n/2次方，比如2^4 = 2^2 * 2^2
        // 如果n是奇数，则a的n次方等于a的n/2次方再乘以a的n/2次方再乘以n，比如 2^5 = 2^2 * 2^2 * 2
        // 例如求32次方，只需要计算5次乘法（2、4、8、16、32）
        
        if x == 0 {
            return 0
        }
        if n == 0 {
            return 1
        }
        if n == 1 {
            return x
        }
        var result = x
        // 处理负数
        if n < 0 {
           return myPow(1 / x, -n)
        }
        
        // 右移动一位相当于/2 效率会比除法快
        result = myPow(x, n >> 1)
        // 结果相乘
        result *= result
        // 判断是否是奇数 则但乘n
        if n & 0x1 > 0 {
            result *= x
        }
        
        return result
        
        
        //直接按照x互相乘以n次，判断n是否小于0，如果小于0的话使用
        //将x转换成1/x，然后进行-n次的互乘
        //但该种方法会循环n次，如果非常大会超出时间限制
//        if x == 0 {
//            return 0
//        }
//        if n == 0 {
//            return 1
//        }
//        var tempX = x
//        var result = 1.0
//        var tempN = n
//        if tempN < 0 {
//            tempX = 1 / x
//            tempN = -1 * tempN
//        }
//        while tempN != 0 {
//
//            result *= tempX
//            tempN -= 1
//        }
//        return result
    }
}

let soluton = Solution.init()
let result = soluton.myPow(2, 10)
print("result = \(result)")
