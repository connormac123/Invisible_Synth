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


`timescale 1ns / 1ps

module sonar #(
    parameter CLK_FREQ_HZ = 100_000_000
)(
    input  wire         clk,
    input  wire         rst,
    input  wire         sonar_pwm,    
    output reg          sonar_trigger,
    output reg [8:0]    distance_in,
    output reg          valid
);

    // The sensor defines 147us per inch.
    // 147us * 100MHz clock = 14,700 cycles per inch.
    localparam CYCLES_PER_INCH = 14_700;
    
    // Wait time between pings (e.g., 60ms) so echoes die down.
    localparam REFRESH_TICK_MAX = 6_000_000; 

    localparam S_IDLE       = 0;
    localparam S_TRIGGER    = 1;
    localparam S_WAIT_HIGH  = 2;
    localparam S_MEASURE    = 3;
    localparam S_COOLDOWN   = 4;

    reg [2:0] state;
    // General purpose timer for trigger pulse and cooldown
    reg [31:0] timer_counter; 
    
    // Specific timers for measuring the PWM pulse width
    reg [31:0] inch_counter_timer;
    reg [8:0]  current_distance_count;

    // --- Synchronization of Input Signal ---
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
    
    // --- Edge Detection ---
    reg pwm_prev;
    wire pwm_rising, pwm_falling;
    always @(posedge clk) begin
        if (rst) pwm_prev <= 0;
        else     pwm_prev <= pwm_sync_1;
    end
    assign pwm_rising  = (pwm_sync_1 && !pwm_prev);
    assign pwm_falling = (!pwm_sync_1 && pwm_prev);

    // --- Main FSM ---
    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
            sonar_trigger <= 0;
            timer_counter <= 0;
            distance_in <= 0;
            valid <= 0;
            inch_counter_timer <= 0;
            current_distance_count <= 0;
        end else begin
            valid <= 0; // Default
            
            case (state)
                S_IDLE: begin
                    timer_counter <= 0;
                    state <= S_TRIGGER;
                end

                S_TRIGGER: begin
                    // Hold trigger high for > 20us (2000 cycles) to initiate read
                    sonar_trigger <= 1;
                    timer_counter <= timer_counter + 1;
                    if (timer_counter > 2000) begin 
                        sonar_trigger <= 0;
                        state <= S_WAIT_HIGH;
                        timer_counter <= 0;
                    end
                end

                S_WAIT_HIGH: begin
                    // Wait for sensor to pull PWM line high
                    if (pwm_rising) begin
                        // Reset measurement counters
                        inch_counter_timer <= 0;
                        current_distance_count <= 0;
                        state <= S_MEASURE;
                    end
                    // Timeout safety if sensor is disconnected
                    else if (timer_counter > REFRESH_TICK_MAX) begin
                        state <= S_COOLDOWN; 
                        timer_counter <= 0;
                    end
                    else begin
                         timer_counter <= timer_counter + 1;
                    end
                end

                S_MEASURE: begin
                    if (pwm_falling) begin
                        // Pulse finished. Latch the result.
                        distance_in <= current_distance_count;
                        valid <= 1;
                        timer_counter <= 0;
                        state <= S_COOLDOWN;
                    end else begin
                        // While PWM is high, increment a timer.
                        // Every time the timer hits 14,700 cycles, increment inch count.
                        if (inch_counter_timer >= CYCLES_PER_INCH) begin
                            current_distance_count <= current_distance_count + 1;
                            inch_counter_timer <= 0;
                        end else begin
                            inch_counter_timer <= inch_counter_timer + 1;
                        end
                    end
                end

                S_COOLDOWN: begin
                    // Wait rest of cycle before pinging again
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
