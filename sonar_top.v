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


`timescale 1ns / 1ps

module sonar_top(
    input         clk,          // 100MHz System Clock
    input         btnC,         // Reset Button
    inout [7:0]   JB,           // Pmod JB
    output [0:0]  JA,           // speaker/amp
    output [0:0]  led
    );
      

    wire rst;
    assign rst = btnC;

    // Internal Wires
    wire sonar_trig;
    wire sonar_echo;
    wire [8:0]  w_distance;     
    wire        w_valid;         
    wire [31:0] w_tuning_word;   
    wire        audio_out;       

    // 2. FIX: Tristate Logic for JB
    // Pmod Pin 2 (RX) is Trigger -> JB[1]
    // Pmod Pin 4 (PWM) is Echo   -> JB[3]
    
    assign JB[1] = sonar_trig; // Drive Trigger Output
    assign JB[3] = 1'bz;       // Set Echo Pin to Input (High Impedance)
    assign sonar_echo = JB[3]; // Read from Echo Pin
    
    // Set unused pins to Z (High Impedance) to be safe
    assign JB[0]   = 1'bz;
    assign JB[2]   = 1'bz;
    assign JB[7:4] = 4'bz;

    // Assign outputs
    assign led[0] = audio_out;
    assign JA[0]  = audio_out; 
    
    sonar inst_sonar (
        .clk(clk),
        .rst(rst),
        .sonar_pwm(sonar_echo),   // Connect input wire
        .sonar_trigger(sonar_trig), // Connect output wire
        .distance_in(w_distance), 
        .valid(w_valid)
    );

    // Calculate Tuning Word
    assign w_tuning_word = 32'd10000 + (w_distance * 32'd2000);

    tone_gen inst_dds (
        .clk(clk),
        .rst(rst),
        .tuning_word(w_tuning_word), 
        .audio_pwm_out(audio_out)    
    );

endmodule
