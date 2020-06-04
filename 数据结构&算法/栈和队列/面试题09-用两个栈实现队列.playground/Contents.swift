class CQueue {
    
    var list1 = [Int]()
    var list2 = [Int]()

    init() {
        
    }
    
    func appendTail(_ value: Int) {
        list1.append(value)
    }
    
    func deleteHead() -> Int {
        if !list2.isEmpty {
            return list2.removeLast()
        }
        
        while !list1.isEmpty {
            list2.append(list1.removeLast())
        }
        
        if list2.isEmpty {
            return -1
        }
        return list2.removeLast()
    }
}


let obj = CQueue()
obj.appendTail(3)
let ret_2: Int = obj.deleteHead()
print("result ===== \(ret_2)")

/*
 两个栈实现先进先出的队列。
 添加的时候直接可以往list1里面加
 删除的时候，第一次list2肯定是空的，需要将list1的数一个一个往里面加。此时最后加入的就是要删除的一开始最先加入的数。
 如果第二次删除的话，先判断list2是不是空，如果不是就直接取最后一个。此时是一开始第二个加入的数
*/
