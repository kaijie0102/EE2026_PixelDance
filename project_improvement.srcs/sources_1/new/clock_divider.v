`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/06/2024 06:10:42 PM
// Design Name: 
// Module Name: clock_divider
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


module clock_divider(
    input CLK,
    input [31:0] frequency,
    output reg slow_clk = 0
    );
    wire [31:0] div;
    wire [31:0] newdiv;
    assign div = (100000000 / frequency ) - 1;
    
    reg [31:0] COUNT = 32'd0;
    
    always @ (posedge CLK) begin
        COUNT <= ((COUNT >= div) ? 32'd0 : COUNT + 1);
        slow_clk <= COUNT == 0;
    end
endmodule
