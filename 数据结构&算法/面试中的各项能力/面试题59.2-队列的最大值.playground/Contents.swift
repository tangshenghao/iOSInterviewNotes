class MaxQueue {

    var queue:[Int] = []
    var maxQueue:[Int] = []
    init() {
        
    }
    
    func max_value() -> Int {
        return maxQueue.first ?? -1
    }
    
    func push_back(_ value: Int) {
        queue.append(value)
        
        while maxQueue.count > 0 && maxQueue.last! <= value {
            maxQueue.removeLast()
        }
        maxQueue.append(value)
    }
    
    func pop_front() -> Int {
        var value = -1
        if queue.count > 0 {
            value = queue.removeFirst()
        }
        
        if maxQueue.count > 0 && maxQueue.first! == value {
            maxQueue.removeFirst()
        }
        
        return value
    }
}

let obj = MaxQueue()
let ret_1: Int = obj.max_value()
obj.push_back(2)
obj.push_back(3)
obj.push_back(1)
let ret_3: Int = obj.pop_front()
let ret_4: Int = obj.max_value()
print("result = \(ret_3) max = \(ret_4)")
