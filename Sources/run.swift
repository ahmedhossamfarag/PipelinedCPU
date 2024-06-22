func readLines() -> [String]{
    let filePath = CommandLine.arguments[1]

    do {
        let fileContent = try String(contentsOfFile: filePath, encoding: .utf8)
        let lines = fileContent.split(separator: "\r\n").map{String(describing: $0)}
        return lines
    } catch {
        print("Error reading file: \(error)")
        exit(1)
    }
}

func readData() -> [Int]{
    if CommandLine.argc == 2 {
        return Array(repeating: 0, count: 100)
    }

    let filePath = CommandLine.arguments[2]

    do {
        let fileContent = try String(contentsOfFile: filePath, encoding: .utf8)
        let data = try fileContent.split(separator: "\n").map{if let int = Int($0) {return int} else {throw FetchError.InvalidInput("Invalid Int \($0)")}}
        return data
    } catch {
        print("Error reading file: \(error)")
        exit(1)
    }
}

func runCode(lines: [String], data: [Int]){
    do{
        let clk = CLK()
        let instructions = try fetch(lines)
        let arch = buildCPU(clk: clk, instructions: instructions, memData: data)

        while true{
            clk.performCycle()
            print(arch)
            print(".....................................................................")
            if(arch.pc.read() == instructions.count * 4){
                exit(1)
            }
        }
    }catch{
        print(error)
        exit(1)
    }
}
