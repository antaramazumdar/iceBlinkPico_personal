module rgb_pwm #(
    parameter CLK_FREQ     = 12000000,  // 12MHz clock
    parameter PWM_INTERVAL = 255        // 8-bit PWM resolution
)(
    input  logic clk,
    output logic pwm_r,
    output logic pwm_g,
    output logic pwm_b
);

    localparam HUE_MAX       = 360;
    localparam STEP_INTERVAL = CLK_FREQ / HUE_MAX;
    logic [$clog2(STEP_INTERVAL)-1:0] hue_count = 0;
    logic [8:0] hue = 0;

    always_ff @(posedge clk) begin
        if (hue_count == STEP_INTERVAL - 1) begin
            hue_count <= 0;
            hue <= (hue == HUE_MAX - 1) ? 0 : hue + 1;
        end else begin
            hue_count <= hue_count + 1;
        end
    end

    logic [7:0] r_val, g_val, b_val;
    logic [8:0] hue_r, hue_g, hue_b;

    always_comb begin
        hue_r = hue;
        hue_g = (hue + 240 < 360) ? hue + 240 : hue + 240 - 360;
        hue_b = (hue + 120 < 360) ? hue + 120 : hue + 120 - 360;
        

        // RED
        if (hue_r < 60)
            r_val = 8'd255;
        else if (hue_r < 120)
            r_val = 8'd255 - ((8'd255 * (hue_r - 60)) / 60);
        else if (hue_r < 240)
            r_val = 8'd0;
        else if (hue_r < 300)
            r_val = ((8'd255 * (hue_r - 240)) / 60);
        else
            r_val = 8'd255;

        // GREEN
        if (hue_g < 60)
            g_val = 8'd255;
        else if (hue_g < 120)
            g_val = 8'd255 - ((8'd255 * (hue_g - 60)) / 60);
        else if (hue_g < 240)
            g_val = 8'd0;
        else if (hue_g < 300)
            g_val = ((8'd255 * (hue_g - 240)) / 60);
        else
            g_val = 8'd255;

        // BLUE
        if (hue_b < 60)
            b_val = 8'd255;
        else if (hue_b < 120)
            b_val = 8'd255 - ((8'd255 * (hue_b - 60)) / 60);
        else if (hue_b < 240)
            b_val = 8'd0;
        else if (hue_b < 300)
            b_val = ((8'd255 * (hue_b - 240)) / 60);
        else
            b_val = 8'd255;
    end

    // PWM counters
    logic [7:0] pwm_count = 0;

    always_ff @(posedge clk) begin
        if (pwm_count == PWM_INTERVAL - 1)
            pwm_count <= 0;
        else
            pwm_count <= pwm_count + 1;
    end

    // PWM outputs
    assign pwm_r = (pwm_count < r_val);
    assign pwm_g = (pwm_count < g_val);
    assign pwm_b = (pwm_count < b_val);

endmodule