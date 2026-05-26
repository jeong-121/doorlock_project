`timescale 1ms/1us

module tb_fsm_module;
    reg clk;
    reg rst;
    reg [3:0] digit_in;
    reg key_valid;
    reg enter;
    reg change;
    reg auto_open;
    reg alarm_clear;

    wire unlock_on;
    wire alarm_on;
    wire locked_on;
    wire input_mode_on;
    wire change_mode_on;
    wire key_led;
    wire beep_on;
    wire [3:0] input_count_led;
    wire [2:0] state;
    wire [1:0] fail_count_out;
    wire [2:0] digit_count_out;
    wire [31:0] timer_count_out;
    wire [31:0] timer_remain_ticks;

    fsm_module #(
        .AUTO_LOCK_TICKS(10)
    ) DUT (
        .clk(clk),
        .rst(rst),
        .digit_in(digit_in),
        .key_valid(key_valid),
        .enter(enter),
        .change(change),
        .auto_open(auto_open),
        .alarm_clear(alarm_clear),
        .unlock_on(unlock_on),
        .alarm_on(alarm_on),
        .locked_on(locked_on),
        .input_mode_on(input_mode_on),
        .change_mode_on(change_mode_on),
        .key_led(key_led),
        .beep_on(beep_on),
        .input_count_led(input_count_led),
        .state(state),
        .fail_count_out(fail_count_out),
        .digit_count_out(digit_count_out),
        .timer_count_out(timer_count_out),
        .timer_remain_ticks(timer_remain_ticks)
    );

    always #0.5 clk = ~clk;

    task press_digit;
        input [3:0] d;
        begin
            digit_in = d;
            key_valid = 1'b1;
            #1;
            key_valid = 1'b0;
            #1;
        end
    endtask

    task press_enter;
        begin
            enter = 1'b1;
            #1;
            enter = 1'b0;
            #1;
        end
    endtask

    task press_change;
        begin
            change = 1'b1;
            #1;
            change = 1'b0;
            #1;
        end
    endtask

    task press_alarm_clear;
        begin
            alarm_clear = 1'b1;
            #1;
            alarm_clear = 1'b0;
            #1;
        end
    endtask

    task input_1234;
        begin
            press_digit(4'd1);
            press_digit(4'd2);
            press_digit(4'd3);
            press_digit(4'd4);
            press_enter;
        end
    endtask

    task input_9999;
        begin
            press_digit(4'd9);
            press_digit(4'd9);
            press_digit(4'd9);
            press_digit(4'd9);
            press_enter;
        end
    endtask

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        digit_in = 4'd0;
        key_valid = 1'b0;
        enter = 1'b0;
        change = 1'b0;
        auto_open = 1'b0;
        alarm_clear = 1'b0;

        #3 rst = 1'b0;

        // Test 1: correct default password 1234 -> UNLOCK
        input_1234;
        #2;
        if (!unlock_on) $display("FAIL: 1234 did not unlock");
        else $display("PASS: 1234 unlock");

        // Wait auto-lock
        #15;
        if (state != 3'd0) $display("FAIL: auto-lock did not return to IDLE");
        else $display("PASS: auto-lock return to IDLE");

        // Test 2: 3 wrong attempts -> ALARM
        input_9999;
        input_9999;
        input_9999;
        #2;
        if (!alarm_on) $display("FAIL: 3 failures did not trigger ALARM");
        else $display("PASS: 3 failures trigger ALARM");

        // Clear alarm
        press_alarm_clear;
        #2;
        if (state != 3'd0) $display("FAIL: alarm_clear did not return to IDLE");
        else $display("PASS: alarm_clear return to IDLE");

        // Test 3: change password to 5678 after unlock
        input_1234;
        #2;
        press_change;
        press_digit(4'd5);
        press_digit(4'd6);
        press_digit(4'd7);
        press_digit(4'd8);
        press_enter;
        #2;

        press_digit(4'd5);
        press_digit(4'd6);
        press_digit(4'd7);
        press_digit(4'd8);
        press_enter;
        #2;
        if (!unlock_on) $display("FAIL: changed password 5678 did not unlock");
        else $display("PASS: changed password 5678 unlock");

        $finish;
    end
endmodule
