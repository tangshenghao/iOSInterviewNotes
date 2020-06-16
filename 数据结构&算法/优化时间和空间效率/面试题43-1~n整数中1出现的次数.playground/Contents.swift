

class Solution {
    func countDigitOne(_ n: Int) -> Int {
        if n <= 0 {
            return 0
        }
        var count = 0
        
        //数位：1代表当前求的个位位置数字个数，10表示求的十位位置数字个数
        var digit = 1
        while n / digit != 0 {
            //digit = 100 表示求百位数字为一的个数
            //302344 / (100 * 10)
            let higherNum = n / (digit * 10)
            
            // (302344 / 100) % 10 = 3
            let currentNum = (n / digit) % 10
            
            // 302344 % 100 = 44
            let lowerNum = n % digit
            
            // 000100, 000101,..., 000199, 001100...001199, ... 301199, 个数就是302 * 100
            count += higherNum * digit
            
            switch currentNum {
            case 0:
                break
            case 1:
                count += (lowerNum + 1)
            default:
                count += 1 * digit
            }
            digit *= 10
        }
        return count
    }
}

let solution = Solution.init()
let result = solution.countDigitOne(5)
print("result = \(result)")
