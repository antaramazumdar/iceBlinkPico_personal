module instr_decoder(
    input  logic [31:0] instruction,
    output logic [6:0] opcode,
    output logic [4:0] rs1,
    output logic [4:0] rs2,
    output logic [4:0] rd,
    output logic [2:0] funct3,
    output logic [6:0] funct7,
    output logic [2:0] immsrc
);

    assign opcode = instruction[6:0];
    assign rs1 = instruction[19:15];
    assign rs2 = instruction[24:20];
    assign rd = instruction[11:7];
    assign funct7 = instruction[31:25];
    assign funct3 = instruction[14:12];

    always_comb begin
        case (opcode)
            // I-type: ALU immediate, load, JALR
            7'b0010011, 7'b0000011, 7'b1100111:
                immsrc = 3'b000;

            // S-type: store instructions
            7'b0100011:
                immsrc = 3'b001;

            // B-type: branch instructions
            7'b1100011:
                immsrc = 3'b010;

            // J-type: JAL
            7'b1101111:
                immsrc = 3'b011;

            // U-type: LUI, AUIPC
            7'b0110111, 7'b0010111:
                immsrc = 3'b100;

            default:
                immsrc = 3'b000;
        endcase
    end

endmodule