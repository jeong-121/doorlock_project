// -----------------------------------------------------------------------------
// piezo_alarm.v
// Piezo sound controller for clk_1khz.
//
// Inputs:
// - key_beep  : short beep on password digit input
// - unlock_on : plays a success melody when rising edge is detected
// - alarm_on  : alarm beeps while high. If FSM holds alarm_on for 10s, alarm is 10s.
//
// Note: with a 1 kHz clock, accurate musical notes are limited. The melody uses
// low-octave approximations of Do-Mi-Sol-Do by dividing the 1 kHz clock.
// For accurate pitches, use a faster clock such as CLK_1MHz.
// -----------------------------------------------------------------------------
module piezo_alarm(
    input  wire clk,        // 1 kHz system clock
    input  wire rst,        // active-high reset
    input  wire alarm_on,
    input  wire key_beep,
    input  wire unlock_on,
    output reg  piezo
);

    localparam MODE_IDLE   = 2'd0;
    localparam MODE_KEY    = 2'd1;
    localparam MODE_UNLOCK = 2'd2;
    localparam MODE_ALARM  = 2'd3;

    reg [1:0] mode;
    reg unlock_prev;
    wire unlock_pulse;
    assign unlock_pulse = unlock_on & ~unlock_prev;

    reg tone;
    reg [15:0] duration_cnt;
    reg [15:0] tone_cnt;
    reg [15:0] half_period;
    reg [2:0]  note_idx;
    reg        gate;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            unlock_prev <= 1'b0;
        end else begin
            unlock_prev <= unlock_on;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mode         <= MODE_IDLE;
            tone         <= 1'b0;
            duration_cnt <= 16'd0;
            tone_cnt     <= 16'd0;
            half_period  <= 16'd1;
            note_idx     <= 3'd0;
            gate         <= 1'b0;
            piezo        <= 1'b0;
        end else begin
            // Alarm has highest priority.
            if (alarm_on) begin
                mode <= MODE_ALARM;
            end else if (unlock_pulse) begin
                mode         <= MODE_UNLOCK;
                duration_cnt <= 16'd0;
                tone_cnt     <= 16'd0;
                note_idx     <= 3'd0;
                tone         <= 1'b0;
                half_period  <= 16'd4;   // Do approximation
            end else if (key_beep && mode == MODE_IDLE) begin
                mode         <= MODE_KEY;
                duration_cnt <= 16'd0;
                tone_cnt     <= 16'd0;
                tone         <= 1'b0;
                half_period  <= 16'd1;   // short 500 Hz beep
            end

            case (mode)
                MODE_IDLE: begin
                    piezo <= 1'b0;
                    gate  <= 1'b0;
                    tone_cnt <= 16'd0;
                    duration_cnt <= 16'd0;
                end

                MODE_KEY: begin
                    // 80 ms key beep.
                    if (duration_cnt >= 16'd80) begin
                        mode  <= MODE_IDLE;
                        piezo <= 1'b0;
                    end else begin
                        duration_cnt <= duration_cnt + 16'd1;
                        if (tone_cnt >= half_period - 1) begin
                            tone_cnt <= 16'd0;
                            tone <= ~tone;
                        end else begin
                            tone_cnt <= tone_cnt + 16'd1;
                        end
                        piezo <= tone;
                    end
                end

                MODE_UNLOCK: begin
                    // Four-note success melody: Do-Mi-Sol-Do, 180 ms per note.
                    if (duration_cnt >= 16'd180) begin
                        duration_cnt <= 16'd0;
                        tone_cnt <= 16'd0;
                        tone <= 1'b0;

                        if (note_idx == 3'd3) begin
                            note_idx <= 3'd0;
                            mode <= MODE_IDLE;
                            piezo <= 1'b0;
                        end else begin
                            note_idx <= note_idx + 3'd1;
                            case (note_idx + 3'd1)
                                3'd1: half_period <= 16'd3; // Mi approximation
                                3'd2: half_period <= 16'd2; // Sol approximation
                                default: half_period <= 16'd1; // high Do approximation
                            endcase
                        end
                    end else begin
                        duration_cnt <= duration_cnt + 16'd1;
                        if (tone_cnt >= half_period - 1) begin
                            tone_cnt <= 16'd0;
                            tone <= ~tone;
                        end else begin
                            tone_cnt <= tone_cnt + 16'd1;
                        end
                        piezo <= tone;
                    end
                end

                MODE_ALARM: begin
                    if (!alarm_on) begin
                        mode  <= MODE_IDLE;
                        piezo <= 1'b0;
                        duration_cnt <= 16'd0;
                        gate <= 1'b0;
                    end else begin
                        // Repeated 200 ms ON / 200 ms OFF alarm beep.
                        if (duration_cnt >= 16'd200) begin
                            duration_cnt <= 16'd0;
                            gate <= ~gate;
                        end else begin
                            duration_cnt <= duration_cnt + 16'd1;
                        end

                        if (tone_cnt >= 16'd1) begin
                            tone_cnt <= 16'd0;
                            tone <= ~tone;
                        end else begin
                            tone_cnt <= tone_cnt + 16'd1;
                        end
                        piezo <= gate ? tone : 1'b0;
                    end
                end

                default: begin
                    mode  <= MODE_IDLE;
                    piezo <= 1'b0;
                end
            endcase
        end
    end

endmodule
