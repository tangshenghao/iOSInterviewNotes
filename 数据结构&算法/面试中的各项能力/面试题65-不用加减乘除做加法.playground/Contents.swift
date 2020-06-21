class Solution {
    func add(_ a: Int, _ b: Int) -> Int {
        //此题使用 相加结果 = 无进位相加 + 进位相加
        var sum = 0
        var carry = 0
        var num1 = a
        var num2 = b
        
        while num2 != 0 { // 当进位为0时跳出
            sum = num1 ^ num2  //无进位相加
            carry = (num1 & num2) << 1  //进位赋值
            num1 = sum  //num1 = 非进位和
            num2 = carry //num2 = 进位
        }
        
        return num1
    }
}

let solution = Solution.init()
let result = solution.add(2, 3)
print("result = \(result)")
