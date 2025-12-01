module regfile (
    input logic clk,
    input logic reset,
    input logic RegWrite,
    input logic [4:0] rs1,
    input logic [4:0] rs2,
    input logic [4:0] rd,
    input logic [31:0]  wd,
    output logic [31:0]  rs1_data,
    output logic [31:0]  rs2_data

);

    logic [31:0] regs [31:0];

    // asynchronous read
    assign rs1_data = (rs1 == 5'd0) ? 32'd0 : regs[rs1];
    assign rs2_data = (rs2 == 5'd0) ? 32'd0 : regs[rs2];

    // synchronous write
    always_ff @(posedge clk) begin
        if (reset) begin 
            integer i;
            for (i = 0; i < 32; i = i + 1) regs[i] = 32'd0;
        end
        else if (RegWrite && (rd != 5'd0)) begin
            regs[rd] <= wd;
        end
    end

    initial begin : init_regs
        integer i;
        for (i = 0; i < 32; i = i + 1) regs[i] = 32'd0;
    end

endmodule