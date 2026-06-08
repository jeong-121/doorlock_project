module top_module(
    input  wire        clk_1khz,
    input  wire        RESET_N,
    input  wire [12:0] TACT_SW,

    output wire [15:0] LEDR,

    output wire [7:0]  FND_SEG,
    output wire [3:0]  FND_COM,

    output wire        CLCD_RS,
    output wire        CLCD_RW,
    output wire        CLCD_E,
    output wire [7:0]  CLCD_DATA,

    output wire        piezo
);

    wire rst;
    assign rst = ~RESET_N;

    wire        key_valid;
    wire [3:0]  digit_in;
    wire        enter;
    wire        change;
    wire        auto_open;

    input_manager #(
        .CLK_FREQ_HZ(1000),
        .DEBOUNCE_MS(20)
    ) U_INPUT (
        .clk(clk_1khz),
        .reset_n(RESET_N),
        .tact_sw(TACT_SW),
        .digit_in(digit_in),
        .key_valid(key_valid),
        .enter(enter),
        .change(change),
        .auto_open(auto_open)
    );

    wire        unlock_on;
    wire        alarm_on;
    wire        key_led;
    wire [3:0]  input_count_led;
    wire [2:0]  state;

    fsm_module #(
        .AUTO_LOCK_TICKS(10000),
        .INPUT_TIMEOUT_TICKS(10000),
        .ALARM_TICKS(10000)
    ) U_FSM (
        .clk(clk_1khz),
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

    wire [2:0] input_cnt;
    assign input_cnt = {2'b00, input_count_led[0]}
                     + {2'b00, input_count_led[1]}
                     + {2'b00, input_count_led[2]}
                     + {2'b00, input_count_led[3]};

    fnd_team_adapter U_FND (
        .clk(clk_1khz),
        .rst(rst),
        .state(state),
        .input_count_led(input_count_led),
        .fnd_seg(FND_SEG),
        .fnd_com(FND_COM)
    );

    lcd_controller #(
        .CLK_HZ(1000)
    ) U_LCD (
        .clk(clk_1khz),
        .rst_n(RESET_N),
        .state(state),
        .input_cnt(input_cnt),
        .lcd_rs(CLCD_RS),
        .lcd_rw(CLCD_RW),
        .lcd_e(CLCD_E),
        .lcd_data(CLCD_DATA)
    );

    reg [9:0] blink_cnt;
    reg       blink;
    always @(posedge clk_1khz or posedge rst) begin
        if (rst) begin
            blink_cnt <= 10'd0;
            blink     <= 1'b0;
        end else if (blink_cnt >= 10'd166) begin
            blink_cnt <= 10'd0;
            blink     <= ~blink;
        end else begin
            blink_cnt <= blink_cnt + 10'd1;
        end
    end

    led_controller U_LED (
        .clk(clk_1khz),
        .rst_n(RESET_N),
        .state(state),
        .input_cnt(input_cnt),
        .blink(blink),
        .led(LEDR)
    );

    piezo_alarm U_PIEZO (
        .clk(clk_1khz),
        .rst(rst),
        .alarm_on(alarm_on),
        .key_beep(key_led),
        .unlock_on(unlock_on),
        .piezo(piezo)
    );

endmodule
