`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.04.2024 09:25:15
// Design Name: 
// Module Name: random_shape_generator
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


module random_shape_generator(
    input clk,
    input get_new, // when get_new flag is 1, obtain new number
    output reg [3:0] random_shape // 5 shapes to drop, C, D, L, R, U
    );
    
    reg [7:0] lfsr_reg; // Keep the LFSR as 8-bit for good sequence properties
    
    initial begin
        lfsr_reg <= 8'b0001_0001; // 0 -> 42 -> 34
    end
    
    reg [3:0] ones;
    reg generate_new = 1;
    always @(posedge clk) begin
        if (get_new == 0 && generate_new == 0) generate_new = 1;

        // Shift left by one bit and insert the new feedback bit at position 0
        lfsr_reg <= {lfsr_reg[6:0], (lfsr_reg[7] ^ lfsr_reg[6])};   
        if (get_new && generate_new) begin 
            // Scale the output to be within 0-4
            ones = lfsr_reg % 10;
            if (ones > 4) begin
                random_shape <= ones - 5; // Adjust if the value is above 5
            end else begin
                random_shape <= ones; // Directly use the value if it's 5 or below
            end
        end 
    end
endmodule