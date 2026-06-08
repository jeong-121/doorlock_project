// input_manager.v
// Debounces 13 tact switches and converts them to the FSM interface.
// tact_sw[0..9] : digit 0..9
// tact_sw[10]   : ENTER
// tact_sw[11]   : CHANGE
// tact_sw[12]   : AUTO_OPEN
module input_manager #(
    parameter integer CLK_FREQ_HZ = 1000,
    parameter integer DEBOUNCE_MS = 20
)(
    input  wire        clk,
    input  wire        reset_n,
    input  wire [12:0] tact_sw,
    output wire [3:0]  digit_in,
    output wire        key_valid,
    output wire        enter,
    output wire        change,
    output wire        auto_open
);

    localparam integer STABLE_CYCLES = (CLK_FREQ_HZ * DEBOUNCE_MS) / 1000;

    wire [12:0] btn_state;

    genvar i;
    generate
        for (i = 0; i < 13; i = i + 1) begin : GEN_DEBOUNCE
            debouncer #(
                .STABLE_CYCLES(STABLE_CYCLES)
            ) U_DEBOUNCER (
                .clk(clk),
                .rst_n(reset_n),
                .din(tact_sw[i]),
                .dout(btn_state[i])
            );
        end
    endgenerate

    assign key_valid = |btn_state[9:0];

    assign digit_in =
        btn_state[0] ? 4'd0 :
        btn_state[1] ? 4'd1 :
        btn_state[2] ? 4'd2 :
        btn_state[3] ? 4'd3 :
        btn_state[4] ? 4'd4 :
        btn_state[5] ? 4'd5 :
        btn_state[6] ? 4'd6 :
        btn_state[7] ? 4'd7 :
        btn_state[8] ? 4'd8 :
        btn_state[9] ? 4'd9 :
                       4'd0;

    assign enter     = btn_state[10];
    assign change    = btn_state[11];
    assign auto_open = btn_state[12];

endmodule
