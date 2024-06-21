enum FetchError: Error{
    case UnexpectedInstruction(String)
}

struct Instruction{
    var label : String?
    var opCode : String = ""
    var args : [String] = []

    func arg(_ i:Int) throws -> String{
        if i < args.count {
            return args[i]
        }
        throw FetchError.UnexpectedInstruction("Unexpected args")
    }
}

extension String.SubSequence {
    func trim() -> String.SubSequence{
        var str = self
        while str.first == " " {str = str.dropFirst()}
        while str.last == " " {str = str.dropLast()}
        return str
    }
}

func splitInstruction(_ str: String) -> Instruction{
    var val = String.SubSequence(str)
    var inst = Instruction()

    if let i = val.firstIndex(of: ":"){
        inst.label = val.prefix(upTo: i).trim().lowercased()
        val = val.suffix(from: val.index(after: i)).trim()
    }

    if let i = val.firstIndex(of: " "){
        inst.opCode = val.prefix(upTo: i).trim().lowercased()
        inst.args = val.suffix(from: val.index(after: i)).split(separator: ",").map{$0.trim().lowercased()}
    }else{
        inst.opCode = val.lowercased()
    }

    return inst
}

func getLabels(_ instructions: [Instruction]) throws -> [String: Int]{
    var dict = [String: Int]()
    for i in 0..<instructions.count{
        if let label = instructions[i].label{
            guard !dict.keys.contains(label) else{
                throw FetchError.UnexpectedInstruction("Duplicate Label")
            }
            dict.updateValue(i, forKey: label)
        }
    }
    return dict
}

func getReg(_ rgname: String) throws -> Int{
    for rg in Registers.allCases{
        if "$\(rg)".lowercased() == rgname{
            return rg.rawValue
        }
    }
    throw FetchError.UnexpectedInstruction("Unexpected Register")
}

func getInt(_ val: String) throws -> Int{
    let int = Int(val)
    guard int != nil else{
        throw FetchError.UnexpectedInstruction("Unexpected Int")
    }
    return int!
}

func getAddress(_ address: String, line: Int, labels: [String: Int]) throws -> Int{
    do {
        let int = try getInt(address)
        return int
    }catch FetchError.UnexpectedInstruction(_) {
        guard labels.keys.contains(address) else{
            throw FetchError.UnexpectedInstruction("Unexpected Label")
        }
        return labels[address]! - line - 1
    }
}

func splitMemAddress(_ address: String) throws -> (Int, Int){
    if let i = address.firstIndex(of: "("), let j = address.lastIndex(of: ")"){
        return (try getInt(String(describing: address[..<i])) ,try getReg(String(describing: address[address.index(after: i)..<j])))
    }
    return (0,Registers.NONE.rawValue)
}

func map(_ inst : Instruction, line : Int, labels : [String:Int]) throws -> Int{

    var code: Int = 0
    var rd: Int = 0, rs: Int = 0, rt: Int = 0
    var immediate: Int = 0
    var aluCode: Int = 0
    var address: Int = 0
    switch inst.opCode{
        case "add", "sub", "sll", "srl", "and", "nor", "slt", "sltu" :
            code = OpCode.ALU.rawValue
            rd = try getReg(inst.arg(0))
            rs = try getReg(inst.arg(1))
            rt = try getReg(inst.arg(2))
            aluCode = ALUCode.allCases.first(where: {"\($0)".lowercased() == inst.opCode})?.rawValue ?? ALUCode.NONE.rawValue

        case "addi":
            code = OpCode.ADDI.rawValue
            rt = try getReg(inst.arg(0))
            rs = try getReg(inst.arg(1))
            immediate = try getInt(inst.arg(2))

        case "beq", "bne":
            code = OpCode.allCases.first(where: {"\($0)".lowercased() == inst.opCode})?.rawValue ?? OpCode.NONE.rawValue
            rs = try getReg(inst.arg(0))
            rt = try getReg(inst.arg(1))
            immediate = try getAddress(inst.arg(2), line: line, labels: labels)

        case "lw", "sw":
            code = inst.opCode == "lw" ? OpCode.LW.rawValue : OpCode.SW.rawValue
            rt = try getReg(inst.arg(0))
            (immediate, rs) = try splitMemAddress(inst.arg(1))

        case "j":
            code = OpCode.J.rawValue
            address = try getAddress(inst.arg(0), line: line, labels: labels)

        case "skip":
            return 0

        default:
            throw FetchError.UnexpectedInstruction("Unexcpected opcode \(inst.opCode)")
    }

    immediate = immediate & ((1<<16)-1)
    address = address & ((1<<26)-1)

    return (code << 26) | (rs << 21) | (rt << 16) | (rd << 11) | immediate | address | aluCode
}

func fetch(_ lines: [String]) throws  -> [Int]{
    let instructions = lines.map{splitInstruction($0)}
    let labels = try getLabels(instructions)
    let codes = try instructions.enumerated().map{
        do{
            return try map($1, line: $0, labels: labels)
        }catch FetchError.UnexpectedInstruction(let msg){
            throw FetchError.UnexpectedInstruction("Line \($0) : \(msg)")
        }
    }
    return codes
}

