// MP1

module top(
    input logic     clk, 
    output logic    RGB_R, 
    output logic    RGB_G, 
    output logic    RGB_B
);

    // CLK frequency is 12MHz, so 12,000,000 cycles is 1s
    parameter BLINK_INTERVAL = 12000000/6;
    logic [$clog2(BLINK_INTERVAL) - 1:0] count = 0;
    typedef enum logic [2:0] {
        red = 3'b100,
        yellow = 3'b110,
        green = 3'b010,
        cyan = 3'b011,
        blue = 3'b001,
        magenta = 3'b101,
    } color_list;
    color_list current_color = red;

    always_ff @(posedge clk) begin
        if (count == BLINK_INTERVAL - 1) begin
            count <= 0;
            case (current_color)
                red: current_color<=yellow;
                yellow: current_color<=green;
                green: current_color<=cyan;
                cyan: current_color<=blue;
                blue: current_color<=magenta;
                magenta: current_color<=red;
                default: current_color<=red;
            endcase
        end
        else begin
            count <= count + 1;
        end
    end

    always_comb begin
        RGB_R = ~current_color[2];  // Invert logic for active-low LED
        RGB_G = ~current_color[1];
        RGB_B = ~current_color[0];
    end

endmodule
