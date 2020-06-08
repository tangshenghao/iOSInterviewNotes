class Solution {
    func isNumber(_ s: String) -> Bool {
        //判断是否是数字有一个标准
        //A[.[B]][e|EC] 或者 .B[e|EC]
        if s.isEmpty {
            return false
        }
        //去掉首尾空格
        let strArray = Array(s)
        var tempArray:[Character] = strArray
        for item in strArray {
            if item == " " {
                tempArray.removeFirst()
            } else {
                break
            }
        }
        if tempArray.count == 0 {
            return false
        }
        for item in strArray.reversed() {
            if item == " " {
                tempArray.removeLast()
            } else {
                break
            }
        }
        if tempArray.count == 0 {
            return false
        }
        // 记录当前判断位置
        var index = 0;
        // 判断整数部分是否 可带符号数字
        var result = scanInt(tempArray, &index)
        // 判断小数部分
        if index < tempArray.count && tempArray[index] == "." {
            index += 1
            // 小数点前面有带符号数字或者小数点后面有数字即可
            result = scanUnsignedInt(tempArray, &index) || result
        }
        if index < tempArray.count && ( tempArray[index] == "e" || tempArray[index] == "E")  {
            index += 1
            result = result && scanInt(tempArray, &index)
        }
        return result && (index == tempArray.count)
    }
    
    func scanInt(_ arr:[Character] , _ index: inout Int) -> Bool {
        if index < arr.count && ( arr[index] == "+" || arr[index] == "-") {
            index += 1
        }
        return scanUnsignedInt(arr, &index)
    }
    
    func scanUnsignedInt(_ arr:[Character] , _ index: inout Int) -> Bool {
        var flag = false
        while ( index < arr.count && arr[index] >= "0" && arr[index] <= "9" ) {
            index += 1
            flag = true
        }
        return flag
    }
}


let solution = Solution.init()
let result = solution.isNumber("0.8")
print("\(result)")
