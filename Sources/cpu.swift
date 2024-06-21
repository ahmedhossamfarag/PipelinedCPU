
func buildIF(architicture: Architicture){
    let pc_mux = architicture.pc_mux
    let pc = architicture.pc
    let inst_memo = architicture.inst_memo
    let add4 = architicture.add4
    let if_id = architicture.if_id

    let ex_mem = architicture.ex_mem
    let branchcontrol = architicture.branchcontrol

    // pc_mux
    connect(add4.outSignal, &pc_mux.arg1Signal)
    connect(ex_mem.j_add.outSignal, &pc_mux.arg2Signal)
    connect(branchcontrol.pcSrcSignal, &pc_mux.selectSignal)

    // pc
    connect(pc_mux.outSignal, &pc.inSignal)

    // inst_memo
    connect(pc.outSignal, &inst_memo.addressSignal)

    // add4
    connect(pc.outSignal, &add4.arg1Signal)
    connect(4, &add4.arg2Signal)

    // if_id
    connect(add4.outSignal, &if_id.pc.inSignal)
    connect(inst_memo.instSignal, &if_id.inst.inSignal)

}

func buildID(architicture: Architicture){
    let if_id = architicture.if_id
    let control = architicture.control
    let registers = architicture.registers
    let sign_extend = architicture.sign_extend
    let id_ex = architicture.id_ex
    
    let mem_wb = architicture.mem_wb
    let wr_data_mux = architicture.wr_data_mux

    // control
    connect(if_id.inst.outSignal![26,31], &control.opCodeSignal)

    // registers
    connect(if_id.inst.outSignal![21,25], &registers.readRg1Signal)
    connect(if_id.inst.outSignal![16, 20], &registers.readRg2Signal)
    connect(mem_wb.wb.outSignal![0], &registers.regWriteSignal)
    connect(wr_data_mux.outSignal, &registers.writeDataSignal)
    connect(mem_wb.wr_rg.outSignal, &registers.writeRgSignal)

    // sign_extend
    connect(if_id.inst.outSignal![0,15], &sign_extend.inSignal)

    // id_ex    
    connect(if_id.pc.outSignal, &id_ex.pc.inSignal)
    connect(registers.readData1Signal, &id_ex.data1.inSignal)
    connect(registers.readData2Signal, &id_ex.data2.inSignal)
    connect(if_id.inst.outSignal![26, 31], &id_ex.opCode.inSignal)
    connect(sign_extend.outSignal, &id_ex.inst_0_15.inSignal)
    connect(if_id.inst.outSignal![16,20], &id_ex.inst_16_20.inSignal)
    connect(if_id.inst.outSignal![11,15], &id_ex.inst_11_15.inSignal)
    connect(control.wbSignal, &id_ex.wb.inSignal)
    connect(control.mSignal, &id_ex.m.inSignal)
    connect(control.exSignal, &id_ex.ex.inSignal)

}

func buildEX(architicture: Architicture){
    let id_ex = architicture.id_ex
    let j_add = architicture.j_add
    let shift2 = architicture.shift2
    let alu = architicture.alu
    let alu_mux = architicture.alu_mux
    let alu_control = architicture.alu_control
    let rg_wr_mux = architicture.rg_wr_mux
    let ex_mem = architicture.ex_mem

    // j_add
    connect(id_ex.pc.outSignal, &j_add.arg1Signal)
    connect(shift2.outSignal, &j_add.arg2Signal)

    // shift2
    connect(id_ex.inst_0_15.outSignal, &shift2.inSignal)

    // alu
    connect(id_ex.data1.outSignal, &alu.arg1Signal)
    connect(alu_mux.outSignal, &alu.arg2Signal)
    connect(alu_control.aluCodeSignal, &alu.codeSignal)

    // alu_mux
    connect(id_ex.ex.outSignal![2], &alu_mux.selectSignal)
    connect(id_ex.data2.outSignal, &alu_mux.arg1Signal)
    connect(id_ex.inst_0_15.outSignal, &alu_mux.arg2Signal)

    // alu_control
    connect(id_ex.opCode.outSignal, &alu_control.opCodeSignal)
    connect(id_ex.inst_0_15.outSignal![0,5], &alu_control.inst_0_5_Signal)

    // rg_wr_mux
    connect(id_ex.inst_16_20.outSignal, &rg_wr_mux.arg1Signal)
    connect(id_ex.inst_11_15.outSignal, &rg_wr_mux.arg2Signal)
    connect(id_ex.ex.outSignal![0], &rg_wr_mux.selectSignal)

    // ex_mem
    connect(id_ex.wb.outSignal, &ex_mem.wb.inSignal)
    connect(id_ex.m.outSignal, &ex_mem.m.inSignal)
    connect(j_add.outSignal, &ex_mem.j_add.inSignal)
    connect(id_ex.opCode.outSignal, &ex_mem.opCode.inSignal)
    connect(id_ex.data2.outSignal, &ex_mem.data2.inSignal)
    connect(alu.zeroSignal, &ex_mem.alu_zero.inSignal)
    connect(alu.resultSignal, &ex_mem.alu__result.inSignal)
    connect(rg_wr_mux.outSignal, &ex_mem.wr_rg.inSignal)

}

func buildMEM(architicture: Architicture){
    let ex_mem = architicture.ex_mem
    let branchcontrol = architicture.branchcontrol
    let memo = architicture.memo
    let mem_wb = architicture.mem_wb

    // branchcontrol
    connect(ex_mem.opCode.outSignal, &branchcontrol.opCodeSignal)
    connect(ex_mem.alu_zero.outSignal, &branchcontrol.zeroSignal)

    // memo
    connect(ex_mem.m.outSignal![1], &memo.memReadSignal)
    connect(ex_mem.m.outSignal![2], &memo.memWriteSignal)
    connect(ex_mem.alu__result.outSignal, &memo.addressSignal)
    connect(ex_mem.data2.outSignal, &memo.dataSignal)

    // mem_wb
    connect(ex_mem.wb.outSignal, &mem_wb.wb.inSignal)
    connect(ex_mem.alu__result.outSignal, &mem_wb.alu_result.inSignal)
    connect(memo.outSignal, &mem_wb.mem_read.inSignal)
    connect(ex_mem.wr_rg.outSignal, &mem_wb.wr_rg.inSignal)

}

func buildWB(architicture: Architicture){
    let mem_wb = architicture.mem_wb
    let wr_data_mux = architicture.wr_data_mux

    // wr_data_mux
    connect(mem_wb.wb.outSignal![1], &wr_data_mux.selectSignal)
    connect(mem_wb.mem_read.outSignal, &wr_data_mux.arg1Signal)
    connect(mem_wb.alu_result.outSignal, &wr_data_mux.arg2Signal)

}

func buildCPU(clk: CLK, instructions: [Int], memData: [Int]) ->  Architicture{
    let architicture = Architicture(clk: clk, instructions: instructions, memData: memData)

    // IF
    buildIF(architicture: architicture)

    // ID
    buildID(architicture: architicture)

    // EX
    buildEX(architicture: architicture)

    // MEM
    buildMEM(architicture: architicture)

    // WB
    buildWB(architicture: architicture)

    return architicture
}

