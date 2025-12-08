`timescale 1ns/1ps
`include "top copy.sv"

module mp4_tb;
    logic clk;
    logic reset;

    top dut (
        .clk   (clk),
        .reset (reset)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Simulation control
    initial begin
        #2000;
        $display("Simulation finished.");
        // Dump final register file contents
        for (int i = 0; i < 32; i++) begin
            $display("x%0d = %h", i, dut.u_register_file.regs[i]);
        end
        $finish;
    end

    // Monitor signals for debugging
    always_ff @(posedge clk) begin
        $display("[%0t] PC=%h IR=%h ALUResult=%h rs1=%h rs2=%h wd=%h",
                 $time,
                 dut.pc,
                 dut.IR,
                 dut.ALUResult,
                 dut.rs1_data,
                 dut.rs2_data,
                 dut.wd);

        // Also show register writes
        if (dut.RegWrite) begin
            $display("Register write: x%0d <= %h", dut.rd, dut.wd);
        end
    end

    // Dump waveforms
    initial begin
        $dumpfile("mp4_tb.vcd");
        $dumpvars(0, mp4_tb);
    end
endmodule