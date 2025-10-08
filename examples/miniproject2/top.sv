`include "mp2.sv"

// HSV RGB LED driver top-level module for iceBlinkPico

module top #(
    parameter CLK_FREQ     = 12000000,     // 12MHz clock
    parameter PWM_INTERVAL = 255           // 8-bit PWM resolution
)(
    input  logic clk,                      // Connected to pin 20
    output logic RGB_R,                    // Connected to pin 41 (active low)
    output logic RGB_G,                    // Connected to pin 40 (active low)
    output logic RGB_B                     // Connected to pin 39 (active low)
);

    logic pwm_r, pwm_g, pwm_b;

    rgb_pwm #(
        .CLK_FREQ     (CLK_FREQ),
        .PWM_INTERVAL (PWM_INTERVAL)
    ) u_rgb_pwm (
        .clk    (clk),
        .pwm_r  (pwm_r),
        .pwm_g  (pwm_g),
        .pwm_b  (pwm_b)
    );

    // Active-low LED outputs
    assign RGB_R = ~pwm_r;
    assign RGB_G = ~pwm_g;
    assign RGB_B = ~pwm_b;

endmodule