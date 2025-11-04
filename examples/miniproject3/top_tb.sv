`timescale 1ns / 1ps
`include "top.sv"

module top_tb;

    // Testbench signals
    logic clk;
    logic SW;
    logic BOOT;
    logic _48b;
    logic _45a;

    // Clock generation: 100 MHz (10 ns period)
    always begin
        #5 clk = ~clk;
    end

    // Instantiate the top module
    top uut (
        .clk(clk),
        .SW(SW),
        .BOOT(BOOT),
        ._48b(_48b),
        ._45a(_45a)
    );

    // Simulation control
    initial begin
        // Initialize signals
        clk = 0;
        SW = 0;
        BOOT = 0;

        // Dump waveform
        $dumpfile("simulation.vcd");
        $dumpvars(0, top_tb);

        // --- Test sequence begins ---
        #100;  // small delay for stabilization

        // Test 1: Green channel only
        SW = 0; BOOT = 0;
        $display("[%0t] Test 1: Green channel only", $time);
        #2000000;  // run for 2 ms

        // Test 2: Red channel only
        SW = 0; BOOT = 1;
        $display("[%0t] Test 2: Red channel only", $time);
        #2000000;  // run for 2 ms

        // Test 3: Blue channel only
        SW = 1; BOOT = 0;
        $display("[%0t] Test 3: Blue channel only", $time);
        #2000000;  // run for 2 ms

        // Test 4: Full RGB (white) mode
        SW = 1; BOOT = 1;
        $display("[%0t] Test 4: Full RGB", $time);
        #2000000;  // run for 2 ms

        // Test 5: Idle state (let Game of Life evolve naturally)
        SW = 0; BOOT = 0;
        $display("[%0t] Test 5: Idle - observing Game of Life frames", $time);
        #8000000;  // run for 8 ms

        // Finish simulation
        $display("[%0t] Simulation complete", $time);
        $finish;
    end

endmodule
