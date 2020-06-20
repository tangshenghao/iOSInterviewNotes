class Solution {
    func maxSlidingWindow(_ nums: [Int], _ k: Int) -> [Int] {
        
        if k <= 0 || k > nums.count || nums.isEmpty {
            return []
        }
        // 大小实际为 count - k + 1
        var result: [Int] = []
        // 创建一个数组，用作单调的双端队列，将队列中的对头数据返回
        var queue: [Int] = []
        
        for i in 0..<nums.count {
            
            // 判断是不是递减、保持队头最大值
            while !queue.isEmpty && nums[queue.last!] <= nums[i] {
                queue.removeLast()
            }
            
            queue.append(i)
            // 对头元素索引超过窗口的起始点，则删除对头元素，维持队里是窗口的范围内
            if i - k == queue.first! {
                queue.removeFirst()
            }
            
            // 超过K大小的窗口时，每次将队头数据加到结果中
            if  i >= k - 1 {
                result.append(nums[queue.first!])
            }
        }
        
        return result
    }
}
let solution = Solution.init()
let result = solution.maxSlidingWindow([1,3,-1,-3,5,3,6,7], 3)
print("result = \(result)")

