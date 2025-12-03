`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/01/2025 09:49:52 AM
// Design Name: 
// Module Name: Top_AirSynth
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

module Top_AirSynth(
    input clk,               // 100MHz System Clock
    output amp_audio_out,    // Pmod Pin 1 (AIN): The Audio Signal
    output amp_gain,         // Pmod Pin 2 (GAIN): Volume Control
    output amp_shutdown      // Pmod Pin 4 (SHUT): On/Off Switch
    );

    // --- 1. HARDWARE CONFIGURATION ---
    // The Pmod AMP2 requires these signals to be constant to work.
    assign amp_gain = 1'b0;      // Set Gain Low (6dB) to protect hearing/speakers
    assign amp_shutdown = 1'b1;  // Set Shutdown HIGH (Active Low) to turn the amp ON

    // --- 2. LOGIC SETUP ---
    // Define the specific Note value (e.g., 440Hz)
    // Formula: M = 440 * 2^32 / 100,000,000 = 18898
    wire [31:0] current_note_M = 18898; 

    // --- 3. INSTANTIATE THE GENERATOR ---
    // This connects your "Engine" (audio_generator) to the "Car" (Top Module)
    Audio_Devise my_sound_engine (
        .clk(clk),
        .tuning_word(current_note_M),
        .audio_out(amp_audio_out)  // This signal goes out to Pmod Pin 1 (J1)
    );

endmodule