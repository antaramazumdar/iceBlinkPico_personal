`timescale 1ns/1ps
`include "top copy.sv"

module final_tb;

    logic clk;
    logic reset;
    logic led;
    logic red;
    logic green;
    logic blue;

    // Instantiate dut with small divider for simulation
    top #(.CPU_DIV_WIDTH(8)) dut (
        .clk    (clk),
        .reset  (reset),
        .led    (led),
        .red    (red),
        .green  (green),
        .blue   (blue)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        reset = 1'b1;
        #40;
        reset = 1'b0;
    end

    initial begin
        #300_000;   // 300 µs
        $display("Simulation finished.");

        // Dump register file contents
        for (int i = 0; i < 32; i++) begin
            $display("x%0d = %h", i, dut.u_register_file.regs[i]);
        end

        $finish;
    end

    always_ff @(posedge clk) begin
        if (dut.cpu_en) begin
            $display("[%0t] CPU STEP:", $time);
            $display("  PC=%h  IR=%h  ALUResult=%h", dut.pc, dut.IR, dut.ALUResult);
            $display("  rs1=%h  rs2=%h  wd=%h", dut.rs1_data, dut.rs2_data, dut.wd);
            $display("  State=%b  LEDs: R=%0d G=%0d B=%0d", 
                     dut.state_out, dut.red, dut.green, dut.blue);

            if (dut.RegWrite)
                $display("  RegWrite: x%0d <= %h", dut.rd, dut.wd);
        end
    end

    initial begin
        $dumpfile("final_tb.vcd");
        $dumpvars(0, final_tb);
    end

endmodule