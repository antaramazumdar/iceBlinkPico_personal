
module controller (
    input logic clk, 
    output logic load_sreg, 
    output logic transmit_pixel, 
    output logic next_frame,
    output logic [5:0] pixel
);

    localparam TRANSMIT_FRAME       = 1'b0;
    localparam IDLE                 = 1'b1;

    localparam [2:0] READ_CH_VALS   = 3'b001;
    localparam [2:0] LOAD_SREG      = 3'b010;
    localparam [2:0] TRANSMIT_PIXEL = 3'b100;

    localparam [8:0] TRANSMIT_CYCLES    = 9'd360;       // = 24 bits / pixel x 15 cycles / bit
    localparam [21:0] IDLE_CYCLES       = 22'd3976832;   // = 375000 - 64 x (360 + 2) for 32 frames / second

    logic state = TRANSMIT_FRAME;
    logic next_state;

    logic [2:0] transmit_phase = READ_CH_VALS;
    logic [2:0] next_transmit_phase;

    logic [5:0] current_pixel = 6'd0;
    logic [8:0] transmit_counter = 9'd0;
    logic [21:0] idle_counter = 22'd0;

    logic transmit_pixel_done;
    logic idle_done;

    assign transmit_pixel_done = (transmit_counter == TRANSMIT_CYCLES - 1);
    assign idle_done = (idle_counter == IDLE_CYCLES - 1);

    always_ff @(negedge clk) begin
        state <= next_state;
        transmit_phase <= next_transmit_phase;
    end

    always_comb begin
        next_state = state;
        next_frame = 0;
        case (state)
            TRANSMIT_FRAME: begin
                if ((current_pixel == 6'd63) && (transmit_pixel_done))
                    next_state = IDLE;
            end

            IDLE: begin
                next_frame = 1;
                if (idle_done)
                    next_state = TRANSMIT_FRAME;
            end
        endcase
    end

    always_comb begin
        next_transmit_phase = READ_CH_VALS;
        if (state == TRANSMIT_FRAME) begin
            case (transmit_phase)
                READ_CH_VALS:
                    next_transmit_phase = LOAD_SREG;
                LOAD_SREG:
                    next_transmit_phase = TRANSMIT_PIXEL;
                TRANSMIT_PIXEL:
                    next_transmit_phase = transmit_pixel_done ? READ_CH_VALS : TRANSMIT_PIXEL;
            endcase
        end
    end

    always_ff @(negedge clk) begin
        if ((state == TRANSMIT_FRAME) && transmit_pixel_done) begin
            current_pixel <= current_pixel + 1;
        end
    end


    always_ff @(negedge clk) begin
        if (transmit_phase == TRANSMIT_PIXEL) begin
            transmit_counter <= transmit_counter + 1;
        end
        else begin
            transmit_counter <= 9'd0;
        end
    end

    always_ff @(negedge clk) begin
        if (state == IDLE) begin
            idle_counter <= idle_counter + 1;
        end
        else begin
            idle_counter <= 20'd0;
        end
    end

    assign pixel = current_pixel;
    assign load_sreg = (transmit_phase == LOAD_SREG);
    assign transmit_pixel = (transmit_phase == TRANSMIT_PIXEL);

endmodule
