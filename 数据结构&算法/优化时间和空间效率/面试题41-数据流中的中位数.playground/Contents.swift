class MedianFinder {

    var arr:[Int] = []
    /** initialize your data structure here. */
    init() {
        
    }
    //该题使用插入排序方式
    //插入排序可以在插入一个数字之后，不影响其他位置的顺序
    //此处利用二分查找，找出插入的值的位置。时间复杂度为O(logN)
    //然后执行插入指定的位置-此处应该是插入具体位置，然后所有后续的数向后移动。需要花O(N)的时间
    func addNum(_ num: Int) {
        if arr.isEmpty {
            arr.append(num)
            return
        }
        //二分查找-找到插入数字的顺序位置
        var left = 0
        var right = arr.count - 1
        while left <= right {
            let mid = (left + right) / 2
            if arr[mid] < num {
                left = mid + 1
            } else if arr[mid] == num {
                left = mid
                break
            } else {
                right = mid - 1
            }
        }
        arr.insert(num, at: left)
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

let obj = MedianFinder()
obj.addNum(2)
obj.addNum(1)
let ret_2: Double = obj.findMedian()
print("result = \(ret_2)")

/*
 另外一种解法是创建大小堆
 大顶堆用来存储小的一半的数字
 小顶堆用来存储大的一半的数字
 ，重要的是要维持这两个堆的平衡。
 这样取中值的时候，可以做到，如果大顶堆大于小顶堆，则取大顶堆的顶。
 如果大顶堆等于小顶堆，则取双方顶除2
 
 维持的做法是，添加一个数先加入大顶堆，然后将大顶堆最大的值移除给到小顶堆
 然后如果小顶堆的数量大于大顶堆则，则将小顶堆的最小的值移除给到大顶堆。即可维持平衡
 */



/*
//直接每次新增数据之后排序 会在大数的情况下超时
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


