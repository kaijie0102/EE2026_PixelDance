`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/06/2024 06:55:46 PM
// Design Name: 
// Module Name: beatdetection
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


module beatdetection(
    input clk,
    input custom_fft_clk,  // Clock signal for FFT module
    input [119:0] spectrogram,  // Spectrogram data (20 bars, 6 bits per bar)
    output reg [15:0] led,  // Output indicating beat detection
    output reg [1:0] speed = 0
//    output reg [6:0] seg, // 7 segment display
//    output reg [3:0] an // 7 segment display
    );
    initial begin
        led = 0;
    end
    
   
    // Parameters
    parameter BIN_WIDTH = 500;  // Width of each frequency bin in Hz
    parameter THRESHOLD = 240; // Energy threshold for beat detection
//    parameter THRESHOLD = 280; // Energy threshold for beat detection

    
    reg [1:0] speed = 0;
    
    // Internal variables
    reg [15:0] fft_magnitude[63:0]; // Magnitude of FFT bins
    integer i, j;
    integer bin_index;
    reg [31:0] energy_sum;
    reg [31:0] number_of_beats = 0;
    wire clk_0p3hz;
    slow_clock clk0p3hz (clk, 150_000_000, clk_0p3hz);
    
    wire clk_480;
    slow_clock clock_480Hz(.clk(clk), .max_counts(104167), .new_clk(clk_480));
    wire [3:0] ones, tens, hundreds;
    assign hundreds = energy_sum / 100; 
    assign tens = (energy_sum - hundreds*100) / 10; 
    assign ones = energy_sum % 10; 
    
    reg checked = 0;
    reg [31:0] three_sec_counter = 1;
    
    
    
//    // 7 segment display
//        reg [1:0] an_count = 0;
//        reg [6:0] digit0 = 7'b100_0000; 
//        reg [6:0] digit1 = 7'b111_1001; 
//        reg [6:0] digit2 = 7'b010_0100; 
//        reg [6:0] digit3 = 7'b011_0000; 
//        reg [6:0] digit4 = 7'b001_1001; 
//        reg [6:0] digit5 = 7'b001_0010; 
//        reg [6:0] digit6 = 7'b000_0010; 
//        reg [6:0] digit7 = 7'b111_1000; 
//        reg [6:0] digit8 = 7'b000_0000;
//        reg [6:0] digit9 = 7'b001_0000;
        
        
//         //7 segment display
//        always @(posedge clk_480) begin
//            an_count <= (an_count == 3) ? 0 : an_count + 1;
//            case (an_count)
//            0: begin 
//                an <= 4'b1110;
//                if (ones == 0) seg <= digit0;
//                else if (ones == 1) seg <= digit1;
//                else if (ones == 2) seg <= digit2;
//                else if (ones == 3) seg <= digit3;
//                else if (ones == 4) seg <= digit4;
//                else if (ones == 5) seg <= digit5;
//                else if (ones == 6) seg <= digit6;
//                else if (ones == 7) seg <= digit7;
//                else if (ones == 8) seg <= digit8;
//                else if (ones == 9) seg <= digit9;
//            end
//            1: begin 
//                an <= 4'b1101;
//                if (tens == 0) seg <= digit0;
//                else if (tens == 1) seg <= digit1;
//                else if (tens == 2) seg <= digit2;
//                else if (tens == 3) seg <= digit3;
//                else if (tens == 4) seg <= digit4;
//                else if (tens == 5) seg <= digit5;
//                else if (tens == 6) seg <= digit6;
//                else if (tens == 7) seg <= digit7;
//                else if (tens == 8) seg <= digit8;
//                else if (tens == 9) seg <= digit9;
//            end
//            2: begin 
//                an <= 4'b1011;
//                if (hundreds == 0) seg <= digit0;
//                else if (hundreds == 1) seg <= digit1;
//                else if (hundreds == 2) seg <= digit2;
//                else if (hundreds == 3) seg <= digit3;
//                else if (hundreds == 4) seg <= digit4;
//                else if (hundreds == 5) seg <= digit5;
//                else if (hundreds == 6) seg <= digit6;
//                else if (hundreds == 7) seg <= digit7;
//                else if (hundreds == 8) seg <= digit8;
//                else if (hundreds == 9) seg <= digit9;
//            end
//            3: begin 
//                an <= 4'b0111;
//                if (speed == 0) seg <= digit0;
////                else seg <= digit9;
//                else if (speed == 1) seg <= digit1;
//                else if (speed == 2) seg <= digit2;
////                else if (number_of_beats == 3) seg <= digit3;
////                else if (number_of_beats == 4) seg <= digit4;
////                else if (number_of_beats == 5) seg <= digit5;
////                else if (number_of_beats == 6) seg <= digit6;
////                else if (number_of_beats == 7) seg <= digit7;
////                else if (number_of_beats == 8) seg <= digit8;
////                else if (number_of_beats == 9) seg <= digit9;
//            end
//            default: begin
//                an <= 4'b1111;
//            end
//            endcase
            
//        end
        

    
    // Beat detection logic
    always @(posedge custom_fft_clk) begin
        if (checked) number_of_beats = 0;
        
        // Reset beat_detected flag
        energy_sum <= spectrogram[5:0] + spectrogram[11:6] + spectrogram[17:12] + spectrogram[23:18];
        
        if (energy_sum > THRESHOLD) begin
            // Set beat_detected flag if energy threshold is exceeded
            number_of_beats = number_of_beats + 1;
        end

            
    end
    
    always @(posedge clk) begin
        three_sec_counter <= (three_sec_counter == 300_000_000) ? 0 : three_sec_counter + 1;
        if (three_sec_counter == 0) begin
            checked = 1;
            led[5] = 1;
            if (energy_sum >= 240) begin // 2000 hz
                speed = 2;
                led[2] = 1;
                led[1] = 0;
                led[0] = 0;
            end
            else if (energy_sum >= 195) begin //700 hz
                speed = 1;
                led[2] = 0;
                led[1] = 1;
                led[0] = 0;
            end
            else if (energy_sum < 195) begin //250 hz
                speed = 0;
                led[2] = 0;
                led[1] = 0;
                led[0] = 1;
            end
        end 
        else begin
            checked = 0;
            led[5] = 0;
        end
    end
 

endmodule
