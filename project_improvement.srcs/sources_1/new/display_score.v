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
    input [31:0] highscore,
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
    reg [6:0] seg4 = 0;
    reg [6:0] seg3 = 0;
    reg [1:0] an_count = 0;
    
    // Digits
    reg [3:0] score_tens = 1; // 10's digit for score
    reg [3:0] score_ones = 1; // 1's digit for score
    reg [3:0] highscore_tens = 1; // 10's digit for highscore
    reg [3:0] highscore_ones = 1; // 1's digit for highscore

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
    wire clk_960;
    slow_clock slow_clock_960Hz(.clk(clk), .max_counts(52083), .new_clk(clk_960));
    
    always @ (posedge clk_960)
    begin
        //////////////////////// Display Score ////////////////////////
        score_ones = score % 10;
        score_tens = score / 10;
        
        ////////// 1's Digit //////////
        case (score_ones)
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
        case (score_tens)
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
        
        highscore_ones = highscore % 10;
        highscore_tens = highscore / 10;
        ////////// 1's Digit //////////
        case (highscore_ones)
            0: seg3 = ZERO;
            1: seg3 = ONE;
            2: seg3 = TWO;
            3: seg3 = THREE;
            4: seg3 = FOUR;
            5: seg3 = FIVE;
            6: seg3 = SIX;
            7: seg3 = SEVEN;
            8: seg3 = EIGHT;
            9: seg3 = NINE;
            default: seg3 = ZERO;
        endcase
        
        ///////////// 10's Digit ///////////////
        case (highscore_tens)
            0: seg4 = ZERO;
            1: seg4 = ONE;
            2: seg4 = TWO;
            3: seg4 = THREE;
            4: seg4 = FOUR;
            5: seg4 = FIVE;
            6: seg4 = SIX;
            7: seg4 = SEVEN;
            8: seg4 = EIGHT;
            9: seg4 = NINE;
            default: seg4 = ZERO;
        endcase
        
        ///////// Display both digits ////////////
        an_count <= (an_count == 3) ? 0 : an_count + 1;
        case (an_count)
            0: begin
                    an = 4'b1110;
                    seg = seg1;
                end
            1: begin
                    an = 4'b1101;
                    seg = seg2;
                end
            2: begin
                    an = 4'b1011;
                    seg = seg3;
               end
           3: begin
                    an = 4'b0111;
                    seg = seg4;
              end
            
        endcase
    end

endmodule
