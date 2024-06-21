func test_SignalClass(){
    var x : Int = 0
    var testVal : Int
    let s = Signal(read: {x})

    // Signal.read
    for i in 1...3 {
        x = i
        testVal = s.read()
        assert(testVal == x, "Signal.read: Expected \(x) got \(testVal)")
    }

    // Signal[i,j]
    x = 0b0011001010
    testVal = s[1, 3].read() 
    assert(testVal == 0b101, "Signal[i,j]: Expected \(0b101) got \(testVal)")

    // Signal[i]
    testVal = s[5].read()
    assert(testVal == 0b0, "Signal[i]: Expected \(0b011) got \(testVal)")

    print("Signal Class Passed")
}

func test_ConnectFunc(){
    let s1 = Signal(read: {0})
    var s2 : Signal?

    // connect(Signal,Signal)
    connect(s1, &s2)
    assert(s1 === s2, "connect(Signal,Signal): Expected s1 === s2 get else")

    // connect(Int,Signal)
    connect(2, &s2)
    let testVal = s2?.read()
    assert(testVal == 2, "connect(Int,Signal): Expected 2 get \(String(describing: testVal))")
    
    print("connect Func Passed")
}

func test_RegisterClass(){
    let clk = CLK()
    var x = 0
    let s = Signal(read: {x})
    let r = Register(clk)
    var testVal : Int

    connect(s,&r.inSignal)
    for i in 1...3{
        x = i
        clk.performUpdate()
        testVal = r.outSignal?.read() ?? -1
        assert(testVal == x - 1, "Register.update: Expected \(x-1) got \(testVal)")
        clk.performPropagate()
        assert(testVal == x, "Register.propagete: Expected \(x) got \(testVal)")
    } 

    print("Register Class Passed")
}

func test_MemoryClass(){
    let clk = CLK()
    let data = [9,2,1,4,3,5]
    let memo = Memory(clk: clk, memData: data)
    var address = 0
    let addressSg = Signal(read: {address})
    var d = 0
    let dSg = Signal(read: {d})
    var r = 0
    let rSg = Signal(read: {r})
    var w = 0
    let wSg = Signal(read: {w})
    var val : Int

    connect(addressSg, &memo.addressSignal)
    connect(dSg, &memo.dataSignal)
    connect(rSg, &memo.memReadSignal)
    connect(wSg, &memo.memWriteSignal)

    // read
    r = 1
    address = 3
    val = memo.outSignal?.read() ?? -1
    assert(val == memo[address], "Memory.read: Expected \(memo[address]) got \(val)")
    r = 0
    val = memo.outSignal?.read() ?? -1
    assert(val == 0, "Memory.read: Expected 0 got \(val)")

    // write
    w = 1
    address = 4
    d = 12
    memo.update()
    assert(3 == memo[address], "Memory.update: Expected \(3) got \(memo[address])")
    memo.propagate()
    assert(d == memo[address], "Memory.propagate: Expected \(d) got \(memo[address])")
    w = 0
    address = 0
    clk.performCycle()
    assert(9 == memo[address], "Memory write: Expected \(9) got \(memo[address])")

    print("Memory Class Passed")
}

func test_fetch(){
    // splitInstruction
    var inst = splitInstruction("add $ax, $ax, $bx")
    assert(inst.opCode == "add", "splitInstrunction: Instruction.opCode Expected add got \(inst.opCode)")
    assert(inst.label == nil, "splitInstrunction: Instruction.label  Expected nil got \(inst.label ?? "")")
    assert(inst.args == ["$ax", "$ax", "$bx"], "splitInstrunction: Instruction.args   Expected \(["$ax", "$ax", "$bx"]) got \(inst.args)")

    inst = splitInstruction("L:add $ax, $ax, $bx")
    assert(inst.opCode == "add", "splitInstrunction: Instruction.opCode  Expected add got \(inst.opCode)")
    assert(inst.label == "l", "splitInstrunction: Instruction.label  Expected l got \(inst.label ?? "")")
    assert(inst.args == ["$ax", "$ax", "$bx"], "splitInstrunction: Instruction.args  Expected \(["$ax", "$ax", "$bx"]) got \(inst.args)")

    // map
    let code = try? map(inst, line: 0, labels: [String:Int]())
    var expected = (OpCode.ALU.rawValue << 26) | (Registers.AX.rawValue << 21) | (Registers.BX.rawValue << 16) | (Registers.AX.rawValue << 11) | (ALUCode.ADD.rawValue)
    assert(code == expected, "map: Expected \(expected) got \(String(describing: code))")

    // labels
    let lines =  ["j L", "skip", "skip", "L:skip", "skip"]
    let codes = try! fetch(lines)
    expected = (OpCode.J.rawValue << 26) | (2)
    assert(codes[0] == expected, "labels: Expected \(expected) got \(String(describing: codes[0]))")

    print("fetch Func Passed")
}

func test_CPU(){
    // addi

    let clk = CLK()
    var lines = ["addi $ax, $ax, 11", "skip", "skip", "skip", "skip"]
    var instructions = try! fetch(lines) 
    let data = [0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9]
    
    var arch = buildCPU(clk: clk, instructions: instructions, memData: data)

    for i in 1...5{
        clk.performCycle()
        let val = arch.pc.outSignal?.read() ?? -1
        assert(val == i*4, "CPU: pc expected \(i*4) got \(val)")
    }
    var val = arch.registers.registers[Registers.AX.rawValue]
    assert(val == 11, "CPU: ax expected 11 got \(val)")

    // lw

    lines = ["lw $bx, 3($ds)", "skip", "skip", "skip", "skip"]
    instructions = try! fetch(lines)
    
    arch = buildCPU(clk: clk, instructions: instructions, memData: data)

    for _ in 1...5{
        clk.performCycle()
    }

    val = arch.registers.registers[Registers.BX.rawValue]
    assert(val == data[3], "CPU: bx expected \(data[3]) got \(val)")

    // sw

    lines = ["sw $bx, 3($ds)", "skip", "skip", "skip", "skip"]
    instructions = try! fetch(lines)
    
    arch = buildCPU(clk: clk, instructions: instructions, memData: data)

    for _ in 1...5{
        clk.performCycle()
    }

    val = arch.memo[3]
    assert(val == 0, "CPU: bx expected \(0) got \(val)")

    // j
    lines = ["j -1", "skip", "skip", "skip", "skip"]
    instructions = try! fetch(lines)

    arch = buildCPU(clk: clk, instructions: instructions, memData: data)

    for _ in 1...4{
        clk.performCycle()
    }

    val = arch.pc.outSignal!.read()
    assert(val == 0, "CPU: pc expected \(0) got \(val)")

    // beq 
    lines = ["beq $ax, $bx, -1", "skip", "skip", "skip", "skip"]
    instructions = try! fetch(lines)

    arch = buildCPU(clk: clk, instructions: instructions, memData: data)

    for _ in 1...4{
        clk.performCycle()
    }

    val = arch.pc.outSignal!.read()
    assert(val == 0, "CPU: pc expected \(0) got \(val)")

    print("CPU Passed")
}

