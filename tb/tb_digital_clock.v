`timescale 1ns / 1ps

module tb_digital_clock;

    reg clk;
    reg rst_n;
    reg btn_mode;
    reg btn_up;
    reg btn_snooze;
    reg switch_alm_en;
    
    wire [6:0] seg;
    wire [3:0] an;
    wire buzzer;

    // Instantiate with a low clock frequency for fast simulation
    digital_clock_top #(
        .CLK_FREQ(50) // Dramatically speeds up timekeeping in sim
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .btn_mode(btn_mode),
        .btn_up(btn_up),
        .btn_snooze(btn_snooze),
        .switch_alm_en(switch_alm_en),
        .seg(seg),
        .an(an),
        .buzzer(buzzer)
    );

    // 50MHz Clock Generation
    always #10 clk = ~clk; 

    initial begin
        // Initialize Inputs
        clk = 0; rst_n = 0; btn_mode = 0; btn_up = 0; 
        btn_snooze = 0; switch_alm_en = 0;

        // Reset system
        #100; rst_n = 1;

        // --- TEST 1: Normal Timekeeping ---
        #5000; 

        // --- TEST 2: Set Alarm to 12:02 ---
        // Press Mode 3 times to enter Alarm Min Set state
        btn_mode = 1; #100; btn_mode = 0; #1000; // State 01 (Set HR)
        btn_mode = 1; #100; btn_mode = 0; #1000; // State 01 (Set MIN)
        btn_mode = 1; #100; btn_mode = 0; #1000; // State 10 (Set ALM HR)
        btn_mode = 1; #100; btn_mode = 0; #1000; // State 10 (Set ALM MIN)
        
        // Increment Alarm Minute to 02
        btn_up = 1; #100; btn_up = 0; #1000;
        
        // Exit Set Mode
        btn_mode = 1; #100; btn_mode = 0; #1000; 
        
        // --- TEST 3: Enable Alarm and Wait for Match ---
        switch_alm_en = 1;
        
        // Wait for time to reach 12:02 (Will trigger buzzer)
        #50000; 
        
        // --- TEST 4: Snooze Feature ---
        // Trigger snooze, buzzer should turn off, alarm shifts to 12:07
        btn_snooze = 1; #100; btn_snooze = 0;
        
        #50000;
        
        $display("Simulation Complete.");
        $finish;
    end
endmodule