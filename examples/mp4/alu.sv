module alu (
    input logic [31:0] SrcA,
    input logic [31:0] SrcB,
    input logic [3:0]  ALUOp,
    output logic [31:0] ALUResult,
    output logic        zero,
    output logic        lt_signed,
    output logic        lt_unsigned
);

always_comb begin
    unique case (ALUOp)
        4'b0000: ALUResult = SrcA + SrcB;                 // ADD
        4'b0001: ALUResult = SrcA - SrcB;                 // SUB
        4'b0010: ALUResult = SrcA & SrcB;                 // AND
        4'b0011: ALUResult = SrcA | SrcB;                 // OR
        4'b0100: ALUResult = SrcA ^ SrcB;                 // XOR
        4'b0101: ALUResult = SrcA << SrcB[4:0];          // SLL
        4'b0110: ALUResult = SrcA >> SrcB[4:0];          // SRL
        4'b0111: ALUResult = $signed(SrcA) >>> SrcB[4:0]; // SRA
        4'b1000: ALUResult = lt_signed ? 32'd1 : 32'd0;    // SLT
        4'b1001: ALUResult = lt_unsigned ? 32'd1 : 32'd0;  // SLTU
        default: ALUResult = 32'd0;

    endcase
    end

    assign lt_signed   = ($signed(SrcA) < $signed(SrcB));
    assign lt_unsigned = (SrcA < SrcB);
    assign zero = (ALUResult == 32'd0); // tells ontrol that result is zero (for beq, bne)

endmodule
