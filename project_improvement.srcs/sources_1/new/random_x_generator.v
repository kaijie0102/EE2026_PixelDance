`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.03.2024 16:51:24
// Design Name: 
// Module Name: random_x_generator
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


module random_x_generator(
    input clk,
    input [31:0] random_max_count,
//    input get_new,
    output reg [6:0] random_x, // 7 bits to cover up to 128,
    output [3:0] ones,
    output [3:0] tens
    );
    
    reg [7:0] lfsr_reg; // Keep the LFSR as 8-bit for good sequence properties
    
    // slow clocks
//    wire clk_5sec;
//    slow_clock clock_5sec(.clk(clk), .max_counts(250_000_000), .new_clk(clk_5sec));
    
    initial begin
        lfsr_reg <= 8'b0000_0001; // 0 -> 42 -> 34
    end
    
    reg [31:0] generate_random_counter = 1;
    always @(posedge clk) begin
        
        // 5 seconds countdown
         generate_random_counter <= (generate_random_counter == random_max_count) ? 0 : generate_random_counter + 1;

        // Shift left by one bit and insert the new feedback bit at position 0
        lfsr_reg <= {lfsr_reg[6:0], (lfsr_reg[7] ^ lfsr_reg[6])};   
        if (generate_random_counter == 0) begin
            // Scale the output to be within 0-90
            // This simple scaling works by taking the upper 7 bits, which gives a range of 0-127
            // Then, if the number is above 90, we subtract 90 until it's within the range
            if (lfsr_reg[7:1] > 80) begin
                random_x <= lfsr_reg[7:1] - 80; // Adjust if the value is above 90
            end else begin
                random_x <= lfsr_reg[7:1]; // Directly use the value if it's 90 or below
            end
        end 
//        else generated <= 0;
    end
    
    assign ones = random_x % 10;
    assign tens = random_x / 10;

endmodule
