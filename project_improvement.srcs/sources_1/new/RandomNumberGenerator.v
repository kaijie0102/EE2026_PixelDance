`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.03.2024 21:30:28
// Design Name: 
// Module Name: RandomNumberGenerator
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


module RandomNumberGenerator;
  int seed = 42;
  int unsigned randomNumber;
  
  initial begin
    randomNumber = $urandom(seed);
    $display("Random unsigned number: %d", randomNumber);
  end
endmodule
