enum Registers : Int, CaseIterable {
    case NONE
    case AX, BX, CX, DX
    case SP, BP
    case CS, DS, SS, ES
    case Count
}

enum OpCode : Int, CaseIterable {
    case NONE
    case ADDI
    case LW, SW
    case BEQ, BNE, J
    case ALU
}

enum ALUCode : Int, CaseIterable {
    case NONE
    case ADD, SUB
    case SLL, SRL, AND, NOR
    case SLT, SLTU
}