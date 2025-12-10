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
    input         clk,               // 100MHz System Clock (W5)
    input         btnC,              // Reset Button (U18)
    inout [7:0]   JB,                // Pmod JB (MAXSONAR)
    output        amp_audio_out,     // Pmod JA1 (J1) - Audio Signal
    output        amp_shutdown,      // Pmod JA4 (G2) - Amp ON/OFF
    output        amp_gain,          // Pmod JA2 (L2) - Gain Control
    output [0:0]  led                // On-board LED 0 (V15)
    );
      
    // --- 1. SYSTEM CONTROL & INTERNAL WIRES ---
    wire rst;
    assign rst = btnC; // Center button is the reset

    // Wires for data transfer between modules
    wire sonar_trig;        // Output to Sonar (RX Pin)
    wire sonar_echo;        // Input from Sonar (PWM Pin)
    wire [31:0] w_tuning_word; // The final frequency value (M)
    wire [8:0]  w_distance;    // Distance in inches (0-255)
    wire        w_valid;       // Flag: New distance is ready
    wire        audio_out;     // Final square wave signal

    // --- 2. Pmod AMP2 HARDWARE CONFIGURATION ---
    // The AMP2 requires these static controls
    assign amp_shutdown = 1'b1;  // Set Shutdown HIGH to turn the amplifier ON
    assign amp_gain     = 1'b0;  // Set Gain LOW (safest volume)

    // --- 3. Pmod MAXSONAR TRISTATE LOGIC ---
    // The sonar uses JB: Pin 2 (RX/Trigger) and Pin 4 (PWM/Echo).
    // Pmod Pin 2 (RX) is Trigger -> JB[1] (OUTPUT from FPGA)
    // Pmod Pin 4 (PWM) is Echo   -> JB[3] (INPUT to FPGA)
    
    // Drive Trigger Output (Sonar RX)
    assign JB[1] = sonar_trig; 
    
    // Set Echo Pin to Input (High Impedance)
    assign JB[3] = 1'bz;       
    
    // Read the Echo signal from the physical pin
    assign sonar_echo = JB[3]; 
    
    // Set unused pins to Z (High Impedance) to be safe
    assign JB[0]   = 1'bz;
    assign JB[2]   = 1'bz;
    assign JB[7:4] = 4'bz;


    // --- 4. INSTANTIATE SONAR READER (Input Logic) ---
    // This reads the PWM pulse and converts it to a distance (w_distance)
    sonar inst_sonar (
        .clk(clk),
        .rst(rst),
        .sonar_pwm(sonar_echo),       // Connects the input signal
        .sonar_trigger(sonar_trig),   // Sends the trigger signal out
        .distance_in(w_distance),     // Outputs the raw distance
        .valid(w_valid)
    );
    
    // --- 5. DISTANCE TO FREQUENCY MAPPING LOGIC ---
    
//    // A. QUANTIZE & CLAMP
//    // Calculate the "Zone Index" directly here.
//    // Logic: If distance > 18, clamp index to 9. 
//    // Otherwise, divide distance by 2 (w_distance[4:1]) to get zones 0-9.
    wire [3:0] w_zone_index;
    assign w_zone_index = (w_distance > 9'd18) ? 4'd9 : w_distance[4:1];

      // B. FREQUENCY LOOKUP (Inline LUT)
      // We need a 'reg' variable to assign values inside an 'always' block
    reg [31:0] r_tuning_word;
    
      // Connect that register to your final output wire
    assign w_tuning_word = r_tuning_word;

    always @(*) begin
        case (w_zone_index)
              // Note: These HEX values assume a 100 MHz Clock. 
              // If using 50 MHz, divide these hex values by 2.
            
            4'd0: r_tuning_word = 32'h0000157C; // 0-1"   -> C3
            4'd1: r_tuning_word = 32'h00001869; // 2-3"   -> D3
            4'd2: r_tuning_word = 32'h00001B6A; // 4-5"   -> E3
            4'd3: r_tuning_word = 32'h00001C69; // 6-7"   -> F3
            4'd4: r_tuning_word = 32'h00002166; // 8-9"   -> G3
            4'd5: r_tuning_word = 32'h00002599; // 10-11" -> A3
            4'd6: r_tuning_word = 32'h00002AEC; // 12-13" -> B3
            4'd7: r_tuning_word = 32'h00002AF8; // 14-15" -> C4
            4'd8: r_tuning_word = 32'h0000310E; // 16-17" -> D4
            4'd9: r_tuning_word = 32'h000036D4; // 18"+   -> E4
            
            default: r_tuning_word = 32'd0;     // Silence/Safe default
        endcase
    end

//    assign w_tuning_word = { {23{1'b0}}, w_distance } * 100;

    // --- 6. INSTANTIATE AUDIO GENERATOR (Output Logic) ---
    // This takes the frequency (M value) and generates the square wave
    Audio_Devise my_sound_engine (
        .clk(clk),
        .tuning_word(w_tuning_word), // Distance-based frequency
        .audio_out(audio_out)        // Output signal
    );

    // --- 7. ASSIGN FINAL OUTPUTS ---
    assign amp_audio_out = audio_out; // To Pmod AMP2 Pin 1
