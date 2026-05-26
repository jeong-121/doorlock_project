// -----------------------------------------------------------------------------
// fsm_module.v
// Digital doorlock main FSM with password logic and auto-lock support.
//
// 담당 구현 범위
// 1. Password comparator       : CHECK state, input_buffer == saved_password
// 2. Password change logic     : CHANGE state, saved_password <= input_buffer
// 3. Attempt counter           : fail_count, 3 failures -> ALARM
// 4. Auto-lock timer           : UNLOCK state, timer timeout -> IDLE
//
// Clock assumption: clk = 1 kHz from top_module.
// Default password: 16'h1234 means BCD digits 1,2,3,4.
// -----------------------------------------------------------------------------
module fsm_module #(
    parameter integer AUTO_LOCK_TICKS = 10000
)(
    input  wire       clk,
    input  wire       rst,

    input  wire [3:0] digit_in,
    input  wire       key_valid,
    input  wire       enter,       // keypad '#'
    input  wire       change,      // keypad 'A' or admin/change button
    input  wire       auto_open,   // inside-door immediate open button
    input  wire       alarm_clear, // admin/reset clear for ALARM state

    output reg        unlock_on,
    output reg        alarm_on,
    output reg        locked_on,
    output reg        input_mode_on,
    output reg        change_mode_on,
    output reg        key_led,
    output reg        beep_on,
    output reg  [3:0] input_count_led,
    output reg  [2:0] state,
    output reg  [1:0] fail_count_out,
    output reg  [2:0] digit_count_out,
    output wire [31:0] timer_count_out,
    output wire [31:0] timer_remain_ticks
);

    localparam IDLE   = 3'd0;
    localparam INPUT  = 3'd1;
    localparam CHECK  = 3'd2;
    localparam UNLOCK = 3'd3;
    localparam ALARM  = 3'd4;
    localparam CHANGE = 3'd5;

    reg [15:0] input_buffer;
    reg [15:0] saved_password;
    reg [2:0]  digit_count;   // 0~4. 4 means a complete 4-digit input exists.
    reg [1:0]  fail_count;    // 0~2. 3rd failure enters ALARM immediately.

    reg key_prev;
    reg enter_prev;
    reg change_prev;
    reg auto_open_prev;
    reg alarm_clear_prev;

    wire key_pulse;
    wire enter_pulse;
    wire change_pulse;
    wire auto_open_pulse;
    wire alarm_clear_pulse;
    wire auto_lock_timeout;
    wire auto_lock_enable;

    assign key_pulse         = key_valid & ~key_prev;
    assign enter_pulse       = enter & ~enter_prev;
    assign change_pulse      = change & ~change_prev;
    assign auto_open_pulse   = auto_open & ~auto_open_prev;
    assign alarm_clear_pulse = alarm_clear & ~alarm_clear_prev;

    assign auto_lock_enable = (state == UNLOCK);

    auto_lock_timer #(
        .TIMEOUT_TICKS(AUTO_LOCK_TICKS)
    ) AUTO_LOCK_TIMER (
        .clk(clk),
        .rst(rst),
        .enable(auto_lock_enable),
        .timeout(auto_lock_timeout),
        .count(timer_count_out),
        .remain_ticks(timer_remain_ticks)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            key_prev         <= 1'b0;
            enter_prev       <= 1'b0;
            change_prev      <= 1'b0;
            auto_open_prev   <= 1'b0;
            alarm_clear_prev <= 1'b0;
        end else begin
            key_prev         <= key_valid;
            enter_prev       <= enter;
            change_prev      <= change;
            auto_open_prev   <= auto_open;
            alarm_clear_prev <= alarm_clear;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state           <= IDLE;
            input_buffer    <= 16'd0;
            saved_password  <= 16'h1234;
            digit_count     <= 3'd0;
            fail_count      <= 2'd0;
            unlock_on       <= 1'b0;
            alarm_on        <= 1'b0;
            locked_on       <= 1'b1;
            input_mode_on   <= 1'b0;
            change_mode_on  <= 1'b0;
            key_led         <= 1'b0;
            beep_on         <= 1'b0;
            input_count_led <= 4'b0000;
            fail_count_out  <= 2'd0;
            digit_count_out <= 3'd0;
        end else begin
            key_led <= 1'b0;
            beep_on <= 1'b0;

            case (state)
                IDLE: begin
                    unlock_on       <= 1'b0;
                    alarm_on        <= 1'b0;
                    locked_on       <= 1'b1;
                    input_mode_on   <= 1'b0;
                    change_mode_on  <= 1'b0;
                    input_buffer    <= 16'd0;
                    digit_count     <= 3'd0;
                    input_count_led <= 4'b0000;

                    if (auto_open_pulse) begin
                        unlock_on <= 1'b1;
                        locked_on <= 1'b0;
                        state     <= UNLOCK;
                    end else if (key_pulse && (digit_in <= 4'd9)) begin
                        input_buffer    <= {12'd0, digit_in};
                        digit_count     <= 3'd1;
                        input_count_led <= 4'b0001;
                        key_led         <= 1'b1;
                        beep_on         <= 1'b1;
                        input_mode_on   <= 1'b1;
                        state           <= INPUT;
                    end
                end

                INPUT: begin
                    locked_on     <= 1'b1;
                    input_mode_on <= 1'b1;

                    if (auto_open_pulse) begin
                        unlock_on       <= 1'b1;
                        locked_on       <= 1'b0;
                        input_buffer    <= 16'd0;
                        digit_count     <= 3'd0;
                        input_count_led <= 4'b0000;
                        state           <= UNLOCK;
                    end else if (key_pulse && (digit_in <= 4'd9)) begin
                        key_led <= 1'b1;
                        beep_on <= 1'b1;

                        if (digit_count < 3'd4) begin
                            input_buffer <= {input_buffer[11:0], digit_in};
                            digit_count  <= digit_count + 3'd1;
                            case (digit_count + 3'd1)
                                3'd1: input_count_led <= 4'b0001;
                                3'd2: input_count_led <= 4'b0011;
                                3'd3: input_count_led <= 4'b0111;
                                default: input_count_led <= 4'b1111;
                            endcase
                        end
                    end else if (enter_pulse) begin
                        if (digit_count == 3'd4) begin
                            state <= CHECK;
                        end else begin
                            input_buffer    <= 16'd0;
                            digit_count     <= 3'd0;
                            input_count_led <= 4'b0000;
                            state           <= IDLE;
                        end
                    end
                end

                CHECK: begin
                    input_mode_on <= 1'b0;

                    if (input_buffer == saved_password) begin
                        unlock_on  <= 1'b1;
                        locked_on  <= 1'b0;
                        alarm_on   <= 1'b0;
                        fail_count <= 2'd0;
                        state      <= UNLOCK;
                    end else begin
                        unlock_on <= 1'b0;
                        locked_on <= 1'b1;

                        if (fail_count == 2'd2) begin
                            alarm_on   <= 1'b1;
                            fail_count <= 2'd0;
                            state      <= ALARM;
                        end else begin
                            fail_count      <= fail_count + 2'd1;
                            input_buffer    <= 16'd0;
                            digit_count     <= 3'd0;
                            input_count_led <= 4'b0000;
                            state           <= IDLE;
                        end
                    end
                end

                UNLOCK: begin
                    unlock_on      <= 1'b1;
                    locked_on      <= 1'b0;
                    alarm_on       <= 1'b0;
                    input_mode_on  <= 1'b0;
                    change_mode_on <= 1'b0;

                    if (auto_lock_timeout) begin
                        unlock_on       <= 1'b0;
                        locked_on       <= 1'b1;
                        input_buffer    <= 16'd0;
                        digit_count     <= 3'd0;
                        input_count_led <= 4'b0000;
                        state           <= IDLE;
                    end else if (change_pulse) begin
                        input_buffer    <= 16'd0;
                        digit_count     <= 3'd0;
                        input_count_led <= 4'b0000;
                        change_mode_on  <= 1'b1;
                        state           <= CHANGE;
                    end else if (enter_pulse) begin
                        unlock_on       <= 1'b0;
                        locked_on       <= 1'b1;
                        input_buffer    <= 16'd0;
                        digit_count     <= 3'd0;
                        input_count_led <= 4'b0000;
                        state           <= IDLE;
                    end
                end

                ALARM: begin
                    alarm_on       <= 1'b1;
                    unlock_on      <= 1'b0;
                    locked_on      <= 1'b1;
                    input_mode_on  <= 1'b0;
                    change_mode_on <= 1'b0;

                    if (alarm_clear_pulse) begin
                        alarm_on        <= 1'b0;
                        fail_count      <= 2'd0;
                        input_buffer    <= 16'd0;
                        digit_count     <= 3'd0;
                        input_count_led <= 4'b0000;
                        state           <= IDLE;
                    end else begin
                        state <= ALARM;
                    end
                end

                CHANGE: begin
                    unlock_on      <= 1'b1;
                    locked_on      <= 1'b0;
                    alarm_on       <= 1'b0;
                    change_mode_on <= 1'b1;

                    if (key_pulse && (digit_in <= 4'd9)) begin
                        key_led <= 1'b1;
                        beep_on <= 1'b1;

                        if (digit_count < 3'd4) begin
                            input_buffer <= {input_buffer[11:0], digit_in};
                            digit_count  <= digit_count + 3'd1;
                            case (digit_count + 3'd1)
                                3'd1: input_count_led <= 4'b0001;
                                3'd2: input_count_led <= 4'b0011;
                                3'd3: input_count_led <= 4'b0111;
                                default: input_count_led <= 4'b1111;
                            endcase
                        end
                    end else if (enter_pulse) begin
                        if (digit_count == 3'd4) begin
                            saved_password  <= input_buffer;
                            input_buffer    <= 16'd0;
                            digit_count     <= 3'd0;
                            input_count_led <= 4'b0000;
                            unlock_on       <= 1'b0;
                            locked_on       <= 1'b1;
                            change_mode_on  <= 1'b0;
                            state           <= IDLE;
                        end else begin
                            input_buffer    <= 16'd0;
                            digit_count     <= 3'd0;
                            input_count_led <= 4'b0000;
                            change_mode_on  <= 1'b0;
                            state           <= UNLOCK;
                        end
                    end
                end

                default: begin
                    state <= IDLE;
                end
            endcase

            fail_count_out  <= fail_count;
            digit_count_out <= digit_count;
        end
    end

endmodule
