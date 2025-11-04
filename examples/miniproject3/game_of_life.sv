module game_of_life (
    input  logic        clk,
    input  logic        next_frame,           // Trigger to compute next generation
    input  logic [5:0]  read_address,    // Pixel index (0–63)
    input logic [7:0]   data_input,
    output logic [7:0]  intensity       // Output intensity (0 or 255)
);

    // 2 states for fsm
    localparam IDLE = 1'b0;
    localparam TRANSMIT = 1'b1;

    // 8x8 grid for current and next generation
    logic [7:0] current_grid [0:7][0:7];
    logic [7:0] next_grid    [0:7][0:7];

    // Extract row and column from read_address
    logic [2:0] row, col;
    assign row = read_address[5:3];
    assign col = read_address[2:0];

    // output intensity based on current grid
    assign intensity = current_grid[row][col];

    // Variables for fsm
    logic [5:0] current_pixel = 6'd0;
    logic [2:0] current_row, current_col;
    logic state = IDLE;
    logic next_state;
    logic first_time = 1'b1;
    logic last_frame = 0;
    logic move_on = 0;

    // variables for neighbors
    logic [2:0] up, down, left, right; 

    // change state at positive clock edge
    always_ff @(posedge clk) begin
        state <= next_state;
    end

    // initializing grid
    always_ff @(posedge clk) begin
        last_frame <= next_frame;

        if (next_frame && !last_frame) begin
            if (first_time) begin
                first_time <= 1'b0; // checks off the first time
            end
            else begin
                move_on <= 1'b1; // not first time, so move on
            end
        end
        else if (state == TRANSMIT && current_pixel == 6'd63) begin
            move_on <= 1'b0; // reset after transmitting
        end
    end

    // load initial input
    always_ff @(posedge clk) begin
        if (first_time) begin
            current_grid[row][col] <= data_input;
        end
    end

    // pixel counter
    always_ff @(posedge clk) begin
        if (state == TRANSMIT) begin
            current_pixel <= current_pixel + 1;
        end
        else begin
            current_pixel <= 6'd0;
        end
    end

    // actual fsm
    always_comb begin
        case(state)
            IDLE:
                next_state = move_on? TRANSMIT:IDLE; // if ready to move on, change to TRANSMIT
            TRANSMIT:
                next_state = (current_pixel == 6'd63)? IDLE:TRANSMIT; // if at last pixel, change to IDLE
    
        endcase
    end

    // Transmitting
    logic [5:0] sent_pixel = 6'd0;
    logic done_transmitting = 1'b0;

    always_ff @(posedge clk) begin
        if (state == TRANSMIT && current_pixel == 6'd63) begin
            done_transmitting <= 1'b1;
            sent_pixel <= 6'd0;
        end
        else if (done_transmitting) begin
            current_grid[sent_pixel[5:3]][sent_pixel[2:0]]<= next_grid[sent_pixel[5:3]][sent_pixel[2:0]];
            sent_pixel <= sent_pixel + 1;
            
            if (sent_pixel == 6'd63) begin
                done_transmitting <= 1'b0;
            end
        end
    end

    // computing the next gen by finding the state of neighbors
    logic [3:0] neighbor_count;

    always_ff @(posedge clk) begin
        if (state == TRANSMIT) begin
            current_row = current_pixel[5:3];
            current_col = current_pixel[2:0];

            // wrapping
            up    = (current_row + 7) % 8;
            down  = (current_row + 1) % 8;
            left  = (current_col + 7) % 8;
            right = (current_col + 1) % 8; 

            // count number of live neighbors
            neighbor_count = 4'd0;
            if (current_grid[up][left]          > 8'h00) neighbor_count++;
            if (current_grid[up][current_col]   > 8'h00) neighbor_count++;
            if (current_grid[up][right]         > 8'h00) neighbor_count++;
            if (current_grid[current_row][left] > 8'h00) neighbor_count++;
            if (current_grid[current_row][right]> 8'h00) neighbor_count++;
            if (current_grid[down][left]        > 8'h00) neighbor_count++;
            if (current_grid[down][current_col] > 8'h00) neighbor_count++;
            if (current_grid[down][right]       > 8'h00) neighbor_count++;

            // actual game of life
            if (current_grid[current_row][current_col] > 8'h00) begin //cell is alive
                if (neighbor_count < 2 || neighbor_count > 3)
                    next_grid[current_row][current_col] <= 8'h00;  
                else
                    next_grid[current_row][current_col] <= 8'hFF;  
            end 
            else begin
                // cell is dead
                if (neighbor_count == 3)
                    next_grid[current_row][current_col] <= 8'hFF;  
                else
                    next_grid[current_row][current_col] <= 8'h00;  
            end
        end
    end
endmodule