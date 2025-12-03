`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/01/2025 09:56:21 AM
// Design Name: 
// Module Name: sonar
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


module sonar #(
    parameter CLK_FREQ_HZ = 100_000_000
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        sonar_pwm,    // Input from Pmod pin 4
    output reg         sonar_trigger,// Output to Pmod pin 3 (The new addition)
    output reg [8:0]   distance_in,
    output reg         valid
);

    // --- Constants ---
    // 147us per inch.
    localparam CYCLES_PER_INCH = (CLK_FREQ_HZ / 1_000_000) * 147;
    
    // We need to wait roughly 60ms between pings to let echoes settle.
    // 60ms * 100MHz = 6,000,000 cycles.
    localparam REFRESH_TICK_MAX = 6_000_000; 

    // --- State Machine States (Satisfies FSM Requirement) ---
    localparam S_IDLE       = 0;
    localparam S_TRIGGER    = 1;
    localparam S_WAIT_HIGH  = 2;
    localparam S_MEASURE    = 3;
    localparam S_COOLDOWN   = 4;

    reg [2:0] state;
    reg [31:0] timer_counter; // Re-used for trigger timing and cooldown

    // --- Synchronization (Your code - Kept exactly the same) ---
    reg pwm_sync_0, pwm_sync_1;
    always @(posedge clk) begin
        if (rst) begin
            pwm_sync_0 <= 0;
            pwm_sync_1 <= 0;
        end else begin
            pwm_sync_0 <= sonar_pwm;
            pwm_sync_1 <= pwm_sync_0; 
        end
    end
    
    // --- Edge Detection (Your code - Kept exactly the same) ---
    reg pwm_prev;
    wire pwm_rising, pwm_falling;
    always @(posedge clk) begin
        if (rst) pwm_prev <= 0;
        else     pwm_prev <= pwm_sync_1;
    end
    assign pwm_rising  = (pwm_sync_1 && !pwm_prev);
    assign pwm_falling = (!pwm_sync_1 && pwm_prev);

    // --- The Main FSM Logic ---
    reg [31:0] pulse_width_counter;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
            sonar_trigger <= 0;
            pulse_width_counter <= 0;
            timer_counter <= 0;
            distance_in <= 0;
            valid <= 0;
        end else begin
            // Default valid to 0 (pulse it only for one cycle)
            valid <= 0; 
            
            case (state)
                S_IDLE: begin
                    // Start everything off
                    timer_counter <= 0;
                    state <= S_TRIGGER;
                end

                S_TRIGGER: begin
                    // Hold Trigger High for 10uS (1000 cycles at 100MHz)
                    sonar_trigger <= 1;
                    timer_counter <= timer_counter + 1;
                    if (timer_counter > 1000) begin
                        sonar_trigger <= 0;
                        state <= S_WAIT_HIGH;
                    end
                end

                S_WAIT_HIGH: begin
                    // Wait for the sensor to respond with the rising edge of PWM
                    if (pwm_rising) begin
                        pulse_width_counter <= 0;
                        state <= S_MEASURE;
                    end
                    // Safety: If sensor disconnects, don't hang forever.
                    // If we wait > 50ms without response, go to cooldown.
                    else if (timer_counter > REFRESH_TICK_MAX) begin
                        state <= S_COOLDOWN;
                        timer_counter <= 0;
                    end
                    else begin
                         timer_counter <= timer_counter + 1;
                    end
                end

                S_MEASURE: begin
                    // We are currently reading the pulse
                    if (pwm_falling) begin
                        // CALCULATION DONE HERE
                        distance_in <= pulse_width_counter / CYCLES_PER_INCH;
                        valid <= 1;
                        timer_counter <= 0;
                        state <= S_COOLDOWN;
                    end else begin
                        pulse_width_counter <= pulse_width_counter + 1;
                    end
                end

                S_COOLDOWN: begin
                    // Wait rest of the 60ms cycle before pinging again
                    if (timer_counter < REFRESH_TICK_MAX) begin
                        timer_counter <= timer_counter + 1;
                    end else begin
                        state <= S_IDLE;
                    end
                end
            endcase
        end
    end

endmodule
