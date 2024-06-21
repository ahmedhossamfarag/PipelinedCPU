class Control{
    var opCodeSignal: Signal?
    var wbSignal, mSignal, exSignal :Signal?

    init(){
        wbSignal = Signal(read: self.readWB)
        mSignal = Signal(read: self.readM)
        exSignal = Signal(read: self.readEX)
    }

    func readWB() -> Int{
        let opCode = OpCode(rawValue: opCodeSignal?.read() ?? OpCode.NONE.rawValue) ?? .NONE
        let memoReg = switch opCode {
            case .LW: 0
            default: 1
        }
        let regWrite = switch opCode {
            case .SW, .BEQ, .BNE, .J, .NONE: 0
            default: 1
        }
        return (memoReg << 1) + regWrite
    }

    func readM() -> Int{
        let opCode = OpCode(rawValue: opCodeSignal?.read() ?? OpCode.NONE.rawValue) ?? .NONE
        let memoRW = switch opCode {
            case .LW: 0b01
            case .SW: 0b10
            default: 0
        }
        return memoRW << 1
    }

    func readEX() -> Int{
        let opCode = OpCode(rawValue: opCodeSignal?.read() ?? OpCode.NONE.rawValue) ?? .NONE
        let aluSrc = switch opCode {
            case .ADDI, .LW, .SW: 1
            default: 0
        }
        let regDst = switch opCode {
            case .ADDI, .LW: 0
            default: 1
        }

        return (aluSrc << 2) + regDst
    }
}

class ALUControl{
    var opCodeSignal, inst_0_5_Signal : Signal?
    var aluCodeSignal: Signal?

    init(){
        aluCodeSignal = Signal(read: self.read)
    }

    func read() -> Int{
         let opCode = OpCode(rawValue: opCodeSignal?.read() ?? OpCode.NONE.rawValue) ?? .NONE
        return switch opCode {
            case .NONE: ALUCode.NONE.rawValue
            case .LW, .SW, .ADDI: ALUCode.ADD.rawValue
            case .BEQ, .BNE: ALUCode.SUB.rawValue
            default: inst_0_5_Signal?.read() ?? ALUCode.NONE.rawValue
        }
    }
}

class BranchControl{
    var opCodeSignal, zeroSignal : Signal?
    var pcSrcSignal: Signal?

    init(){
        pcSrcSignal = Signal(read: self.read)
    }

    func read() -> Int{
        let opCode = OpCode(rawValue: opCodeSignal?.read() ?? OpCode.NONE.rawValue) ?? .NONE
        let zero = zeroSignal?.read() == 1
        return switch opCode {
            case .J: 1
            case .BEQ: zero ? 1:0
            case .BNE: zero ? 0:1
            default: 0
        }
    }
}