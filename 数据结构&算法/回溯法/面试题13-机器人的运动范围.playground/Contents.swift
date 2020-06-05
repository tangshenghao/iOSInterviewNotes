
class Solution {
    func movingCount(_ m: Int, _ n: Int, _ k: Int) -> Int {
        
        //利用回溯法，因为是从0，0开始，走过的不用再，记录走过的位置所以不用删掉记录数组
        var visitArray = Array.init(repeating: 0, count: m * n)
        
        return movingCountCore(m, n, k, &visitArray, 0, 0)
    }
    
    func movingCountCore(_ m: Int, _ n: Int, _ k: Int, _ visitArray: inout [Int], _ currentM: Int,_ currentN: Int ) -> Int {
        var count = 0
        //判断当前是否符合标准
        if check(m, n, k, currentM, currentN, visitArray) {
            visitArray[currentM * n + currentN] = 1
            //从1开始加
            //上下左右都走一次-只要没走过的都相加
            count = 1 + movingCountCore(m, n, k, &visitArray, currentM, currentN - 1) + movingCountCore(m, n, k, &visitArray, currentM, currentN + 1) + movingCountCore(m, n, k, &visitArray, currentM + 1, currentN) + movingCountCore(m, n, k, &visitArray, currentM - 1, currentN)
        }
        
        return count
    }
    
    func check(_ m: Int, _ n: Int, _ k: Int, _ currentM: Int,_ currentN: Int, _ visitArray: [Int]) -> Bool {
        if currentM < m && currentN < n && currentM >= 0 && currentN >= 0 && (digitSum(currentM) + digitSum(currentN) <= k && visitArray[currentM * n + currentN] == 0){
            return true
        }
        return false
    }
    
    //数字位数和
    func digitSum(_ value:Int) -> Int {
        var sum = 0
        var tempValue = value
        
        while tempValue > 0 {
            sum += tempValue % 10
            tempValue /= 10
        }
        return sum
    }
}
let solution = Solution.init()
let result = solution.movingCount(1, 2, 1)
print("result == \(result)")


