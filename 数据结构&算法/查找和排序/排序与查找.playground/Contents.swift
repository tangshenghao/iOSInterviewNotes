
//快速排序 while处理
func quickSort(_ arr:inout [Int], start: Int, end: Int) {
    
    if start >= end {
        return
    }
    
    let index = arr[start]
    var tempStart = start
    var tempEnd = end
    while tempStart != tempEnd {
        while arr[tempEnd] >= index && tempStart < tempEnd {
            tempEnd -= 1
        }
        if tempStart == tempEnd {
            break
        }
        while arr[tempStart] <= index && tempStart < tempEnd  {
            tempStart += 1
        }
        if tempStart == tempEnd {
            break
        }
        if tempStart < tempEnd {
            let temp = arr[tempStart]
            arr[tempStart] = arr[tempEnd]
            arr[tempEnd] = temp
        }
    }
    if start != tempStart {
        arr[start] = arr[tempStart]
        arr[tempStart] = index
    }
    
    print("once====\(arr)===\(tempStart)")
    
    quickSort(&arr, start:start , end: tempStart - 1)
    quickSort(&arr, start:tempStart + 1 , end: end)
}

var valueArr : [Int] = [6, 1, 2, 7, 9, 6, 4, 5, 10, 8]
quickSort(&valueArr, start: 0, end: valueArr.count - 1)
print("result = \(valueArr)")

//快速排序 for循环
func quickForSort(_ arr:inout [Int], start: Int, end: Int) {
    if start >= end {
        return
    }
    print("\(start)==\(end)")
    let index = partition(&arr, start: start, end: end)
    print("\(arr)===\(index)")
    if index > start {
        partition(&arr, start: start, end: index - 1)
    }
    if index < end {
        partition(&arr, start: index+1, end: end)
    }
}

func partition(_ arr:inout [Int], start: Int, end: Int) -> Int {
    if start >= end {
        return start
    }
    
    //将最后一个元素作为关键元素
    var index = start
    for i in start..<end+1 {
        
        if arr[i] < arr[end] {
            
            if (index != i) {
                let temp = arr[i]
                arr[i] = arr[index]
                arr[index] = temp
            }
            index += 1
            print("======\(arr)====\(index)")
        }
    }
    
    //将最后的元素交换至index位置
    let temp = arr[end]
    arr[end] = arr[index]
    arr[index] = temp
    
    return index
}


//quickForSort(&valueArr, start: 0, end: valueArr.count - 1)
//print("result = \(valueArr)")
