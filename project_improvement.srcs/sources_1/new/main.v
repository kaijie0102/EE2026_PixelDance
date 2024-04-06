`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.03.2024 23:24:09
// Design Name: 
// Module Name: main
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


module main(
    input clk,
    input [15:0] sw,
    input btnC, btnU, btnL, btnR, btnD,
    inout PS2Clk,  // oled
    inout PS2Data, // oled
    input JB2,   // Connect from this signal to Audio_Capture.v JB MIC PIN 3
    output JB0,   // Connect to this signal from Audio_Capture.v JB MIC PIN 1
    output JB3,   // Connect to this signal from Audio_Capture.v JB MIC PIN 4
    output [15:0] led, 
    output [7:0] JC, // oled
    output [6:0] seg, // 7 segment display
    output [3:0] an, // 7 segment display
    output dp // 7 segmenet display
    );
    
    // OLED display
    slow_clock slow_clock_6p25MHz(.clk(clk), .max_counts(8), .new_clk(clock_6p25M));
    wire frame_beg, send_pix, sample_pix;
    wire [15:0] pix_data;
    wire [12:0] pix_index;
        
    // clocks
    wire clk_1hz, clk_20khz, clk_480;
    slow_clock clock_1hz(.clk(clk), .max_counts(50_000_000), .new_clk(clk_1hz));
    slow_clock clock_20khz(.clk(clk), .max_counts(2500), .new_clk(clk_20khz));
    slow_clock clock_480Hz(.clk(clk), .max_counts(104167), .new_clk(clk_480));
    
    // 7 segment display
    reg [1:0] an_count = 0;
    reg [6:0] digit0 = 7'b100_0000; 
    reg [6:0] digit1 = 7'b111_1001; 
    reg [6:0] digit2 = 7'b010_0100; 
    reg [6:0] digit3 = 7'b011_0000; 
    reg [6:0] digit4 = 7'b001_1001; 
    reg [6:0] digit5 = 7'b001_0010; 
    reg [6:0] digit6 = 7'b000_0010; 
    reg [6:0] digit7 = 7'b111_1000; 
    reg [6:0] digit8 = 7'b000_0000;
    reg [6:0] digit9 = 7'b001_0000; 

    // Audio capture using PMODS Mic 3
    wire [11:0] mic_in;
    audio_capture mic(clk, clk_20khz, JB2, JB0, JB3, mic_in);
    
    // Random number generator
    wire [6:0] random_x;
    wire [3:0] ones;
    wire [3:0] tens;

    random_x_generator random_x_value(.clk(clk), .random_max_count(300_000_000), .random_x(random_x), .ones(ones), .tens(tens)); 
    //     7 segment display
//    always @(posedge clk_480) begin
//        an_count <= (an_count == 3) ? 0 : an_count + 1;
//        case (an_count)
//        0: begin 
//            an <= 4'b1110;
//            if (ones == 0) seg <= digit0;
//            else if (ones == 1) seg <= digit1;
//            else if (ones == 2) seg <= digit2;
//            else if (ones == 3) seg <= digit3;
//            else if (ones == 4) seg <= digit4;
//            else if (ones == 5) seg <= digit5;
//            else if (ones == 6) seg <= digit6;
//            else if (ones == 7) seg <= digit7;
//            else if (ones == 8) seg <= digit8;
//            else if (ones == 9) seg <= digit9;
//        end
//        1: begin 
//            an <= 4'b1101;
//            if (tens == 0) seg <= digit0;
//            else if (tens == 1) seg <= digit1;
//            else if (tens == 2) seg <= digit2;
//            else if (tens == 3) seg <= digit3;
//            else if (tens == 4) seg <= digit4;
//            else if (tens == 5) seg <= digit5;
//            else if (tens == 6) seg <= digit6;
//            else if (tens == 7) seg <= digit7;
//            else if (tens == 8) seg <= digit8;
//            else if (tens == 9) seg <= digit9;
//        end
//        default: begin
//            an <= 4'b1111;
//        end
//        endcase
        
//    end    
    
     ui user_interface(.clk(clk), .sw(sw), .pixel_index(pix_index), .random_x_pos(random_x), .btnC(btnC), .btnU(btnU), .btnL(btnL), .btnR(btnR), .btnD(btnD), .seg(seg), .an(an), .led(led) ,.oled_data(pix_data));
    
    // OLED Display code below
    Oled_Display oled(
        .clk(clock_6p25M), 
        .reset(0), 
        .frame_begin(frame_beg), 
        .sending_pixels(send_pix),
        .sample_pixel(sample_pix), 
        .pixel_index(pix_index), 
        .pixel_data(pix_data), 
        .cs(JC[0]), 
        .sdin(JC[1]), 
        .sclk(JC[3]), 
        .d_cn(JC[4]), 
        .resn(JC[5]), 
        .vccen(JC[6]),
        .pmoden(JC[7])
    );
endmodule
