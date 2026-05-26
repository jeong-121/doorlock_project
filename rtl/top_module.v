// -----------------------------------------------------------------------------
// top_module.v
// Physical TACT_SW mapping + fsm_module integration.
// clk_1khz is assumed to be a 1 kHz clock.
//
// TACT_SW mapping
// [0]~[9]  : digit 0~9
// [10]     : enter / '#'
// [11]     : change / admin 'A'
// [12]     : inside-door auto_open button
// [13]     : reset
// [14]     : alarm clear
// -----------------------------------------------------------------------------
module top_module(
    input  wire        clk_1khz,
    input  wire [14:0] TACT_SW,
    output wire [7:0]  LEDR,
    output wire [2:0]  state,
    output wire [1:0]  fail_count_out,
    output wire [2:0]  digit_count_out,
    output wire [31:0] timer_count_out,
    output wire [31:0] timer_remain_ticks
);

    wire rst;
    wire enter;
    wire change;
    wire auto_open;
    wire alarm_clear;

    wire key_valid;
    wire [3:0] digit_in;

    wire unlock_on;
    wire alarm_on;
    wire locked_on;
    wire input_mode_on;
    wire change_mode_on;
    wire key_led;
    wire beep_on;
    wire [3:0] input_count_led;

    assign rst         = TACT_SW[13];
    assign alarm_clear = TACT_SW[14];
    assign enter       = TACT_SW[10];
    assign change      = TACT_SW[11];
    assign auto_open   = TACT_SW[12];

    assign key_valid = TACT_SW[0] | TACT_SW[1] | TACT_SW[2] | TACT_SW[3] |
                       TACT_SW[4] | TACT_SW[5] | TACT_SW[6] | TACT_SW[7] |
                       TACT_SW[8] | TACT_SW[9];

    assign digit_in =
        TACT_SW[0] ? 4'd0 :
        TACT_SW[1] ? 4'd1 :
        TACT_SW[2] ? 4'd2 :
        TACT_SW[3] ? 4'd3 :
        TACT_SW[4] ? 4'd4 :
        TACT_SW[5] ? 4'd5 :
        TACT_SW[6] ? 4'd6 :
        TACT_SW[7] ? 4'd7 :
        TACT_SW[8] ? 4'd8 :
        TACT_SW[9] ? 4'd9 :
                     4'd0;

    fsm_module #(
        .AUTO_LOCK_TICKS(10000)  // 1 kHz * 10 sec
    ) FSM (
        .clk(clk_1khz),
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

    assign LEDR[0] = input_count_led[0];
    assign LEDR[1] = input_count_led[1];
    assign LEDR[2] = input_count_led[2];
    assign LEDR[3] = input_count_led[3];
    assign LEDR[4] = key_led | beep_on;
    assign LEDR[5] = unlock_on;
    assign LEDR[6] = alarm_on;
    assign LEDR[7] = locked_on | input_mode_on | change_mode_on;

endmodule
