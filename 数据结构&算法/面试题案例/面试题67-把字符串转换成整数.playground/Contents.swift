func strToInt(_ str: String) -> Int {
       var strArray = Array(str)
       if strArray.count == 0 {
           return 0
       }
       var result = 0
       let bndry = Int32.max / 10
       var i = 0
       var sign = 1
       
       //去除前部分空格
       while strArray.count > 0 && strArray[0] == " " {
           strArray.removeFirst()
       }
       if strArray.count == 0 {
           return 0
       }
       if strArray[0] == "-" {
           sign = -1
           i = 1
       } else if strArray[0] == "+" {
           i = 1
       }
       
       for index in i..<strArray.count {
           
           if strArray[index].asciiValue! < Character("0").asciiValue! || strArray[index].asciiValue! > Character("9").asciiValue! {
               break
           }
           if result > bndry || result == bndry && strArray[index] > "7" {
               return sign == 1 ? Int(Int32.max) : Int(Int32.min)
           }
           result = result * 10 + Int(String(strArray[index]))!
       }
       return sign * result
   }
