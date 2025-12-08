`include "memory.sv"
`include "alu.sv"
`include "control_unit.sv"
`include "extend.sv"
`include "instr_decoder.sv"
`include "regfile.sv"


module top (
    input logic clk,
    input logic reset
);

    // Memory buses
    logic [31:0] dmem_address, dmem_data_in, dmem_data_out, imem_address, imem_data_out;

    // wires in the datapath
    // PC
    logic [31:0] pc = 32'h00001000;
    logic [31:0] pc_next;

    // ALU
    logic [31:0] SrcA, SrcB, ALUResult;
    logic [3:0]  ALUOp;
    logic zero, lt_signed, lt_unsigned;

    // extend unit
    logic [31:0] instr;
    logic [2:0]  immsrc;
    logic [31:0] immext;
    
    // reg file
    logic RegWrite;
    logic [4:0] rs1, rs2, rd;
    logic [31:0] wd, rs1_data, rs2_data;

    // control unit
    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;
    logic PCWrite, IRWrite, dmem_wren;
    logic [1:0] ALUSrcA, ALUSrcB, WB_select, PCSrc_select;
    logic [2:0]  BranchType;
    logic [2:0]  state_out;

    // registers
    logic [31:0] IR;                 // instruction register
    logic [31:0] A_reg, B_reg;       // latched register operands
    logic [31:0] Imm_reg;            // latched immediate
    logic [31:0] ALUResult_reg;      // latched ALU result
    logic [31:0] Mem_reg;            // latched memory read data
    logic [31:0] ALUOut;             // latched ALU result used as branch target
    logic [31:0] pc_plus_4_reg;      // latched pc+4 (for JAL/JALR writeback)
    logic [31:0] OldPC;              // holds initial PC

    // instruction for decoder
    assign instr = IR;

    // connecting memory
    assign imem_address = pc;

    //assign imem_address = pc; // gives instruction memory address to pc
    assign dmem_address = ALUResult_reg; // gives alu result to data memory address
    assign dmem_data_in = B_reg; // for stores, B register data must be written into the data mem input
    
    
    // storing and remembering state 
    always_ff @(posedge clk) begin 
        if (PCWrite) begin
            pc <= pc_next;
        end

        if (IRWrite)
            IR <= imem_data_out;
    
        if (state_out == 3'b000) begin 
            pc_plus_4_reg <= pc + 32'd4;
            OldPC <= pc;
        end
    
        if (state_out == 3'b001) begin
            A_reg <= rs1_data;
            B_reg <= rs2_data;
            Imm_reg <= immext; 
            ALUOut <= pc + immext;
            if (opcode==7'b0010111) begin 
                ALUOut <= OldPC + immext;
            end
        end

        if (state_out == 3'b010) begin
            ALUResult_reg <= ALUResult;
            if ((opcode==7'b1100111)) begin
                ALUOut <= ALUResult;       // JALR: rs1+imm
            end
        end


        if (state_out == 3'b011) begin // MEMORY
            Mem_reg <= dmem_data_out;
        end

    end

    // Multiplexers

    // MUX ALUSrcA - selects between PC and A register
    always_comb begin
        unique case (ALUSrcA)
            2'b00: SrcA = pc;
            2'b01: SrcA = A_reg;
            2'b10: SrcA = 32'd0;
            default: SrcA = 32'd0;
        endcase
    end


    // MUX ALUSrcB - selects between B register, constant 4,
    // and immediate extended
    always_comb begin
        unique case (ALUSrcB)
            2'b00: SrcB = B_reg;    // B register
            2'b01: SrcB = 32'd4;    // constant 4
            2'b10: SrcB = immext;   // sign extended immediate (output from extend unit)
            default: SrcB = 32'd0;
        endcase
    end


    // MUX PCSrc - select next PC source
    always_comb begin
        unique case (PCSrc_select)         
            2'b00: pc_next = ALUResult;             // PC+4 for Fetch 
            2'b01: pc_next = ALUOut;                // for branching
            2'b10: pc_next = {ALUResult[31:1], 1'b0}; // for AUIPC

            default: pc_next = ALUResult;
        endcase
    end

    // MUX Writeback
    always_comb begin
    unique case (WB_select)
        2'b00: wd = ALUResult_reg;  // ALU Result
        2'b01: wd = Mem_reg;        // memory
        2'b10: wd = pc_plus_4_reg;  // Next instruction
        2'b11: wd = ALUOut; // AUIPC
        default: wd = 32'd0;
    endcase
    end


    // ALU instantiation
    alu u_alu (
        .SrcA           (SrcA), 
        .SrcB           (SrcB), 
        .ALUOp          (ALUOp), 
        .ALUResult      (ALUResult), 
        .zero           (zero),
        .lt_signed      (lt_signed), 
        .lt_unsigned    (lt_unsigned)
    );

    // Register File Instantiation
    regfile u_register_file (
        .clk           (clk), 
        .reset         (reset), 
        .RegWrite      (RegWrite), 
        .rs1           (rs1), 
        .rs2           (rs2),
        .rd            (rd), 
        .wd            (wd),
        .rs1_data      (rs1_data),
        .rs2_data      (rs2_data)
    );

    // Control unit
    control_unit u_control_unit (
        .clk        (clk),
        .reset      (reset),
        .opcode     (opcode),
        .funct3     (funct3),
        .funct7     (funct7),
        .zero       (zero),
        .lt_signed  (lt_signed),
        .lt_unsigned(lt_unsigned),
        .PCWrite    (PCWrite),
        .RegWrite   (RegWrite),
        .IRWrite    (IRWrite),
        .dmem_wren  (dmem_wren),
        .ALUSrcA    (ALUSrcA),
        .ALUSrcB    (ALUSrcB),
        .ALUOp      (ALUOp),
        .BranchType (BranchType),
        .state_out  (state_out),
        .PCSrc_select (PCSrc_select),
        .WB_select   (WB_select)
    );

    // Extend Unit
    extend u_extend (
        .instr  (IR),
        .immsrc (immsrc),
        .immext (immext)
    );

    // Intruction Decoder
    instr_decoder u_instr_decoder (
        .instruction (IR),
        .opcode      (opcode),
        .rs1         (rs1),
        .rs2         (rs2),
        .rd          (rd),
        .funct3      (funct3),
        .funct7      (funct7),
        .immsrc      (immsrc)
    );



    memory #(
        .IMEM_INIT_FILE_PREFIX  ("rv32i_test")
    ) u1 (
        .clk            (clk), 
        .funct3         (funct3), 
        .dmem_wren      (dmem_wren), 
        .dmem_address   (dmem_address), 
        .dmem_data_in   (dmem_data_in), 
        .imem_address   (imem_address), 
        .imem_data_out  (imem_data_out), 
        .dmem_data_out  (dmem_data_out), 
        .reset          (reset)
    );

endmodule
