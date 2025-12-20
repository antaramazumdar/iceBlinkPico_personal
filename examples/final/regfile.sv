module regfile (
    input  logic        clk,
    input  logic        reset,
    input  logic        RegWrite,
    input  logic [4:0]  rs1,
    input  logic [4:0]  rs2,
    input  logic [4:0]  rd,
    input  logic [31:0] wd,
    output logic [31:0] rs1_data,
    output logic [31:0] rs2_data
);

    logic [31:0] regs [31:0];
    integer i;

    initial begin
        for (i = 0; i < 32; i++)
            regs[i] = 32'd0;
    end

    // synchronous write with reset
    always_ff @(posedge clk) begin
        begin
            if (RegWrite && (rd != 5'd0)) begin
                regs[rd] <= wd;
            end
        end
    end

    // combinational read ports with write-through (bypass)
    always_comb begin
        // defaults
        rs1_data = 32'd0;
        rs2_data = 32'd0;

        if (rs1 == 5'd0) begin
            rs1_data = 32'd0;
        end else if (RegWrite && (rd == rs1) && (rd != 5'd0)) begin
            rs1_data = wd;
        end else begin
            rs1_data = regs[rs1];
        end

        if (rs2 == 5'd0) begin
            rs2_data = 32'd0;
        end else if (RegWrite && (rd == rs2) && (rd != 5'd0)) begin
            rs2_data = wd;
        end else begin
            rs2_data = regs[rs2];
        end
    end

endmodule