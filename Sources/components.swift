class Register : CLK_Listener, CustomStringConvertible{
    var inSignal: Signal?
    var outSignal: Signal?

    var state = (currentState: 0, nextState: 0)

    var description: String { return "\(state.currentState)" }

    required init(_ clk: CLK){
        clk.addListener(listener: self)
        outSignal = Signal(read: self.read)
    }

    func read() -> Int{
        return state.currentState
    }

    func update(){
        state.nextState = inSignal?.read() ?? 0
    }

    func propagate(){
        state.currentState = state.nextState;
    }
}

class Memory : CLK_Listener, CustomStringConvertible{
    var dataSignal, addressSignal, memReadSignal, memWriteSignal: Signal?
    var outSignal: Signal?

    private var memData : [Int]

    var description: String { return "\(memData)" }
    
    var state = (address: 0, data: 0, write: false)

    init(clk: CLK, memData: [Int]){
        self.memData = memData
        clk.addListener(listener: self)
        outSignal = Signal(read: self.read)
    }

    subscript(i: Int) -> Int{ get{memData[i]} }

    func read() -> Int{
        let canRead = memReadSignal?.read() ==  1
        let readAddress = addressSignal?.read() ?? 0
        return canRead ? memData[readAddress%memData.count] : 0
    }

    func update(){
        state.address = addressSignal?.read() ?? 0
        state.data = dataSignal?.read() ?? 0
        state.write = memWriteSignal?.read() == 1
    }

    func propagate(){
        if state.write {
            memData[state.address%memData.count] = state.data
        }
    }
}

class ALU{
    var arg1Signal, arg2Signal, codeSignal: Signal?
    var zeroSignal, resultSignal : Signal?

    init(){
        zeroSignal = Signal(read: self.zero)
        resultSignal = Signal(read: self.result)
    }

    func result() -> Int{
        let arg1 = arg1Signal?.read() ?? 0
        let arg2 = arg2Signal?.read() ?? 0
        let code = ALUCode(rawValue: codeSignal?.read() ?? ALUCode.NONE.rawValue) ?? .NONE
        return switch code {
        case .ADD: arg1 + arg2
        case .SUB: arg1 - arg2
        case .AND: arg1 & arg2
        case .NOR: ~(arg1 | arg2)
        case .SLL: arg1 << arg2
        case .SRL: arg1 >> arg2
        case .SLT: arg1 < arg2 ? 1 : 0
        case .SLTU: UInt(truncatingIfNeeded: arg1) < UInt(truncatingIfNeeded: arg2) ? 1 : 0
        default: 0
        }
    }

    func zero() -> Int{
        return result() == 0 ? 1 : 0
    }
}

class RegistersBlock : CLK_Listener, CustomStringConvertible{
    var readRg1Signal, readRg2Signal, writeRgSignal, writeDataSignal, regWriteSignal: Signal?
    var readData1Signal, readData2Signal: Signal?

    var registers : [Int]

    var description: String{let rgs = Registers.allCases; return registers.enumerated().map{"\(rgs[$0]): \($1)"}.joined(separator: " , ")}

    var state = (writeRg: 0, data: 0, write: false)

    required init(clk: CLK){
        self.registers = Array(repeating: 0, count: Registers.Count.rawValue)
        clk.addListener(listener: self)
        readData1Signal = Signal(read: self.readRg1)
        readData2Signal = Signal(read: self.readRg2)
    }

    func readRg1() -> Int{
        let readRg = readRg1Signal?.read() ?? 0
        return readRg < registers.count ? registers[readRg] : 0
    }

    func readRg2() -> Int{
        let readRg = readRg2Signal?.read() ?? 0
        return readRg < registers.count ? registers[readRg] : 0
    }

    func update(){
        state.writeRg = writeRgSignal?.read() ?? 0
        state.data = writeDataSignal?.read() ?? 0
        state.write = regWriteSignal?.read() == 1
    }

    func propagate(){
        if state.write {
            registers[state.writeRg] = state.data
        }
    }
}

class InstMemory{
    var addressSignal: Signal?
    var instSignal: Signal?

    let instructions : [Int]

    init(instructions : [Int]){
        self.instructions = instructions
        instSignal = Signal(read: self.read)
    }

    func read() -> Int{
        let address = addressSignal?.read() ?? 0
        return instructions[(address / 4)%instructions.count]
    }
}

class Mux{
    var arg1Signal, arg2Signal, selectSignal : Signal?
    var outSignal: Signal?

    init(){
        outSignal = Signal(read: self.read)
    }

    func read() -> Int{
        let arg1 = arg1Signal?.read() ?? 0
        let arg2 = arg2Signal?.read() ?? 0
        let select = selectSignal?.read() ?? 0
        return select == 0 ? arg1 : arg2
    }
}

class Adder{
    var arg1Signal, arg2Signal : Signal?
    var outSignal: Signal?

    init(){
        outSignal = Signal(read: self.read)
    }

    func read() -> Int{
        let arg1 = arg1Signal?.read() ?? 0
        let arg2 = arg2Signal?.read() ?? 0
        return arg1 + arg2
    }
}

class Shift2{
    var inSignal : Signal?
    var outSignal: Signal?

    init(){
        outSignal = Signal(read: self.read)
    }

    func read() -> Int{
        let arg = inSignal?.read() ?? 0
        return arg << 2
    }
}

class SignExtend{
    var inSignal : Signal?
    var outSignal: Signal?

    let pos: Int

    init(pos: Int){
        self.pos = pos
        outSignal = Signal(read: self.read)
    }

    func read() -> Int{
        let arg = inSignal?.read() ?? 0
        let sign = (arg >> pos) & 1
        return sign == 0 ? arg : (-1 << pos ) | arg
    }
}
