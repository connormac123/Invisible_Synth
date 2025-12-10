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
    input           clk,          // 100MHz System Clock
    input           btnC,         // Reset Button
    input [15:0]    sw,           // SWITCHES (Because why not)
    inout [7:0]     JB,           // Pmod JB (Tristate for Sonar)
    output [15:0]   led,          // 16 LEDs
    output [3:0]    JA            // Pmod JA (Gain Control)
    );
      
    wire rst;
    assign rst = btnC;

    // Internal Wires
    wire sonar_trig;
    wire sonar_echo;
    wire [8:0] w_distance;      
    wire       w_valid;   
    wire        audio_out;     // Final square wave signal   
    
    // --- Audio Amp Connections ---
    assign JA[0] = audio_out;  // JA1: Audio Signal
    assign JA[1] = 1'b0;       // JA2: Gain (Low = 6dB)
    assign JA[2] = 1'b0;       // JA3: Unused (Ground/Low)
    assign JA[3] = 1'b1;       // JA4: Shutdown (High = Amp ON)   

    // --- Tristate Logic ---
    assign JB[1] = sonar_trig; 
    assign JB[3] = 1'bz;       
    assign sonar_echo = JB[3]; 
    
    
        // Drive Trigger Output (Sonar RX)
    assign JB[1] = sonar_trig; 
    
    // Set Echo Pin to Input (High Impedance)
    assign JB[3] = 1'bz;       
    
    // Read the Echo signal from the physical pin
    assign sonar_echo = JB[3]; 
    
    assign amp_shutdown = 1'b1;  // Set Shutdown HIGH to turn the amplifier ON
    assign amp_gain     = 1'b0;  // Set Gain LOW (safest volume)
    
    // --- Sensor Driver ---
    sonar inst_sonar (
        .clk(clk),
        .rst(rst),
        .sonar_pwm(sonar_echo),     
        .sonar_trigger(sonar_trig), 
        .distance_in(w_distance),   
        .valid(w_valid)
    );

    
    reg [15:0] led_bar_reg;
    reg [31:0] r_tuning_word;
    
    always @(*) begin
        // Default: Silence (0 Hz)
        r_tuning_word = 0; 
        
        if (w_distance < 12) begin
            // Too close / Noise: Silence
            r_tuning_word = 0; 
        end
        else if (w_distance < 20) begin
            // Note C4 (Middle C) - 261 Hz
            r_tuning_word = 32'd11236; 
        end
        else if (w_distance < 28) begin
            // Note D4 - 294 Hz
            r_tuning_word = 32'd12612; 
        end
        else if (w_distance < 36) begin
            // Note E4 - 330 Hz
            r_tuning_word = 32'd14157; 
        end
        else if (w_distance < 44) begin
            // Note F4 - 349 Hz
            r_tuning_word = 32'd15000; 
        end
        else if (w_distance < 52) begin
            // Note G4 - 392 Hz
            r_tuning_word = 32'd16836; 
        end
        else if (w_distance < 60) begin
            // Note A4 - 440 Hz
            r_tuning_word = 32'd18899; 
        end
        else if (w_distance < 68) begin
            // Note B4 - 494 Hz
            r_tuning_word = 32'd21213; 
        end
        else if (w_distance < 76) begin
            // Note C5 (High C) - 523 Hz
            r_tuning_word = 32'd22472; 
        end
        else begin
            // > 68 inches: Out of range (Silence)
            r_tuning_word = 0;
        end
    end

    // --- Audio Tone Generator ---
    tone_gen inst_audio (
        .clk(clk),
        .tuning_word(r_tuning_word), // Distance-based frequency
        .audio_out(audio_out)        // Output signal
    );
    
    // Output assignment
    assign amp_audio_out = audio_out;
    
    always @(*) begin
        // Reset all to 0 first
        led_bar_reg = 16'b0;
        
        // Check thresholds in 4-inch increments
        if (w_distance >= 8)   led_bar_reg[0]  = 1'b1;
        if (w_distance >= 12)  led_bar_reg[1]  = 1'b1;
        if (w_distance >= 16)  led_bar_reg[2]  = 1'b1;
        if (w_distance >= 20)  led_bar_reg[3]  = 1'b1;
        if (w_distance >= 24)  led_bar_reg[4]  = 1'b1;
        if (w_distance >= 28)  led_bar_reg[5]  = 1'b1;
        if (w_distance >= 32)  led_bar_reg[6]  = 1'b1;
        if (w_distance >= 36)  led_bar_reg[7]  = 1'b1; // Halfway (2.8 feet)
        if (w_distance >= 40)  led_bar_reg[8]  = 1'b1;
        if (w_distance >= 44)  led_bar_reg[9]  = 1'b1;
        if (w_distance >= 48)  led_bar_reg[10] = 1'b1;
        if (w_distance >= 52)  led_bar_reg[11] = 1'b1;
        if (w_distance >= 56) led_bar_reg[12] = 1'b1;
        if (w_distance >= 60) led_bar_reg[13] = 1'b1;
        if (w_distance >= 64) led_bar_reg[14] = 1'b1;
        if (w_distance >= 68) led_bar_reg[15] = 1'b1; // Max (~5.3 feet)
        
        if (w_distance > 72) begin
            led_bar_reg = 16'b0;
        end
    end
    
    assign led = led_bar_reg;

endmodule