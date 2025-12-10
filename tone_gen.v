`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/01/2025 10:35:45 AM
// Design Name: 
// Module Name: tone_gen
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


module tone_gen(
    input clk, // 100Mhz system clock
    input [31:0] tuning_word, // 'M' value determines pitch
    output audio_out 
    ); 
    
    //Accumulator 
    reg [31:0] accumulator = 0; 
    
    // math logic 
    // M = (f_out) * 2^32) / f_clk
    always @(posedge clk) begin
        accumulator <= accumulator + tuning_word;
    end 
    
    // output 
    assign audio_out = accumulator[31];   

   
endmodule