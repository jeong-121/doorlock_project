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

    // Short timeout values for simulation.
    fsm_module #(
        .AUTO_LOCK_TICKS(10),
        .INPUT_TIMEOUT_TICKS(10)
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
        clk = 0;
        forever #0.5 clk = ~clk; // 1 kHz equivalent in this timescale
    end

    task press_digit;
        input [3:0] d;
        begin
            digit_in = d;
            key_valid = 1'b1;
            #2;
            key_valid = 1'b0;
            #2;
        end
    endtask

    task press_enter;
        begin
            enter = 1'b1;
            #2;
            enter = 1'b0;
            #2;
        end
    endtask

    initial begin
        digit_in = 0;
        key_valid = 0;
        enter = 0;
        change = 0;
        auto_open = 0;

        rst = 1;
        #3;
        rst = 0;
        #3;

        // Scenario 1: input inactivity timeout
        press_digit(4'd1);
        press_digit(4'd2);
        #15; // INPUT_TIMEOUT_TICKS exceeded
        if (state !== 3'd0) $display("ERROR: INPUT timeout did not return to IDLE");

        // Scenario 2: normal unlock with 1234
        press_digit(4'd1);
        press_digit(4'd2);
        press_digit(4'd3);
        press_digit(4'd4);
        press_enter();
        #3;
        if (state !== 3'd3 || unlock_on !== 1'b1) $display("ERROR: unlock failed");

        // Scenario 3: auto-lock after UNLOCK
        #15;
        if (state !== 3'd0 || unlock_on !== 1'b0) $display("ERROR: auto-lock failed");

        $display("Simulation finished");
        $stop;
    end

endmodule
