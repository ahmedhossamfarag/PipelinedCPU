import Foundation

guard CommandLine.argc == 2 else {
    print("Usage: swift run <program> <file-path>")
    exit(1)
}


let lines = readLines()
let data = readData()

runCode(lines: lines, data: data)
