class CQueue {
    
    var list1 = [Int]()
    var list2 = [Int]()

    init() {
        
    }
    
    func appendTail(_ value: Int) {
        list1.append(value)
    }
    
    func deleteHead() -> Int {
        if list2.count > 0 {
            return list2.removeLast()
        } else {
            while list1.count > 0 {
                let list1Last = list1.removeLast()
                list2.append(list1Last)
            }
            return list2.popLast() ?? -1
        }
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
