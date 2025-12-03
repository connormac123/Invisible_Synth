`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/01/2025 10:00:16 AM
// Design Name: 
// Module Name: sonar_top
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


module sonar_top(
    input         clk,          // 100MHz System Clock
    input         btnC,          // Reset Button
    input [3:3] JB, //sonar echo
    output [2:2] JC, //sonar trig
    output [0:0] JA, //speaker/amp
    output [0:0] led
    );
      
    assign btnC = rst;
    assign JC[2] = sonar_trig;
    assign JB[3] = sonar_echo;
    assign led[0] = audio_out;
    
    wire [8:0]  w_distance;      // Distance in inches (from Sonar)
    wire        w_valid;         // "New data ready" pulse
    wire [31:0] w_tuning_word;   // The "M" value for the synth
    wire        w_audio_pwm;     // The final 1-bit audio signal

    sonar inst_sonar (
        .clk(clk),
        .rst(rst),
        .sonar_pwm(sonar_echo),   // Connect input pin
        .sonar_trigger(sonar_trig), // Connect output pin
        .distance_in(w_distance), // Output data to wire
        .valid(w_valid)
    );

    // We need to calculate 'M' (Tuning Word) based on distance.
    // Logic: Higher Distance = Lower Pitch? Or Higher Pitch?
    // Let's do: Base Frequency + (Distance * Scaler)
    
    // Example: Base M for 200Hz is ~8589. 
    // Let's make it change drastically with distance.
    // tuning_word = 10,000 + (distance * 2000)
    
    assign w_tuning_word = 32'd10000 + (w_distance * 32'd2000);

    tone_gen inst_dds (
        .clk(clk),
        .rst(rst),
        .tuning_word(w_tuning_word), // Input the calculated M
        .audio_pwm_out(audio_out)    // Output the sound
    );
   

endmodule


