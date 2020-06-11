class Solution {
    func validateStackSequences(_ pushed: [Int], _ popped: [Int]) -> Bool {

        if pushed.count == 0 && popped.count == 0 {
            return true
        }
        
        if pushed.count == 0 || popped.count == 0 {
            return false
        }
        
        //此题用辅助栈模拟压栈和出栈。
        //如果辅助栈最上方的数与出栈序列一致时
        //移除辅助栈
        //最后判断辅助栈是否为空
        
        var simuStack:[Int] = []
        var index = 0
        for e in pushed {
            simuStack.append(e)
            while index < popped.count && simuStack.last == popped[index] {
                simuStack.removeLast()
                index += 1
            }
        }
//        var simuStack:[Int] = []
//        var i = 0
//        var j = 0
//        while j < popped.count {
//            if i < pushed.count {
//                simuStack.append(pushed[i])
//
//            }
//            if j == popped.count {
//                break
//            }
//            if simuStack.last == popped[j] {
//                simuStack.removeLast()
//                j += 1
//            } else if i >= popped.count {
//                break
//            }
//            i += 1
//        }
        return simuStack.isEmpty
    }
}

let solution = Solution.init()
let result = solution.validateStackSequences([1,2,3,4,5], [4,5,3,2,1])
print("result = \(result)")
