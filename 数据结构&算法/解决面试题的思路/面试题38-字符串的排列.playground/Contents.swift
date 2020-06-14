class Solution {
    
    //此题使用回溯 - 深度搜索
    var paths: [String] = []
    var path: String = ""
    
    
    func permutation(_ s: String) -> [String] {
        
        if s.count == 0 {
            return []
        }
        
        if s.count == 1 {
            return [s]
        }
        
        var visited = Array.init(repeating: false, count: s.count)
        let sArray = s.sorted()
        
        backtrack(sArray, &visited)
        
        return paths
    }
    
    func backtrack(_ arr:[Character], _ visited: inout [Bool]) {
        if path.count == arr.count {
            paths.append(String(path))
        }
        
        for index in 0..<arr.count {
            if visited[index] == true {
                continue
            }
            
            if index > 0 && arr[index] == arr[index - 1] && visited[index - 1] == true {
                continue
            }
            
            visited[index] = true
            path.append(arr[index])
            
            backtrack(arr, &visited)
            
            path.removeLast()
            visited[index] = false
        }
    }
}

let solution = Solution.init()
let result = solution.permutation("abc")
print(result)
