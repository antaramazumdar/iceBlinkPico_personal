module control_unit (
    input  logic clk,
    input  logic reset,
    input  logic cpu_en,          
    input  logic [6:0] opcode,
    input  logic [2:0] funct3,
    input  logic [6:0] funct7,
    input  logic      zero,          // ALU zero flag
    input  logic      lt_signed,     // ALU signed comparison
    input  logic      lt_unsigned,   // ALU unsigned comparison

    // Signal outputs
    output logic PCWrite,
    output logic RegWrite,
    output logic IRWrite,
    output logic dmem_wren,
    output logic [1:0] ALUSrcA,
    output logic [1:0] ALUSrcB,
    output logic [3:0] ALUOp,
    output logic [2:0] BranchType,
    output logic [2:0] state_out,
    output logic [1:0] PCSrc_select,
    output logic [1:0] WB_select
);

    // FSM states
    typedef enum logic [2:0]{
        FETCH = 3'b000,
        DECODE = 3'b001,
        EXECUTE = 3'b010,
        MEMORY = 3'b011,
        WRITEBACK = 3'b100
    } fsm_state;

    fsm_state current_state, next_state;

    // instruction decoding variables
    logic R_type, I_type, S_type, B_type, U_type, J_type;
    logic Load, Store, Branch, JAL, JALR, LUI, AUIPC;

    logic branch_cond; // to check if branching condition is met

    // check which opcode for instruction type
    always_comb begin
        R_type = (opcode == 7'b0110011);
        I_type = (opcode == 7'b0010011);
        Load   = (opcode == 7'b0000011);
        Store  = (opcode == 7'b0100011);
        Branch = (opcode == 7'b1100011);
        JAL    = (opcode == 7'b1101111);
        JALR   = (opcode == 7'b1100111);
        LUI    = (opcode == 7'b0110111);
        AUIPC  = (opcode == 7'b0010111);
        S_type = Store;
        B_type = Branch;
        U_type = LUI || AUIPC;
        J_type = JAL || JALR;
    end

    // FSM sequential logic 
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            current_state <= FETCH;
        else if (cpu_en)
            current_state <= next_state;
    end

    assign state_out = current_state;

    // next state logic
    always_comb begin
        case(current_state)
            FETCH:  next_state = DECODE;

            DECODE: begin
                if (R_type || I_type || U_type || J_type || Load || Store || B_type)
                    next_state = EXECUTE;
                else
                    next_state = FETCH;
            end

            EXECUTE: begin
                if (Load || Store)
                    next_state = MEMORY;
                else if (R_type || I_type || U_type || J_type)
                    next_state = WRITEBACK;
                else
                    next_state = FETCH;
            end

            MEMORY: begin
                if (Load)
                    next_state = WRITEBACK;
                else
                    next_state = FETCH;
            end

            WRITEBACK: next_state = FETCH;

            default: next_state = FETCH;
        endcase
    end

    // controlsignals
    always_comb begin
        PCWrite = 0;
        IRWrite = 0;
        RegWrite = 0;
        dmem_wren = 0;
        ALUSrcA = 2'b00;
        ALUSrcB = 2'b00;
        BranchType = 3'b000;
        branch_cond = 0;
        PCSrc_select = 2'b00;
        ALUOp = 4'b0000;
        WB_select = 2'b00;

        case (current_state)
            FETCH: begin 
                // enable loading instruction from memory to IR
                IRWrite = 1'b1; 

                // can also use ALU to increment PC here
                ALUSrcA = 2'b00;    // pc
                ALUSrcB = 2'b01;    // 4
                ALUOp = 4'b0000;    // add
                PCWrite = 1'b1;     // enable write
            end
            
            DECODE: begin 
                // nothing needs to be done except for branching
                ALUSrcA = 2'b00;    // pc for branch/auipc
                ALUSrcB = 2'b10;    // imm for branch
                ALUOp   = 4'b0000;  // add
            end

            EXECUTE: begin 
                if (R_type) begin 
                    ALUSrcA = 2'b01;    // rs1
                    ALUSrcB = 2'b00;    // rs2
                    case ({funct7,funct3})
                        10'b0000000000: ALUOp = 4'b0000; // ADD
                        10'b0100000000: ALUOp = 4'b0001; // SUB
                        10'b0000000111: ALUOp = 4'b0010; // AND
                        10'b0000000110: ALUOp = 4'b0011; // OR
                        10'b0000000100: ALUOp = 4'b0100; // XOR
                        10'b0000000001: ALUOp = 4'b0101; // SLL
                        10'b0000000101: ALUOp = 4'b0110; // SRL
                        10'b0100000101: ALUOp = 4'b0111; // SRA
                        10'b0000000010: ALUOp = 4'b1000; // SLT
                        10'b0000000011: ALUOp = 4'b1001; // SLTU
                        default: ALUOp = 4'b0000;
                    endcase
                end

                else if (I_type) begin 
                    ALUSrcA = 2'b01;    // rs1
                    ALUSrcB = 2'b10;    // imm
                    case (funct3)
                        3'b000: ALUOp = 4'b0000; // ADDI
                        3'b001: ALUOp = 4'b0101; // SLLI
                        3'b010: ALUOp = 4'b1000; // SLTI
                        3'b011: ALUOp = 4'b1001; // SLTIU
                        3'b100: ALUOp = 4'b0100; // XORI
                        3'b101: ALUOp = (funct7[5]) ? 4'b0111 : 4'b0101; // SRAI/SRLI
                        3'b110: ALUOp = 4'b0011; // ORI
                        3'b111: ALUOp = 4'b0010; // ANDI
                        
                        default: ALUOp = 4'b0000;
                    endcase
                end

                else if (Load || Store) begin 
                    ALUSrcA = 2'b01; // rs1
                    ALUSrcB = 2'b10; // imm
                    ALUOp   = 4'b0000; // ADD
                end

                else if (B_type) begin
                    // subtract the two values to check if they're equal (zero)                    
                    ALUSrcA = 2'b01; // rs1
                    ALUSrcB = 2'b00; // rs2
                    ALUOp   = 4'b0001; // SUB 
                    case (funct3) // code what each type is based on funct3
                        3'b000: BranchType = 3'b000; // BEQ
                        3'b001: BranchType = 3'b001; // BNE
                        3'b100: BranchType = 3'b010; // BLT
                        3'b101: BranchType = 3'b011; // BGE
                        3'b110: BranchType = 3'b100; // BLTU
                        3'b111: BranchType = 3'b101; // BGEU
                        default: BranchType = 3'b000;
                    endcase

                    unique case (BranchType) // check conditions for branching
                        3'b000: branch_cond = zero;                 // BEQ
                        3'b001: branch_cond = ~zero;                // BNE
                        3'b010: branch_cond = lt_signed;            // BLT
                        3'b011: branch_cond = ~lt_signed;           // BGE
                        3'b100: branch_cond = lt_unsigned;          // BLTU
                        3'b101: branch_cond = ~lt_unsigned;         // BGEU
                        default: branch_cond = 1'b0;
                    endcase

                    if (branch_cond) begin // if branching condition met
                        PCWrite = 1;
                        PCSrc_select = 2'b01; 
                    end

                end

                else if (AUIPC) begin
                    ALUSrcA = 2'b00; // pc
                    ALUSrcB = 2'b10; // imm
                    ALUOp   = 4'b0000; // ADD
                end

                else if (JAL || JALR) begin
                    ALUSrcA = (JAL) ? 2'b00 : 2'b01; // pc or rs1
                    ALUSrcB = 2'b10; // immext
                    ALUOp   = 4'b0000; // ADD
                    PCWrite = 1;
                    PCSrc_select = (JAL) ? 2'b01 : 2'b10;
                end

                else if (LUI) begin
                    ALUSrcA = 2'b10; // zero
                    ALUSrcB = 2'b10; // imm
                    ALUOp   = 4'b0000; // ADD
                end

            end

            MEMORY: begin 
                if (Load) begin
                    dmem_wren = 1'b0;
                end
                else if (Store) begin
                    dmem_wren = 1'b1;
                end
            end
            WRITEBACK: begin
                if (!Store && !Branch) begin
                    RegWrite = 1'b1;
                    if (Load) begin // choose writeback source
                        WB_select = 2'b01; // memory
                    end
                    else if (JAL || JALR) begin
                        WB_select = 2'b10; // pc+4
                    end
                    else if (AUIPC) begin
                        WB_select = 2'b11; // ALUOut (pc + immext computed in DECODE)
                    end

                    else begin
                        WB_select = 2'b00; // ALU
                    end
                end
                else begin
                    RegWrite = 1'b0;
                    WB_select = 2'b00;
                end
            end

        endcase
    end

endmodule