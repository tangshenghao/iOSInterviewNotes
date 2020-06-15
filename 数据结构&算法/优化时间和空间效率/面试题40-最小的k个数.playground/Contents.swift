class Solution {
    func getLeastNumbers(_ arr: [Int], _ k: Int) -> [Int] {
        
        let length = arr.count
        if length == k {
            return arr
        }
        if k == 0 {
            return []
        }
        
        //基于快速排序的解法 循环
        var tempArr = arr
        var start = 0
        var end = tempArr.count - 1
        var index = partition(&tempArr, start, end)
        while index != k - 1 {
            if index > k - 1 {
                end = index - 1
                index = partition(&tempArr, start, end)
            } else if index < k - 1 {
                start = index + 1
                index = partition(&tempArr, start, end)
            }
        }
        return Array(tempArr[0..<k])
        //由于限定了0 <= arr[i] <= 10000
        //可以基于桶排序做出该道题
//        var bucket:[Int] = Array.init(repeating: 0, count: 10000)
//
//        for val in arr {
//            bucket[val] += 1
//        }
//
//        var result:[Int] = []
//        var count = 0
//        for (index, val) in bucket.enumerated() {
//            if val > 0 {
//                var temp = val
//                while temp != 0 {
//                    result.append(index)
//                    temp -= 1
//                    count += 1
//                    if count == k {
//                        return result
//                    }
//                }
//            }
//        }
//        return result
    }
    
    func partition(_ arr: inout [Int], _ start: Int, _ end:Int) -> Int {
        
        let pivot = arr[end]
        var i = start
        for j in start..<end {
            if arr[j] < pivot {
                (arr[i], arr[j]) = (arr[j], arr[i])
                i += 1
            }
        }
        (arr[i], arr[end]) = (arr[end], arr[i])
        return i
    }
}

let solution = Solution.init()
let result = solution.getLeastNumbers([0,0,1,3,4,5,0,7,6,7]
, 9)
print("result = \(result)")
