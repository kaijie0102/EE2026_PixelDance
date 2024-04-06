`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.04.2024 23:27:03
// Design Name: 
// Module Name: display_score
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


module display_score(
    input clk,
    input [31:0] score,
    output reg [3:0] an,
    output reg [6:0] seg
    );
    
    // Initialisation
    initial begin
        an = 4'b1111;
        seg = 7'b111_1111;
    end
    
    // Anodes and Segments
    reg [6:0] seg1 = 0;
    reg [6:0] seg2 = 0;
    reg an_count = 0;
    
    // Digits
    reg [31:0] score_digit_2 = 1; // 10's digit
    reg [31:0] score_digit_1 = 1; // 1's digit

    // 7 Segment Display for Digits
    parameter ZERO = 7'b1000000;
    parameter ONE = 7'b1111001;
    parameter TWO = 7'b0100100;
    parameter THREE = 7'b0110000;
    parameter FOUR = 7'b0011001;
    parameter FIVE = 7'b0010010;
    parameter SIX = 7'b0000010;
    parameter SEVEN = 7'b1111000;
    parameter EIGHT = 7'b0000000;
    parameter NINE = 7'b0010000;
    
    // Clock
    wire clk_480;
    slow_clock slow_clock_480Hz(.clk(clk), .max_counts(104167), .new_clk(clk_480));
    
    always @ (posedge clk_480)
    begin
        //////////////////////// Display Score ////////////////////////
        score_digit_1 = score % 10;
//        score_digit_2 = (score - score_digit_1) / 10 ;
        score_digit_2 = score / 10;
        
        ////////// 1's Digit //////////
        case (score_digit_1)
            0: seg1 = ZERO;
            1: seg1 = ONE;
            2: seg1 = TWO;
            3: seg1 = THREE;
            4: seg1 = FOUR;
            5: seg1 = FIVE;
            6: seg1 = SIX;
            7: seg1 = SEVEN;
            8: seg1 = EIGHT;
            9: seg1 = NINE;
            default: seg1 = ZERO;
        endcase
        
        ///////////// 10's Digit ///////////////
        case (score_digit_2)
            0: seg2 = ZERO;
            1: seg2 = ONE;
            2: seg2 = TWO;
            3: seg2 = THREE;
            4: seg2 = FOUR;
            5: seg2 = FIVE;
            6: seg2 = SIX;
            7: seg2 = SEVEN;
            8: seg2 = EIGHT;
            9: seg2 = NINE;
            default: seg2 = ZERO;
        endcase
        
        ///////// Display both digits ////////////
        an_count <= (an_count == 1) ? 0 : 1;
        case (an_count)
            0: begin
                    an = 4'b1110;
                    seg = seg1;
                end
            1: begin
                    an = 4'b1101;
                    seg = seg2;
                end
        endcase
    end

endmodule
