class MedianFinder {

    var arr:[Int] = []
    /** initialize your data structure here. */
    init() {
        
    }
    
    func addNum(_ num: Int) {
        arr.append(num)
        //直接排序不行。。因为每次都是插入到最后。尝试只执行1次快排。因为一次快排可以
        partition()
    }
    
    func partition() {
        
        let pivot = arr[arr.count - 1]
        let end = arr.count - 1
        var i = 0
        for j in 0..<arr.count - 1 {
            if arr[j] < pivot {
                (arr[i], arr[j]) = (arr[j], arr[i])
                i += 1
            }
        }
        (arr[i], arr[end]) = (arr[end], arr[i])
    }
    
    func findMedian() -> Double {
        if arr.count == 0 {
            return 0
        }
        if arr.count % 2 == 0 {
            let val1 = Double(arr[arr.count / 2])
            let val2 = Double(arr[arr.count / 2 - 1])
            return (val1 + val2) / 2
        } else {
            return Double(arr[arr.count / 2])
        }
    }
}



/*  //直接每次新增数据之后排序 会在大数的情况下超时
class MedianFinder {
    
    
    var arr:[Int] = []
    /** initialize your data structure here. */
    init() {
        
    }
    
    func addNum(_ num: Int) {
        arr.append(num)
        arr.sort()
    }
    
    func findMedian() -> Double {
        if arr.count == 0 {
            return 0
        }
        if arr.count % 2 == 0 {
            let val1 = Double(arr[arr.count / 2])
            let val2 = Double(arr[arr.count / 2 - 1])
            return (val1 + val2) / 2
        } else {
            return Double(arr[arr.count / 2])
        }
    }
}

*/

let obj = MedianFinder()
obj.addNum(2)
obj.addNum(1)
let ret_2: Double = obj.findMedian()
print("result = \(ret_2)")
