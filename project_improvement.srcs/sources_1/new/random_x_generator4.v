`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.04.2024 09:27:08
// Design Name: 
// Module Name: random_x_generator4
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


module random_x_generator4(
    input clk,
    input get_new, // when get_new flag is 1, obtain new number
    output reg [6:0] random_x // 7 bits to cover up to 128,
    );
    
    reg [7:0] lfsr_reg; // Keep the LFSR as 8-bit for good sequence properties
    
    initial begin
        lfsr_reg <= 8'b0001_1011; // 0 -> 42 -> 34
    end
    
    reg [31:0] generate_random_counter = 1;
    reg generate_new = 1;
    always @(posedge clk) begin
        if (get_new == 0 && generate_new == 0) generate_new = 1;
        
        // Shift left by one bit and insert the new feedback bit at position 0
        lfsr_reg <= {lfsr_reg[6:0], (lfsr_reg[7] ^ lfsr_reg[6])};   
        if (get_new && generate_new) begin 
            generate_new = 0; // stop generating new number
            // Scale the output to be within 0-80
            // This simple scaling works by taking the upper 7 bits, which gives a range of 0-127
            // Then, if the number is above 80s, we subtract 80 until it's within the range
            if (lfsr_reg[7:1] > 80) begin
                random_x <= lfsr_reg[7:1] - 80; // Adjust if the value is above 80
            end else begin
                random_x <= lfsr_reg[7:1]; // Directly use the value if it's 80 or below
            end
        end 
    end
endmodule
