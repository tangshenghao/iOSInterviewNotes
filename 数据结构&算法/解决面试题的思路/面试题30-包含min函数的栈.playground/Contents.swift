class MinStack {

    /** initialize your data structure here. */
    var stackOne:[Int]
    var stackTwo:[Int]
    init() {
        //模拟栈的数组
        stackOne = []
        
        //模拟辅助栈的数组
        stackTwo = []
    }
    
    func push(_ x: Int) {
        stackOne.append(x)
        
        if (stackTwo.count == 0 || stackTwo.last! > x) {
            stackTwo.append(x)
        } else {
            stackTwo.append(stackTwo.last!)
        }
    }
    
    func pop() {
        stackOne.removeLast()
        stackTwo.removeLast()
    }
    
    func top() -> Int {
        return stackOne.last ?? Int.max
    }
    
    func min() -> Int {
        return stackTwo.last ?? Int.max
    }
}


let obj = MinStack()
obj.push(-1)
obj.push(2)
obj.push(1)
obj.push(6)
obj.push(9)
obj.pop()
let ret_3: Int = obj.top()
let ret_4: Int = obj.min()

print("ret3 = \(ret_3)   ret4 = \(ret_4)")
