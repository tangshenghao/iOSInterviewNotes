class Solution {
    //此题字符串的ascii码来对应key值，做类似哈希表的数组，先循环一次字符串，记录对应字符串出现的次数
    //第二次循环字符串找出第一个在数组中值为1的字符
    func firstUniqChar(_ s: String) -> Character {
        if s.isEmpty {
            return " "
        }
        
        var map :[Int] = Array.init(repeating: 0, count: 256)
        
        for item in s {
            let asciiValue = item.asciiValue ?? 0
            map[Int(asciiValue)] += 1
        }
        
        var result : Character = " "
        for item in s {
            let asciiValue = item.asciiValue ?? 0
            if map[Int(asciiValue)] == 1 {
                result = item
                break
            }
        }
        return result
    }
}

let solution = Solution.init()
let result = solution.firstUniqChar("abaccdeff")
print("result = \(result)")
