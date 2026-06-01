`timescale 1ms/1us

module tb_fsm_module;
    reg clk;
    reg rst;
    reg [3:0] digit_in;
    reg key_valid;
    reg enter;
    reg change;
    reg auto_open;

    wire unlock_on;
    wire alarm_on;
    wire key_led;
    wire [3:0] input_count_led;
    wire [2:0] state;

    localparam IDLE   = 3'd0;
    localparam INPUT  = 3'd1;
    localparam CHECK  = 3'd2;
    localparam UNLOCK = 3'd3;
    localparam ALARM  = 3'd4;
    localparam CHANGE = 3'd5;

    // Short timeout for simulation only. Board top uses 10000 ticks = 10 seconds.
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
        .unlock_on(unlock_on),
        .alarm_on(alarm_on),
        .key_led(key_led),
        .input_count_led(input_count_led),
        .state(state)
    );

    initial begin
        clk = 1'b0;
        forever #0.5 clk = ~clk; // 1 kHz equivalent in ms timescale
    end

    task press_digit;
        input [3:0] value;
        begin
            @(negedge clk);
            digit_in = value;
            key_valid = 1'b1;
            @(negedge clk);
            key_valid = 1'b0;
            digit_in = 4'd0;
            repeat (2) @(negedge clk);
        end
    endtask

    task press_enter;
        begin
            @(negedge clk);
            enter = 1'b1;
            @(negedge clk);
            enter = 1'b0;
            repeat (2) @(negedge clk);
        end
    endtask

    task press_change;
        begin
            @(negedge clk);
            change = 1'b1;
            @(negedge clk);
            change = 1'b0;
            repeat (2) @(negedge clk);
        end
    endtask

    task input_password_1234;
        begin
            press_digit(4'd1);
            press_digit(4'd2);
            press_digit(4'd3);
            press_digit(4'd4);
            press_enter;
        end
    endtask

    task input_password_9999;
        begin
            press_digit(4'd9);
            press_digit(4'd9);
            press_digit(4'd9);
            press_digit(4'd9);
            press_enter;
        end
    endtask

    initial begin
        digit_in = 4'd0;
        key_valid = 1'b0;
        enter = 1'b0;
        change = 1'b0;
        auto_open = 1'b0;
        rst = 1'b1;
        repeat (3) @(negedge clk);
        rst = 1'b0;
        repeat (3) @(negedge clk);

        // 1) Correct default password 1234 -> UNLOCK.
        input_password_1234;
        repeat (3) @(negedge clk);
        if (state !== UNLOCK || unlock_on !== 1'b1) begin
            $display("FAIL: 1234 did not unlock");
            $finish;
        end

        // 2) Auto-lock after timeout -> IDLE.
        repeat (15) @(negedge clk);
        if (state !== IDLE || unlock_on !== 1'b0) begin
            $display("FAIL: auto-lock did not return to IDLE");
            $finish;
        end

        // 3) Three failures -> ALARM.
        input_password_9999;
        input_password_9999;
        input_password_9999;
        repeat (3) @(negedge clk);
        if (state !== ALARM || alarm_on !== 1'b1) begin
            $display("FAIL: three failures did not enter ALARM");
            $finish;
        end

        // 4) Reset clears ALARM and restores default password.
        rst = 1'b1;
        repeat (3) @(negedge clk);
        rst = 1'b0;
        repeat (3) @(negedge clk);
        if (state !== IDLE || alarm_on !== 1'b0) begin
            $display("FAIL: reset did not clear alarm");
            $finish;
        end

        // 5) Password change: unlock with 1234, change to 9999, then unlock with 9999.
        input_password_1234;
        repeat (3) @(negedge clk);
        press_change;
        press_digit(4'd9);
        press_digit(4'd9);
        press_digit(4'd9);
        press_digit(4'd9);
        press_enter;
        repeat (3) @(negedge clk);
        if (state !== IDLE) begin
            $display("FAIL: password change did not re-lock");
            $finish;
        end

        input_password_9999;
        repeat (3) @(negedge clk);
        if (state !== UNLOCK || unlock_on !== 1'b1) begin
            $display("FAIL: changed password 9999 did not unlock");
            $finish;
        end

        $display("PASS: password logic and auto-lock tests completed");
        $finish;
    end
endmodule
