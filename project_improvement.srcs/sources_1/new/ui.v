`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// CONTENT PAGE
// 199 - Selection of Interface
// 283 - Game Logic
// 535 - Points Tracking
// 598 - Game Speed
// 680 - Game Randomness
// 716 - Game Display
// 962 - OLED Display

// Company: 
// Engineer: 
// 
// Create Date: 29.03.2024 16:31:38
// Design Name: 
// Module Name: ui
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ui(
    input clk,
    input [15:0] sw,
    input [12:0] pixel_index,
    input [6:0] random_x_pos,
    input btnC, btnU, btnL, btnR, btnD,
    input [1:0] difficulty,
    output [6:0] seg,
    output [3:0] an,
//    output reg [15:0] led,
    output reg [15:0] oled_data
    );
        
    //find pixel coordinates
    wire [6:0] x;
    wire [5:0] y;
    assign x = (pixel_index % 96); //from 0 to 95
    assign y = (pixel_index / 96); //from 0 to 63
    
    //create colours
    parameter WHITE = 16'b11111_111111_11111;
    parameter BLACK = 16'b00000_000000_00000;
    parameter RED = 16'b11111_000000_00000;
    parameter YELLOW = 16'b11111_111111_00000;
    parameter GREEN = 16'b00000_111111_00000;
    parameter BLUE = 16'b00000_000000_11111;
    parameter ORANGE = 16'b1111111111100000;
    parameter PURPLE = 16'b1111100000011111;
    parameter TEAL = 16'b0000011111111111;  
    parameter UP_ARROW_COLOUR = 16'b1101100000000000;
    parameter DOWN_ARROW_COLOUR = 16'b0101010101111111;
    parameter RIGHT_ARROW_COLOUR = 16'b1110010110011111;
    parameter LEFT_ARROW_COLOUR = 16'b1111110100000100;
    parameter CENTRE_ARROW_COLOUR = 16'b0000011111100000;

    ////////////////////////////////
    ///////// Interfaces////////////
    ////////////////////////////////
    wire [15:0] welcome_pixel_data;
    welcome_interface welcome_bg (
        .clk(clk),
        .row(pixel_index[12:7]),
        .col(pixel_index[6:0]),
        .color_data(welcome_pixel_data)
    );
    
    wire [15:0] pressC_pixel_data;
    instr_press_centre press_c_bg (
        .clk(clk),
        .row(pixel_index[12:7]),
        .col(pixel_index[6:0]),
        .color_data(pressC_pixel_data)
    );
    
    wire [15:0] pressD_pixel_data;
    instr_press_down press_d_bg (
        .clk(clk),
        .row(pixel_index[12:7]),
        .col(pixel_index[6:0]),
        .color_data(pressD_pixel_data)
    );
    
    wire [15:0] pressL_pixel_data;
    instr_press_left press_l_bg (
        .clk(clk),
        .row(pixel_index[12:7]),
        .col(pixel_index[6:0]),
        .color_data(pressL_pixel_data)
    );
    
    wire [15:0] pressR_pixel_data;
    instr_press_right press_r_bg (
        .clk(clk),
        .row(pixel_index[12:7]),
        .col(pixel_index[6:0]),
        .color_data(pressR_pixel_data)
    );
    
    wire [15:0] pressU_pixel_data;
    instr_press_up press_up_bg (
        .clk(clk),
        .row(pixel_index[12:7]),
        .col(pixel_index[6:0]),
        .color_data(pressU_pixel_data)
    );
    
    wire [15:0] start_pixel_data;
    game_start_interface game_start_bg (
        .clk(clk),
        .row(pixel_index[12:7]),
        .col(pixel_index[6:0]),
        .color_data(start_pixel_data)
    );
    
    wire [15:0] tryAgain_pixel_data;
    try_again_interface try_again_bg (
        .clk(clk),
        .row(pixel_index[12:7]),
        .col(pixel_index[6:0]),
        .color_data(tryAgain_pixel_data)
    );
    
    wire [15:0] beatHigh_pixel_data;
    beaten_high_score_interface beatHigh_bg (
        .clk(clk),
        .row(pixel_index[12:7]),
        .col(pixel_index[6:0]),
        .color_data(beatHigh_pixel_data)
    );
    
    // Slow Clocks
    wire clk_90pix, clk_3sec;
    slow_clock clock_90pix(.clk(clk), .max_counts(555_556), .new_clk(clk_90pix));
    slow_clock clock_3sec(.clk(clk), .max_counts(150_000_000), .new_clk(clk_3sec));
    
    // Pressing to make shapes "disappear"
    reg [6:0] x_lowest, y_lowest; // x and y coordinate of plus signs relative to origin
    reg [6:0] x_point_display, y_point_display; // x and y for point display
    reg a_pressed, b_pressed, c_pressed, d_pressed, button_pressed;
    reg [31:0] dbCount = 0; // debouncing
    reg btn_ready = 1; // debouncing
    
    // OLED Display for main game
    reg [15:0] game_pixel_data;
    
    // Score tracking for main game
    reg [31:0] accuracy = 0; // distance between line and shape when button is pressed
    reg [31:0] score = 0; // keeping track of score
    reg [31:0] highscore = 0; // keeping track of high score 
    reg finishGameFlag = 0;
    reg justStartGameFlag = 0;
    reg [31:0] finishGameCounter = 0;
    reg [31:0] oneSecondCounter = 0; // counter for 1 second
    reg [31:0] secondsCounter = 0; // count from 0 to 20
    reg highscoreBeatenFlag = 1;
    reg zeroFlag = 0;
    reg oneFlag = 0;
    reg twoFlag = 0;
    reg threeFlag = 0;
    reg pointFlag = 0;
    reg [31:0] pt_delay_counter = 1;
    reg correct_button = 0;
    
//    {0: centre, 1: down, 2: left, 3: right, 4: up}
    reg [2:0] correct_buttonA = 0, correct_buttonB = 0, correct_buttonC = 0, correct_buttonD = 0;

    
    reg [3:0] interface_state = 0;
    always @(posedge clk) begin
    
        ///////////////////////////////////////////
        ///////////////// Game End //////////////
        ///////////////////////////////////////////
        
        // reset score when new game starts
        if (finishGameFlag) begin
            shape_a = 0;
            shape_b = 0;
            shape_c = 0;
            shape_d = 0;
            oneFlag = 0;
            twoFlag = 0;
            threeFlag = 0;
            zeroFlag = 0;
            y_lowest = 0;
            secondsCounter = 0;
            oneSecondCounter = 0;
            
            if (btnC) begin
                score = 0;
            end
            
            // Setting high score
            if (highscore < score) begin
                highscore = score;
                highscoreBeatenFlag = 1;
            end
        end
        
        ////////////////////////////////
        ///selection of interface //////
        ////////////////////////////////
        case(interface_state) 
            4'b0000: begin // Welcome page interface
                oled_data = welcome_pixel_data;
                if (btnR) begin
                  interface_state <= 4'b0001; // Transition to Second Interface
                end
            end
            4'b0001: begin // Second Interface
                oled_data = pressC_pixel_data;
                if (btnC) begin
                  interface_state <= 4'b0010; // Transition to Down Interface
                end
            end
            4'b0010: begin // Down Interface
//                led[2] <= 1;
                oled_data = pressD_pixel_data;
                if (btnD) begin
                    interface_state <= 4'b0011; // Transition to Left Interface
                end
            end
            4'b0011: begin // Left Interface
                oled_data = pressL_pixel_data;
                if (btnL) begin
                  interface_state <= 4'b0100; // Transition to Right Interface
                end
            end
            4'b0100: begin // Right Interface
                oled_data = pressR_pixel_data;
                if (btnR) begin
                  interface_state <= 4'b0101; // Transition to Up Interface
                end
            end
            4'b0101: begin // Up Interface
                oled_data = pressU_pixel_data;
                if (btnU) begin
                  interface_state <= 4'b0110; // Transition to Beaten High Score Interface
                end
            end
            4'b0110: begin // Start game interface
                oled_data = start_pixel_data;
                if (sw[15]) begin
                  interface_state <= 4'b0111; // Transition to Next State
                end
            end
            4'b0111: begin // Main Game
                oled_data = game_pixel_data;
                if (finishGameFlag && ~highscoreBeatenFlag) begin
                    interface_state <= 4'b1000; // Transition to Try Again State
                end
                else if (finishGameFlag && highscoreBeatenFlag) begin
                    interface_state <= 4'b1001; // Transition to high score beaten interface
                end
            end
            4'b1000: begin // Try Again Interface
                oled_data = tryAgain_pixel_data;
                if (btnC) begin
                  finishGameFlag <= 0;
                  justStartGameFlag = 1;
                  interface_state <= 4'b0111; // Transition to Game
                end
            end
            4'b1001: begin // Add your logic for the new interface state here
                oled_data = beatHigh_pixel_data;
                if (btnC) begin
                    finishGameFlag <= 0;
                    justStartGameFlag = 1;
                    interface_state <= 4'b0111; // Transition to Game
                end
            end
            default: begin
                oled_data = welcome_pixel_data; // Default to User Interface
            end
        endcase
        
        /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        ///////////////// Game Logic ////////////////////////////////////////////////////////////////////////////////////////////////////
        /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        if (sw[14]) begin // toggle up and down to restart game
            finishGameFlag = 1;
//            highscoreBeatenFlag = 0;
        end
        
        if (interface_state == 4'b0111 && finishGameFlag == 0) begin
            highscoreBeatenFlag = 0;
            finishGameCounter <= (finishGameCounter == 2_000_000_000) ? 0 : finishGameCounter + 1;
            finishGameFlag = (finishGameCounter == 2_000_000_000) ? 1 : 0;
            
            oneSecondCounter <= (oneSecondCounter == 100_000_000 - 1) ? 0: oneSecondCounter + 1;
            secondsCounter = (oneSecondCounter == 100_000_000 - 1) ? secondsCounter + 1 : secondsCounter;
            
            justStartGameFlag = (finishGameCounter >= 50_000_000) ? 0 : 1;
            
            // generating random_shapes for shape A. {0: centre, 1: down, 2: left, 3: right, 4: up}
            random_shapeA = random_gen_shapeA;
            if (shape_a) begin
                case(random_shapeA) 
                    4'b0000: begin
                        correct_buttonA <= 0;
                        moving_shape_a <= c_arrowA;
                        if (y_pos_a < 5) shape_a_colour <= CENTRE_ARROW_COLOUR;
                    end
                    4'b0001: begin
                        correct_buttonA <= 1;
                        moving_shape_a <= d_arrowA;
                        if (y_pos_a < 5) shape_a_colour <= DOWN_ARROW_COLOUR;
                    end
                    4'b0010: begin
                        correct_buttonA <= 2;
                        moving_shape_a <= l_arrowA;
                        if (y_pos_a < 5) shape_a_colour <= LEFT_ARROW_COLOUR;
                    end
                    4'b0011: begin
                        correct_buttonA <= 3;
                        moving_shape_a <= r_arrowA;
                        if (y_pos_a < 5) shape_a_colour <= RIGHT_ARROW_COLOUR;
                     end
                    4'b0100: begin
                        correct_buttonA <= 4;
                        moving_shape_a <= u_arrowA;
                        if (y_pos_a < 5) shape_a_colour <= UP_ARROW_COLOUR;
                    end
                    default: begin
                        correct_buttonA <= 4;
                        moving_shape_a <= u_arrowA;
                        if (y_pos_a < 5) shape_a_colour <= UP_ARROW_COLOUR;
                    end
                endcase
            end
            
            random_shapeB = random_gen_shapeB;
            // generating random_shapes for shape B. {0: centre, 1: down, 2: left, 3: right, 4: up}
            if (shape_b) begin
                case(random_shapeB) 
                    4'b0000: begin
                        moving_shape_b <= c_arrowB;
                        if (y_pos_b < 5) shape_b_colour <= CENTRE_ARROW_COLOUR;
                        correct_buttonB <= 0;
                    end
                    4'b0001: begin
                        correct_buttonB <= 1;
                        moving_shape_b <= d_arrowB;
                        if (y_pos_b < 5) shape_b_colour <= DOWN_ARROW_COLOUR;
                    end
                    4'b0010: begin
                        correct_buttonB <= 2;
                        moving_shape_b <= l_arrowB;
                        if (y_pos_b < 5) shape_b_colour <= LEFT_ARROW_COLOUR;
                        end
                    4'b0011: begin
                        correct_buttonB <= 3;
                        moving_shape_b <= r_arrowB;
                        if (y_pos_b < 5) shape_b_colour <= RIGHT_ARROW_COLOUR;
                        end
                    4'b0100: begin
                        correct_buttonB <= 4;
                        moving_shape_b <= u_arrowB;
                        if (y_pos_b < 5) shape_b_colour <= UP_ARROW_COLOUR;
                    end
                    default: begin
                        correct_buttonB <= 4;                    
                        moving_shape_b <= u_arrowB;
                        if (y_pos_b < 5) shape_b_colour <= UP_ARROW_COLOUR;
                    end
                endcase
            end
            
            random_shapeC = random_gen_shapeC;
            if (shape_c) begin
                case(random_shapeC) 
                    4'b0000: begin
                        correct_buttonC <= 0;
                        moving_shape_c <= c_arrowC;
                        if (y_pos_c < 5) shape_c_colour <= CENTRE_ARROW_COLOUR;
                    end
                    4'b0001: begin
                        correct_buttonC <= 1;
                        moving_shape_c <= d_arrowC;
                        if (y_pos_c < 5) shape_c_colour <= DOWN_ARROW_COLOUR;
                    end
                    4'b0010: begin
                        correct_buttonC <= 2;
                        moving_shape_c <= l_arrowC;
                        if (y_pos_c < 5) shape_c_colour <= LEFT_ARROW_COLOUR;
                        end
                    4'b0011: begin
                        correct_buttonC <= 3;
                        moving_shape_c <= r_arrowC;
                        if (y_pos_c < 5) shape_c_colour <= RIGHT_ARROW_COLOUR;
                        end
                    4'b0100: begin
                        correct_buttonC <= 4;
                        moving_shape_c <= u_arrowC;
                        if (y_pos_c < 5) shape_c_colour <= UP_ARROW_COLOUR;
                    end
                    default: begin
                        correct_buttonC <= 4;
                        moving_shape_c <= u_arrowC;
                        if (y_pos_c < 5) shape_c_colour <= UP_ARROW_COLOUR;
                    end
                endcase
            end
            
            random_shapeD = random_gen_shapeD;
            if (shape_d) begin
                case(random_shapeD) 
                    4'b0000: begin
                        correct_buttonD <= 0;
                        moving_shape_d <= c_arrowD;
                        if (y_pos_d < 5) shape_d_colour <= CENTRE_ARROW_COLOUR;
                    end
                    4'b0001: begin
                        correct_buttonD <= 1;
                        moving_shape_d <= d_arrowD;
                        if (y_pos_d < 5) shape_d_colour <= DOWN_ARROW_COLOUR;
                    end
                    4'b0010: begin
                        correct_buttonD <= 2;
                        moving_shape_d <= l_arrowD;
                        if (y_pos_d < 5) shape_d_colour <= LEFT_ARROW_COLOUR;
                        end
                    4'b0011: begin
                        correct_buttonD <= 3;
                        moving_shape_d <= r_arrowD;
                        if (y_pos_d < 5) shape_d_colour <= RIGHT_ARROW_COLOUR;
                        end
                    4'b0100: begin
                        correct_buttonD <= 4;
                        moving_shape_d <= u_arrowD;
                        if (y_pos_d < 5) shape_d_colour <= UP_ARROW_COLOUR;
                    end
                    default: begin
                        correct_buttonD <= 4;
                        moving_shape_d <= u_arrowD;
                        if (y_pos_d < 5) shape_d_colour <= UP_ARROW_COLOUR;
                    end
                endcase
            end
            
            // speed of "release" of shapes from the top into the screen
            if (difficulty == 0) drop_counter_max = 300_000_000;
            else if (difficulty == 1) drop_counter_max = 200_000_000;
            else if (difficulty == 2) drop_counter_max = 100_000_000;
            
            drop_counter <= (drop_counter == drop_counter_max) ? 0 : drop_counter + 1;
//            drop_counter <= (drop_counter == 100_000_000) ? 0 : drop_counter + 1;
            if (drop_counter == 0) begin
                if (~shape_a) begin 
                    shape_a <= 1;
                end
                else if (~shape_b) begin
                    shape_b <= 1;
                end
                else if (~shape_c) begin
                    shape_c <= 1;
                end
                else if (~shape_d) begin
                    shape_d <= 1;
                end
            end

            if (y_pos_a > 62 || (shape_a && button_pressed && y_lowest == y_pos_a)) begin
                if (y_pos_a > 62) shape_a = 0; // deactivate upon hitting bottom
                if (shape_a && button_pressed) begin
                    shape_a_colour <= BLACK;
                end   
            end
            
            if (y_pos_b > 62 || (shape_b && button_pressed && y_lowest == y_pos_b)) begin
                if (y_pos_b > 62) shape_b = 0; // deactivate upon hitting bottom
                if (shape_b && button_pressed) begin
                    shape_b_colour <= BLACK;
                end   
            end  
            
            if (y_pos_c > 62 || (shape_c && button_pressed && y_lowest == y_pos_c)) begin
                if (y_pos_c > 62) shape_c = 0; // deactivate upon hitting bottom
                if (shape_c && button_pressed) begin
                    shape_c_colour <= BLACK;
                end   
            end
            
            if (y_pos_d > 62 || (shape_d && button_pressed && y_lowest == y_pos_d)) begin
                if (y_pos_d > 62) shape_d = 0; // deactivate upon hitting bottom
                if (shape_d && button_pressed) begin
                    shape_d_colour <= BLACK;
                end   
            end    
            ////////////////////////////////////////////////////////////
            // Keep track of lowest dropping item ////////////////////
            ////////////////////////////////////////////////////////////
            if ((y_pos_a > y_pos_b && y_pos_a > y_pos_c && y_pos_a > y_pos_d) && (y_pos_a < line_y + 3)) begin
                y_lowest = y_pos_a;
                x_lowest = random_x_a;
                y_point_display = y_pos_a;
                x_point_display = random_x_a;
                
                // pass on lowest
                if (shape_b && (shape_a_colour == BLACK)) begin 
                //y_point_display = y_pos_b;
                    y_lowest = y_pos_b;
                    x_lowest = random_x_b;
                end
                
            end
            else if ((y_pos_b > y_pos_a && y_pos_b > y_pos_c && y_pos_b > y_pos_d) && (y_pos_b < line_y + 3)) begin
                y_lowest = y_pos_b;
                x_lowest = random_x_b;
                y_point_display = y_pos_b;
                x_point_display = random_x_b;
                if (shape_b_colour == BLACK) begin // if b is black, pass on the lowest
                    if (shape_c) begin 
                        y_lowest = y_pos_c;
                        x_lowest = random_x_c;
                    end
                    else if (shape_a) begin 
                        y_lowest = y_pos_a;
                        x_lowest = random_x_a;
                    end
                end 
            end
            else if ((y_pos_c > y_pos_a && y_pos_c > y_pos_b && y_pos_c > y_pos_d) && (y_pos_c < line_y + 3) ) begin
                 y_lowest = y_pos_c;
                 x_lowest = random_x_c;
                 y_point_display = y_pos_c;
                 x_point_display = random_x_c;
                 if (shape_c_colour == BLACK) begin
                     if (shape_d) begin 
                         y_lowest = y_pos_d;
                         x_lowest = random_x_d;
                     end
                     else if (shape_a) begin 
                         y_lowest = y_pos_a;
                         x_lowest = random_x_a;
                     end
                 end
            end
            else if ((y_pos_d > y_pos_a && y_pos_d > y_pos_b && y_pos_d > y_pos_c) && (y_pos_d < line_y + 3)) begin
                 y_lowest = y_pos_d;
                 x_lowest = random_x_d;
                 y_point_display = y_pos_d;
                 x_point_display = random_x_d;
                 if (shape_d_colour == BLACK) begin
                    if (shape_a) begin 
                        y_lowest = y_pos_a;
                        x_lowest = random_x_a;
                    end
                 end
            end
    
           ////////////////////////////////////////////////////////////////////////////////////////////////
           //////////////////////////////////// Points Tracking /////////////////////////////////////////////////
           ////////////////////////////////////////////////////////////////////////////////////////////////
            
            /////////// Debouncer ///////////
            if (~btn_ready) begin
                dbCount = (dbCount == 30_000_000 - 1) ? 0 : dbCount + 1; // 1_250_000
                if (dbCount == 0) btn_ready = 1;
            end
            
            /////////// Button pressed ///////////
            if (btn_ready && justStartGameFlag == 0 && (btnC || btnD || btnL || btnR || btnU)) begin
                pt_delay_counter = 1;
                btn_ready = 0;
    
                // TODO: If button is pressed and button matches the "shape" of the lowest 
                correct_button = 0;
                button_pressed = 1;
                
                // If button is correct, allocate points{0: centre, 1: down, 2: left, 3: right, 4: up}
                if (y_lowest == y_pos_a && ( (correct_buttonA == 0 && btnC) || (correct_buttonA == 1 && btnD) 
                    || (correct_buttonA == 2 && btnL) || (correct_buttonA == 3 && btnR) 
                    || (correct_buttonA == 4 && btnU) ) ) begin
                    correct_button = 1;
                end
                
                if (y_lowest == y_pos_b && ((correct_buttonB == 0 && btnC) || (correct_buttonB == 1 && btnD) 
                    || (correct_buttonB == 2 && btnL) || (correct_buttonB == 3 && btnR) 
                    || (correct_buttonB == 4 && btnU))) begin
                    correct_button = 1;
                end
                
                if (y_lowest == y_pos_c && ((correct_buttonC == 0 && btnC) || (correct_buttonC == 1 && btnD) 
                    || (correct_buttonC == 2 && btnL) || (correct_buttonC == 3 && btnR) 
                    || (correct_buttonC == 4 && btnU))) begin
                    correct_button = 1;
                end
                
                if (y_lowest == y_pos_d && ((correct_buttonD == 0 && btnC) || (correct_buttonD == 1 && btnD) 
                    || (correct_buttonD == 2 && btnL) || (correct_buttonD == 3 && btnR) 
                    || (correct_buttonD == 4 && btnU))) begin
                    correct_button = 1;
                end
                
                
                // accuracy value
                if (y_lowest + 3 < line_y) accuracy = line_y - (y_lowest +3);
                else accuracy = (y_lowest +3) - line_y;
                // score allocation
                if (correct_button && accuracy <= 3) // +3 (green)
                begin
                    score =  score + 3;
//                    led = 16'b00000_00000_001000;
                    threeFlag = 1;
                    correct_button = 0;
                end
                else if (correct_button && accuracy <= 5) // +2 (blue)
                begin
                    score = score + 2;
//                    led = 16'b00000_00000_000100;
                    twoFlag = 1;
                    correct_button = 0;
                end
                else if (correct_button && accuracy <= 7) // +1 (yellow)
                begin
                    score = score + 1;
//                    led = 16'b00000_00000_000010;
                    oneFlag = 1;
                    correct_button = 0;
                end
                else // +0 (red)
                begin
//                    led = 16'b00000_00000_000001;
                    zeroFlag = 1;
                end
            end 
            else button_pressed = 0;
            
            if (zeroFlag || oneFlag || twoFlag || threeFlag)  begin  
                // count for half a second
                pt_delay_counter <= (pt_delay_counter == 10_000_000 - 1) ? 0 : pt_delay_counter + 1;
                if (pt_delay_counter == 0 || (y_lowest == 63)) begin
                    if (y_lowest == 63) pt_delay_counter = 1;
                    if (zeroFlag) zeroFlag <= 0;
                    if (oneFlag) oneFlag <= 0;
                    if (twoFlag) twoFlag <= 0;
                    if (threeFlag) threeFlag <= 0;
                end
            end
            
        end

    end
    
    ////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////// Game Speed //////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////
    // Display Score
    display_score score_display (.clk(clk), .score(score), .highscore(highscore), .an(an), .seg(seg));

    // For every shape: y_pos_a, random_x, shape_a (visibility), arrow_a, a_pressed
    reg shape_a = 0, shape_b = 0, shape_c = 0, shape_d = 0;
    reg [15:0] shape_a_colour = ORANGE, shape_b_colour = RED, shape_c_colour = GREEN, shape_d_colour = PURPLE;
    reg [31:0] drop_counter = 1;
    reg [31:0] drop_counter_max;
    
    
    // Movement code block
    reg [3:0] speed_store = 3; // 0: 90px/s 1: 45 px/s 2: 30px/sec 5: 15px/sec
    reg [3:0] speed_counter = 0;
    reg [12:0] y_pos_a, y_pos_b, y_pos_c, y_pos_d;
    reg [12:0] y_pos_centre = 0, y_pos_down = 0, y_pos_left = 0, y_pos_right = 0, y_pos_up = 0;
//    reg [1:0] difficulty;
    always @(posedge clk_90pix) begin
        // setting speed
//        if (~sw[13]) begin
//            speed_store <= 2; // count 1 beats to make frequency 90px/s -> 45px/s 
//        end
//        else if (sw[13]) begin
//            speed_store <= 6; // count 2 beats to make frequency 90px/s -> 30px/s when btnl or btnr is pressed
//        end
        
        if (difficulty == 0) begin
            // easy
            speed_store = 5;
        end
        else if (difficulty == 1) begin
            // medium
            speed_store = 3;
        end
        else if (difficulty == 2) begin
            // hard
            speed_store = 1;
        end
        
        // drop the shape from the top
        if (~shape_a) y_pos_a <= 0; // for every new random x, reset y to 0
        if (~shape_b) y_pos_b <= 0; // for every new random x, reset y to 0
        if (~shape_c) y_pos_c <= 0; // for every new random x, reset y to 0
        if (~shape_d) y_pos_d <= 0; // for every new random x, reset y to 0
        
        speed_counter <= (speed_counter == speed_store) ? 0 : speed_counter + 1;
        // movement of shape
        if (speed_counter == 0) begin
            y_pos_a <= (y_pos_a < 63) ? y_pos_a + 1 : 0;
            if (y_pos_a == 62) begin
                a_ready_flag = 1;
                shapeA_ready_flag = 1;
            end
            else begin
                a_ready_flag = 0;
                shapeA_ready_flag = 0;
            end
            
            y_pos_b <= (y_pos_b < 63) ? y_pos_b + 1 : 0;
            if (y_pos_b == 62) begin
                b_ready_flag = 1;
                shapeB_ready_flag = 1;
            end
            else begin
                b_ready_flag = 0;
                shapeB_ready_flag = 0;
            end

            y_pos_c <= (y_pos_c < 63) ? y_pos_c + 1 : 0;
            if (y_pos_c == 62) begin
                c_ready_flag = 1;
                shapeC_ready_flag = 1;
            end
            else begin
                c_ready_flag = 0;
                shapeC_ready_flag = 0;
            end

            y_pos_d <= (y_pos_d < 63) ? y_pos_d + 1 : 0;
            if (y_pos_d == 62) begin
                d_ready_flag = 1;
                shapeD_ready_flag = 1;
            end
            else begin
                d_ready_flag = 0;   
                shapeD_ready_flag = 0;
            end

        end
        
    end
    
    ////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////// Game Randomness ///////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////
    // generate random every 3s
    wire [6:0] random_x, random_x_a, random_x_b, random_x_c, random_x_d;
    reg [6:0] random_x_centre, random_x_down, random_x_left, random_x_right, random_x_up;
    reg [3:0] random_shapeA, random_shapeB, random_shapeC, random_shapeD;
    wire [3:0] random_gen_shapeA, random_gen_shapeB, random_shapeC, random_shapeD;
    wire [3:0] ones, tens, random_shape;
    wire a_ready_for_new, b_ready_for_new, c_ready_for_new, d_ready_for_new, shape_ready_for_new; // everytime, shape goes to top, get new x
    wire shapeA_ready_for_new, shapeB_ready_for_new, shapeC_ready_for_new, shapeD_ready_for_new;   
    reg a_ready_flag = 0, b_ready_flag = 0, c_ready_flag = 0, d_ready_flag = 0, shape_ready_flag = 0;
    reg shapeA_ready_flag = 0, shapeB_ready_flag = 0, shapeC_ready_flag = 0, shapeD_ready_flag = 0;
    assign a_ready_for_new = a_ready_flag;
    assign b_ready_for_new = b_ready_flag;
    assign c_ready_for_new = c_ready_flag;
    assign d_ready_for_new = d_ready_flag;
    assign shape_ready_for_new = shape_ready_flag;
    assign shapeA_ready_for_new = shapeA_ready_flag;
    assign shapeB_ready_for_new = shapeB_ready_flag;
    assign shapeC_ready_for_new = shapeC_ready_flag;
    assign shapeD_ready_for_new = shapeD_ready_flag;
    

    random_x_generator1 random_gen1(.clk(clk), .get_new(a_ready_for_new), .random_x(random_x_a));
    random_x_generator2 random_gen2(.clk(clk), .get_new(b_ready_for_new), .random_x(random_x_b));
    random_x_generator3 random_gen3(.clk(clk), .get_new(c_ready_for_new), .random_x(random_x_c));
    random_x_generator4 random_gen4(.clk(clk), .get_new(d_ready_for_new), .random_x(random_x_d));
    random_shape_generator random_gen_shape(.clk(clk), .get_new(shape_ready_for_new), .random_shape(random_shape));
    random_shape_generator random_gen_shape1(.clk(clk), .get_new(shapeA_ready_for_new), .random_shape(random_gen_shapeA));
    random_shape_generator random_gen_shape2(.clk(clk), .get_new(shapeB_ready_for_new), .random_shape(random_gen_shapeB));
    random_shape_generator random_gen_shape3(.clk(clk), .get_new(shapeC_ready_for_new), .random_shape(random_gen_shapeC));
    random_shape_generator random_gen_shape4(.clk(clk), .get_new(shapeD_ready_for_new), .random_shape(random_gen_shapeD));
    
    ////////////////////////////////////////////////////////////////////////
    /////////////////////////// Gane Display ///////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    reg moving_shape_a, moving_shape_b, moving_shape_c, moving_shape_d;
    wire moving_square_a, moving_square_b, moving_square_c, moving_square_d, line;    
    wire plus_zero, plus_one, plus_two, plus_three;
    wire c_arrow, d_arrow, l_arrow, r_arrow, u_arrow;
    wire c_arrowA, d_arrowA, l_arrowA, r_arrowA, u_arrowA;
    reg [7:0] line_y = 55;
    assign moving_square_a = (x >= random_x_a && x < random_x_a + 5 ) && (y >= y_pos_a && y < y_pos_a + 5);
    assign moving_square_b = (x >= random_x_b && x < random_x_b + 5 ) && (y >= y_pos_b && y < y_pos_b + 5);
    assign moving_square_c = (x >= random_x_c && x < random_x_c + 5 ) && (y >= y_pos_c && y < y_pos_c + 5);
    assign moving_square_d = (x >= random_x_d && x < random_x_d + 5 ) && (y >= y_pos_d && y < y_pos_d + 5);
    assign line = (x >= 0 && x <= 95) && y == line_y;  
    assign plus_zero = (((x >= 8 + x_point_display) && (x < 17 + x_point_display) && (y == 4 + y_point_display))
        || ((x == 12 + x_point_display) && (y >= y_point_display) && (y < 9 + y_point_display)) 
        || ((x >= 19 + x_point_display) && (x < 25 + x_point_display) && (y == y_point_display)) 
        || ((x == 19 + x_point_display) && (y >= y_point_display) && (y < 9 + y_point_display)) 
        || ((x >= 19 + x_point_display) && (x < 25 + x_point_display) && (y == 8 + y_point_display)) 
        || ((x == 24 + x_point_display) && (y >= y_point_display) && (y < 9 + y_point_display)));
    assign plus_one = (((x >= 8 + x_point_display) && (x < 15 + x_point_display) && (y == 3 + y_point_display))
        || ((x == 11 + x_point_display) && (y >= y_point_display) && (y < 7 + y_point_display))
        || ((x == 17 + x_point_display) && (y >= y_point_display) && y < 7 + y_point_display));
    assign plus_two = (((x >= 7 + x_point_display) && (x < 16 + x_point_display) && (y == 3 + y_point_display))
        || ((x == 11 + x_point_display) && (y >= y_point_display - 1) && (y < 8 + y_point_display)) 
        || ((x >= 18 + x_point_display) && (x < 23 + x_point_display) && (y == y_point_display - 1)) 
        || ((x == 22 + x_point_display) && (y >= y_point_display - 1) && (y < 4 + y_point_display)) 
        || ((x >= 18 + x_point_display) && (x < 23 + x_point_display) && (y == 3 + y_point_display)) 
        || ((x == 18 + x_point_display) && (y >= 3 + y_point_display) && (y < 8 + y_point_display))
        || ((x >= 18 + x_point_display) && (x < 23 + x_point_display) && (y == 7 + y_point_display)));
    assign plus_three = (((x >= 7 + x_point_display) && (x < 16 + x_point_display) && (y == 3 + y_point_display))
       || ((x == 11 + x_point_display) && (y >= y_point_display - 1) && (y < 8 + y_point_display)) 
       || ((x >= 18 + x_point_display) && (x < 23 + x_point_display) && (y == y_point_display - 1)) 
       || ((x == 22 + x_point_display) && (y >=  y_point_display - 1) && (y < 8 + y_point_display)) 
       || ((x >= 18 + x_point_display) && (x < 23 + x_point_display) && (y == 3 + y_point_display)) 
       || ((x >= 18 + x_point_display) && (x < 23 + x_point_display) && (y == 7 + y_point_display)));

    assign u_arrowA = ((x == random_x_a + 4) && (y >= y_pos_a) && (y < y_pos_a + 5)) || 
                        ((x >= random_x_a + 3) && (x < random_x_a + 6) && (y >= y_pos_a + 1) && (y < y_pos_a + 5)) ||
                        ((x >= random_x_a + 2) && (x < random_x_a + 7) && (y >= y_pos_a + 2) && (y < y_pos_a + 5)) ||
                        ((x >= random_x_a + 1) && (x < random_x_a + 8) && (y >= y_pos_a + 3) && (y < y_pos_a + 5)) ||
                        ((x >= random_x_a) && (x < random_x_a + 9) && (y >= y_pos_a + 4) && (y < y_pos_a + 5)) ||
                        ((y >= y_pos_a + 5) && (y < y_pos_a + 10) && (x == random_x_a + 4 ));
    assign l_arrowA = ((y == y_pos_a + 4) && (x >= random_x_a) && (x < random_x_a + 5)) || 
                        ((y >= y_pos_a + 3) && (y < y_pos_a + 6) && (x >= random_x_a + 1) && (x < random_x_a + 5)) ||
                        ((y >= y_pos_a + 2) && (y < y_pos_a + 7) && (x >= random_x_a + 2) && (x < random_x_a + 5)) ||
                        ((y >= y_pos_a + 1) && (y < y_pos_a + 8) && (x >= random_x_a + 3) && (x < random_x_a + 5)) ||
                        ((y >= y_pos_a) && (y < y_pos_a + 9) && (x >= random_x_a + 4) && (x < random_x_a + 5)) ||
                        ((x >= random_x_a + 5) && (x < random_x_a + 10) && (y == y_pos_a + 4 ));
    assign d_arrowA = ((x == random_x_a + 4) && (y <= y_pos_a) && (y > y_pos_a - 5)) || 
                        ((x >= random_x_a + 3) && (x < random_x_a + 6) && (y <= y_pos_a - 1) && (y > y_pos_a - 5)) ||
                        ((x >= random_x_a + 2) && (x < random_x_a + 7) && (y <= y_pos_a - 2) && (y > y_pos_a - 5)) ||
                        ((x >= random_x_a + 1) && (x < random_x_a + 8) && (y <= y_pos_a - 3) && (y > y_pos_a - 5)) ||
                        ((x >= random_x_a) && (x < random_x_a + 9) && (y <= y_pos_a - 4) && (y > y_pos_a - 5)) ||
                        ((y <= y_pos_a - 5) && (y > y_pos_a - 10) && (x == random_x_a + 4 ));
    assign r_arrowA = ((y == y_pos_a + 4) && (x <= random_x_a) && (x > random_x_a - 5)) || 
                        ((y >= y_pos_a + 3) && (y < y_pos_a + 6) && (x <= random_x_a - 1) && (x > random_x_a - 5)) ||
                        ((y >= y_pos_a + 2) && (y < y_pos_a + 7) && (x <= random_x_a - 2) && (x > random_x_a - 5)) ||
                        ((y >= y_pos_a + 1) && (y < y_pos_a + 8) && (x <= random_x_a - 3) && (x > random_x_a - 5)) ||
                        ((y >= y_pos_a) && (y < y_pos_a + 9) && (x <= random_x_a - 4) && (x > random_x_a - 5)) ||
                        ((x <= random_x_a - 5) && (x > random_x_a - 10) && (y == y_pos_a + 4 ));
    assign c_arrowA = ((x >= random_x_a + 3) && (x < random_x_a + 6) && (y >= y_pos_a + 3) && (y < y_pos_a + 6)) ||
                        ((x == random_x_a + 5) && (y == y_pos_a + 3)) || ((x == random_x_a + 6) && (y == y_pos_a + 3)) || ((x >= random_x_a + 5) && (x < random_x_a + 8) && (y == y_pos_a + 2)) ||
                        ((x >= random_x_a + 6) && (x < random_x_a + 9) && (y == y_pos_a + 1)) || ((x >= random_x_a +7) && (x < random_x_a + 9) && (y == y_pos_a)) ||
                        ((x == random_x_a + 2) && (y == y_pos_a + 3)) || ((x >= random_x_a + 1) && (x < random_x_a + 4) && (y == y_pos_a + 2)) ||
                        ((x >= random_x_a ) && (x < random_x_a + 3) && (y == y_pos_a + 1)) || ((x >= random_x_a) && (x < random_x_a + 2) && (y == y_pos_a)) ||
                        ((x == random_x_a + 6) && (y == y_pos_a + 5)) || ((x >= random_x_a + 5) && (x < random_x_a + 8) && (y == y_pos_a + 6)) ||
                        ((x >= random_x_a + 6) && (x < random_x_a + 9) && (y == y_pos_a + 7)) || ((x >= random_x_a +7) && (x < random_x_a + 9) && (y == y_pos_a + 8)) ||
                        ((x == random_x_a + 2) && (y == y_pos_a + 5)) || ((x >= random_x_a + 1) && (x < random_x_a + 4) && (y == y_pos_a + 6)) ||
                        ((x >= random_x_a) && (x < random_x_a + 3) && (y == y_pos_a + 7)) || ((x >= random_x_a) && (x < random_x_a + 2) && (y == y_pos_a + 8));
                        
    
    assign u_arrowB = ((x == random_x_b + 4) && (y >= y_pos_b) && (y < y_pos_b + 5)) || 
                        ((x >= random_x_b + 3) && (x < random_x_b + 6) && (y >= y_pos_b + 1) && (y < y_pos_b + 5)) ||
                        ((x >= random_x_b + 2) && (x < random_x_b + 7) && (y >= y_pos_b + 2) && (y < y_pos_b + 5)) ||
                        ((x >= random_x_b + 1) && (x < random_x_b + 8) && (y >= y_pos_b + 3) && (y < y_pos_b + 5)) ||
                        ((x >= random_x_b) && (x < random_x_b + 9) && (y >= y_pos_b + 4) && (y < y_pos_b + 5)) ||
                        ((y >= y_pos_b + 5) && (y < y_pos_b + 10) && (x == random_x_b + 4 ));
    assign l_arrowB = ((y == y_pos_b + 4) && (x >= random_x_b) && (x < random_x_b + 5)) || 
                        ((y >= y_pos_b + 3) && (y < y_pos_b + 6) && (x >= random_x_b + 1) && (x < random_x_b + 5)) ||
                        ((y >= y_pos_b + 2) && (y < y_pos_b + 7) && (x >= random_x_b + 2) && (x < random_x_b + 5)) ||
                        ((y >= y_pos_b + 1) && (y < y_pos_b + 8) && (x >= random_x_b + 3) && (x < random_x_b + 5)) ||
                        ((y >= y_pos_b) && (y < y_pos_b + 9) && (x >= random_x_b + 4) && (x < random_x_b + 5)) ||
                        ((x >= random_x_b + 5) && (x < random_x_b + 10) && (y == y_pos_b + 4 ));
    assign d_arrowB = ((x == random_x_b + 4) && (y <= y_pos_b) && (y > y_pos_b - 5)) || 
                        ((x >= random_x_b + 3) && (x < random_x_b + 6) && (y <= y_pos_b - 1) && (y > y_pos_b - 5)) ||
                        ((x >= random_x_b + 2) && (x < random_x_b + 7) && (y <= y_pos_b - 2) && (y > y_pos_b - 5)) ||
                        ((x >= random_x_b + 1) && (x < random_x_b + 8) && (y <= y_pos_b - 3) && (y > y_pos_b - 5)) ||
                        ((x >= random_x_b) && (x < random_x_b + 9) && (y <= y_pos_b - 4) && (y > y_pos_b - 5)) ||
                        ((y <= y_pos_b - 5) && (y > y_pos_b - 10) && (x == random_x_b + 4 ));
    assign r_arrowB = ((y == y_pos_b + 4) && (x <= random_x_b) && (x > random_x_b - 5)) || 
                        ((y >= y_pos_b + 3) && (y < y_pos_b + 6) && (x <= random_x_b - 1) && (x > random_x_b - 5)) ||
                        ((y >= y_pos_b + 2) && (y < y_pos_b + 7) && (x <= random_x_b - 2) && (x > random_x_b - 5)) ||
                        ((y >= y_pos_b + 1) && (y < y_pos_b + 8) && (x <= random_x_b - 3) && (x > random_x_b - 5)) ||
                        ((y >= y_pos_b) && (y < y_pos_b + 9) && (x <= random_x_b - 4) && (x > random_x_b - 5)) ||
                        ((x <= random_x_b - 5) && (x > random_x_b - 10) && (y == y_pos_b + 4 ));
    assign c_arrowB = ((x >= random_x_b + 3) && (x < random_x_b + 6) && (y >= y_pos_b + 3) && (y < y_pos_b + 6)) ||
                        ((x == random_x_b + 5) && (y == y_pos_b + 3)) || ((x == random_x_b + 6) && (y == y_pos_b + 3)) || ((x >= random_x_b + 5) && (x < random_x_b + 8) && (y == y_pos_b + 2)) ||
                        ((x >= random_x_b + 6) && (x < random_x_b + 9) && (y == y_pos_b + 1)) || ((x >= random_x_b +7) && (x < random_x_b + 9) && (y == y_pos_b)) ||
                        ((x == random_x_b + 2) && (y == y_pos_b + 3)) || ((x >= random_x_b + 1) && (x < random_x_b + 4) && (y == y_pos_b + 2)) ||
                        ((x >= random_x_b ) && (x < random_x_b + 3) && (y == y_pos_b + 1)) || ((x >= random_x_b) && (x < random_x_b + 2) && (y == y_pos_b)) ||
                        ((x == random_x_b + 6) && (y == y_pos_b + 5)) || ((x >= random_x_b + 5) && (x < random_x_b + 8) && (y == y_pos_b + 6)) ||
                        ((x >= random_x_b + 6) && (x < random_x_b + 9) && (y == y_pos_b + 7)) || ((x >= random_x_b +7) && (x < random_x_b + 9) && (y == y_pos_b + 8)) ||
                        ((x == random_x_b + 2) && (y == y_pos_b + 5)) || ((x >= random_x_b + 1) && (x < random_x_b + 4) && (y == y_pos_b + 6)) ||
                        ((x >= random_x_b) && (x < random_x_b + 3) && (y == y_pos_b + 7)) || ((x >= random_x_b) && (x < random_x_b + 2) && (y == y_pos_b + 8));

    assign u_arrowC = ((x == random_x_c + 4) && (y >= y_pos_c) && (y < y_pos_c + 5)) || 
                        ((x >= random_x_c + 3) && (x < random_x_c + 6) && (y >= y_pos_c + 1) && (y < y_pos_c + 5)) ||
                        ((x >= random_x_c + 2) && (x < random_x_c + 7) && (y >= y_pos_c + 2) && (y < y_pos_c + 5)) ||
                        ((x >= random_x_c + 1) && (x < random_x_c + 8) && (y >= y_pos_c + 3) && (y < y_pos_c + 5)) ||
                        ((x >= random_x_c) && (x < random_x_c + 9) && (y >= y_pos_c + 4) && (y < y_pos_c + 5)) ||
                        ((y >= y_pos_c + 5) && (y < y_pos_c + 10) && (x == random_x_c + 4 ));
    assign l_arrowC = ((y == y_pos_c + 4) && (x >= random_x_c) && (x < random_x_c + 5)) || 
                        ((y >= y_pos_c + 2) && (y < y_pos_c + 7) && (x >= random_x_c + 2) && (x < random_x_c + 5)) ||
                        ((y >= y_pos_c + 1) && (y < y_pos_c + 8) && (x >= random_x_c + 3) && (x < random_x_c + 5)) ||
                        ((y >= y_pos_c) && (y < y_pos_c + 9) && (x >= random_x_c + 4) && (x < random_x_c + 5)) ||
                        ((x >= random_x_c + 5) && (x < random_x_c + 10) && (y == y_pos_c + 4 ));
    assign d_arrowC = ((x == random_x_c + 4) && (y <= y_pos_c) && (y > y_pos_c - 5)) || 
                        ((x >= random_x_c + 3) && (x < random_x_c + 6) && (y <= y_pos_c - 1) && (y > y_pos_c - 5)) ||
                        ((x >= random_x_c + 2) && (x < random_x_c + 7) && (y <= y_pos_c - 2) && (y > y_pos_c - 5)) ||
                        ((x >= random_x_c + 1) && (x < random_x_c + 8) && (y <= y_pos_c - 3) && (y > y_pos_c - 5)) ||
                        ((x >= random_x_c) && (x < random_x_c + 9) && (y <= y_pos_c - 4) && (y > y_pos_c - 5)) ||
                        ((y <= y_pos_c - 5) && (y > y_pos_c - 10) && (x == random_x_c + 4 ));
    assign r_arrowC = ((y == y_pos_c + 4) && (x <= random_x_c) && (x > random_x_c - 5)) || 
                        ((y >= y_pos_c + 3) && (y < y_pos_c + 6) && (x <= random_x_c - 1) && (x > random_x_c - 5)) ||
                        ((y >= y_pos_c + 2) && (y < y_pos_c + 7) && (x <= random_x_c - 2) && (x > random_x_c - 5)) ||
                        ((y >= y_pos_c + 1) && (y < y_pos_c + 8) && (x <= random_x_c - 3) && (x > random_x_c - 5)) ||
                        ((y >= y_pos_c) && (y < y_pos_c + 9) && (x <= random_x_c - 4) && (x > random_x_c - 5)) ||
                        ((x <= random_x_c - 5) && (x > random_x_c - 10) && (y == y_pos_c + 4 ));
    assign c_arrowC = ((x >= random_x_c + 3) && (x < random_x_c + 6) && (y >= y_pos_c + 3) && (y < y_pos_c + 6)) ||
                        ((x == random_x_c + 5) && (y == y_pos_c + 3)) || ((x == random_x_c + 6) && (y == y_pos_c + 3)) || ((x >= random_x_c + 5) && (x < random_x_c + 8) && (y == y_pos_c + 2)) ||
                        ((x >= random_x_c + 6) && (x < random_x_c + 9) && (y == y_pos_c + 1)) || ((x >= random_x_c +7) && (x < random_x_c + 9) && (y == y_pos_c)) ||
                        ((x == random_x_c + 2) && (y == y_pos_c + 3)) || ((x >= random_x_c + 1) && (x < random_x_c + 4) && (y == y_pos_c + 2)) ||
                        ((x >= random_x_c ) && (x < random_x_c + 3) && (y == y_pos_c + 1)) || ((x >= random_x_c) && (x < random_x_c + 2) && (y == y_pos_c)) ||
                        ((x == random_x_c + 6) && (y == y_pos_c + 5)) || ((x >= random_x_c + 5) && (x < random_x_c + 8) && (y == y_pos_c + 6)) ||
                        ((x >= random_x_c + 6) && (x < random_x_c + 9) && (y == y_pos_c + 7)) || ((x >= random_x_c +7) && (x < random_x_c + 9) && (y == y_pos_c + 8)) ||
                        ((x == random_x_c + 2) && (y == y_pos_c + 5)) || ((x >= random_x_c + 1) && (x < random_x_c + 4) && (y == y_pos_c + 6)) ||
                        ((x >= random_x_c) && (x < random_x_c + 3) && (y == y_pos_c + 7)) || ((x >= random_x_c) && (x < random_x_c + 2) && (y == y_pos_c + 8));
                        
    assign u_arrowD = ((x == random_x_d + 4) && (y >= y_pos_d) && (y < y_pos_d + 5)) || 
                        ((x >= random_x_d + 3) && (x < random_x_d + 6) && (y >= y_pos_d + 1) && (y < y_pos_d + 5)) ||
                        ((x >= random_x_d + 2) && (x < random_x_d + 7) && (y >= y_pos_d + 2) && (y < y_pos_d + 5)) ||
                        ((x >= random_x_d + 1) && (x < random_x_d + 8) && (y >= y_pos_d + 3) && (y < y_pos_d + 5)) ||
                        ((x >= random_x_d) && (x < random_x_d + 9) && (y >= y_pos_d + 4) && (y < y_pos_d + 5)) ||
                        ((y >= y_pos_d + 5) && (y < y_pos_d + 10) && (x == random_x_d + 4 ));
    assign l_arrowD = ((y == y_pos_d + 4) && (x >= random_x_d) && (x < random_x_d + 5)) || 
                        ((y >= y_pos_d + 3) && (y < y_pos_d + 6) && (x >= random_x_d + 1) && (x < random_x_d + 5)) ||
                        ((y >= y_pos_d + 2) && (y < y_pos_d + 7) && (x >= random_x_d + 2) && (x < random_x_d + 5)) ||
                        ((y >= y_pos_d + 1) && (y < y_pos_d + 8) && (x >= random_x_d + 3) && (x < random_x_d + 5)) ||
                        ((y >= y_pos_d) && (y < y_pos_d + 9) && (x >= random_x_d + 4) && (x < random_x_d + 5)) ||
                        ((x >= random_x_d + 5) && (x < random_x_d + 10) && (y == y_pos_d + 4 ));
    assign d_arrowD = ((x == random_x_d + 4) && (y <= y_pos_d) && (y > y_pos_d - 5)) || 
                        ((x >= random_x_d + 3) && (x < random_x_d + 6) && (y <= y_pos_d - 1) && (y > y_pos_d - 5)) ||
                        ((x >= random_x_d + 2) && (x < random_x_d + 7) && (y <= y_pos_d - 2) && (y > y_pos_d - 5)) ||
                        ((x >= random_x_d + 1) && (x < random_x_d + 8) && (y <= y_pos_d - 3) && (y > y_pos_d - 5)) ||
                        ((x >= random_x_d) && (x < random_x_d + 9) && (y <= y_pos_d - 4) && (y > y_pos_d - 5)) ||
                        ((y <= y_pos_d - 5) && (y > y_pos_d - 10) && (x == random_x_d + 4 ));
    assign r_arrowD = ((y == y_pos_d + 4) && (x <= random_x_d) && (x > random_x_d - 5)) || 
                        ((y >= y_pos_d + 3) && (y < y_pos_d + 6) && (x <= random_x_d - 1) && (x > random_x_d - 5)) ||
                        ((y >= y_pos_d + 2) && (y < y_pos_d + 7) && (x <= random_x_d - 2) && (x > random_x_d - 5)) ||
                        ((y >= y_pos_d + 1) && (y < y_pos_d + 8) && (x <= random_x_d - 3) && (x > random_x_d - 5)) ||
                        ((y >= y_pos_d) && (y < y_pos_d + 9) && (x <= random_x_d - 4) && (x > random_x_d - 5)) ||
                        ((x <= random_x_d - 5) && (x > random_x_d - 10) && (y == y_pos_d + 4 ));
    assign c_arrowD = ((x >= random_x_d + 3) && (x < random_x_d + 6) && (y >= y_pos_d + 3) && (y < y_pos_d + 6)) ||
                        ((x == random_x_d + 5) && (y == y_pos_d + 3)) || ((x == random_x_d + 6) && (y == y_pos_d + 3)) || ((x >= random_x_d + 5) && (x < random_x_d + 8) && (y == y_pos_d + 2)) ||
                        ((x >= random_x_d + 6) && (x < random_x_d + 9) && (y == y_pos_d + 1)) || ((x >= random_x_d +7) && (x < random_x_d + 9) && (y == y_pos_d)) ||
                        ((x == random_x_d + 2) && (y == y_pos_d + 3)) || ((x >= random_x_d + 1) && (x < random_x_d + 4) && (y == y_pos_d + 2)) ||
                        ((x >= random_x_d ) && (x < random_x_d + 3) && (y == y_pos_d + 1)) || ((x >= random_x_d) && (x < random_x_d + 2) && (y == y_pos_d)) ||
                        ((x == random_x_d + 6) && (y == y_pos_d + 5)) || ((x >= random_x_d + 5) && (x < random_x_d + 8) && (y == y_pos_d + 6)) ||
                        ((x >= random_x_d + 6) && (x < random_x_d + 9) && (y == y_pos_d + 7)) || ((x >= random_x_d +7) && (x < random_x_d + 9) && (y == y_pos_d + 8)) ||
                        ((x == random_x_d + 2) && (y == y_pos_d + 5)) || ((x >= random_x_d + 1) && (x < random_x_d + 4) && (y == y_pos_d + 6)) ||
                        ((x >= random_x_d) && (x < random_x_d + 3) && (y == y_pos_d + 7)) || ((x >= random_x_d) && (x < random_x_d + 2) && (y == y_pos_d + 8));
                        
    assign zero = (((x == 91) && (y >= 2) && (y < 10))
                  || ((x == 92) && (y >= 2) && (y < 10))
                  || ((x == 94) && (y >= 2) && (y < 10))
                  || ((x == 95) && (y >= 2) && (y < 10))
                  || ((x >= 91) && (x < 96) && (y == 2))
                  || ((x >= 91) && (x < 96) && (y == 3))
                  || ((x >= 91) && (x < 96) && (y == 8))
                  || ((x >= 91) && (x < 96) && (y == 9)));
    assign one = (((x == 91) && (y >= 2) && (y < 10))
                 || ((x == 92) && (y >= 2) && (y < 10)));
    assign two = (((x >= 91) && (x < 96) && ((y == 2) || (y == 3) || (y == 5) || (y == 6) || (y == 8) || (y == 9))) ||
                  (((x == 94) || (x == 95)) && (y >= 2) && (y < 7)) ||
                  (((x == 91) || (x == 92)) && (y >= 5) && (y < 10)));
    assign three = 
         (((x >= 91) && (x < 96) && ((y == 2) || (y == 3) || (y == 5) || (y == 6) || (y == 8) || (y == 9))) ||
         ((x == 94) && (y >= 2) && (y < 10)) ||
         ((x == 95) && (y >= 2) && (y < 10)));
    assign four = 
         ((x >= 91) && (x < 96) && (y == 5)) ||
         ((x >= 91) && (x < 96) && (y == 6)) ||
         ((x == 94) && (y >= 2) && (y < 10)) ||
         ((x == 95) && (y >= 2) && (y < 10)) ||
         ((x == 91) && (y >= 2) && (y < 7))  ||
         ((x == 92) && (y >= 2) && (y < 7));
    assign five = 
              (((x >= 91) && (x < 96) && ((y == 2) || (y == 3) || (y == 5) || (y == 6) || (y == 8) || (y == 9))) ||
              (((x == 94) || (x == 95)) && (y >= 5) && (y < 10)) ||
              (((x == 91) || (x == 92)) && (y >= 2) && (y < 7)));
    assign six = 
             ((x >= 91) && (x < 96) && (y == 2)) ||
             ((x >= 91) && (x < 96) && (y == 3)) ||
             ((x == 91) && (y >= 2) && (y < 10)) ||
             ((x == 92) && (y >= 2) && (y < 10)) ||
             ((x >= 91) && (x < 96) && (y == 9)) ||
             ((x >= 91) && (x < 96) && (y == 6)) ||
             ((x == 95) && (y >= 6) && (y < 10));
     assign seven = 
              ((x >= 91 && x < 96 && y == 2) ||
              (x == 94 && y >= 2 && y < 10) ||
              (x == 95 && y >= 2 && y < 10) ||
              (x == 91 && y >= 2 && y < 5) ||
              (x == 92 && y >= 2 && y < 5));
     assign eight= 
              (((x >= 91) && (x < 96) && (y == 2)) ||
              ((x >= 91) && (x < 96) && (y == 5)) ||
              ((x >= 91) && (x < 96) && (y == 6)) ||
              ((x == 94) && (y >= 2) && (y < 10)) ||
              ((x == 95) && (y >= 2) && (y < 10)) ||
              ((x == 91) && (y >= 2) && (y < 10)) ||
              ((x == 92) && (y >= 2) && (y < 10)) ||
              ((x >= 91) && (x < 96) && (y == 9)));
     assign nine = 
              (((x >= 91) && (x < 96) && (y == 2)) ||
              ((x >= 91) && (x < 96) && (y == 6)) ||
              ((x == 94) && (y >= 2) && (y < 10)) ||
              ((x == 95) && (y >= 2) && (y < 10)) ||
              ((x == 91) && (y >= 2) && (y < 7)) ||
              ((x == 92) && (y >= 2) && (y < 7))) ;
     assign ten = 
              ((x == 88 && (y >= 2 && y < 10)) ||
              (x == 89 && (y >= 2 && y < 10)) ||
              (x == 91 && (y >= 2 && y < 10)) ||
              (x == 92 && (y >= 2 && y < 10)) ||
              (x == 94 && (y >= 2 && y < 10)) ||
              (x == 95 && (y >= 2 && y < 10)) ||
              ((x >= 91 && x < 96) && (y == 2 || y == 3 || y == 8 || y == 9)));
     assign eleven = 
              (((x == 88) && (y >= 2) && (y < 10)) || 
              ((x == 89) && (y >= 2) && (y < 10)) || 
              ((x == 91) && (y >= 2) && (y < 10)) || 
              ((x == 92) && (y >= 2) && (y < 10))) ;
     assign twelve = 
              ((x == 88 && y >= 2 && y < 10) || (x == 89 && y >= 2 && y < 10) ||
              ((x >= 91 && x < 96) && (y == 2 || y == 3 || y == 5 || y == 6 || y == 8 || y == 9)) ||
              ((x == 94 && y >= 2 && y < 7) || (x == 95 && y >= 2 && y < 7)) ||
              ((x == 91 || x == 92) && (y >= 5 && y < 10))) ;
     assign thirteen = 
               ((x == 88 && y >= 2 && y < 10) ||
               (x == 89 && y >= 2 && y < 10) ||
               ((x >= 91 && x < 96) && (y == 2 || y == 3 || y == 5 || y == 6 || y == 8 || y == 9)) ||
               ((x == 94 || x == 95) && (y >= 2 && y < 10))) ;
     assign fourteen = 
              ((x == 88 && y >= 2 && y < 10) || (x == 89 && y >= 2 && y < 10) ||
              ((x >= 91 && x < 96) && (y == 5 || y == 6)) ||
              ((x == 94 || x == 95) && y >= 2 && y < 10) ||
              ((x == 91 || x == 92) && y >= 2 && y < 7)) ;
      assign fifteen = ((x == 88 || x == 89) && (y >= 2 && y < 10)) ||
                       ((x >= 91 && x < 96) && (y == 2 || y == 3 || y == 5 || y == 6 || y == 8 || y == 9)) ||
                       ((x == 94 || x == 95) && (y >= 5 && y < 10)) ||
                       ((x == 91 || x == 92) && (y >= 2 && y < 7));
      assign sixteen = ((x == 88 && y >= 2 && y < 10) || 
                       (x == 89 && y >= 2 && y < 10) || 
                       ((x >= 91 && x < 96) && (y == 2 || y == 3)) || 
                       (x == 91 && y >= 2 && y < 10) || 
                       (x == 92 && y >= 2 && y < 10) || 
                       ((x >= 91 && x < 96) && y == 9) || 
                       ((x >= 91 && x < 96) && y == 6) || 
                       (x == 95 && y >= 6 && y < 10)); 
      assign seventeen = ((((x == 88 || x == 89 || x == 94 || x == 95 ) && (y >= 2 && y < 10)) 
                        || ((x >= 91 && x < 96) && y == 2))
                        || ((x == 91 || x == 92) && (y >= 2 && y < 5)));
      assign eighteen = (((x == 88 || x == 89 || x == 94 || x == 95 || x == 91 || x == 92) && (y >= 2 && y < 10)) ||
                        (x >= 91 && x < 96 && (y == 2 || y == 5 || y == 6)) ||
                        (x >= 91 && x < 96 && y == 9)) ;
      assign nineteen = (((x == 88 || x == 89 || x == 94 || x == 95) && (y >= 2 && y < 10))  || 
                         ((x >= 91 && x < 96) && (y == 2 || y == 6)) ||
                         ((x == 91 || x == 92) && (y >= 2 && y < 7)));
      assign twenty = (((x >= 85) && (x < 88) && (y == 2))
                       || ((x >= 85) && (x < 90) && (y == 3))
                       || ((x == 89) && (y >= 2) && (y < 7))
                       || ((x == 88) && (y >= 2) && (y < 7))
                       || ((x >= 85) && (x < 90) && (y == 5))
                       || ((x >= 85) && (x < 90) && (y == 6))
                       || ((x == 85) && (y >= 5) && (y < 10))
                       || ((x == 86) && (y >= 5) && (y < 10))
                       || ((x >= 85) && (x < 90) && (y == 8))
                       || ((x >= 85) && (x < 90) && (y == 9))
                       || ((x >= 91) && (x < 96) && (y == 2))
                       || ((x >= 91) && (x < 96) && (y == 3))
                       || ((x == 91) && (y >= 2) && (y < 10))
                       || ((x == 92) && (y >= 2) && (y < 10))
                       || ((x == 95) && (y >= 2) && (y < 10))
                       || ((x == 94) && (y >= 2) && (y < 10))
                       || ((x >= 91) && (x < 96) && (y == 8))
                       || ((x >= 91) && (x < 96) && (y == 9)));

    ////////////////////////////////////////////////////////////////////////
    ////////////////////////// OLED Display ////////////////////////////////
    ////////////////////////////////////////////////////////////////////////    
    always @(posedge clk) begin
        if (line) game_pixel_data <= BLUE;
        else if (moving_shape_a && shape_a) game_pixel_data <= shape_a_colour;
        else if (moving_shape_b && shape_b) game_pixel_data <= shape_b_colour;
        else if (moving_shape_c && shape_c) game_pixel_data <= shape_c_colour;
        else if (moving_shape_d && shape_d) game_pixel_data <= shape_d_colour;
        
        
        // Points reflection
        else if (plus_zero && zeroFlag) game_pixel_data <= RED;
        else if (plus_one && oneFlag) game_pixel_data <= YELLOW;
        else if (plus_two && twoFlag) game_pixel_data <= BLUE;
        else if (plus_three && threeFlag) game_pixel_data <= GREEN;
        
        // OLED Timer
        else if (secondsCounter == 0 && twenty) game_pixel_data <= WHITE;
        else if (secondsCounter == 1 && nineteen) game_pixel_data <= WHITE;
        else if (secondsCounter == 2 && eighteen) game_pixel_data <= WHITE;
        else if (secondsCounter == 3 && seventeen) game_pixel_data <= WHITE;
        else if (secondsCounter == 4 && sixteen) game_pixel_data <= WHITE;
        else if (secondsCounter == 5 && fifteen) game_pixel_data <= WHITE;
        else if (secondsCounter == 6 && fourteen) game_pixel_data <= WHITE;
        else if (secondsCounter == 7 && thirteen) game_pixel_data <= WHITE;
        else if (secondsCounter == 8 && twelve) game_pixel_data <= WHITE;
        else if (secondsCounter == 9 && eleven) game_pixel_data <= WHITE;
        else if (secondsCounter == 10 && ten) game_pixel_data <= WHITE;
        else if (secondsCounter == 11 && nine) game_pixel_data <= WHITE;
        else if (secondsCounter == 12 && eight) game_pixel_data <= WHITE;
        else if (secondsCounter == 13 && seven) game_pixel_data <= WHITE;
        else if (secondsCounter == 14 && six) game_pixel_data <= WHITE;
        else if (secondsCounter == 15 && five) game_pixel_data <= WHITE;
        else if (secondsCounter == 16 && four) game_pixel_data <= WHITE;
        else if (secondsCounter == 17 && three) game_pixel_data <= WHITE;
        else if (secondsCounter == 18 && two) game_pixel_data <= WHITE;
        else if (secondsCounter == 19 && one) game_pixel_data <= WHITE;
        else if (secondsCounter == 20 && zero) game_pixel_data <= WHITE;
        else game_pixel_data <= BLACK;
    end
    
endmodule
