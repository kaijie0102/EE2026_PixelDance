`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.04.2024 11:48:15
// Design Name: 
// Module Name: trigger
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: This file is used to trigger a flag every x seconds. x will be defined by trigger_count.
// 
//////////////////////////////////////////////////////////////////////////////////


module trigger(
    input clk, 
    input [31:0] trigger_count,
    output reg trigger_bit = 0
    );
    
    // Formula for converting frequency to trigger_count. trigger_count = 100M / required_frequency
    // Eg. 6.25MHz: (100M/6.25M) / 2 = 16 --> trigger_count = 16
    
    // 1Hz: counts = 50_000_000
    // 5Hz: counts = 10_000_000
    // 10Hz: counts = 5_000_000
    // 100Hz: counts = 500_000
    
    reg [31:0]counter_32bits = 1;
    
    always @(posedge clk)
    begin
        counter_32bits <= (counter_32bits == trigger_count - 1) ? 0 : counter_32bits + 1;
        trigger_bit <= (counter_32bits >= 0 && counter_32bits < 50_000_000) ? 1 : 0;
    end
endmodule
