struct IF_ID{
    var pc , inst : Register

    init(_ clk: CLK){
        pc = Register(clk)
        inst = Register(clk)
    }
}

struct ID_EX{
    var wb, m, ex, pc, data1, data2, opCode, inst_0_15, inst_16_20, inst_11_15: Register

    init(_ clk: CLK){
        wb = Register(clk)
        m = Register(clk)
        ex = Register(clk)
        pc = Register(clk)
        data1 = Register(clk)
        data2 = Register(clk)
        opCode = Register(clk)
        inst_0_15 = Register(clk)
        inst_16_20 = Register(clk)
        inst_11_15 = Register(clk)
    }
}

struct EX_MEM{
     var wb, m, j_add, opCode, alu_zero, alu__result, data2, wr_rg: Register
     
     init(_ clk: CLK){
        wb = Register(clk)
        m = Register(clk)
        j_add = Register(clk)
        opCode = Register(clk)
        alu_zero = Register(clk)
        alu__result = Register(clk)
        data2 = Register(clk)
        wr_rg = Register(clk)
     }
}

struct MEM_WB{
    var wb, mem_read, alu_result, wr_rg: Register

    init(_ clk: CLK){
        wb = Register(clk)
        mem_read = Register(clk)
        alu_result = Register(clk)
        wr_rg = Register(clk)
    }
}

struct Architicture : CustomStringConvertible{
    // IF
    let pc_mux : Mux
    let pc : Register
    let inst_memo : InstMemory
    let add4 : Adder
    let if_id : IF_ID

    // ID
    let control : Control
    let registers : RegistersBlock
    let sign_extend: SignExtend
    let id_ex : ID_EX

    // EX
    let j_add : Adder
    let shift2 : Shift2
    let alu : ALU
    let alu_mux : Mux
    let alu_control : ALUControl
    let rg_wr_mux : Mux
    let ex_mem : EX_MEM

    // MEM
    let branchcontrol : BranchControl
    let memo : Memory
    let mem_wb : MEM_WB

    // WB
    let wr_data_mux : Mux


    init(clk: CLK, instructions: [Int], memData: [Int]){
        // IF
        pc_mux = Mux()
        pc = Register(clk)
        inst_memo = InstMemory(instructions: instructions)
        add4 = Adder()
        if_id = IF_ID(clk)

        // ID
        control = Control()
        registers = RegistersBlock(clk: clk)
        sign_extend = SignExtend(pos: 15)
        id_ex = ID_EX(clk)

        // EX
        j_add = Adder()
        shift2 = Shift2()
        alu = ALU()
        alu_mux = Mux()
        alu_control = ALUControl()
        rg_wr_mux = Mux()
        ex_mem = EX_MEM(clk)

        // MEM
        branchcontrol = BranchControl()
        memo = Memory(clk: clk, memData: memData)
        mem_wb = MEM_WB(clk)

        // WB
        wr_data_mux = Mux()

    }

    
    var description: String{
        return """
        pc: \(pc)
        registers: \(registers)
        memory: \(memo)
        """
    }
}
