`timescale 1ns / 1ps

// ============================================================================
// Module: digital_clock_top
// Description: Advanced Digital Clock with Alarm, Snooze, and 7-Seg Multiplexing
// ============================================================================
module digital_clock_top #(
    parameter CLK_FREQ = 50_000_000 // 50 MHz default
)(
    input  wire clk,            // System Clock
    input  wire rst_n,          // Active-low Reset
    input  wire btn_mode,       // Toggle Modes: Run -> Set Time -> Set Alarm
    input  wire btn_up,         // Increment HR/MIN
    input  wire btn_snooze,     // Snooze Alarm (+5 mins)
    input  wire switch_alm_en,  // Enable/Disable Alarm
    output wire [6:0] seg,      // 7-Segment display (A-G)
    output wire [3:0] an,       // 7-Segment Anodes (Digit select)
    output reg  buzzer          // Alarm Buzzer/LED
);

    // --- Internal Signals ---
    wire tick_1hz, tick_1khz;
    wire db_mode, db_up, db_snooze;
    
    reg [5:0] sec, min, alm_min;
    reg [4:0] hr, alm_hr;
    
    reg [1:0] state; // 00: Run, 01: Set Time, 10: Set Alarm
    reg set_sel;     // 0: Set HR, 1: Set MIN
    
    // --- 1. Clock Dividers ---
    reg [25:0] cnt_1hz;
    reg [15:0] cnt_1khz;
    
    assign tick_1hz  = (cnt_1hz == CLK_FREQ - 1);
    assign tick_1khz = (cnt_1khz == (CLK_FREQ / 1000) - 1);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt_1hz <= 0;
            cnt_1khz <= 0;
        end else begin
            cnt_1hz  <= tick_1hz  ? 0 : cnt_1hz + 1;
            cnt_1khz <= tick_1khz ? 0 : cnt_1khz + 1;
        end
    end

    // --- 2. Button Debouncers (Simplified for 1kHz tick) ---
    // Instantiating debouncers for buttons
    debouncer d1 (.clk(clk), .rst_n(rst_n), .tick(tick_1khz), .btn_in(btn_mode), .btn_out(db_mode));
    debouncer d2 (.clk(clk), .rst_n(rst_n), .tick(tick_1khz), .btn_in(btn_up), .btn_out(db_up));
    debouncer d3 (.clk(clk), .rst_n(rst_n), .tick(tick_1khz), .btn_in(btn_snooze), .btn_out(db_snooze));

    // --- 3. UI State Machine ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= 2'b00;
            set_sel <= 0;
        end else if (db_mode) begin
            if (state == 2'b10 && set_sel == 1) begin
                state <= 2'b00; // Back to run mode
                set_sel <= 0;
            end else if (set_sel == 1) begin
                state <= state + 1;
                set_sel <= 0;
            end else begin
                set_sel <= 1; // Toggle to edit minutes
            end
        end
    end

    // --- 4. Timekeeping & Alarm Logic ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hr <= 5'd12; min <= 6'd0; sec <= 6'd0;
            alm_hr <= 5'd12; alm_min <= 6'd1;
        end else begin
            // Manual Setting
            if (db_up && state == 2'b01) begin // Set Time
                if (set_sel == 0) hr <= (hr == 23) ? 0 : hr + 1;
                else              min <= (min == 59) ? 0 : min + 1;
            end 
            else if (db_up && state == 2'b10) begin // Set Alarm
                if (set_sel == 0) alm_hr <= (alm_hr == 23) ? 0 : alm_hr + 1;
                else              alm_min <= (alm_min == 59) ? 0 : alm_min + 1;
            end
            
            // Snooze Logic (+5 mins)
            if (db_snooze && buzzer) begin
                if (alm_min >= 55) begin
                    alm_min <= alm_min + 5 - 60;
                    alm_hr  <= (alm_hr == 23) ? 0 : alm_hr + 1;
                end else begin
                    alm_min <= alm_min + 5;
                end
            end

            // Normal Timekeeping
            if (state == 2'b00 && tick_1hz) begin
                if (sec == 59) begin
                    sec <= 0;
                    if (min == 59) begin
                        min <= 0;
                        hr <= (hr == 23) ? 0 : hr + 1;
                    end else begin
                        min <= min + 1;
                    end
                end else begin
                    sec <= sec + 1;
                end
            end
        end
    end

    // --- 5. Alarm Comparator ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            buzzer <= 0;
        else if (switch_alm_en && (hr == alm_hr) && (min == alm_min) && (sec < 60)) // Ring for 1 min
            buzzer <= 1;
        else if (db_snooze || !switch_alm_en || (min != alm_min))
            buzzer <= 0;
    end

    // --- 6. Seven-Segment Multiplexing ---
    wire [4:0] disp_hr  = (state == 2'b10) ? alm_hr  : hr;
    wire [5:0] disp_min = (state == 2'b10) ? alm_min : min;
    
    wire [3:0] d3 = disp_hr / 10;   // Tens of Hour
    wire [3:0] d2 = disp_hr % 10;   // Ones of Hour
    wire [3:0] d1 = disp_min / 10;  // Tens of Minute
    wire [3:0] d0 = disp_min % 10;  // Ones of Minute

    reg [1:0] mux_sel;
    reg [3:0] current_digit;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) mux_sel <= 0;
        else if (tick_1khz) mux_sel <= mux_sel + 1;
    end

    always @(*) begin
        case(mux_sel)
            2'b00: current_digit = d0;
            2'b01: current_digit = d1;
            2'b10: current_digit = d2;
            2'b11: current_digit = d3;
            default: current_digit = 4'b0000;
        endcase
    end

    // Anode decoding (Active Low)
    assign an = ~(4'b0001 << mux_sel);

    // Cathode decoding (Active Low)
    assign seg = seg_decode(current_digit);

    function [6:0] seg_decode;
        input [3:0] num;
        case(num)
            4'h0: seg_decode = 7'b1000000; 
            4'h1: seg_decode = 7'b1111001; 
            4'h2: seg_decode = 7'b0100100; 
            4'h3: seg_decode = 7'b0110000;
            4'h4: seg_decode = 7'b0011001; 
            4'h5: seg_decode = 7'b0010010; 
            4'h6: seg_decode = 7'b0000010; 
            4'h7: seg_decode = 7'b1111000;
            4'h8: seg_decode = 7'b0000000; 
            4'h9: seg_decode = 7'b0010000; 
            default: seg_decode = 7'b1111111;
        endcase
    endfunction

endmodule

// ============================================================================
// Module: debouncer (One-Shot Pulse Generator)
// ============================================================================
module debouncer (
    input clk, rst_n, tick, btn_in,
    output reg btn_out
);
    reg [2:0] shift_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= 0;
            btn_out <= 0;
        end else if (tick) begin
            shift_reg <= {shift_reg[1:0], btn_in};
            // Trigger pulse only on rising edge of stable signal
            btn_out <= (shift_reg == 3'b011); 
        end else begin
            btn_out <= 0; // Ensure it's a single clock cycle pulse
        end
    end
endmodule