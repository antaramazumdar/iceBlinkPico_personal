`timescale 10ns/10ns

module tb_top;
    
    parameter PWM_INTERVAL = 1200;

    logic clk = 0;
    logic RGB_R, RGB_G, RGB_B;

    top # (
        .PWM_INTERVAL   (PWM_INTERVAL)
    ) u0 (
        .clk            (clk),
        .RGB_R          (RGB_R),
        .RGB_G          (RGB_G),
        .RGB_B          (RGB_B)
    );

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_top);
        #500000000; 
        $finish;
    end

    always begin
        #4
        clk = ~clk;
    end
endmodule
